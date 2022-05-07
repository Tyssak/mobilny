// TU PISAMY ALGORYTM DO STEROWANIA NIC WIECEJ NIE RUSZAMY
// TUTAJ DODAWAJ ZMIENNE GLOBALNE
final int WEST = 1 ;  // binarnie 00000001
final int SOUTH= 2 ;  // binarnie 00000010
final int EAST = 4  ;  // binarnie 00000100
final int NORTH = 8 ; // binarnie 00001000

//współrzędne w labiryncie w którym robot startuje ( 10 pole, bo 2 rzad 2 kolumna, z czego 1 i ostania kolumna i rzad nie licza się do labiryntu)
//    1  2  3  4  5  6  7  8  9  10  //powinno być od 0, a nie od 1
// 11 12 13 14 15 16 17 18 19 20 21
// 22 23 24 25 26 27 28 29 30 31 32
// 33 34 35 36 37 38 39 40 41 42 43
// 44 45 46 47 48 49 50 51 52 53 54
// 55 56 57 58 59 60 61 62 63 64 
int indeks = 23;

//wielkość labiryntu
int liczba_rzedow = 6; //zawsze podawać o 2 większą
int liczba_kolumn = 11; //zawsze podawać o 2 większą

int[] mapa = new int[liczba_rzedow*liczba_kolumn-1];

int kierunek = EAST;
//final int M= 4;
//final int N= 9;
//int[] mapa = new int[M*N];
final float trun_time= 48; //trzeba znaleźć takie turn_time i mU, żeby mU*turn_time dawało skręt o 90st
final int distanceF= 45; //dystans od ściany przód, aby czujnik ją zauważył
final int distanceF2= 30; //dystans od ściany przód, aby czujnik uznał, że trzeba skręcić
final int distance= 100; //dystans od ściany bok, aby czujnik ją zauważył
final int go_time = 175;
float W; //W i do przodu
//int indeks = 0;
// jakies przykladowe zmienne do tego slabego algorytmu co tam jest
float vL, vR, dF, dR, dL, dB, uR, uL;
float err = 0, perr = 0, derr = 0, sumerr = 0;
float kp = 0.002;
float kd = 0.000009;
float ki = 0.000001;
float mU;  
int dir = 1;
long p_time = 0;
int goRL = 0;
int goF = 0;
int id;
boolean straight_tunel = false;
boolean initialise = false;
boolean win = false;
short []odwiedzono = new short[liczba_rzedow*liczba_kolumn-2];

// funkcja sterująca robotem
void controls()
{
  boolean chamuj_sie=false;
  if(!initialise)
  {
    initialise=true;
    for(int i=0; i<liczba_rzedow*liczba_kolumn-2; i++)
    {
      mapa[i]=0;
      odwiedzono[i]=0;
    }
  }
  id = indeks;
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
    err = 0.6*(dR - dL);
  } else if (goF>0)
  {
    if (dR<dL && dR < distance)
    {
      err = 0.6*(dR - 58);
    }
    else if (dL<dR && dL < distance)
    {
      err = 0.6*(58 - dL);
    }
    else
    {
      err = vR - vL;
    }
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
  
  
  if (goRL==0 && goF==0 && !win)
  {
 /* if (dR > 1000)  //wykrywa, że bardzo daleko nie ma ściany, a więc wyjście z labiryntu
  {                 //nie działa w symulacji, bo zakres czujnika za mały
    goRight(kierunek);
    win = true;
  }
  else if (dL > 1000)
  {
    goLeft(kierunek);
    win = true;
  }
  else*/ if (dF > distance && dR < distance && dL < distance)
  {
    System.out.println("F");
    goForward();
    
    straight_tunel=true;
  }
  else if (dF > distance && dR < distance) //rozgałęzienie prosto/lewo
  {
    System.out.println("F/L");
    if(kierunek==NORTH)
    {
      if(odwiedzono[indeks]==0) //Jeśli robot nie był wcześniej na danym rozwidleniu
      {                         //to jedzie prosto
        goForward();
      }
      else if (odwiedzono[indeks+liczba_kolumn]==1) //Jeśli robot trafił na skrzyżowanie na którym
      {                                            //już był, to zawraca o ile droga którą przyjechał 
        goBack(kierunek);                                 //została przebyta tylko 1 raz
      }
      else if(odwiedzono[indeks-liczba_kolumn]<=odwiedzono[indeks-1])
      {                            //W innym przypadku wybiera drogę, która została
        goForward();               //Przebyta mniej razy
      }
      else
      {
        goLeft(kierunek);
      }
    }
    else if(kierunek==SOUTH)
    {
      if(odwiedzono[indeks]==0) //Jeśli robot nie był wcześniej na danym rozwidleniu
      {                         //to jedzie prosto
        goForward();
      }
      else if (odwiedzono[indeks-liczba_kolumn]==1) //Jeśli robot trafił na skrzyżowanie na którym
      {                                            //już był, to zawraca o ile droga którą przyjechał 
        goBack(kierunek);                                 //została przebyta tylko 1 raz
      }
      else if(odwiedzono[indeks+liczba_kolumn]<=odwiedzono[indeks+1])
      {                            //W innym przypadku wybiera drogę, która została
        goForward();               //Przebyta mniej razy
      }
      else
      {
        goLeft(kierunek);
      }
    }
    else if(kierunek==WEST)
    {
      if(odwiedzono[indeks]==0) //Jeśli robot nie był wcześniej na danym rozwidleniu
      {                         //to jedzie prosto
        goForward();
      }
      else if (odwiedzono[indeks+1]==1) //Jeśli robot trafił na skrzyżowanie na którym
      {                                 //już był, to zawraca o ile droga którą przyjechał 
        goBack(kierunek);                       //została przebyta tylko 1 raz
      }
      else if(odwiedzono[indeks-1]<=odwiedzono[indeks+liczba_kolumn])
      {                            //W innym przypadku wybiera drogę, która została
        goForward();               //Przebyta mniej razy
      }
      else
      {
        goLeft(kierunek);
      }
    }
    else if(kierunek==EAST)
    {
      if(odwiedzono[indeks]==0) //Jeśli robot nie był wcześniej na danym rozwidleniu
      {                         //to jedzie prosto
        goForward();
      }
      else if (odwiedzono[indeks-1]==1) //Jeśli robot trafił na skrzyżowanie na którym
      {                                 //już był, to zawraca o ile droga którą przyjechał 
        goBack(kierunek);                       //została przebyta tylko 1 raz
      }
      else if(odwiedzono[indeks+1]<=odwiedzono[indeks-liczba_kolumn])
      {                            //W innym przypadku wybiera drogę, która została
        goForward();               //Przebyta mniej razy
      }
      else
      {
        goLeft(kierunek);
      }
    }
  }
  else if (dF > distance && dL < distance ) //rozgałęzienie prosto/prawo
  {
    System.out.println("F/R");
    if(kierunek==NORTH)
    {
      if(odwiedzono[indeks]==0) //Jeśli robot nie był wcześniej na danym rozwidleniu
      {                         //to jedzie prosto
        goForward();
      }
      else if (odwiedzono[indeks+liczba_kolumn]==1) //Jeśli robot trafił na skrzyżowanie na którym
      {                                            //już był, to zawraca o ile droga którą przyjechał 
        goBack(kierunek);                                 //została przebyta tylko 1 raz
      }
      else if(odwiedzono[indeks-liczba_kolumn]<=odwiedzono[indeks+1])
      {                            //W innym przypadku wybiera drogę, która została
        goForward();               //Przebyta mniej razy
      }
      else
      {
        goRight(kierunek);
      }
    }
    else if(kierunek==SOUTH)
    {
      if(odwiedzono[indeks]==0) //Jeśli robot nie był wcześniej na danym rozwidleniu
      {                         //to jedzie prosto
        goForward();
      }
      else if (odwiedzono[indeks-liczba_kolumn]==1) //Jeśli robot trafił na skrzyżowanie na którym
      {                                            //już był, to zawraca o ile droga którą przyjechał 
        goBack(kierunek);                                 //została przebyta tylko 1 raz
      }
      else if(odwiedzono[indeks+liczba_kolumn]<=odwiedzono[indeks-1])
      {                            //W innym przypadku wybiera drogę, która została
        goForward();               //Przebyta mniej razy
      }
      else
      {
        goRight(kierunek);
      }
    }
    else if(kierunek==WEST)
    {
      if(odwiedzono[indeks]==0) //Jeśli robot nie był wcześniej na danym rozwidleniu
      {                         //to jedzie prosto
        goForward();
      }
      else if (odwiedzono[indeks+1]==1) //Jeśli robot trafił na skrzyżowanie na którym
      {                                 //już był, to zawraca o ile droga którą przyjechał 
        goBack(kierunek);                       //została przebyta tylko 1 raz
      }
      else if(odwiedzono[indeks-1]<=odwiedzono[indeks-liczba_kolumn])
      {                            //W innym przypadku wybiera drogę, która została
        goForward();               //Przebyta mniej razy
      }
      else
      {
        goRight(kierunek);
      }
    }
    else if(kierunek==EAST)
    {
      if(odwiedzono[indeks]==0) //Jeśli robot nie był wcześniej na danym rozwidleniu
      {                         //to jedzie prosto
        goForward();
      }
      else if (odwiedzono[indeks-1]==1) //Jeśli robot trafił na skrzyżowanie na którym
      {                                 //już był, to zawraca o ile droga którą przyjechał 
        goBack(kierunek);                       //została przebyta tylko 1 raz
      }
      else if(odwiedzono[indeks+1]<=odwiedzono[indeks+liczba_kolumn])
      {                            //W innym przypadku wybiera drogę, która została
        goForward();               //Przebyta mniej razy
      }
      else
      {
        goRight(kierunek);
      }
    }
  }
  else if (dF > distance) // rozgałęznienie prosto/prawo/lewo
  {
    System.out.println("F/R/L");
    if(kierunek==NORTH)
    {
      if(odwiedzono[indeks]==0) //Jeśli robot nie był wcześniej na danym rozwidleniu
      {                         //to jedzie prosto
        goForward();
      }
      else if (odwiedzono[indeks+liczba_kolumn]==1) //Jeśli robot trafił na skrzyżowanie na którym
      {                                            //już był, to zawraca o ile droga którą przyjechał 
        goBack(kierunek);                                 //została przebyta tylko 1 raz
      }
      else if(odwiedzono[indeks-liczba_kolumn]<=odwiedzono[indeks+1] && odwiedzono[indeks-liczba_kolumn]<=odwiedzono[indeks-1])
      {                            //W innym przypadku wybiera drogę, która została
        goForward();               //Przebyta mniej razy
      }
      else if (odwiedzono[indeks+1]<=odwiedzono[indeks-1])
      {
        goRight(kierunek);
      }
      else
      {
        goLeft(kierunek);
      }
    }
    else if(kierunek==SOUTH)
    {
      if(odwiedzono[indeks]==0) //Jeśli robot nie był wcześniej na danym rozwidleniu
      {                         //to jedzie prosto
        goForward();
      }
      else if (odwiedzono[indeks-liczba_kolumn]==1) //Jeśli robot trafił na skrzyżowanie na którym
      {                                            //już był, to zawraca o ile droga którą przyjechał 
        goBack(kierunek);                                 //została przebyta tylko 1 raz
      }
      else if(odwiedzono[indeks+liczba_kolumn]<=odwiedzono[indeks+1] && odwiedzono[indeks+liczba_kolumn]<=odwiedzono[indeks-1])
      {                            //W innym przypadku wybiera drogę, która została
        goForward();               //Przebyta mniej razy
      }
      else if (odwiedzono[indeks-1]<=odwiedzono[indeks+1])
      {
        goRight(kierunek);
      }
      else
      {
        goLeft(kierunek);
      }
    }
    else if(kierunek==WEST)
    {
      if(odwiedzono[indeks]==0) //Jeśli robot nie był wcześniej na danym rozwidleniu
      {                         //to jedzie prosto
        goForward();
      }
      else if (odwiedzono[indeks+1]==1) //Jeśli robot trafił na skrzyżowanie na którym
      {                                            //już był, to zawraca o ile droga którą przyjechał 
        goBack(kierunek);                                 //została przebyta tylko 1 raz
      }
      else if(odwiedzono[indeks-1]<=odwiedzono[indeks+liczba_kolumn] && odwiedzono[indeks-1]<=odwiedzono[indeks-liczba_kolumn])
      {                            //W innym przypadku wybiera drogę, która została
        goForward();               //Przebyta mniej razy
      }
      else if (odwiedzono[indeks-liczba_kolumn]<=odwiedzono[indeks+liczba_kolumn])
      {
        goRight(kierunek);
      }
      else
      {
        goLeft(kierunek);
      }
    }
    else if(kierunek==EAST)
    {
      if(odwiedzono[indeks]==0) //Jeśli robot nie był wcześniej na danym rozwidleniu
      {                         //to jedzie prosto
        goForward();
      }
      else if (odwiedzono[indeks-1]==1) //Jeśli robot trafił na skrzyżowanie na którym
      {                                            //już był, to zawraca o ile droga którą przyjechał 
        goBack(kierunek);                                 //została przebyta tylko 1 raz
      }
      else if(odwiedzono[indeks+1]<=odwiedzono[indeks+liczba_kolumn] && odwiedzono[indeks+1]<=odwiedzono[indeks-liczba_kolumn])
      {                            //W innym przypadku wybiera drogę, która została
        goForward();               //Przebyta mniej razy
      }
      else if (odwiedzono[indeks+liczba_kolumn]<=odwiedzono[indeks-liczba_kolumn])
      {
        goRight(kierunek);
      }
      else
      {
        goLeft(kierunek);
      }
    }
  }
    else if(dF < distanceF && dR > distance && dL < distance) //zakręt w prawo
    {
      System.out.println("R");
      goRight(kierunek);
    }
    else if(dF < distanceF && dR < distance && dL > distance) //zakręt w lewo
    {
      System.out.println("L");
      goLeft(kierunek); //<>//
    }
    else if(dF < distanceF && dR > distance && dL > distance) //rozgałęznienie prawo/lewo
    {
      System.out.println("R/L");
      if (kierunek == EAST)
      {
        if(odwiedzono[indeks]==0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        {                         //to jedzie w prawo
          goRight(kierunek);
        }
        else if (odwiedzono[indeks-1]==1) //Jeśli robot trafił na skrzyżowanie na którym
        {                                 //już był, to zawraca o ile droga którą przyjechał 
          goBack(kierunek);                       //została przebyta tylko 1 raz
        }
        else if(odwiedzono[indeks+liczba_kolumn]<=odwiedzono[indeks-liczba_kolumn])
        {                            //W innym przypadku wybiera drogę, która została
          goRight(kierunek);               //Przebyta mniej razy
        }
        else
        {
          goLeft(kierunek);
        }
      } 
      else if (kierunek == WEST)
      {
        if(odwiedzono[indeks]==0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        {                         //to jedzie w prawo
          goRight(kierunek);
        }
        else if (odwiedzono[indeks+1]==1) //Jeśli robot trafił na skrzyżowanie na którym
        {                                 //już był, to zawraca o ile droga którą przyjechał 
          goBack(kierunek);                       //została przebyta tylko 1 raz
        }
        else if(odwiedzono[indeks-liczba_kolumn]<=odwiedzono[indeks+liczba_kolumn])
        {                            //W innym przypadku wybiera drogę, która została
          goRight(kierunek);                //Przebyta mniej razy
        }
        else
        {
          goLeft(kierunek);
        }
      } 
      else if (kierunek == NORTH)
      {
        if(odwiedzono[indeks]==0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        {                         //to jedzie w prawo
          goRight(kierunek);
        }
        else if (odwiedzono[indeks+liczba_kolumn]==1) //Jeśli robot trafił na skrzyżowanie na którym
        {                                 //już był, to zawraca o ile droga którą przyjechał 
          goBack(kierunek);                       //została przebyta tylko 1 raz
        }
        else if(odwiedzono[indeks+1]<=odwiedzono[indeks-1])
        {                            //W innym przypadku wybiera drogę, która została
          goRight(kierunek);                //Przebyta mniej razy
        }
        else
        {
          goLeft(kierunek);
        }
      } 
      else if (kierunek == SOUTH)
      {
        if(odwiedzono[indeks]==0) //Jeśli robot nie był wcześniej na danym rozwidleniu
        {                         //to jedzie w prawo
          goRight(kierunek);
        }
        else if (odwiedzono[indeks-liczba_kolumn]==1) //Jeśli robot trafił na skrzyżowanie na którym
        {                                 //już był, to zawraca o ile droga którą przyjechał 
          goBack(kierunek);                       //została przebyta tylko 1 raz
        }
        else if(odwiedzono[indeks-1]<=odwiedzono[indeks+1])
        {                            //W innym przypadku wybiera drogę, która została
          goRight(kierunek);                //Przebyta mniej razy
        }
        else
        {
          goLeft(kierunek);
        }
      }
    }
    else if(dF < distance && dR < distance && dL < distance) //Ślepa uliczka
    {
      odwiedzono[indeks]++;
      goBack(kierunek); 
    }
    else
    {
      goForwardErr();
      chamuj_sie=true;
    }
    if(!chamuj_sie)
    {
        odwiedzono[indeks]++;
        indeks = updateId(id, kierunek);  
        if (indeks==0)
        {
          System.out.println("Pojazd opóścił labirynt");
          win = true;
        }
    }
    
  }
  else if (goRL>0 && goRL < trun_time)
    {
      goRL++;
    } 
    else if (goRL==trun_time)
    {
      Stop();
      goForward();
    } 
    else if (goF==go_time || (goF > (go_time - (int)floor(go_time/10)) && dF < distanceF2))
    {
      Stop();
    } 
    else if (goF < go_time)
    {
        goF++;
       // System.out.println(goF);
    } 
  // ograniczenie napięcia
  uR = constrain(uR, -5, 5);
  uL = constrain(uL, -5, 5);

  // -- END CONTROLS --
  // -- podawanie napięcia na silniki --
  // wartosci np. od -5 do 5
  bot.writeLEFT(uL);
  bot.writeRIGHT(uR);
  /*for (int i=0; i<liczba_rzedow*liczba_kolumn; i++)
  {
    System.out.println("wsp " + i + " sciany " + mapa[i] + " odwiedzono " + odwiedzono[i]);
  }*/
 // System.out.println("id= " + indeks);
}
private void goForward()
{
  goF++;
  goRL=0;
  mU=0;
  W=1;
}
private void goForwardErr()
{
  goF=goF+10;
  goRL=0;
  mU=0;
  W=0.2;
}
private void goRight(int kier)
{
  System.out.println("Skręcam w prawo");
 // sprawdzaj = 0;  
  goRL++;
  mU=1.1;
  W=0;
  if (kier==NORTH)
  {
    kierunek = EAST; 
  }
  else if (kier==SOUTH)
  {
    kierunek = WEST; 
  }
  else if (kier==WEST)
  {
    kierunek = NORTH; 
  }
  else if (kier==EAST)
  {
    kierunek = SOUTH; 
  }
}
private void goLeft(int kier)
{
  System.out.println("Skręcam w lewo");
 // sprawdzaj = 0;  
  goRL++;
  mU=-1.1;
  W=0;
  if (kier==NORTH)
  {
    kierunek = WEST; 
  }
  else if (kier==SOUTH)
  {
    kierunek = EAST; 
  }
  else if (kier==WEST)
  {
    kierunek = SOUTH; 
  }
  else if (kier==EAST)
  {
    kierunek = NORTH; 
  }
}
private void Stop()
{
  goF=0;
  goRL=0;
  mU=0;
  W=0;
}
private void goBack(int kier)
{
  System.out.println("Wracam");
//  sprawdzaj = 0;  
  goRL++;
  mU=2.2;
  W=0;
  if (kier==NORTH)
  {
    kierunek = SOUTH; 
  }
  else if (kier==SOUTH)
  {
    kierunek = NORTH; 
  }
  else if (kier==WEST)
  {
    kierunek = EAST; 
  }
  else if (kier==EAST)
  {
    kierunek = WEST; 
  }
}

int updateId(int id, int kier)
{
  int ide=id;
  switch(kier)
  {
    case NORTH:
      ide = id -liczba_kolumn;
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
    System.out.println("id= " + ide);
  if (ide<10 || ide > 52 || ide%11==10 || ide%11==9)
  {
    return 0;
  }
  else
  {
    return ide;
  }
}


/*private void dodaj_sciane(int id, int kier)
{
  //mapa[indeks] = mapa[indeks] + kierunek;
  /* if (mapa[id]<=0 || mapa[id]>15)
   {
   mapa[id]=0;
   }  */
/*  int inde=id;
  mapa[id] = mapa[id] | kier;
  if ( kier == NORTH ) {
    if (id + liczba_kolumn<liczba_rzedow*liczba_kolumn)
    {
      id = inde + liczba_kolumn;
      mapa[id] = mapa[id] | SOUTH;
    }
    // kierunek=kierunek-NORTH;
  }
  if ( kier == EAST ) {
    if (id + 1<liczba_rzedow*liczba_kolumn)
    {
      id = inde + 1;
      mapa[id] = mapa[id] | WEST;
    }
    //    kierunek=kierunek-EAST;
  }
  if ( kier == SOUTH ) {
    if (id - liczba_kolumn>0)
    {
      id = inde - liczba_kolumn ;
      mapa[id]= mapa[id] | NORTH;
    }
    // kierunek=kierunek-SOUTH;
  }
  if ( kier == WEST ) {
    if (id - 1>0)
    {
      id = inde - 1;
      mapa[id] = mapa[id] | EAST;
    }
  }
  // System.out.println("wsp " + inde + " sciany " + mapa[inde]);
}*/
