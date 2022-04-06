// TU PISAMY ALGORYTM DO STEROWANIA NIC WIECEJ NIE RUSZAMY
// TUTAJ DODAWAJ ZMIENNE GLOBALNE
// ------------------------------
// np. wektor punktów
// ArrayList <PVector> points = new ArrayList<PVector>();
// points.add(new PVector(x,y));

// jakies przykladowe zmienne do tego slabego algorytmu co tam jest
float vL, vR, dF, dR, dL, dB, uR, uL;
float err = 0, perr = 0, derr = 0, sumerr = 0;
float kp = 0.003;
float kd = 0.000009;
float ki = 0.000001;
float mU = 2;
int dir = 1;
long p_time = 0;

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
  err = dR - dL;
  
  float dT = (millis() - p_time)/1000.0;
  p_time = millis();
  
  derr = (err - perr)*dT;
  sumerr += err;
   
  //(dConstL - dL) + (dConstR - dR)
  float u = kp*err + kd*derr + ki*sumerr;
  
  uR = dir*(mU + u);
  uL = dir*(mU - u);
  
  if(dF < 10 || dB < 10 || dR < 10 || dL < 10)
     mU = 0;
  else 
    mU = 2;
  
  
  // ograniczenie napięcia
  uR = constrain(uR, -5, 5);
  uL = constrain(uL, -5, 5);
  
  // -- END CONTROLS --
  // -- podawanie napięcia na silniki --
  // wartosci np. od -5 do 5
  bot.writeLEFT(uL);
  bot.writeRIGHT(uR);
}