Robot bot;
Maze maze;
boolean manual, vertical;
int WALL_WIDTH, CELL_SIZE, R_LENG;

void setup()
{
  fullScreen();
  if(displayHeight > displayWidth) 
    vertical = true;
  else 
    vertical = false;
    
  rectMode(CENTER);
 
  if(!vertical)
  {
      CELL_SIZE = width/10;
      R_LENG = width/16;
  }
  else
  {
    CELL_SIZE = height/17;
    R_LENG = height/27;
  }
    
  WALL_WIDTH = 5;
 
  maze = new Maze(CELL_SIZE, CELL_SIZE, width - CELL_SIZE, 4*height/5);
  bot = new Robot(new PVector(2*CELL_SIZE, 2*CELL_SIZE));
  manual = false;
}

void draw()
{
  background(120);
  bot.show();
  maze.show();
  showInterface();
  controls();
}

void mouseReleased()
{ 
  if(mouseX < height/8 && mouseY > height - height/8)
    resetAll();
}

void showInterface()
{
  pushStyle();
  fill(120);
  rect(width/2, height - height/16, width, height/8);
  
  fill(60);
  
  if(mousePressed && mouseX < height/8 && mouseY > height - height/8)
     strokeWeight(3);
  else 
     strokeWeight(1);
     
  rect(height/16, height - height/16, height/8, height/8);
  
  if(mousePressed && mouseX > width - height/8 && mouseY > height - height/8)
     strokeWeight(3);
  else 
     strokeWeight(1);
  
  rect(width - height/16, height - height/16, height/8, height/8);
  
  fill(255);
  textAlign(CENTER, CENTER);
  
  if(manual)
    text("MANUAL",width - height/16, height- height/16, height/8, height/8);
  else 
    text("AUTOMATIC", width - height/16, height-height/16, height/8, height/8);
   
  text("RESET", height/16, height - height/16, height/8, height/8);
   
  fill(255);
  text(" Sensor data: ", 2*width/5, height - 6*height/64);
  text(" * front = " + bot.getFRONT_SENSOR(), 2*width/5, height - 5*height/64);
  text(" * left  = " + bot.getLEFT_SENSOR(), 2*width/5, height - 4*height/64);
  text(" * back  = " + bot.getREAR_SENSOR(), 2*width/5, height - 3*height/64);
  text(" * right = " + bot.getRIGHT_SENSOR(), 2*width/5, height - 2*height/64);
  popStyle();
}

void resetAll()
{
  maze = new Maze(CELL_SIZE, CELL_SIZE, width - CELL_SIZE, 4*height/5);
  bot = new Robot(new PVector(2*CELL_SIZE, 2*CELL_SIZE));
  manual = false;
}
