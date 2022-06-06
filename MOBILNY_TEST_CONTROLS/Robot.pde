void movBot()
{
  b_vel.set(1,0);
  
  dCr = b_data[4] - pCr;
  dCl = b_data[5] - pCl;
  
  pCr = b_data[4];
  pCl = b_data[5];
  
  dXr = 0;
  dXl = 0;
  dX = 0;
  
  pdistF = distF;
  pdistR = distR;
  pdistL = distL;
  
  distF = b_data[1];
  distR = b_data[2];
  distL = b_data[3];
  
  dir = byte(b_data[0]);

  switch(dir)
  {
      case 20:   
      case 1:
      case 2:
      case 3:
        dXr = WHEEL_R*PI*float(dCr/10); // dx = (2*(dC/20)*π*R)
        dXl = WHEEL_R*PI*float(dCl/10);
        break;

      case 4:
        dXr = WHEEL_R*PI*float(dCr)/10.0;
        dXl = -1*WHEEL_R*PI*float(dCl)/10.0;
        break;
      case 5:
        dXr = -1*WHEEL_R*PI*float(dCr)/10.0;
        dXl = WHEEL_R*PI*float(dCl)/10.0;
        break;

      case 6:
      case 7:
      case 8:
        dXr = -1*WHEEL_R*PI*float(dCr)/10.0;
        dXl = -1*WHEEL_R*PI*float(dCl)/10.0;
        break;  
   
      default:
        break; 
  } 
  
    b_ang += (dXl - dXr)/b_width;
    b_vel.setMag((dXl+dXr)/2.0);
    b_vel.rotate(b_ang);
    b_pos.add(b_vel);

    if(distF > 5 && ( dir != 0 || abs(distF - pdistF) > 2))
      wall_pts.add(new PVector(b_pos.x + (distF+3)*cos(b_ang), b_pos.y+(distF+3)*sin(b_ang)));
    
    if(distL > 7 && ( dir != 0 || abs(distL - pdistL) > 2))
      wall_pts.add(new PVector(b_pos.x + (distL+6)*cos(b_ang - PI/2), b_pos.y+(distL+6)*sin(b_ang - PI/2)));
   
    if(distR > 7 && ( dir != 0 || abs(distR - pdistR) > 2))
      wall_pts.add(new PVector(b_pos.x + (distR+6)*cos(b_ang + PI/2), b_pos.y+(distR+6)*sin(b_ang + PI/2)));
}
