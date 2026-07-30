#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <DHT.h>

#define DHTPIN 4
#define DHTTYPE DHT11

#define TRIG_PIN 16
#define ECHO_PIN 17

#define LED1 12
#define LED2 14

LiquidCrystal_I2C lcd(0x27, 16, 2);
DHT dht(DHTPIN, DHTTYPE);

long duration;
float distance;

void setup() {

  Serial.begin(115200);

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

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

  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);

  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);

  digitalWrite(TRIG_PIN, LOW);

  duration = pulseIn(ECHO_PIN, HIGH);

  distance = duration * 0.034 / 2;

  

  float temp = dht.readTemperature();
  float hum = dht.readHumidity();



  if(distance < 50)
  {
    digitalWrite(LED1,HIGH);
    digitalWrite(LED2,HIGH);
  }
  else
  {
    digitalWrite(LED1,LOW);
    digitalWrite(LED2,LOW);
  }

  

  lcd.clear();

  lcd.setCursor(0,0);
  lcd.print("T:");
  lcd.print(temp);
  lcd.print((char)223);
  lcd.print("C");

  lcd.setCursor(10,0);
  lcd.print("H:");
  lcd.print(hum);

  lcd.setCursor(0,1);
  lcd.print("D:");
  lcd.print(distance);
  lcd.print(" cm");


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
