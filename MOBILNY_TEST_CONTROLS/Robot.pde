void movBot()
{
  b_vel = new PVector(1, 0);
  
  dCr = b_data[6];
  dCl = b_data[7];
  dXr = 0;
  dXl = 0;
  dX = 0;
  distF = b_data[1];
  distR = b_data[2];
  distL = b_data[3];

  switch(dir)
  {
      case 0:   
      case 1:
      case 2:
      case 3:
        dXr = WHEEL_R*PI*dCr/10; // dx = (2*(dC/20)*π*R)
        dXl = WHEEL_R*PI*dCl/10;
        break;

      case 4:
        dXr = WHEEL_R*PI*dCr/10;
        dXl = -1*WHEEL_R*PI*dCl/10;
        break;
      case 5:
        dXr = -1*WHEEL_R*PI*dCr/10;
        dXl = WHEEL_R*PI*dCl/10;
        break;

      case 6:
      case 7:
      case 8:
        dXr = -1*WHEEL_R*PI*dCr/10;
        dXl = -1*WHEEL_R*PI*dCl/10;
        break;  
   
      default:
        break; 
  } 
    b_ang += (dXl - dXr)/b_width;
    b_vel.setMag((dXl+dXr)/2.0);
    b_vel.rotate(b_ang);
    b_pos.add(b_vel);

    if(distF > 0)
      wall_pts.add(new PVector(b_pos.x + distF*cos(b_ang), b_pos.y+distF*sin(b_ang)));
    
    if(distL > 0)
      wall_pts.add(new PVector(b_pos.x + distL*cos(b_ang - PI/2), b_pos.y+distL*sin(b_ang - PI/2)));
   
    if(distR > 0)
      wall_pts.add(new PVector(b_pos.x + distR*cos(b_ang + PI/2), b_pos.y+distR*sin(b_ang + PI/2)));
  
}
