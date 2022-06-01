#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266WebServer.h>

// define pins 
#define pMotoVR D13
#define pMotoVL D8

#define pOut1 A0
#define pOut2 D11
#define pOut3 D10
#define pOut4 D9

#define pTrig D6

#define pEchoF D2
#define pEchoL D7
#define pEchoR D5

#define pEncL D3
#define pEncR D4

const int NUM_SLOTS = 20;
const float WHEEL_R = 33.1;

// ap server settings 
const char *ssid = "esp";
const char *password = "1234qwerty";
ESP8266WebServer server(80);
WiFiEventHandler stationConnectedHandler;
WiFiEventHandler stationDisconnectedHandler;

// other variables 
int dir = 0, inDir = 0;
boolean ledON = false;
long prev_check = 0, check_interval = 100;
float dFront = 0, dLeft = 0, dRight = 0; 
float vR = 0, vL = 0;

int countR = 0, countL = 0, prevCR = 0, prevCL = 0, dCL = 0, dCR = 0;

// PID
const float K = 0.065, Ki = 0.025, Kd = 0.008;

float errL = 0, p_errL = 0, sum_errL = 0, errR = 0, p_errR = 0, sum_errR = 0;
float uR = 0, uL = 0, VRr = 0, VLr = 0;
int sensor_ind = 0;


IRAM_ATTR void incL()
{
  countL++;
}

IRAM_ATTR void incR()
{
  countR++;
}

void setup() {
  delay(1000);
  Serial.begin(115200);
  Serial.println();
  Serial.print("Configuring pinouts...");
  
  // pin modes and initial values
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(pMotoVR, OUTPUT);
  pinMode(pMotoVL, OUTPUT);
  digitalWrite(pMotoVR, 0);
  digitalWrite(pMotoVL, 0);
  pinMode(pOut1, OUTPUT);
  pinMode(pOut2, OUTPUT);
  pinMode(pOut3, OUTPUT);
  pinMode(pOut4, OUTPUT);
  
  pinMode(pEncL, INPUT);
  pinMode(pEncR, INPUT);
  pinMode(pTrig, OUTPUT);
  
  pinMode(pEchoF, INPUT);
  pinMode(pEchoL, INPUT);
  pinMode(pEchoR, INPUT);

  analogWriteFreq(40000);

  // encoders interrupts
  attachInterrupt(digitalPinToInterrupt(pEncL), incL, RISING);
  attachInterrupt(digitalPinToInterrupt(pEncR), incR, RISING);
  
  // CONFIGURE WIFI ACCESS POINT
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
  
  // TEST MOTORS
  //Serial.println(":Motors test:");
  //testDIRControl();
  //Serial.println(":Speed change test:");
  //testPWMControl();
}

void loop() {
  server.handleClient();
  rec_get();
  /*if (Serial.available()) 
  {
    inDir = Serial.read(); 
    checkDirection();
  }*/
  controls();

  if (millis() - prev_check > check_interval)
  {
    getDistances();
    float dT = (millis() - prev_check)/1000.0;
    vL = (countL - prevCL)/18.0/dT;
    vR = (countR - prevCR)/18.0/dT;
    prevCL = countL;
    prevCR = countR;
    prev_check = millis();

    
    Serial.print("Direction = ");
    Serial.println(dir);

    Serial.println(" ----- Distances: ------ ");
    Serial.print("F = ");
    Serial.print(dFront);
    Serial.print(" , R = ");
    Serial.print(dRight);
    Serial.print(" , L = ");
    Serial.println(dLeft);

    /*
    Serial.println(" ----- v ------ ");
    Serial.print("vR = ");
    Serial.print(vR);
    Serial.print(", vL = ");
    Serial.println(vL);
    Serial.println(" ----- u ------ ");
    Serial.print("uR = ");
    Serial.print(uR);
    Serial.print(", uL = ");
    Serial.println(uL);
    

    */
  } 
}

   


// ---------------------- OBSŁUGA CZUJNIKÓW ------------------------------

void controls()
{
  p_errL = errL;
  p_errR = errR;

  errL = VLr - vL;
  errR = VRr - vR;
 
  sum_errL += errL;
  sum_errR += errR;
  
  if(sum_errR > 10000)
     sum_errR = 10000;

   if(sum_errL > 10000)
     sum_errL = 10000;
     
  float dErrL = errL - p_errL;
  float dErrR = errR - p_errR;

  uL = K*vL + Ki*sum_errL + Kd*dErrL;
  uR = K*vR + Ki*sum_errR + Kd*dErrR;

  uL = constrain(uL, 0, 250);
  uR = constrain(uR, 0, 250);
  
  analogWrite(pMotoVR, uR);
  analogWrite(pMotoVL, uL);
}

void getDistances()
{
  digitalWrite(pTrig, LOW);
  delayMicroseconds(1);
  digitalWrite(pTrig, HIGH);
  delayMicroseconds(5);
  digitalWrite(pTrig, LOW);

  if(sensor_ind == 0)
    dFront= pulseIn(pEchoF, HIGH)/58.2;

  if(sensor_ind == 1)
    dLeft = pulseIn(pEchoL, HIGH)/58.2;

  if(sensor_ind == 2)
    dRight = pulseIn(pEchoR, HIGH)/58.2;

  sensor_ind = (sensor_ind + 1)%3;
}


// -------------------- OBSŁUGA SILNIKÓW ---------------------------------
void checkDirection()
{
  // możliwe kombinacje nacisniętych klawiszy 
  // 1 - [W}, 2 - [AW], 3 - [WD], 4 - [A], 5 - [D]
  // 6 - [S]. 7 - [AS], 8 - [SD], 0 - NULL
 
  
  // ustawienie odpowiednich wartosci na pinach IN1, IN2, IN3, IN4 mostka H
  if (inDir != dir) // zeby wklepac wartosci tylko jak sie zmienia sterowanie a nie w kazdej iteracji
  {
    dir = inDir;
    switch(dir)
    {
        case 1:
        case 2:
        case 3:
          // oba silniki do przodu
          digitalWrite(pOut1, HIGH);
          digitalWrite(pOut2, LOW);
          digitalWrite(pOut3, HIGH);
          digitalWrite(pOut4, LOW);
          break;

        case 4:
          // prawy przód, lewy tył
          digitalWrite(pOut1, HIGH);
          digitalWrite(pOut2, LOW);
          digitalWrite(pOut3, LOW);
          digitalWrite(pOut4, HIGH);
          break;
          
        case 5:
          // lewy przód, prawy tył
          digitalWrite(pOut1, LOW);
          digitalWrite(pOut2, HIGH);
          digitalWrite(pOut3, HIGH);
          digitalWrite(pOut4, LOW);
          break;
      
        case 6:
        case 7:
        case 8:
          // oba do tyłu
          digitalWrite(pOut1, LOW);
          digitalWrite(pOut2, HIGH);
          digitalWrite(pOut3, LOW);
          digitalWrite(pOut4, HIGH);
          break;

        default:
          digitalWrite(pOut1, LOW);
          digitalWrite(pOut2, LOW);
          digitalWrite(pOut3, LOW);
          digitalWrite(pOut4, LOW);
          break;
    }

     setMotors(dir);
  }
}

void setMotors(int num_dir)
{
  uR = 0;
  uL = 0;
  sum_errL = 0;
  sum_errR = 0;
  
        
    switch(num_dir)
    {
        case 0:
        VRr = 0;
        VLr = 0;
        
          break;
        case 1:
        case 4:
        case 5:
        case 6:
        VRr = 3;
        VLr = 3;
          break;
          
        case 2:
        case 7:
        VRr = 3;
        VLr = 2;
          break;
        case 3:
        case 8:
        VRr = 2;
        VLr = 3;
          break; 
        default:
        VRr = 0;
        VLr = 0;
          break;
    }
}

// ------------- PRZYJĘCIE DANYCH Z APLIKACJI (HTTP GET) ---------------
void rec_get()
{
  String dataMes = String(dir) + "," + String(dFront) + 
  "," + String(dLeft) + "," + String(dRight) + "," + 
  String(countR) + "," + String(countL) + "," + 
  String(dCR) + "," + String(dCL) + "\n";

  // wysłanie danych z czujników odległości
  server.send(200, "text", dataMes);

  // przyjęcie informacji wysyłanej przez apke 
  inDir = atoi(server.arg("dir").c_str());
  checkDirection();
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

// ------------------------ MOTOR TESTING --------------
void testDIRControl() {
  // Set motors to maximum speed
  // For PWM maximum possible values are 0 to 255
  //digitalWrite(pMotoVL, HIGH);
  //digitalWrite(pMotoVR, HIGH);
  analogWrite(pMotoVL, 150);
  analogWrite(pMotoVR, 150);
  delay(1000);
  
  digitalWrite(pOut1, HIGH);
  digitalWrite(pOut2, LOW);
  digitalWrite(pOut3, HIGH);
  digitalWrite(pOut4, LOW);
  delay(2000);
  
  digitalWrite(pOut1, LOW);
  digitalWrite(pOut2, HIGH);
  digitalWrite(pOut3, LOW);
  digitalWrite(pOut4, HIGH);
  delay(2000);
  
  digitalWrite(pOut1, LOW);
  digitalWrite(pOut2, LOW);
  digitalWrite(pOut3, LOW);
  digitalWrite(pOut4, LOW);
}

// This function lets you control speed of the motors
void testPWMControl() {

  digitalWrite(pOut1, HIGH);
  digitalWrite(pOut2, LOW);
  digitalWrite(pOut3, HIGH);
  digitalWrite(pOut4, LOW);
  
  for (int i = 0; i < 256; i+= 5) {
    analogWrite(pMotoVL, i);
    analogWrite(pMotoVR, i);
    delay(250);
  }

  for (int i = 255; i >= 0; i-=5) {
    analogWrite(pMotoVL, i);
    analogWrite(pMotoVR, i);
    delay(250);
  }
  
  digitalWrite(pOut1, LOW);
  digitalWrite(pOut2, HIGH);
  digitalWrite(pOut3, LOW);
  digitalWrite(pOut4, HIGH);
  delay(200);

  for (int i = 0; i < 256; i+= 5) {
    analogWrite(pMotoVL, i);
    analogWrite(pMotoVR, i);
    delay(250);
  }

  for (int i = 255; i >= 0; i-=5) {
    analogWrite(pMotoVL, i);
    analogWrite(pMotoVR, i);
    delay(250);
    
  }
  
  digitalWrite(pOut1, LOW);
  digitalWrite(pOut2, LOW);
  digitalWrite(pOut3, LOW);
  digitalWrite(pOut4, LOW);
}
