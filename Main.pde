Robot bot;
Maze maze;
boolean manual;
float WALL_WIDTH;
float CELL_SIZE;
float R_LENG;

PVector joystick_pos, joystick_ipos;
int jrad;
boolean jpressed;

void setup()
{
  size(600,1000);
  rectMode(CENTER);
  
  joystick_pos = new PVector(width/2, height - 50);
  joystick_ipos = new PVector(width/2, height - 50);
  jpressed = false;
  jrad = 50;
  
  CELL_SIZE = width/10;
  WALL_WIDTH = 5;
  R_LENG = width/16;
  
  maze = new Maze(50, 50, 500, 800);
  bot = new Robot(new PVector(50+CELL_SIZE, 50+CELL_SIZE));
  manual = true;
}

void draw()
{
  background(120);

  bot.show();
  maze.show();
  showInterface();

  if (!manual)
    controls();
  else 
    man_controls();
}

void mousePressed()
{
  if (manual)
  {
    if(dist(mouseX, mouseY, joystick_ipos.x, joystick_ipos.y) < jrad)
      jpressed = true;
    
    if(dist(mouseX, mouseY, joystick_ipos.x, joystick_ipos.y) > (jrad << 1))
    {
        jpressed = false;
        joystick_pos.set(joystick_ipos);
    }
  }
}

void mouseReleased()
{
  if(mouseX > width - 160 && mouseY > height - 120)
    manual = !manual;
    
  if(mouseX > width - 100 && mouseY < 100)
    resetAll();
    
  jpressed = false;
  joystick_pos.set(joystick_ipos);
}

void showInterface()
{
  pushStyle();
  fill(0);
  rect(width/2, height-70, width, 140);
  
  rect(width-50,50,100,100);
 
  fill(30);
  rect(width-80,height-60,160,120);
  fill(255);
  textAlign(CENTER, CENTER);
  if(manual)
    text("MANUAL",width-80,height-60,160,120);
  else 
    text("AUTOMATIC", width-80,height-60,160,120);
    
  text("RESET", width-50, 50, 100, 100);
   
  fill(255);
  text(" *front: " + bot.getFRONT_SENSOR(), 30, height - 110);
  text(" *left: " + bot.getLEFT_SENSOR(), 30, height - 80);
  text(" *back: " + bot.getREAR_SENSOR(), 30, height - 50);
  text(" *right: " + bot.getRIGHT_SENSOR(), 30, height - 20);
  text(" : alpha : = " + bot.alpha, 160, height - 110);
  popStyle();
  
  if(manual)
  {
     fill(120);
     ellipse(joystick_ipos.x, joystick_ipos.y, jrad << 1, jrad << 1);
     fill(60);
     ellipse(joystick_pos.x, joystick_pos.y, jrad, jrad);
  }
}

void man_controls()
{        
  float mag = joystick_pos.dist(joystick_ipos);
  float diffy = joystick_pos.y - joystick_ipos.y;
  float diffx = joystick_pos.x - joystick_ipos.x;
  float ang = atan(diffy/diffx);
  if(ang < 0)
    ang += TWO_PI;
    
  mag = map(mag, 0, jrad, 0, 5);
  
  if(jpressed)
  {
    joystick_pos.x = mouseX;
    joystick_pos.y = mouseY;
    if(dist(mouseX, mouseY, joystick_ipos.x, joystick_ipos.y) > jrad)
    {
       float phi = atan2((mouseY - joystick_ipos.y), mouseX - joystick_ipos.x);
       joystick_pos.x = joystick_ipos.x + jrad*cos(phi);
       joystick_pos.y = joystick_ipos.y + jrad*sin(phi);
    }
  }
  float ss, off;
  float uL = 0, uR = 0;
  int i = 0;
  
  while(ang > i*PI/3)
  {  
    i++;
  }
  
  switch(i)
  {
    case 1:
       off = map(mag, 0, 5, 0, 1);
       ss = map(ang, PI/3, 2*PI/3, 0, 3);
       uL = -ss - off;
       uR = -ss + off;
    break;
    
    case 2:
       uL = -mag;
       uR = -mag;    
    break;
    
    case 3:
       off = map(mag, 0, 5, 0, 1);
       ss = map(ang, 2*PI/3, PI, 0, 3);
       uL = -ss + off;
       uR = -ss - off;
    break;
    
    case 4:
       off = map(mag, 0, 5, 0, 1);
       ss = map(ang, PI, 4*PI/3, 0, 3);
       uL = ss - off;
       uR = ss + off;
    break;
    
    case 5:
      uL = mag;
      uR = mag;
    break;
    
    case 6:
       off = map(mag, 0, 5, 0, 1);
       ss = map(ang, 5*PI/3, TWO_PI, 0, 3);
       uL = ss + off;
       uR = ss - off;
    break;
    
    default:
    break;
    
  }
  
  bot.writeLEFT(uL);
  bot.writeRIGHT(uR);
}

void resetAll()
{
  maze = new Maze(50, 50, 500, 800);
  bot = new Robot(new PVector(50+CELL_SIZE, 50+CELL_SIZE));
  manual = true;
  joystick_pos = new PVector(width/2, height - 50);
}
