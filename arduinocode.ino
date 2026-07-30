#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <DHT.h>
#include <hd44780.h>
#include <hd44780ioClass/hd44780_I2Cexp.h>
#include <DHT.h>

#define DHTPIN 4
#define DHTTYPE DHT11
#define TRIG_PIN 17
#define ECHO_PIN 16



#define LED1 12
#define LED2 14

LiquidCrystal_I2C lcd(0x27, 16, 2);
DHT dht(DHTPIN, DHTTYPE);



void setup() {

  Serial.begin(115200);
  pinMode(TRIG_PIN,OUTPUT);
  pinMode(ECHO_PIN,INPUT);

  

  pinMode(LED1, OUTPUT);
  pinMode(LED2, OUTPUT);

  dht.begin();

  lcd.init();
  lcd.backlight();

  lcd.setCursor(0,0);
  lcd.print("Smart Campus");

  lcd.setCursor(0,1);
  lcd.print("Starting...");

  delay(2000);

  lcd.clear();
}

void loop() {

  // ---------- Ultrasonic ----------
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);

  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);

  digitalWrite(TRIG_PIN, LOW);

  duration = pulseIn(ECHO_PIN, HIGH, 30000);

  distance = duration * 0.0343 / 2;



  // ---------- DHT11 ----------

  float temp = dht.readTemperature();
  float hum = dht.readHumidity();

  // ---------- LEDs ----------

  if (distance > 0 && distance < 50) {
  digitalWrite(LED1, HIGH);
  digitalWrite(LED2, HIGH);
} else {
  digitalWrite(LED1, LOW);
  digitalWrite(LED2, LOW);
}

  // ---------- LCD ----------

 lcd.clear();

lcd.setCursor(0,0);
lcd.print("T:");
lcd.print(temp,1);
lcd.print((char)223);
lcd.print("C ");

lcd.setCursor(9,0);
lcd.print("H:");
lcd.print(hum,0);
lcd.print("%");

lcd.setCursor(0,1);
lcd.print("D:");
lcd.print(distance,0);
lcd.print(" cm");
  // ---------- Serial ----------

  Serial.print("Temperature : ");
  Serial.print(temp);

  Serial.print(" C   ");

  Serial.print("Humidity : ");
  Serial.print(hum);

  Serial.print("%   ");

  Serial.print("Distance : ");
  Serial.print(distance);

  Serial.println(" cm");

  delay(1000);
}
