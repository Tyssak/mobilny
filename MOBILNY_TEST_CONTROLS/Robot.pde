void checkDir(byte inDir)
{
  if(inDir != dir)
  {
    dir = inDir;
    
   switch(inDir)
    {
      case 0: // 0000 idle
        dir = 0;
        break;
        
      case 1: // 0001 forward
        dir = 1;
        break;
        
      case 3: // 0011 forward-left
        dir = 2;
        break;
        
     case 5: // 0101 forward-right
        dir = 3;
        break;
        
     case 2: // 0010 left
        dir = 4;
        break;
        
     case 4: //0100 right
        dir = 5;
        break;
        
     case 8: //1000 backward
        dir = 6;
        break;
        
     case 10: //1010 backward left
        dir = 7;
        break;
        
     case 12: //1100 backward right
        dir = 8;
        break;
        
     default: //----
       dir = 0;
        break;
    }   
  }
}

void movBot()
{
  b_vel = new PVector(1, 0);
  
  switch(dir)
  {
      case 0:
        b_vR = 0;
        b_vL = 0;
        break;      
      case 1:
        b_vR = 12;
        b_vL = 12;
        break;
      case 2:
        b_vR = 12;
        b_vL = 8;
        break;
      case 3:
        b_vR = 8;
        b_vL = 12;
        break;
      case 4:
        b_vR = 12;
        b_vL = -12;
        break;
      case 5:
        b_vR = -12;
        b_vL = 12;
        break;
      case 6:
        b_vR = -12;
        b_vL = -12;
        break;
      case 7:
        b_vR = -12;
        b_vL = -8;
        break;
      case 8:
        b_vR = -8;
        b_vL = -12;
        break;     
      default:
        break; 
  } 
  
  if(wifi)
  {
    float dt = 0.05;
    b_vel.setMag((b_vL+b_vR)/2);
    b_ang += (b_vL - b_vR)*dt/b_width;
    b_vel.rotate(b_ang);
    b_pos.add(b_vel.x*dt,b_vel.y*dt,b_vel.z*dt);
    wall_pts.add(new PVector(b_pos.x + b_data[1]*cos(b_ang), b_pos.y+b_data[1]*sin(b_ang)));
    wall_pts.add(new PVector(b_pos.x + b_data[2]*cos(b_ang - PI/2), b_pos.y+b_data[2]*sin(b_ang - PI/2)));
    wall_pts.add(new PVector(b_pos.x + b_data[3]*cos(b_ang + PI/2), b_pos.y+b_data[3]*sin(b_ang + PI/2)));
    
  } else
  {
    float dt = 0.05;
    b_vel.setMag((b_vL+b_vR)/2);
    b_ang += (b_vL - b_vR)*dt/b_width;
    b_vel.rotate(b_ang);
    b_pos.add(b_vel.x*dt,b_vel.y*dt,b_vel.z*dt);
    wall_pts.add(new PVector(b_pos.x + (45+random(8)-4)*cos(b_ang + PI/2), b_pos.y+(45+random(8)-4)*sin(b_ang + PI/2)));
    wall_pts.add(new PVector(b_pos.x + (25+random(4)-2)*cos(b_ang - PI/2), b_pos.y+(25+random(2)-2)*sin(b_ang - PI/2)));
    b_data[4]+=b_vR;
    b_data[5]+=b_vL;
  }
}
