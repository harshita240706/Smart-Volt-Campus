#include <WiFi.h>
#include "ThingSpeak.h"
#include <Wire.h>
#include <hd44780.h>
#include <hd44780ioClass/hd44780_I2Cexp.h>
#include <DHT.h>
#include <ESP32Servo.h>
#include <SPI.h>
#include <MFRC522.h>
#include <WebServer.h>

// --- Configuration ---
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
unsigned long myChannelNumber = 1234567; // Your Channel ID
const char* myWriteAPIKey = "YOUR_WRITE_KEY";

// --- Pin Definitions ---
#define DHTPIN 4
#define DHTTYPE DHT11
#define TRIG_PIN 16
#define ECHO_PIN 17
#define LED1 12
#define LED2 14
#define LED3 27
#define LED4 26
#define MQ135_PIN 34  // Analog
#define BUZZER_PIN 2
#define SERVO_PIN 15
#define SWITCH_PIN 33
#define RFID_SS 5
#define RFID_RST 32

// --- Objects ---
hd44780_I2Cexp lcd; // Auto-detects address, 16x2 configured in begin()
DHT dht(DHTPIN, DHTTYPE);
Servo windowServo;
MFRC522 mfrc522(RFID_SS, RFID_RST);
WiFiClient client;
WebServer server(80);

// --- State Variables ---
bool teacherPresent = false;
bool occupationDetected = false;
bool smokeDetected = false;
String mode = "auto"; // auto or manual
unsigned long lastActivityTime = 0;
unsigned long lastThingSpeakUpdate = 0;
unsigned long lastEnergyCalcTime = 0;
float totalEnergyWh = 0.0;
const float LED_POWER_WATTS = 0.05; // 50mW

void setup() {
  Serial.begin(115200);

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(LED1, OUTPUT);
  pinMode(LED2, OUTPUT);
  pinMode(LED3, OUTPUT);
  pinMode(LED4, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(SWITCH_PIN, INPUT_PULLUP);

  dht.begin();
  lcd.begin(16, 2);
  lcd.backlight();
  windowServo.attach(SERVO_PIN);
  windowServo.write(0); // Close window

  SPI.begin();
  mfrc522.PCD_Init();

  connectWiFi();
  ThingSpeak.begin(client);
  setupWebServer();

  lastActivityTime = millis();
  lastEnergyCalcTime = millis();
}

void loop() {
  server.handleClient();

  // 1. Check RFID (Teacher)
  if (mfrc522.PICC_IsNewCardPresent() && mfrc522.PICC_ReadCardSerial()) {
    teacherPresent = !teacherPresent; // Toggle teacher presence
    Serial.println(teacherPresent ? "Teacher Entered" : "Teacher Left");
    mfrc522.PICC_HaltA();
    lastActivityTime = millis();
  }

  // 2. Ultrasonic Sensing (Occupation)
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  long duration = pulseIn(ECHO_PIN, HIGH);
  float distance = duration * 0.034 / 2;

  if (distance > 0 && distance < 200) { // Detection range
    occupationDetected = true;
    lastActivityTime = millis();
  } else {
    occupationDetected = false;
  }

  // 3. Environment (DHT11)
  float temp = dht.readTemperature();
  float hum = dht.readHumidity();

  // 4. Smoke Detection (MQ135)
  int smokeLevel = analogRead(MQ135_PIN);
  smokeDetected = (smokeLevel > 1500); // Adjust threshold as needed

  // 5. Control Logic
  handleLEDs();
  handleSafety(smokeDetected);
  updateLCD(temp, hum, smokeDetected);

  // 6. Energy Calculation
  calculateEnergy();

  // 7. Power Management (Sleep)
  if (millis() - lastActivityTime > 900000) { // 15 mins
    goToSleep();
  }

  // 8. Cloud Update
  if (millis() - lastThingSpeakUpdate > 20000) {
    updateCloud(temp, hum, smokeLevel);
    lastThingSpeakUpdate = millis();
  }

  delay(500);
}

void handleLEDs() {
  bool manualSwitch = digitalRead(SWITCH_PIN) == LOW;

  if (mode == "manual") {
    digitalWrite(LED1, manualSwitch);
    digitalWrite(LED2, manualSwitch);
    digitalWrite(LED3, manualSwitch);
    digitalWrite(LED4, manualSwitch);
  } else {
    if (occupationDetected) {
      digitalWrite(LED1, HIGH);
      digitalWrite(LED2, HIGH);
      if (teacherPresent) {
        digitalWrite(LED3, HIGH);
        digitalWrite(LED4, HIGH);
      } else {
        digitalWrite(LED3, LOW);
        digitalWrite(LED4, LOW);
      }
    } else {
      digitalWrite(LED1, LOW);
      digitalWrite(LED2, LOW);
      digitalWrite(LED3, LOW);
      digitalWrite(LED4, LOW);
    }
  }
}

void handleSafety(bool smoke) {
  if (smoke) {
    digitalWrite(BUZZER_PIN, HIGH);
    windowServo.write(90);
  } else {
    digitalWrite(BUZZER_PIN, LOW);
    windowServo.write(0);
  }
}

void updateLCD(float t, float h, bool smoke) {
  lcd.clear();
  if (smoke) {
    lcd.setCursor(0,0);
    lcd.print("SMOKE DETECTED!");
    lcd.setCursor(0,1);
    lcd.print("EVACUATE NOW");
  } else {
    lcd.setCursor(0,0);
    lcd.print("T:"); lcd.print(t); lcd.print("C ");
    if (h > 70) lcd.print("Humid");
    else lcd.print("Fav.");

    lcd.setCursor(0,1);
    lcd.print("H:"); lcd.print(h); lcd.print("% ");
    if (teacherPresent) lcd.print("Tchr IN");
    else if (occupationDetected) lcd.print("Occupy");
  }
}

void calculateEnergy() {
  unsigned long currentTime = millis();
  float durationHours = (currentTime - lastEnergyCalcTime) / 3600000.0;

  int ledsOn = 0;
  if (digitalRead(LED1)) ledsOn++;
  if (digitalRead(LED2)) ledsOn++;
  if (digitalRead(LED3)) ledsOn++;
  if (digitalRead(LED4)) ledsOn++;

  totalEnergyWh += (ledsOn * LED_POWER_WATTS * durationHours);
  lastEnergyCalcTime = currentTime;
}

void updateCloud(float t, float h, int sLevel) {
  ThingSpeak.setField(1, t);
  ThingSpeak.setField(2, h);
  int occStatus = 0;
  if (teacherPresent) occStatus = 2;
  else if (occupationDetected) occStatus = 1;
  ThingSpeak.setField(3, occStatus);
  ThingSpeak.setField(4, smokeDetected ? 1 : 0);
  ThingSpeak.setField(5, (mode == "auto" ? 0 : 1));
  ThingSpeak.setField(6, digitalRead(LED1) ? 1 : 0);
  ThingSpeak.setField(7, sLevel);
  ThingSpeak.setField(8, totalEnergyWh);
  ThingSpeak.writeFields(myChannelNumber, myWriteAPIKey);
}

void setupWebServer() {
  server.on("/status", HTTP_GET, []() {
    String json = "{";
    json += "\"temp\":" + String(dht.readTemperature()) + ",";
    json += "\"humidity\":" + String(dht.readHumidity()) + ",";
    json += "\"motion\":" + String(occupationDetected ? "true" : "false") + ",";
    json += "\"smoke\":" + String(smokeDetected ? "true" : "false") + ",";
    json += "\"smokeLevel\":" + String(analogRead(MQ135_PIN)) + ",";
    json += "\"mode\":\"" + mode + "\",";
    json += "\"light\":\"" + String(digitalRead(LED1) ? "on" : "off") + "\",";
    json += "\"teacher\":" + String(teacherPresent ? "true" : "false") + ",";
    json += "\"energy\":" + String(totalEnergyWh);
    json += "}";
    server.send(200, "application/json", json);
  });
  server.begin();
}

void connectWiFi() {
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
}

void goToSleep() {
  lcd.clear();
  lcd.print("Sleep Mode...");
  delay(1000);
  esp_light_sleep_start();
  lastActivityTime = millis();
}
