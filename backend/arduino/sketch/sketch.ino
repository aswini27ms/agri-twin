#include <Modulino.h>
#include <Arduino_RouterBridge.h>

ModulinoThermo thermo;

float celsius = 0;
float humidity = 0;

const int SOIL_PIN = A0;
int soilRaw = 0;

// Functions exposed to the Python side over the Bridge
float getTemperature() { return celsius; }
float getHumidity() { return humidity; }
int getSoilMoisture() { return soilRaw; }
String ping() { return "PONG"; }

void setup() {
  Serial.begin(115200);
  while (!Serial);

  Modulino.begin();
  thermo.begin();
  pinMode(SOIL_PIN, INPUT);

  Bridge.begin();
  Bridge.provide("getTemperature", getTemperature);
  Bridge.provide("getHumidity", getHumidity);
  Bridge.provide("getSoilMoisture", getSoilMoisture);
  Bridge.provide("ping", ping);
    
  Serial.println("Arduino Ready");
}

void loop() {
  celsius = thermo.getTemperature();
  humidity = thermo.getHumidity();
  soilRaw = analogRead(SOIL_PIN);

  Serial.print("Temperature: ");
  Serial.print(celsius);
  Serial.print("  Humidity: ");
  Serial.print(humidity);
  Serial.print("  Soil: ");
  Serial.println(soilRaw);

  delay(1000);
}