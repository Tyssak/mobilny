// --------- ZMIENNE DO WIFI ---------
import processing.net.*;
Client c;
String input;
int []data_in;

// ---------- STAŁE DO ODTWARZANIA --------
final float cm = 1;         // ile pixeli to 1 cm 
final float dt = 0.05; 
final int FRAMEINT = 10;    // co ile klatek odbieramy dane
final float WHEEL_R = 3.31; // [cm] promien kola

// --------- INNE ZMIENNE -----------
int offx, offy, off_c;
boolean manual, screen_lock, wifi;

byte out, dir, out_dir;

// ------- DANE ROBOTA ----------
PVector b_pos, b_vel;
float dCr, dCl, dXr, dXl, dX, distF, distR, distL;
float b_ang, b_width;
int b_data_size;
int []b_data;

// ----------- DANE LABIRYNTU --------
ArrayList <PVector> wall_pts;
float wall_w;

// ------- INICJALIZACJA ---------
void setup()
{
   size(400, 600);
   frameRate(60);
   rectMode(CENTER);
   
   offx = width/5;
   offy = height/8;
   off_c = 2*offy/3;
   
   b_pos = new PVector(0,0);
   b_vel = new PVector(0,0);
   b_ang = 0;
   b_width = 13*cm;
   dCr = 0;
   dCl = 0;
   dXr = 0;
   dXl = 0;
   dX = 0;
   distF = 0;
   distR = 0;
   distL = 0;

   wifi = true; 
   manual = true;
   screen_lock = false;
   
   out = 0;
   out_dir = 0;
   dir = 0;
   
   // information about robot
   b_data_size = 8;
   b_data = new int[b_data_size];
   for(int i = 0; i < b_data_size; i++)
     b_data[i] = 0;

   // walls
   wall_pts = new ArrayList<PVector>();
   wall_w = 3*cm;
   
   // connect to server in wifi mode 
   if(wifi)
   {
     c = new Client(this, "192.168.4.1", 80); // Replace with your server's IP and port
     c.write("GET jajo HTTP/1.0\r\n"); 
   }  
}

// ---------- PĘTLA GŁÓWNA ----------
void draw()
{
  background(240);
  
  // ---- ODBIERANIE DANYCH ----
  if (wifi && (frameCount % FRAMEINT == 0)) 
  {
    getData();
    sendData(); 

    // ---- UPDATE BOTA ----
    movBot();
  }
 
  // ---- RYSOWANIE ----
  drawBot();
  drawMaze();
  drawInterface();
}

void mouseReleased()
{
  if(mouseX > width - offx && mouseY > 5*offy + offy/2 && mouseY < 6*offy && wifi)
  {
    dataMemory = "GET /?dir=" + str(byte(11)) + " HTTP/1.0 \r\n";
    c = new Client(this, "192.168.4.1", 80); // Connect to server on port 80
    c.write(dataMemory);
  }
  
  if(mouseX > width - offx && mouseY > 6*offy && mouseY < 5*offy + 3*offy/2 && wifi)
  {
     dataMemory = "GET /?dir=" + str(byte(10)) + " HTTP/1.0 \r\n";
     c = new Client(this, "192.168.4.1", 80); // Connect to server on port 80
     c.write(dataMemory);
  }
    
  if(mouseX > width - offx && mouseY > 5*offy + 3*offy/2 && mouseY < 7*offy)
    screen_lock = !screen_lock;
   
  if(mouseX > width - 2*offx && mouseY > 7*offy && wifi)
  {
    manual = !manual;
    dataMemory = "GET /?dir=" + str(byte(9)) + " HTTP/1.0 \r\n";
    c = new Client(this, "192.168.4.1", 80); // Connect to server on port 80
    c.write(dataMemory);
  }
  
   if(manual)
   for(int r = 0; r < 3; r++)
      for(int c = 0; c < 3; c++)
        if(dist(mouseX,mouseY,offx+c*off_c , height - 2*offy + r*off_c ) < off_c/2)
        {
          switch(r*3 + c)
          {
            case 4:
              out_dir = 0;
            break;
        
            case 1:
              out_dir = 1;
              break;
              
            case 0: 
              out_dir = 2;
              break;
              
           case 2: 
              out_dir = 3;
              break;
              
           case 3: 
              out_dir = 4;
              break;
              
           case 5: 
              out_dir = 5;
              break;
              
           case 7: 
              out_dir = 6;
              break;
              
           case 6: 
              out_dir = 7;
              break;
              
           case 8: 
              out_dir = 8;
              break;
              
           default: //----
             out_dir = 0;
              break;
          }
       } 
}

void sendData()
{
  dataMemory = "GET /?dir=" + str(out_dir) + " HTTP/1.0 \r\n";
  c = new Client(this, "192.168.4.1", 80); // Connect to server on port 80
  c.write(dataMemory);
  c.write("\r\n"); // Use the HTTP "GET" command to ask for a Web page
}

void getData()
{
  String[] input_lines = loadStrings("http://192.168.4.1");
  data_in = int(split(input_lines[0], ','));
  for(int i = 0; i < data_in.length; i++)
    b_data[i] = data_in[i];
}
