#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266WebServer.h>

// define pins 
#define pMotoVR D13
#define pMotoVL D8

#define pOut1 D2
#define pOut2 D11
#define pOut3 D10
#define pOut4 D9

#define pTrig D7

#define pEchoF D6
//#define pEchoL D5
//#define pEchoR D4
//#define pEncL D3
//#define pEncR D2
#define buzzPin D3

// ap server settings 
const char *ssid = "esp";
const char *password = "1234qwerty";
ESP8266WebServer server(80);
WiFiEventHandler stationConnectedHandler;
WiFiEventHandler stationDisconnectedHandler;

// other variables 
int dir = 0, inDir = 0;
boolean ledON = false;
long prev_check = 0, check_interval = 300;
float dFront = 0, dLeft = 0, dRight = 0, uR =0, uL = 0;

void setup() {
  delay(1000);
  Serial.begin(115200);
  Serial.println();
  
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
  Serial.println("Writes");
  digitalWrite(pOut1, LOW);
  digitalWrite(pOut2, LOW);
  digitalWrite(pOut3, LOW);
  digitalWrite(pOut4, LOW);
  Serial.println("End");
  
  //pinMode(pEncL, INPUT);
  //pinMode(pEncR, INPUT);
  pinMode(pTrig, OUTPUT);
  pinMode(pEchoF, INPUT);
  //pinMode(pEchoL, INPUT);
  //pinMode(pEchoR, INPUT);
  pinMode(buzzPin, OUTPUT);
  digitalWrite(buzzPin, LOW);
  
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
  
  //play();
  if (millis() - prev_check > check_interval)
  {
    getDistances();
    prev_check = millis();
  }
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
  //dLeft = pulseIn(pEchoL, HIGH)/58.2;
  //dRight = pulseIn(pEchoR, HIGH)/58.2;
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

     writeMotors(dir);
  }
}

void writeMotors(int num_dir)
{
    switch(num_dir)
    {
        case 0:
          uL = 0;
          uR = 0;
          break;
        case 1:
        case 4:
        case 5:
        case 6:
          uL = 240;
          uR = 240;
          break;
        case 2:
        case 7:
          uR = 240;
          uL = 160;
          break;
        case 3:
        case 8:
          uR = 160;
          uL = 240;
          break; 
        default:
          uL = 0;
          uR = 0;
          break;
    }

   // wyplucie wartości na wyjścia
   analogWrite(pMotoVR, uR);
   analogWrite(pMotoVL, uL);
}

// ------------- PRZYJĘCIE DANYCH Z APLIKACJI (HTTP GET) ---------------
void rec_get()
{
  String dataMes = String(dir) + "," + String(dFront) + 
  "," + String(dLeft) + "," + String(dRight) + "\n";

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
/*
// --------------- MARSZ IMPERIALNY ---------------------------
#define C0 16.35
#define Db0 17.32
#define D0  18.35
#define Eb0 19.45
#define E0  20.60
#define F0  21.83
#define Gb0 23.12
#define G0  24.50
#define Ab0 25.96
#define LA0 27.50
#define Bb0 29.14
#define B0  30.87
#define C1  32.70
#define Db1 34.65
#define D1  36.71
#define Eb1 38.89
#define E1  41.20
#define F1  43.65
#define Gb1 46.25
#define G1  49.00
#define Ab1 51.91
#define LA1 55.00
#define Bb1 58.27
#define B1  61.74
#define C2  65.41
#define Db2 69.30
#define D2  73.42
#define Eb2 77.78
#define E2  82.41
#define F2  87.31
#define Gb2 92.50
#define G2  98.00
#define Ab2 103.83
#define LA2 110.00
#define Bb2 116.54
#define B2  123.47
#define C3  130.81
#define Db3 138.59
#define D3  146.83
#define Eb3 155.56
#define E3  164.81
#define F3  174.61
#define Gb3 185.00
#define G3  196.00
#define Ab3 207.65
#define LA3 220.00
#define Bb3 233.08
#define B3  246.94
#define C4  261.63
#define Db4 277.18
#define D4  293.66
#define Eb4 311.13
#define E4  329.63
#define F4  349.23
#define Gb4 369.99
#define G4  392.00
#define Ab4 415.30
#define LA4 440.00
#define Bb4 466.16
#define B4  493.88
#define C5  523.25
#define Db5 554.37
#define D5  587.33
#define Eb5 622.25
#define E5  659.26
#define F5  698.46
#define Gb5 739.99
#define G5  783.99
#define Ab5 830.61
#define LA5 880.00
#define Bb5 932.33
#define B5  987.77
#define C6  1046.50
#define Db6 1108.73
#define D6  1174.66
#define Eb6 1244.51
#define E6  1318.51
#define F6  1396.91
#define Gb6 1479.98
#define G6  1567.98
#define Ab6 1661.22
#define LA6 1760.00
#define Bb6 1864.66
#define B6  1975.53
#define C7  2093.00
#define Db7 2217.46
#define D7  2349.32
#define Eb7 2489.02
#define E7  2637.02
#define F7  2793.83
#define Gb7 2959.96
#define G7  3135.96
#define Ab7 3322.44
#define LA7 3520.01
#define Bb7 3729.31
#define B7  3951.07
#define C8  4186.01
#define Db8 4434.92
#define D8  4698.64
#define Eb8 4978.03
// DURATION OF THE NOTES
const int BPM = 120;    //  you can change this value changing all the others
const int Q = 60000/BPM; //quarter 1/4
const int H = 2*Q; //half 2/4
const int E = Q/2;   //eighth 1/8
const int S = Q/4; // sixteenth 1/16
const int W = 4*Q; // whole 4/4

const float note[] = { LA3, LA3, LA3, F3, C4,
                     LA3, F3, C4, LA3,
                     E4, E4, E4, F4, C4,
                     Ab3, F3, C4, LA3,
                     LA4, LA3, LA3, LA4, Ab4, G4,
                     Gb4, E4, F4, Bb3, Eb4, D4, Db4,
                     C4, B3, C4, F3, Ab3, F3, LA3,
                     C4, LA3, C4, E4,
                     LA4, LA3, LA3, LA4, Ab4, G4,
                     Gb4, E4, F4, Bb3, Eb4, D4, Db4,
                     C4, B3, C4, F3, Ab3, F3, C4,
                     LA3, F3, C4, LA3, 0
};

const int duration[] = {       Q, Q, Q, E+S, S,
                         Q, E+S, S, H,             
                         Q, Q, Q, E+S, S,
                         Q, E+S, S, H,
                         Q, E+S, S, Q, E+S, S,     
                         S, S, 2*E+1, E, Q, E+S, S,
                         S, S, 2*E+1,E, Q, E+S, S,
                         Q, E+S, S, H,
                         Q, E+S, S, Q, E+S, S,
                         S, S, 2*E+1, E, Q, E+S, S,
                         S, S, 2*E+1, E, Q, E+S, S,
                         Q, E+S, S, H, 2*H                
};

int ind = 0;
long change_time = 0;

void play()
{
  if (ind > 55)
    ind = 0;

  if (millis() - change_time > duration[ind] + 1)
  {
    tone(buzzPin, note[ind], duration[ind]);
    ind++;
    change_time = millis();
  }
}
*/
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
  digitalWrite(pOut2, LOW);
  digitalWrite(pOut3, LOW);
  digitalWrite(pOut4, LOW);
}
