#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266WebServer.h>

// --------- ZDEFINIOWANIE PINÓW --------
#define pMotoVR D13
#define pMotoVL D8

#define pOut1 D14
#define pOut2 D11
#define pOut3 D10
#define pOut4 D9

#define pTrig D6

#define pEchoF D2
#define pEchoL D7
#define pEchoR D0

#define pEncL D3
#define pEncR D4

const float WHEEL_R = 33.1;

// ------------ DANE SERWERA ---------------
const char *ssid = "esp";
const char *password = "1234qwerty";
ESP8266WebServer server(80);
WiFiEventHandler stationConnectedHandler;
WiFiEventHandler stationDisconnectedHandler;

// ------------ INNE DANE ----------------
int dir = 0, inDir = 0;
long prev_check = 0, check_interval = 100;
float dFront = 0, dLeft = 0, dRight = 0; 
float vR = 0, vL = 0;
int sensor_ind = 0;

boolean AUTOMATIC = false, LOOKING = false;

int countR = 0, countL = 0, prevCR = 0, prevCL = 0, dCL = 0, dCR = 0;

// ------------- PID -----------------
const float K = 0.065, Ki = 0.025, Kd = 0.008;

float errL = 0, p_errL = 0, sum_errL = 0, errR = 0, p_errR = 0, sum_errR = 0;
float uR = 0, uL = 0, VRr = 0, VLr = 0;

// ----------- PRZERWANIA ENKODERÓW ---------
IRAM_ATTR void incL()
{
  countL++;
}

IRAM_ATTR void incR()
{
  countR++;
}

// ----------- INICJALIZACJA -----------
void setup() 
{
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

// -------------- PĘTLA GŁÓWNA -----------
void loop() 
{
  server.handleClient();

  if(AUTOMATIC)
  {
     // solve_maze() ?
     Serial.println("...");
  }
  else
    controls();

  // ------- AKTUALIZACJE DANYCH Z CZUJNIKÓW -------
  if (millis() - prev_check > check_interval)
  {
    getDistances();
    float dT = (millis() - prev_check)/1000.0;
    vL = (countL - prevCL)/18.0/dT;             // PREDKOSC OBROTOWA
    vR = (countR - prevCR)/18.0/dT;
    prevCL = countL;
    prevCR = countR;
    prev_check = millis();
    
    // -------- DEBUGGOWANIE W KONSOLI ------------
    /*
    Serial.print("Direction = ");
    Serial.println(dir);
    Serial.println(" ----- Distances: ------ ");
    Serial.print("F = ");
    Serial.print(dFront);
    Serial.print(" , R = ");
    Serial.print(dRight);
    Serial.print(" , L = ");
    Serial.println(dLeft);
    
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

// ------------------- STEROWANIE SILNIKAMI ------------
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


// ------------------ OBSŁUGA CZUJNIKÓW -----------------------
void getDistances()
{
  digitalWrite(pTrig, LOW);
  delayMicroseconds(1);
  digitalWrite(pTrig, HIGH);
  delayMicroseconds(5);
  digitalWrite(pTrig, LOW);

  if(sensor_ind == 0)
  {
    dFront= pulseIn(pEchoF, HIGH)/58.2;
    if(dFront > 100)
       dFront = 0;
  }

  if(sensor_ind == 1)
  {
    dLeft = pulseIn(pEchoL, HIGH)/58.2;
    if(dLeft > 100)
       dLeft = 0;
  }

  if(sensor_ind == 2)
  {
    dRight = pulseIn(pEchoR, HIGH)/58.2;
    if(dRight > 100)
       dRight = 0;
  }

  sensor_ind = (sensor_ind + 1)%3;
}

// -------------------- WYBRANIE KIERUNKU JAZDY ---------------------------------
void checkDirection()
{
  // możliwe kombinacje nacisniętych klawiszy/
  // kierunki jazdy
  // 1 - [W}, 2 - [AW], 3 - [WD], 4 - [A], 5 - [D]
  // 6 - [S]. 7 - [AS], 8 - [SD], 0 - NULL

  // ustawienie odpowiednich wartosci na pinach IN1, IN2, IN3, IN4 mostka H
  if (inDir != dir) // zeby wklepac wartosci tylko jak sie zmienia sterowanie a nie w kazdej iteracji
  {
    switch(inDir)
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
        
        case 9: 
          AUTOMATIC = !AUTOMATIC;
          LOOKING = false;
          break;

        case 10:
          LOOKING = !LOOKING;
          break;

        case 11:
          resetData();
          break;

        default:
          digitalWrite(pOut1, LOW);
          digitalWrite(pOut2, LOW);
          digitalWrite(pOut3, LOW);
          digitalWrite(pOut4, LOW);
          AUTOMATIC = false;
          LOOKING = false;
          break;
    }
    
     if(!AUTOMATIC && inDir < 9)
     {
        dir = inDir;
        setMotors(dir);
     }
  }
}

// ------------- USTAWIENIE WARTOŚCI ZADANYCH ------------
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
  // ------------ PRZYJMOWANIE DANYCH ----------
  // przyjęcie informacji wysyłanej przez apke 
  inDir = atoi(server.arg("dir").c_str());
  checkDirection();

  // ------------- WYSYŁANIE DANYCH ------------
  String dataMes = String(dir) + "," + String(dFront) + 
      "," + String(dLeft) + "," + String(dRight) + "," + 
      String(countR) + "," + String(countL) + "," + 
      String(dCR) + "," + String(dCL) + "\n";

  server.send(200, "text/html", dataMes);
}

// ---------- INFORMACJE O PODŁĄCZONYCH STACJACH -------------------------

void onStationConnected(const WiFiEventSoftAPModeStationConnected& evt) 
{
  Serial.print("Station connected: ");
  Serial.println(macToString(evt.mac));
}

void onStationDisconnected(const WiFiEventSoftAPModeStationDisconnected& evt) 
{
  Serial.print("Station disconnected: ");
  Serial.println(macToString(evt.mac));
}

String macToString(const unsigned char* mac) 
{
  char buf[20];
  snprintf(buf, sizeof(buf), "%02x:%02x:%02x:%02x:%02x:%02x",
           mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
  return String(buf);
}

// -------------------------------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------------
// ----------- DANE ALGORYTM LABIRYNT ----------

const int WEST = 1 ;  // binarnie 00000001
const int SOUTH = 2 ; // binarnie 00000010
const int EAST = 4  ;  // binarnie 00000100
const int NORTH = 8 ; // binarnie 00001000

//współrzędne w labiryncie w którym robot startuje ( 10 pole, bo 2 rzad 2 kolumna, z czego 1 i ostania kolumna i rzad nie licza się do labiryntu)
//    1  2  3  4  5  6  7  8  9  10  //powinno być od 0, a nie od 1
// 11 12 13 14 15 16 17 18 19 20 21
// 22 23 24 25 26 27 28 29 30 31 32
// 33 34 35 36 37 38 39 40 41 42 43
// 44 45 46 47 48 49 50 51 52 53 54
// 55 56 57 58 59 60 61 62 63 64

int indeks = 23;
int liczba_rzedow = 6; 
int liczba_kolumn = 11;

int *mapa = new int[liczba_rzedow * liczba_kolumn - 1];

int kierunek = EAST; //początkowy zwrot robota

const int go_time = 55; // takie go_time, aby dla funkcji Forward_test() przejechał długość = 1 segmentowi labiryntu
const int trun_time = 17; //takie turn_time, żeby dawało skręt o 90st
const int distanceF = 45; //dystans od ściany przód, aby czujnik ją zauważył
const int distanceF2 = 30; //dystans od ściany przód, aby czujnik uznał, że trzeba skręcić
const int distance = 100; //dystans od ściany bok, aby czujnik ją zauważył

const int good_distance = 58; //optymalna odległość robota od ściany bocznej
long p_time = 0;
int id;

int goRL = 0;
int goF = 0;

bool straight_tunel = false;
bool initialise = false;
bool win = false;
bool zawracanko = false;
int *odwiedzono = new int[liczba_rzedow * liczba_kolumn - 1];

//-------------PID - cz. odległości --------
const float kp1 = 0.095, ki1 = 0.025, kd1 = 0.008; // do dostrojenia
float err1 = 0, perr1 = 0, sumerr1 = 0, derr1 = 0;

//-------------PID - enkodery --------
const float kp2 = 0.065, ki2 = 0.025, kd2 = 0.008; // do dostrojenia
float err2 = 0, perr2 = 0, sumerr2 = 0, derr2 = 0;

// -------------------- RESETOWANIE DANYCH LABIRYNTU ---------------
void resetData()
{
  for(int i = 0; i < liczba_kolumn - 1; i++) 
    for(int j = 0; j < liczba_rzedow; j++)
    {
      odwiedzono[i*liczba_kolumn + j] = 0;
      mapa[i*liczba_kolumn + j] = 0;
    }
}

// --------------------- LABIYNT ----------------
void solve_maze()
{
  void goRight(int);
  void goLeft(int);
  void goForward();
  void goForwardErr();
  void goBack(int);
  void Stop();
  int updateId(int, int);

  bool chamuj_sie = false;
  if (!initialise)
  {
    initialise = true;
    for (int i = 0; i < liczba_rzedow * liczba_kolumn - 2; i++)
    {
      mapa[i] = 0;
      odwiedzono[i] = 0;
    }
  }
  id = indeks;
  getDistances();

  perr1 = err1;
  perr2 = err2;

  float dT = (millis() - p_time) / 1000.0;
  p_time = millis();
  if (straight_tunel && dRight < distance && dLeft < distance) //jak prosty tunel z ścianami z dwoch ston to PID stara się wyrównać odległość między nimi
  {                                                           
    err1 =dRight - dLeft;
    err2= vR - vL;
  } else if (goF>0) //jak robot jedzie do przodu
  {
    if (dRight<dLeft && dRight < distance) //i ma ścianę tylko z prawej strony, to stara się wyrównać odległość od niej
    {
      err1 = dRight - good_distance;
      err2= vR - vL;
    }
    else if (dLeft<dRight && dLeft < distance) //i ma ścianę tylko z lewej strony, to stara się wyrównać odległość od niej
    {
      err1 = good_distance - dLeft;
      err2= vR - vL;
    }
    else //nie ma w pobliżu ścian to bierze PID tylko z enkoderów 
    {
      err1=0;
      err2 = vR - vL;
    }
  } else //jak skręca to brak PID
  {
    err1=0;
    err2=0;
    perr2=0;
    sumerr2=0;
    perr1=0;
    sumerr1=0;
  }
  derr1 = (err1 - perr1)*dT;
  sumerr1 += err1;
  derr2 = (err2 - perr2)*dT;
  sumerr2 += err2;
  
  if (sumerr1>10000)
    sumerr1=10000;

  if (sumerr2>10000)
    sumerr2=10000;
    
  float u1 = kp1*err1 + kd1*derr1 + ki1*sumerr1;
  float u2 = kp2*err2 + kd2*derr2 + ki2*sumerr2;
  uR = dir*(u1 + u2 + VRr)*50;
  uL = dir*(-u1 - u2 + VLr)*50;
  
  uL = constrain(uL, 0, 250);
  uR = constrain(uR, 0, 250);

  analogWrite(pMotoVR, uR);
  analogWrite(pMotoVL, uL);

  if (goRL == 0 && goF == 0 && !win)
  {
    if (dRight == 0 && dLeft == 0)  //wykrywa, że bardzo daleko nie ma ściany, a więc wyjście z labiryntu
    { 
      Stop();
      win = true;
    }
    else if (dFront > distance && dRight < distance && dLeft < distance) //prosty tunel
    {
      // Serial.print("F/L");
      goForward();
      straight_tunel = true;
    }
    else if (dFront > distance && dRight < distance) //rozgałęzienie prosto/lewo
    {
      // Serial.print("F/L");
      if (kierunek == NORTH)
      {
        if (odwiedzono[indeks] == 0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        { //to jedzie prosto
          goForward();
        }
        else if (odwiedzono[indeks + liczba_kolumn] == 1) //Jeśli robot trafił na skrzyżowanie na którym
        { //już był, to zawraca o ile droga którą przyjechał
          goBack(kierunek);                                 //została przebyta tylko 1 raz
        }
        else if (odwiedzono[indeks - liczba_kolumn] <= odwiedzono[indeks - 1])
        { //W innym przypadku wybiera drogę, która została
          goForward();               //Przebyta mniej razy
        }
        else
        {
          goLeft(kierunek);
        }
      }
      else if (kierunek == SOUTH)
      {
        if (odwiedzono[indeks] == 0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        { //to jedzie prosto
          goForward();
        }
        else if (odwiedzono[indeks - liczba_kolumn] == 1) //Jeśli robot trafił na skrzyżowanie na którym
        { //już był, to zawraca o ile droga którą przyjechał
          goBack(kierunek);                                 //została przebyta tylko 1 raz
        }
        else if (odwiedzono[indeks + liczba_kolumn] <= odwiedzono[indeks + 1])
        { //W innym przypadku wybiera drogę, która została
          goForward();               //Przebyta mniej razy
        }
        else
        {
          goLeft(kierunek);
        }
      }
      else if (kierunek == WEST)
      {
        if (odwiedzono[indeks] == 0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        { //to jedzie prosto
          goForward();
        }
        else if (odwiedzono[indeks + 1] == 1) //Jeśli robot trafił na skrzyżowanie na którym
        { //już był, to zawraca o ile droga którą przyjechał
          goBack(kierunek);                       //została przebyta tylko 1 raz
        }
        else if (odwiedzono[indeks - 1] <= odwiedzono[indeks + liczba_kolumn])
        { //W innym przypadku wybiera drogę, która została
          goForward();               //Przebyta mniej razy
        }
        else
        {
          goLeft(kierunek);
        }
      }
      else if (kierunek == EAST)
      {
        if (odwiedzono[indeks] == 0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        { //to jedzie prosto
          goForward();
        }
        else if (odwiedzono[indeks - 1] == 1) //Jeśli robot trafił na skrzyżowanie na którym
        { //już był, to zawraca o ile droga którą przyjechał
          goBack(kierunek);                       //została przebyta tylko 1 raz
        }
        else if (odwiedzono[indeks + 1] <= odwiedzono[indeks - liczba_kolumn])
        { //W innym przypadku wybiera drogę, która została
          goForward();               //Przebyta mniej razy
        }
        else
        {
          goLeft(kierunek);
        }
      }
    }
    else if (dFront > distance && dLeft < distance ) //rozgałęzienie prosto/prawo
    {
      // Serial.print("F/R");
      if (kierunek == NORTH)
      {
        if (odwiedzono[indeks] == 0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        { //to jedzie prosto
          goForward();
        }
        else if (odwiedzono[indeks + liczba_kolumn] == 1) //Jeśli robot trafił na skrzyżowanie na którym
        { //już był, to zawraca o ile droga którą przyjechał
          goBack(kierunek);                                 //została przebyta tylko 1 raz
        }
        else if (odwiedzono[indeks - liczba_kolumn] <= odwiedzono[indeks + 1])
        { //W innym przypadku wybiera drogę, która została
          goForward();               //Przebyta mniej razy
        }
        else
        {
          goRight(kierunek);
        }
      }
      else if (kierunek == SOUTH)
      {
        if (odwiedzono[indeks] == 0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        { //to jedzie prosto
          goForward();
        }
        else if (odwiedzono[indeks - liczba_kolumn] == 1) //Jeśli robot trafił na skrzyżowanie na którym
        { //już był, to zawraca o ile droga którą przyjechał
          goBack(kierunek);                                 //została przebyta tylko 1 raz
        }
        else if (odwiedzono[indeks + liczba_kolumn] <= odwiedzono[indeks - 1])
        { //W innym przypadku wybiera drogę, która została
          goForward();               //Przebyta mniej razy
        }
        else
        {
          goRight(kierunek);
        }
      }
      else if (kierunek == WEST)
      {
        if (odwiedzono[indeks] == 0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        { //to jedzie prosto
          goForward();
        }
        else if (odwiedzono[indeks + 1] == 1) //Jeśli robot trafił na skrzyżowanie na którym
        { //już był, to zawraca o ile droga którą przyjechał
          goBack(kierunek);                       //została przebyta tylko 1 raz
        }
        else if (odwiedzono[indeks - 1] <= odwiedzono[indeks - liczba_kolumn])
        { //W innym przypadku wybiera drogę, która została
          goForward();               //Przebyta mniej razy
        }
        else
        {
          goRight(kierunek);
        }
      }
      else if (kierunek == EAST)
      {
        if (odwiedzono[indeks] == 0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        { //to jedzie prosto
          goForward();
        }
        else if (odwiedzono[indeks - 1] == 1) //Jeśli robot trafił na skrzyżowanie na którym
        { //już był, to zawraca o ile droga którą przyjechał
          goBack(kierunek);                       //została przebyta tylko 1 raz
        }
        else if (odwiedzono[indeks + 1] <= odwiedzono[indeks + liczba_kolumn])
        { //W innym przypadku wybiera drogę, która została
          goForward();               //Przebyta mniej razy
        }
        else
        {
          goRight(kierunek);
        }
      }
    }
    else if (dFront > distance) // rozgałęznienie prosto/prawo/lewo
    {
      // Serial.print("F/R/L");
      if (kierunek == NORTH)
      {
        if (odwiedzono[indeks] == 0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        { //to jedzie prosto
          goForward();
        }
        else if (odwiedzono[indeks + liczba_kolumn] == 1) //Jeśli robot trafił na skrzyżowanie na którym
        { //już był, to zawraca o ile droga którą przyjechał
          goBack(kierunek);                                 //została przebyta tylko 1 raz
        }
        else if (odwiedzono[indeks - liczba_kolumn] <= odwiedzono[indeks + 1] && odwiedzono[indeks - liczba_kolumn] <= odwiedzono[indeks - 1])
        { //W innym przypadku wybiera drogę, która została
          goForward();               //Przebyta mniej razy
        }
        else if (odwiedzono[indeks + 1] <= odwiedzono[indeks - 1])
        {
          goRight(kierunek);
        }
        else
        {
          goLeft(kierunek);
        }
      }
      else if (kierunek == SOUTH)
      {
        if (odwiedzono[indeks] == 0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        { //to jedzie prosto
          goForward();
        }
        else if (odwiedzono[indeks - liczba_kolumn] == 1) //Jeśli robot trafił na skrzyżowanie na którym
        { //już był, to zawraca o ile droga którą przyjechał
          goBack(kierunek);                                 //została przebyta tylko 1 raz
        }
        else if (odwiedzono[indeks + liczba_kolumn] <= odwiedzono[indeks + 1] && odwiedzono[indeks + liczba_kolumn] <= odwiedzono[indeks - 1])
        { //W innym przypadku wybiera drogę, która została
          goForward();               //Przebyta mniej razy
        }
        else if (odwiedzono[indeks - 1] <= odwiedzono[indeks + 1])
        {
          goRight(kierunek);
        }
        else
        {
          goLeft(kierunek);
        }
      }
      else if (kierunek == WEST)
      {
        if (odwiedzono[indeks] == 0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        { //to jedzie prosto
          goForward();
        }
        else if (odwiedzono[indeks + 1] == 1) //Jeśli robot trafił na skrzyżowanie na którym
        { //już był, to zawraca o ile droga którą przyjechał
          goBack(kierunek);                                 //została przebyta tylko 1 raz
        }
        else if (odwiedzono[indeks - 1] <= odwiedzono[indeks + liczba_kolumn] && odwiedzono[indeks - 1] <= odwiedzono[indeks - liczba_kolumn])
        { //W innym przypadku wybiera drogę, która została
          goForward();               //Przebyta mniej razy
        }
        else if (odwiedzono[indeks - liczba_kolumn] <= odwiedzono[indeks + liczba_kolumn])
        {
          goRight(kierunek);
        }
        else
        {
          goLeft(kierunek);
        }
      }
      else if (kierunek == EAST)
      {
        if (odwiedzono[indeks] == 0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        { //to jedzie prosto
          goForward();
        }
        else if (odwiedzono[indeks - 1] == 1) //Jeśli robot trafił na skrzyżowanie na którym
        { //już był, to zawraca o ile droga którą przyjechał
          goBack(kierunek);                                 //została przebyta tylko 1 raz
        }
        else if (odwiedzono[indeks + 1] <= odwiedzono[indeks + liczba_kolumn] && odwiedzono[indeks + 1] <= odwiedzono[indeks - liczba_kolumn])
        { //W innym przypadku wybiera drogę, która została
          goForward();               //Przebyta mniej razy
        }
        else if (odwiedzono[indeks + liczba_kolumn] <= odwiedzono[indeks - liczba_kolumn])
        {
          goRight(kierunek);
        }
        else
        {
          goLeft(kierunek);
        }
      }
    }
    else if (dFront < distanceF && dRight > distance && dLeft < distance) //zakręt w prawo
    {
      // Serial.print("R");
      goRight(kierunek);
    }
    else if (dFront < distanceF && dRight < distance && dLeft > distance) //zakręt w lewo
    {
      // Serial.print("L");
      goLeft(kierunek);
    }
    else if (dFront < distanceF && dRight > distance && dLeft > distance) //rozgałęznienie prawo/lewo
    {
      // Serial.print("R/L");
      if (kierunek == EAST)
      {
        if (odwiedzono[indeks] == 0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        { //to jedzie w prawo
          goRight(kierunek);
        }
        else if (odwiedzono[indeks - 1] == 1) //Jeśli robot trafił na skrzyżowanie na którym
        { //już był, to zawraca o ile droga którą przyjechał
          goBack(kierunek);                       //została przebyta tylko 1 raz
        }
        else if (odwiedzono[indeks + liczba_kolumn] <= odwiedzono[indeks - liczba_kolumn])
        { //W innym przypadku wybiera drogę, która została
          goRight(kierunek);               //Przebyta mniej razy
        }
        else
        {
          goLeft(kierunek);
        }
      }
      else if (kierunek == WEST)
      {
        if (odwiedzono[indeks] == 0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        { //to jedzie w prawo
          goRight(kierunek);
        }
        else if (odwiedzono[indeks + 1] == 1) //Jeśli robot trafił na skrzyżowanie na którym
        { //już był, to zawraca o ile droga którą przyjechał
          goBack(kierunek);                       //została przebyta tylko 1 raz
        }
        else if (odwiedzono[indeks - liczba_kolumn] <= odwiedzono[indeks + liczba_kolumn])
        { //W innym przypadku wybiera drogę, która została
          goRight(kierunek);                //Przebyta mniej razy
        }
        else
        {
          goLeft(kierunek);
        }
      }
      else if (kierunek == NORTH)
      {
        if (odwiedzono[indeks] == 0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        { //to jedzie w prawo
          goRight(kierunek);
        }
        else if (odwiedzono[indeks + liczba_kolumn] == 1) //Jeśli robot trafił na skrzyżowanie na którym
        { //już był, to zawraca o ile droga którą przyjechał
          goBack(kierunek);                       //została przebyta tylko 1 raz
        }
        else if (odwiedzono[indeks + 1] <= odwiedzono[indeks - 1])
        { //W innym przypadku wybiera drogę, która została
          goRight(kierunek);                //Przebyta mniej razy
        }
        else
        {
          goLeft(kierunek);
        }
      }
      else if (kierunek == SOUTH)
      {
        if (odwiedzono[indeks] == 0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        { //to jedzie w prawo
          goRight(kierunek);
        }
        else if (odwiedzono[indeks - liczba_kolumn] == 1) //Jeśli robot trafił na skrzyżowanie na którym
        { //już był, to zawraca o ile droga którą przyjechał
          goBack(kierunek);                       //została przebyta tylko 1 raz
        }
        else if (odwiedzono[indeks - 1] <= odwiedzono[indeks + 1])
        { //W innym przypadku wybiera drogę, która została
          goRight(kierunek);                //Przebyta mniej razy
        }
        else
        {
          goLeft(kierunek);
        }
      }
    }
    else if (dFront < distance && dRight < distance && dLeft < distance) //Ślepa uliczka
    {
      odwiedzono[indeks]++;
      goBack(kierunek);
    }
    else
    {
      goForwardErr();
      chamuj_sie = true;
    }
    
    if (!chamuj_sie)
    {
      odwiedzono[indeks]++;
      indeks = updateId(id, kierunek);
      if (indeks == 0)
      {
        //Serial.print("Pojazd opóścił labirynt");
        win = true;
      }
    }
  }
  else if (goRL>=trun_time*2)
  {
    Stop();
    goForward();
  }
  else if (goRL==trun_time && !zawracanko )
  {
    Stop();
    goForward();
  }
  else if (goRL>0 && goRL < 2*trun_time)
  {
    goRL++;
  }
  else if (goF == go_time || (goF > (go_time - (int)floor(go_time / 10)) && dFront < distanceF2))
  {
    Stop();
  }
  else if (goF < go_time)
  {
    goF++;
  }
}

void goForward()
{
  zawracanko = false;
  goF++;
  goRL = 0;
  digitalWrite(pOut1, HIGH);
  digitalWrite(pOut2, LOW);
  digitalWrite(pOut3, HIGH);
  digitalWrite(pOut4, LOW);
  setMotors(1);
}

void goForwardErr()
{
  zawracanko = false;
  goF = goF + 10;
  goRL = 0;
  digitalWrite(pOut1, HIGH);
  digitalWrite(pOut2, LOW);
  digitalWrite(pOut3, HIGH);
  digitalWrite(pOut4, LOW);
  setMotors(9);
}

void goRight(int kier)
{
  zawracanko = false;
  digitalWrite(pOut1, LOW);
  digitalWrite(pOut2, HIGH);
  digitalWrite(pOut3, HIGH);
  digitalWrite(pOut4, LOW);
  setMotors(1);
  //// Serial.print("Skręcam w prawo");
  // sprawdzaj = 0;
  goRL++;

  if (kier == NORTH)
  {
    kierunek = EAST;
  }
  else if (kier == SOUTH)
  {
    kierunek = WEST;
  }
  else if (kier == WEST)
  {
    kierunek = NORTH;
  }
  else if (kier == EAST)
  {
    kierunek = SOUTH;
  }
}

void goLeft(int kier)
{
  zawracanko = false;
  // Serial.print("Skręcam w lewo");
  // sprawdzaj = 0;
  goRL++;
  digitalWrite(pOut1, HIGH);
  digitalWrite(pOut2, LOW);
  digitalWrite(pOut3, LOW);
  digitalWrite(pOut4, HIGH);
  setMotors(1);
  if (kier == NORTH)
  {
    kierunek = WEST;
  }
  else if (kier == SOUTH)
  {
    kierunek = EAST;
  }
  else if (kier == WEST)
  {
    kierunek = SOUTH;
  }
  else if (kier == EAST)
  {
    kierunek = NORTH;
  }
}

void Stop()
{
  zawracanko = false;
  goF = 0;
  goRL = 0;
  digitalWrite(pOut1, LOW);
  digitalWrite(pOut2, LOW);
  digitalWrite(pOut3, LOW);
  digitalWrite(pOut4, LOW);
  setMotors(0);
}
void goBack(int kier)
{
  zawracanko = true;
  // Serial.print("Wracam");
  //  sprawdzaj = 0;
  goRL++;
  digitalWrite(pOut1, LOW);
  digitalWrite(pOut2, HIGH);
  digitalWrite(pOut3, HIGH);
  digitalWrite(pOut4, LOW);
  setMotors(1); //zawracanie do poprawy
  if (kier == NORTH)
  {
    kierunek = SOUTH;
  }
  else if (kier == SOUTH)
  {
    kierunek = NORTH;
  }
  else if (kier == WEST)
  {
    kierunek = EAST;
  }
  else if (kier == EAST)
  {
    kierunek = WEST;
  }
}

int updateId(int id, int kier)
{
  int ide = id;
  switch (kier)
  {
    case NORTH:
      ide = id - liczba_kolumn;
      break;
    case SOUTH:
      ide = id + liczba_kolumn;
      break;
    case EAST:
      ide = id + 1;
      break;
    case WEST:
      ide = id - 1;
      break;
  }
  //Serial.print("id= " + ide);
  if (ide < 10 || ide > 52 || ide % 11 == 10 || ide % 11 == 9)
  {
    return 0;
  }
  else
  {
    return ide;
  }
}

void Right_test()
{
    perr1 = err1;
    perr2 = err2;

  float dT = (millis() - p_time)/1000.0;
  p_time = millis();

  if (straight_tunel && dRight < distance && dLeft < distance) //jak prosty tunel z ścianami z dwoch ston to PID stara się wyrównać odległość między nimi
  {                                                           
    err1 =dRight - dLeft;
    err2= vR - vL;
  } else if (goF>0) //jak robot jedzie do przodu
  {
    if (dRight<dLeft && dRight < distance) //i ma ścianę tylko z prawej strony, to stara się wyrównać odległość od niej
    {
      err1 = dRight - good_distance;
      err2= vR - vL;
    }
    else if (dLeft<dRight && dLeft < distance) //i ma ścianę tylko z lewej strony, to stara się wyrównać odległość od niej
    {
      err1 = good_distance - dLeft;
      err2= vR - vL;
    }
    else //nie ma w pobliżu ścian to bierze PID tylko z enkoderów 
    {
      err1=0;
      err2 = vR - vL;
    }
  } else //jak skręca to brak PID
  {
    err1=0;
    err2=0;
    perr2=0;
    sumerr2=0;
    perr1=0;
    sumerr1=0;
  }
  derr1 = (err1 - perr1)*dT;
  sumerr1 += err1;
  derr2 = (err2 - perr2)*dT;
  sumerr2 += err2;
  
  if (sumerr1>10000)
    sumerr1=10000;

  if (sumerr2>10000)
    sumerr2=10000;
    
  float u1 = kp1*err1 + kd1*derr1 + ki1*sumerr1;
  float u2 = kp2*err2 + kd2*derr2 + ki2*sumerr2;
  uR = dir*(u1 + u2 + VRr)*50;
  uL = dir*(-u1 - u2 + VLr)*50;
  
  uL = constrain(uL, 0, 250);
  uR = constrain(uR, 0, 250);

  analogWrite(pMotoVR, uR);
  analogWrite(pMotoVL, uL);
  if(goRL == 0)
  {
    goRight(NORTH);
  }
  else if (goRL > 0 && goRL < trun_time)
  {
    goRL++;
  }
  else if (goRL == trun_time)
  {
    Stop();
  }
}

void Forward_test()
{
      perr1 = err1;
    perr2 = err2;

  float dT = (millis() - p_time)/1000.0;
  p_time = millis();

  if (straight_tunel && dRight < distance && dLeft < distance) //jak prosty tunel z ścianami z dwoch ston to PID stara się wyrównać odległość między nimi
  {                                                           
    err1 =dRight - dLeft;
    err2= vR - vL;
  } else if (goF>0) //jak robot jedzie do przodu
  {
    if (dRight<dLeft && dRight < distance) //i ma ścianę tylko z prawej strony, to stara się wyrównać odległość od niej
    {
      err1 = dRight - good_distance;
      err2= vR - vL;
    }
    else if (dLeft<dRight && dLeft < distance) //i ma ścianę tylko z lewej strony, to stara się wyrównać odległość od niej
    {
      err1 = good_distance - dLeft;
      err2= vR - vL;
    }
    else //nie ma w pobliżu ścian to bierze PID tylko z enkoderów 
    {
      err1=0;
      err2 = vR - vL;
    }
  } else //jak skręca to brak PID
  {
    err1=0;
    err2=0;
    perr2=0;
    sumerr2=0;
    perr1=0;
    sumerr1=0;
  }
  derr1 = (err1 - perr1)*dT;
  sumerr1 += err1;
  derr2 = (err2 - perr2)*dT;
  sumerr2 += err2;
  
  if (sumerr1>10000)
    sumerr1=10000;

  if (sumerr2>10000)
    sumerr2=10000;
    
  float u1 = kp1*err1 + kd1*derr1 + ki1*sumerr1;
  float u2 = kp2*err2 + kd2*derr2 + ki2*sumerr2;
  uR = dir*(u1 + u2 + VRr)*50;
  uL = dir*(-u1 - u2 + VLr)*50;
  
  uL = constrain(uL, 0, 250);
  uR = constrain(uR, 0, 250);

  analogWrite(pMotoVR, uR);
  analogWrite(pMotoVL, uL);
  if(goF == 0)
  {
    goForward();
  }
  else if (goF > 0 && goF < go_time)
  {
    goF++;
  }
  else if (goF == go_time)
  {
    Stop(); 
    goF = go_time;
  }
}
