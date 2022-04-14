#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266WebServer.h>

// define pins 
#define pMotoVR 13
#define pMotoVL 12

#define pOut1 11
#define pOut2 10
#define pOut3 9
#define pOut4 8

#define pTrig 7

#define pEchoF 6
#define pEchoL 5
#define pEchoR 4
#define pEncL 3
#define pEncR 2

// ap server settings 
const char *ssid = "esp";
const char *password = "1234qwerty";
ESP8266WebServer server(80);
WiFiEventHandler stationConnectedHandler;
WiFiEventHandler stationDisconnectedHandler;

// other variables 
int freq = 1;
boolean ledON = false;
long prev_blink = 0;
float dFront = 0, dLeft = 0, dRight = 0;

void setup() {
  delay(1000);
  // pin modes
  pinMode(LED_BUILTIN, OUTPUT);
//  pinMode(pMotoVR, OUTPUT);
//  pinMode(pMotoVL, OUTPUT);
//  pinMode(pOut1, OUTPUT);
//  pinMode(pOut2, OUTPUT);
//  pinMode(pOut3, OUTPUT);
//  pinMode(pOut4, OUTPUT);
//  pinMode(pEncL, INPUT);
//  pinMode(pEncR, INPUT);
//  pinMode(pTrig, OUTPUT);
//  pinMode(pEchoF, INPUT);
//  pinMode(pEchoL, INPUT);
//  pinMode(pEchoR, INPUT);

  
  digitalWrite(LED_BUILTIN, LOW);
  
  Serial.begin(115200);
  Serial.println();
  Serial.print("Configuring access point...");

  WiFi.persistent(false);
  WiFi.mode(WIFI_AP);
  WiFi.softAP(ssid, password);

  stationConnectedHandler = WiFi.onSoftAPModeStationConnected(&onStationConnected);
  stationDisconnectedHandler = WiFi.onSoftAPModeStationDisconnected(&onStationDisconnected);

  IPAddress myIP = WiFi.softAPIP();
  Serial.print("AP IP address: ");
  Serial.println(myIP);
  server.on("/", HTTP_GET, rec_get);
  server.begin();
  Serial.println("HTTP server started");
}

void loop() {
  server.handleClient();

  if (millis() - prev_blink > 1000/freq)
  {
      if(ledON)
        digitalWrite(LED_BUILTIN, LOW);
      else
        digitalWrite(LED_BUILTIN, HIGH);

      ledON = !ledON;
      prev_blink = millis();
  }

  //getDistances();
  //checkDirection();
  //writeMotors();
}
// ---------------------- OBSŁUGA CZUJNIKÓW ------------------------------

void getDistances()
{
  digitalWrite(pTrig, LOW);
  delayMicroseconds(2);
  digitalWrite(pTrig, HIGH);
  delayMicroseconds(10);
  digitalWrite(pTrig, LOW);

  dFront= pulseIn(pEchoF, HIGH)/58.2;
  dLeft = pulseIn(pEchoL, HIGH)/58.2;
  dRight = pulseIn(pEchoR, HIGH)/58.2;

  // przykładowy output informacji o dystansie 
  if(dFront >= 400 || dFront <= 2)
    Serial.println("Out of range");
  else
  {
    Serial.print("Dist front = ");
    Serial.print(dFront);
    Serial.println(" cm");
    delay(500);
  }
}


// -------------------- OBSŁUGA SILNIKÓW ---------------------------------
void checkDist()
{
  // możliwe kombinacje nacisniętych klawiszy 
  // 0 - [W}, 1 - [AW], 2 - [WD], 3 - [A], 4 - [D]
  // 5 - [S]. 6 - [AS], 7 - [SD]
  
  int dir = 0;  // to bedzie zmienna tutaj co decyduje
  int inDir = 0;// zmienna przesłana z apki (odczytany server.arg(2) czy coś)

  // ustawienie odpowiednich wartosci na pinach IN1, IN2, IN3, IN4 mostka H
  if (inDir != dir) 
  {
    dir = inDir;
    switch(dir)
    {
        case 0:
        case 1:
        case 2:
          // oba silniki do przodu
          break;

        case 3:
          // prawy przód, lewy tył
          break;
        case 4:
          // lewy przód, prawy tył
          break;
      
        case 5:
        case 6:
        case 7:
          // oba do tyłu
          break;

        default:
          break;
    }
  }
}

void writeMotors(int num_dir)
{
  int uL = 0, uR = 0;
  // ustawienie wartości uL i uR w zaleznosci od kierunku
  // można zrobić że te wartości są jakieś globalne a tu będą tylko inkrementowane/dek
  // zeby nie jezdzil ze stałą prędkoscią tylko sie "rozpędzał" przy trzymaniu przycisku
  // tk bedzie super
    switch(num_dir)
    {
        case 0:
          break;
        case 1:
          break;
        case 2:
          break;

        case 3:
          // prawy przód, lewy tył
          break;
        case 4:
          // lewy przód, prawy tył
          break;
      
        case 5:
          break;
        case 6:
          break;
        case 7:
          // oba do tyłu
          break;

        default:
          break;
    }

   // wyplucie wartości na wyjścia
   // analogWrite(pMotoVR, uR);
   // analogWrite(pMotoVL, uL);
}

// ------------- PRZYJĘCIE DANYCH Z APLIKACJI (HTTP GET) ---------------
void rec_get()
{
  server.send(200, "text/html", "<h1>You are connected mordo</h1> <br> <a>It works actually</a>");
  
  Serial.println("HTTP GET REQUEST: ");
  String message;
  for (uint8_t i = 0; i < server.args(); i++) {
    message += server.argName(i) + ": " + server.arg(i) + "\n";
  }
  Serial.println(message);
  freq = atoi(server.arg("freq").c_str());
}

// ---------- INFORMACJE O PODŁĄCZONYCH STACJACH -------------------------

void onStationConnected(const WiFiEventSoftAPModeStationConnected& evt) {
  Serial.print("Station connected: ");
  Serial.println(macToString(evt.mac));
}

void onStationDisconnected(const WiFiEventSoftAPModeStationDisconnected& evt) {
  Serial.print("Station disconnected: ");
  Serial.println(macToString(evt.mac));
}

String macToString(const unsigned char* mac) {
  char buf[20];
  snprintf(buf, sizeof(buf), "%02x:%02x:%02x:%02x:%02x:%02x",
           mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
  return String(buf);
}
