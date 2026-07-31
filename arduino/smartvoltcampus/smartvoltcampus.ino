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

//==========================
// WiFi & ThingSpeak
//==========================

const char* ssid = "Uday";
const char* password = "zoris._.ud";

unsigned long myChannelNumber = 3440531;
const char* myWriteAPIKey = "UCRGIKPG27SAN1KM";

WiFiClient client;
WebServer server(80);

//==========================
// Pin Definitions
//==========================

#define DHTPIN          4
#define DHTTYPE         DHT11

#define TRIG_PIN        16
#define ECHO_PIN        17

#define LED1            12
#define LED2            14
#define LED3            2      // Changed from GPIO27
#define LED4            15

#define MQ135_PIN       34

#define BUZZER_PIN      25

#define SERVO_PIN       13

#define SWITCH_PIN      33

#define RFID_SS         5
#define RFID_RST        27

//==========================
// Objects
//==========================

DHT dht(DHTPIN, DHTTYPE);

hd44780_I2Cexp lcd;

Servo windowServo;

MFRC522 mfrc522(RFID_SS, RFID_RST);

//==========================
// RFID Authorized UID
// Replace with your card UID
//==========================

byte authorizedUID[4] = {0x00,0x00,0x00,0x00};

//==========================
// Variables
//==========================

bool teacherPresent = false;

bool occupationDetected = false;

bool smokeDetected = false;

bool manualMode = false;

float temperature = 0;

float humidity = 0;

int smokeLevel = 0;

float totalEnergyWh = 0;

unsigned long previousThingSpeak = 0;

unsigned long previousEnergy = 0;

unsigned long lastActivity = 0;

const float LED_POWER = 0.05;

//==========================
// Function Prototypes
//==========================

void connectWiFi();
void setupWebServer();

void readRFID();
void readUltrasonic();
void readDHT();
void readSmoke();

void controlLights();
void controlSafety();

void updateLCD();

void updateThingSpeak();

void calculateEnergy();

void sleepCheck();

//==========================
// Setup
//==========================

void setup()
{
    Serial.begin(115200);

    pinMode(TRIG_PIN,OUTPUT);
    pinMode(ECHO_PIN,INPUT);

    pinMode(LED1,OUTPUT);
    pinMode(LED2,OUTPUT);
    pinMode(LED3,OUTPUT);
    pinMode(LED4,OUTPUT);

    pinMode(BUZZER_PIN,OUTPUT);

    pinMode(SWITCH_PIN,INPUT_PULLUP);

    dht.begin();

    lcd.begin(16,2);
    lcd.backlight();

    windowServo.attach(SERVO_PIN);
    windowServo.write(0);

    SPI.begin();

    mfrc522.PCD_Init();

    connectWiFi();

    ThingSpeak.begin(client);

    setupWebServer();

    previousEnergy = millis();

    lastActivity = millis();

    Serial.println("SmartVolt Campus Started");
}

//==========================
// Main Loop
//==========================

void loop()
{
    server.handleClient();

    if(WiFi.status()!=WL_CONNECTED)
    {
        connectWiFi();
    }

    readRFID();

    readUltrasonic();

    readDHT();

    readSmoke();

    manualMode = (digitalRead(SWITCH_PIN)==LOW);

    controlLights();

    controlSafety();

    updateLCD();

    calculateEnergy();

    if(millis()-previousThingSpeak>20000)
    {
        updateThingSpeak();
        previousThingSpeak=millis();
    }

    sleepCheck();

    delay(100);
}
//==================================================
// WiFi Connection
//==================================================

void connectWiFi()
{
  Serial.print("Connecting to WiFi");

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  unsigned long startTime = millis();

  while (WiFi.status() != WL_CONNECTED && millis() - startTime < 15000)
  {
    Serial.print(".");
    delay(500);
  }

  if (WiFi.status() == WL_CONNECTED)
  {
    Serial.println();
    Serial.println("WiFi Connected");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
  }
  else
  {
    Serial.println();
    Serial.println("WiFi Connection Failed");
  }
}

//==================================================
// RFID Reading
//==================================================

void readRFID()
{
  if (!mfrc522.PICC_IsNewCardPresent())
    return;

  if (!mfrc522.PICC_ReadCardSerial())
    return;

  bool authorized = true;

  for (byte i = 0; i < 4; i++)
  {
    if (mfrc522.uid.uidByte[i] != authorizedUID[i])
    {
      authorized = false;
      break;
    }
  }

  if (authorized)
  {
    teacherPresent = !teacherPresent;

    Serial.println("--------------------------------");
    Serial.println("Authorized Card");

    if (teacherPresent)
      Serial.println("Teacher Entered");
    else
      Serial.println("Teacher Left");

    digitalWrite(BUZZER_PIN, HIGH);
    delay(150);
    digitalWrite(BUZZER_PIN, LOW);

    lastActivity = millis();
  }
  else
  {
    Serial.println("--------------------------------");
    Serial.println("Unauthorized Card");

    for (int i = 0; i < 3; i++)
    {
      digitalWrite(BUZZER_PIN, HIGH);
      delay(100);
      digitalWrite(BUZZER_PIN, LOW);
      delay(100);
    }
  }

  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
}

//==================================================
// Ultrasonic Sensor
//==================================================

void readUltrasonic()
{
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);

  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);

  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH, 30000);

  if (duration == 0)
  {
    occupationDetected = false;
    return;
  }

  float distance = duration * 0.0343 / 2.0;

  Serial.print("Distance : ");
  Serial.print(distance);
  Serial.println(" cm");

  if (distance > 2 && distance < 150)
  {
    occupationDetected = true;
    lastActivity = millis();
  }
  else
  {
    occupationDetected = false;
  }
}

//==================================================
// DHT11
//==================================================

void readDHT()
{
  float t = dht.readTemperature();
  float h = dht.readHumidity();

  if (isnan(t) || isnan(h))
  {
    Serial.println("DHT Read Failed");
    return;
  }

  temperature = t;
  humidity = h;
}

//==================================================
// MQ135 Smoke Sensor
//==================================================

void readSmoke()
{
  smokeLevel = analogRead(MQ135_PIN);

  Serial.print("Smoke Level : ");
  Serial.println(smokeLevel);

  if (smokeLevel > 1500)
    smokeDetected = true;
  else
    smokeDetected = false;
}
//==================================================
// Control Lights
//==================================================

void controlLights()
{
    // Manual mode
    if (manualMode)
    {
        bool sw = (digitalRead(SWITCH_PIN) == LOW);

        digitalWrite(LED1, sw);
        digitalWrite(LED2, sw);
        digitalWrite(LED3, sw);
        digitalWrite(LED4, sw);

        return;
    }

    // Auto mode

    if (!occupationDetected)
    {
        digitalWrite(LED1, LOW);
        digitalWrite(LED2, LOW);
        digitalWrite(LED3, LOW);
        digitalWrite(LED4, LOW);
        return;
    }

    // Occupation detected
    digitalWrite(LED1, HIGH);
    digitalWrite(LED2, HIGH);

    if (teacherPresent)
    {
        digitalWrite(LED3, HIGH);
        digitalWrite(LED4, HIGH);
    }
    else
    {
        digitalWrite(LED3, LOW);
        digitalWrite(LED4, LOW);
    }
}

//==================================================
// Safety Control
//==================================================

void controlSafety()
{
    if(smokeDetected)
    {
        digitalWrite(BUZZER_PIN,HIGH);
        windowServo.write(90);
    }
    else
    {
        digitalWrite(BUZZER_PIN,LOW);
        windowServo.write(0);
    }
}

//==================================================
// LCD Update
//==================================================

void updateLCD()
{
    lcd.clear();

    lcd.setCursor(0,0);
    lcd.print("T:");
    lcd.print(temperature,1);
    lcd.print(" H:");
    lcd.print(humidity,0);

    lcd.setCursor(0,1);

    if(smokeDetected)
    {
        lcd.print("SMOKE ALERT");
    }
    else if(teacherPresent)
    {
        lcd.print("Teacher Present");
    }
    else if(occupationDetected)
    {
        lcd.print("Occupied");
    }
    else
    {
        lcd.print("Room Empty");
    }
}

//==================================================
// Energy Calculation
//==================================================

void calculateEnergy()
{
    unsigned long current = millis();

    float hours = (current - previousEnergy) / 3600000.0;

    int ledCount = 0;

    if(digitalRead(LED1)) ledCount++;
    if(digitalRead(LED2)) ledCount++;
    if(digitalRead(LED3)) ledCount++;
    if(digitalRead(LED4)) ledCount++;

    totalEnergyWh += ledCount * LED_POWER * hours;

    previousEnergy = current;
}

//==================================================
// Sleep Check
//==================================================

void sleepCheck()
{
    if(millis() - lastActivity < 900000)
        return;

    lcd.clear();

    lcd.setCursor(0,0);
    lcd.print("Sleep Mode");

    lcd.setCursor(0,1);
    lcd.print("Waiting...");

    delay(1000);

    Serial.println("Entering Light Sleep");

    esp_light_sleep_start();

    lastActivity = millis();
}
//==================================================
// ThingSpeak Upload
//==================================================

void updateThingSpeak()
{
  ThingSpeak.setField(1, temperature);
  ThingSpeak.setField(2, humidity);

  int occupancy = 0;

  if (teacherPresent)
    occupancy = 2;
  else if (occupationDetected)
    occupancy = 1;

  ThingSpeak.setField(3, occupancy);
  ThingSpeak.setField(4, smokeDetected ? 1 : 0);
  ThingSpeak.setField(5, manualMode ? 1 : 0);
  ThingSpeak.setField(6, digitalRead(LED1));
  ThingSpeak.setField(7, smokeLevel);
  ThingSpeak.setField(8, totalEnergyWh);

  int status = ThingSpeak.writeFields(myChannelNumber, myWriteAPIKey);

  if (status == 200)
  {
    Serial.println("ThingSpeak Updated Successfully");
  }
  else
  {
    Serial.print("ThingSpeak Error : ");
    Serial.println(status);
  }
}

//==================================================
// Web Server
//==================================================

void setupWebServer()
{

  server.on("/", HTTP_GET, []()
  {
    server.send(200, "text/plain", "SmartVolt Campus Server Running");
  });

  server.on("/status", HTTP_GET, []()
  {

    String json = "{";

    json += "\"temperature\":";
    json += String(temperature,1);

    json += ",\"humidity\":";
    json += String(humidity,1);

    json += ",\"teacher\":";
    json += teacherPresent ? "true" : "false";

    json += ",\"occupied\":";
    json += occupationDetected ? "true" : "false";

    json += ",\"smoke\":";
    json += smokeDetected ? "true" : "false";

    json += ",\"smokeLevel\":";
    json += String(smokeLevel);

    json += ",\"manualMode\":";
    json += manualMode ? "true" : "false";

    json += ",\"led1\":";
    json += digitalRead(LED1);

    json += ",\"led2\":";
    json += digitalRead(LED2);

    json += ",\"led3\":";
    json += digitalRead(LED3);

    json += ",\"led4\":";
    json += digitalRead(LED4);

    json += ",\"energy\":";
    json += String(totalEnergyWh,3);

    json += "}";

    server.send(200, "application/json", json);

  });

  server.begin();

  Serial.println("Web Server Started");
}

//==================================================
// End of SmartVolt Campus
//==================================================
