// TU PISAMY ALGORYTM DO STEROWANIA NIC WIECEJ NIE RUSZAMY
// TUTAJ DODAWAJ ZMIENNE GLOBALNE
//WEST = 1;    // binarnie 00000001
//SOUTH= 2;   // binarnie 00000010
//EAST = 4;    // binarnie 00000100
//NORTH = 8;   // binarnie 00001000

//final int M= 4;
//final int N= 9;
//int[] mapa = new int[M*N];
final int trun_time= 26; //trzeba znaleźć takie turn_time i mU, żeby mU*turn_time dawało skręt o 90st
final int distanceF= 25; //dystans od ściany przód, aby czujnik ją zauważył
final int distance= 100; //dystans od ściany bok, aby czujnik ją zauważył
int W; //W i do przodu
//int indeks = 0;
// jakies przykladowe zmienne do tego slabego algorytmu co tam jest
float vL, vR, dF, dR, dL, dB, uR, uL;
float err = 0, perr = 0, derr = 0, sumerr = 0;
float kp = 0.002;
float kd = 0.000009;
float ki = 0.000001;
float mU = 2;
int dir = 1;
long p_time = 0;
int goRL = 0;
boolean straight_tunel = false;
boolean going_straight = false;
boolean turn = false;

// funkcja sterująca robotem
void controls()
{
  // dostępne wartości z czujników:
  // -- lewy i prawy enkoder prędkości obrotowej --
  vL = bot.encLEFT();
  vR = bot.encRIGHT();
  // --- czujniki odległości ---
  dF = bot.getFRONT_SENSOR();
  dR = bot.getRIGHT_SENSOR();
  dL = bot.getLEFT_SENSOR();
  dB = bot.getREAR_SENSOR();

  // -----------------------------------
  // -- CONTROLS HERE --
  // napięcia na lewe i na prawe koł
  //float dConstR = 60.0;
  //float dConstL = 60.0;

  perr = err;

  float dT = (millis() - p_time)/1000.0;
  p_time = millis();


  //(dConstL - dL) + (dConstR - dR)

  if (straight_tunel && dR < distance && dL < distance)
  {
    err = dR - dL;
  } else if (going_straight)
  {
    err = vR - vL;
    //System.out.println(vR + " " + vL);
  } else
  {
    err=0;
  }
  derr = (err - perr)*dT;
  sumerr += err;
  float u = kp*err + kd*derr + ki*sumerr;


  uR = dir*(mU + 0.5*u + W);
  uL = dir*(-mU - 0.5*u + W);


  if (dF > distance && dR < distance && dL < distance & !turn) //prosty tunel
    {
      goForward();
      straight_tunel=true;
    }
    else if(dF > distanceF && !turn)
    {
      goForward();
    }
  else if (goRL == 0)
  {
    if (dF < distanceF && dR > distance) //zakręt w prawo
    {
      goRight();
    } else if (dF < distanceF &&  dL > distance) //zakręt w lewo
    {
      goLeft();
    }
    else if (dF < distanceF &&  dL < distance && dR < distance)
    {
      if (dL < dR)
      {
        goRight();
      }
      else
      {
        goLeft();
      }
    }
  }
  else if (goRL < trun_time)
  {
    goRL++;
  }
   else if (goRL==trun_time)
  {
    Stop();
  } else
  {
    Stop();
  }

  // ograniczenie napięcia
  uR = constrain(uR, -5, 5);
  uL = constrain(uL, -5, 5);

  // -- END CONTROLS --
  // -- podawanie napięcia na silniki --
  // wartosci np. od -5 do 5
  bot.writeLEFT(uL);
  bot.writeRIGHT(uR);
}
void goForward()
{
  going_straight = true;
  turn = false;
  mU=0;
  W=1;
}
void goRight()
{
  going_straight = false;
  turn = true;
  goRL++;
  mU=2;
  W=0;
}
void goLeft()
{
  going_straight = false;
  turn = true;
  goRL++;
  mU=-2;
  W=0;
}
void goBack()
{
  mU=0;
  W=-1;
}
void Stop()
{
  goRL=0;
  mU=0;
  W=0;
  straight_tunel=false;
  going_straight = false;
  turn = false;
}
/*void dodaj_sciane(int indeks, kierunek)
 {
 mapa[indeks] = mapa[indeks] | kierunek;
 if( kierunek == NORTH ) {
 indeks = indeks + 16;          // teraz indeks pokazuje na segment powyżej
 mapa[indeks] = mapa[indeks] | SOUTH;
 }
 if( kierunek == EAST ) {
 indeks = indeks + 1;
 mapa[indeks] = mapa[indeks] | WEST;
 }
 if( kierunek == SOUTH ) {
 indeks = indeks + 240;    // równoważne z odjęciem 16
 mapa[indeks] = mapa[indeks] | NORTH;
 }
 if( kierunek == WEST ) {
 indeks = indeks + 255;    // równoważne z odjęciem 1
 mapa[indeks] = mapa[indeks] | EAST;
 }
 }*/
