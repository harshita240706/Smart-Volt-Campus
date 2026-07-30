# ESP32 Reference Code (Arduino C++)

This code sets up the ESP32 as a Web Server that the Flutter app can talk to.

> [!WARNING]
> You will need to install the **ESPAsyncWebServer** and **ArduinoJson** libraries in your Arduino IDE to compile this.

```cpp
#include <WiFi.h>
#include <ESPAsyncWebServer.h>
#include <ArduinoJson.h>

const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

AsyncWebServer server(80);

// Global States
String mode = "auto";
bool lightOn = false;
bool fanOn = false;

// Sensor Placeholders (Replace with actual sensor readings)
float getTemperature() { return 24.5; }
bool isMotionDetected() { return digitalRead(PIR_PIN); }
bool isSmokeDetected() { return digitalRead(SMOKE_PIN); }

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) { delay(1000); Serial.print("."); }
  Serial.println("\nIP Address: " + WiFi.localIP().toString());

  // --- API ENDPOINTS ---

  // 1. GET Status
  server.on("/status", HTTP_GET, [](AsyncWebServerRequest *request){
    StaticJsonDocument<200> doc;
    doc["temp"] = getTemperature();
    doc["motion"] = isMotionDetected();
    doc["smoke"] = isSmokeDetected();
    doc["mode"] = mode;
    doc["light"] = lightOn ? "on" : "off";
    doc["fan"] = fanOn ? "on" : "off";

    String response;
    serializeJson(doc, response);
    request->send(200, "application/json", response);
  });

  // 2. SET Mode
  server.on("/setMode", HTTP_GET, [](AsyncWebServerRequest *request){
    if (request->hasParam("val")) {
      mode = request->getParam("val")->value();
      request->send(200, "text/plain", "OK");
    }
  });

  // 3. CONTROL Device (Only works if mode is manual)
  server.on("/control", HTTP_GET, [](AsyncWebServerRequest *request){
    if (mode == "manual" && request->hasParam("device") && request->hasParam("state")) {
      String device = request->getParam("device")->value();
      bool state = request->getParam("state")->value() == "on";

      if (device == "light") lightOn = state;
      if (device == "fan") fanOn = state;
      request->send(200, "text/plain", "OK");
    } else {
      request->send(403, "text/plain", "Forbidden: Change to manual mode first");
    }
  });

  server.begin();
}

void loop() {
  if (mode == "auto") {
    // --- AUTOMATIC LOGIC ---
    if (isMotionDetected()) {
      lightOn = true;
    } else {
      lightOn = false;
    }

    if (getTemperature() > 28.0) {
      fanOn = true;
    } else {
      fanOn = false;
    }
  }

  // Apply physical states to pins
  digitalWrite(LIGHT_RELAY_PIN, lightOn ? HIGH : LOW);
  digitalWrite(FAN_RELAY_PIN, fanOn ? HIGH : LOW);
}
```
