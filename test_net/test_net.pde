import processing.net.*;

Client c;
String input;
int data[];
String dataMemory = "";
int dir = 0;
char [] keys = {'0', '0', '0', '0'};
int []botdata = new int[4];

// bot and drawing
final float cm = 1;  //ile pixeli to 1 cm 
final float dt = 0.05;
PVector bpos, bvel;
float bang;


void setup() 
{
  size(400, 400);
  frameRate(60); 
  
  // drawing stuff
  rectMode(CENTER);
  bpos = new PVector(width/2, height/2);
  bvel = new PVector(0,0);
  bang = -PI/2;
  
  // Connect to the server's IP address and port
  c = new Client(this, "192.168.4.1", 80); // Replace with your server's IP and port
  c.write("GET /Processing sketch connected. HTTP/1.0\r\n"); 
}

void draw() 
{
  background(240);
  
  
  checkDir();
  drawBot();
  
  if (c.active() && (frameCount % 2 == 0)) 
    sendData();

  if (c.available() > 0) 
  {
    input = c.readStringUntil('\n');   // tu jakieś readUntilByte czy cos wstawic
    botdata = int(split(input, ','));
    //println(botdata);  
  }
}

void keyPressed()
{ 
  if (key == 'W' || key == 'w')
    keys[3] = '1';

  if (key == 'A' || key == 'a')
    keys[2] = '1';

  if (key == 'D' || key == 'd')
    keys[1] = '1';

  if (key == 'S' || key == 's')
    keys[0] = '1';
}

void keyReleased()
{
  if (key == 'W' || key == 'w')
    keys[3] = '0';

  if (key == 'A' || key == 'a')
    keys[2] = '0';

  if (key == 'D' || key == 'd')
    keys[1] = '0';

  if (key == 'S' || key == 's')
    keys[0] = '0';
}

void sendData()
{
  dataMemory = "GET /?dir=" + str(dir) + " HTTP/1.0 \r\n";
  c = new Client(this, "192.168.4.1", 80); // Connect to server on port 80
  c.write(dataMemory);
  c.write("\r\n"); // Use the HTTP "GET" command to ask for a Web page
  dataMemory = "";
}

void checkDir()
{
   switch(new String(keys))
    {
      case "0000":
        dir = 0;
        break;
        
      case "0001":
        dir = 1;
        break;
        
      case "0011":
        dir = 2;
        break;
        
     case "0101":
        dir = 3;
        break;
        
     case "0010":
        dir = 4;
        break;
        
     case "0100":
        dir = 5;
        break;
        
     case "1000":
        dir = 6;
        break;
        
     case "1010":
        dir = 7;
        break;
        
     case "1100":
        dir = 8;
        break;
        
     default:
       dir = 0;
        break;
    }   
}

void movBot()
{
  bvel = new PVector(0, 1);
  bvel.setMag(2*dt);
  bvel.rotate(bang);
  float da = 0.1;
  
  switch(dir)
  {
      case 0:
        break;
        
      case 1:
        bpos.add(bvel);
        break;
      case 2:
        bpos.add(bvel);
        bang += da;
        break;
      case 3:
        bpos.add(bvel);
        break;
      case 4:
        bpos.add(bvel);
        bang += da;
        break;
      case 5:
        bpos.add(bvel);
        break;
      case 6:
        bpos.add(bvel);
        bang += da;
        break;
      case 7:
        bpos.add(bvel);
        break;
      case 8:
        bpos.add(bvel);
        bang += da;
        break;
        
      default:
        break; 
  } 
}

void drawBot()
{
  pushMatrix();
  translate(bpos.x, bpos.y);
  rotate(bang);
  noStroke();
  fill(160);
  rect(-2*cm, 0, 22*cm, 10*cm);
  rect( 7.5*cm, 0, 3*cm,  16*cm);
  fill(40);
  rect(0,  6.5*cm, 6.5*cm, 3*cm);
  rect(0, -6.5*cm, 6.5*cm, 3*cm);
  popMatrix();
  
  fill(0);
  textAlign(CENTER, CENTER);
  text("Dir : " + str(botdata[0]), width - 50, height - 90, 100, 60);
  //text("DF  : " + str(botdata[1]), width - 50, height - 30, 100, 60);
}
