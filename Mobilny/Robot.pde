class Robot
{
  private PVector pos, vel, acc;
  private PVector pSensR, pSensL, pSensB, pSensF;
  public float wid, leng, alpha, mass, leftV, rightV;
  private PVector[] maxPts;
  
  // helping variables
  private float offBeta, offGamma, hh, hR, hr, rr, RR;
  
  // state space
  private float x1, x2, x3, x4, x5;
  private float uLEFT, uRIGHT;
  
  // sensors
  private float sFRONT, sBACK, sLEFT, sRIGHT;
  
  
  Robot(PVector init_pos)
  {
    pos = init_pos;
    vel = new PVector(0,0);
    acc = new PVector(0,0);
    
    alpha = 0;
    leng = R_LENG; 
    wid = 3*leng/5;
    mass = 0.2;
    
    hr = leng/2.0-leng/5.0;
    hR = leng - hr;
    hh = wid/2.0;
    offGamma = atan(hr/hh);
    offBeta = atan(hh/hR);
    rr = sqrt(hr*hr + hh*hh);
    RR = sqrt(hh*hh + hR*hR);
    
    pSensR = new PVector(hr, hh);
    pSensL = new PVector(hr, -hh);
    pSensF = new PVector(hR, 0);
    pSensB = new PVector(-hr, 0);
    
    maxPts = new PVector[8];
    
    maxPts[0] = new PVector(this.pos.x + rr*cos(alpha - offGamma), this.pos.y + rr*sin(alpha - offGamma));
    maxPts[1] = new PVector(this.pos.x + rr*cos(alpha + offGamma), this.pos.y + rr*sin(alpha + offGamma));
    maxPts[2] = new PVector(this.pos.x + RR*cos(alpha - offBeta),  this.pos.y + RR*sin(alpha - offBeta));
    maxPts[3] = new PVector(this.pos.x + RR*cos(alpha + offBeta),  this.pos.y + RR*sin(alpha + offBeta));
    maxPts[4] = new PVector(this.pos.x + RR*cos(alpha + offBeta),  this.pos.y + RR*sin(alpha + offBeta));
    maxPts[5] = new PVector(this.pos.x + RR*cos(alpha + offBeta),  this.pos.y + RR*sin(alpha + offBeta));
    maxPts[6] = new PVector(this.pos.x + RR*cos(alpha + offBeta),  this.pos.y + RR*sin(alpha + offBeta));
    maxPts[7] = new PVector(this.pos.x + RR*cos(alpha + offBeta),  this.pos.y + RR*sin(alpha + offBeta));
       
    x1 = 0;
    x2 = 0;
    x3 = 0;
    x4 = 0;
    x5 = 0;
    
    uLEFT = 0;
    uRIGHT = 0;
    
    sLEFT = 0;
    sRIGHT = 0;
    sBACK = 0;
    sFRONT = 0;
  }
  
  private void update()
  {
    // simulation constants
    // --------
    float L = 0.4; //
    float R = 15;
    float m = 4;
    float B = 1300; //F = B*i
    float T = 2;
    float dt = 0.05;
    
    sensors();
    
    x1 += (uLEFT/L - R/L*x1)*dt;
    x2 += (uRIGHT/L - R/L*x2)*dt;
    x3 += (2*B/m * x1 - T*x3)*dt;
    x4 += (2*B/m * x2 - T*x4)*dt;
    x5 += (x4 - x3)*dt/this.wid;
        
    leftV = x3;
    rightV = x4;
    alpha = x5;
    
    vel = new PVector(1,0);
    vel.setMag((leftV + rightV)/2);
    vel.rotate(alpha);
   
    if(!collides(new PVector(pos.x + vel.x*dt, pos.y + vel.y*dt)))
      pos.add(new PVector(vel.x*dt, vel.y*dt));
    else
      vel.set(0,0,0);
      
    acc.set(0,0,0);
 
    uLEFT = 0;
    uRIGHT = 0;
  }
  
  private void sensors()
  {
     PVector baec = new PVector(this.pos.x + this.hR*cos(this.alpha), this.pos.y + this.hR*sin(this.alpha));
     PVector step = new PVector(1,0);
     
     step.rotate(this.alpha);
     
     int count = 0;
     
     while(!wallDetected(baec) && count < 1023)
     {
       baec.add(step);
       count++;
     }
     
     sFRONT = count;
     
     step.rotate(PI/2);
     baec.set(this.pos.x + this.hr*cos(this.alpha+PI/2), this.pos.y + this.hr*sin(this.alpha+PI/2));
     count = 0;
     
     while(!wallDetected(baec) && count < 1023)
     {
       baec.add(step);
       count++;
     }
     
     sRIGHT = count;
     
     step.rotate(PI/2);
     baec.set(this.pos.x + this.hr*cos(this.alpha+PI), this.pos.y + this.hr*sin(this.alpha + PI));
     count = 0;
     
     while(!wallDetected(baec) && count < 1023)
     {
       baec.add(step);
       count++;
     }
     
     sBACK = count;
     
     step.rotate(PI/2);
     baec.set(this.pos.x + this.hr*cos(this.alpha-PI/2), this.pos.y + this.hr*sin(this.alpha-PI/2));
     count = 0;
     
     while(!wallDetected(baec) && count < 1023)
     {
       baec.add(step);
       count++;
     }
     
     sLEFT = count; 
  }
  
  private boolean wallDetected(PVector ps)
  {
    for(int i = 0; i < maze.getCellsNum(); i++)
       if(maze.cells[i].inside(ps))
         return true;
    //color c = get(int(ps.x), int(ps.y));
    //if(red(c) < 5.0 && green(c) < 5.0 && blue(c) < 5.0)
    //   return true;
    
    
    return false;
  }
  
  private boolean collides(PVector nxtPos)
  {
    for(int i = 0; i < maze.getCellsNum(); i++)
    {
      maxPts[0].set(nxtPos.x + rr*cos(alpha - offGamma - PI/2), nxtPos.y + rr*sin(alpha - offGamma - PI/2));
      maxPts[1].set(nxtPos.x + rr*cos(alpha + offGamma + PI/2), nxtPos.y + rr*sin(alpha + offGamma + PI/2));
      maxPts[2].set(nxtPos.x + RR*cos(alpha - offBeta),  nxtPos.y + RR*sin(alpha - offBeta));
      maxPts[3].set(nxtPos.x + RR*cos(alpha + offBeta),  nxtPos.y + RR*sin(alpha + offBeta));
      maxPts[4].set(nxtPos.x + rr*cos(alpha + PI), nxtPos.y + rr*sin(alpha + PI));
      maxPts[5].set(nxtPos.x + RR*cos(alpha), nxtPos.y + RR*sin(alpha));
      maxPts[6].set(nxtPos.x + hh*cos(alpha + PI/2), nxtPos.y + hh*sin(alpha + PI/2));
      maxPts[7].set(nxtPos.x + hh*cos(alpha - PI/2), nxtPos.y + hh*sin(alpha - PI/2));
      
      for(int j = 0; j < 8; j++)
        if(maze.cells[i].inside(maxPts[j]))
           return true;
    }
   
    return false;
  }
  
  public void writeLEFT(float u)
  {
    uLEFT = u;
    this.update();
  }
  
  public void writeRIGHT(float u)
  {
    uRIGHT = u;
    this.update();
  }
  
  public float encLEFT()
  {
    return this.leftV;
  }
  
  public float encRIGHT()
  {
    return this.rightV;
  }
  
  public float getLEFT_SENSOR()
  {
    return sLEFT;
  }
  
  public float getRIGHT_SENSOR()
  {
    return sRIGHT;
  }
  
  public float getFRONT_SENSOR()
  {
    return sFRONT;
  }
  
  public float getREAR_SENSOR()
  {
    return sBACK;
  }
  
  public void show()
  {
    if(uLEFT == 0 && uRIGHT == 0)
      this.update();
    
    pushMatrix();
    pushStyle();
    translate(this.pos.x, this.pos.y);
    rotate(this.alpha);
    fill(180);
    rect(this.leng/5,0,this.leng, this.wid);
    fill(255,0,0);
    rect(0, this.hh + this.wid/10, this.hr, this.wid/5);
    rect(0, -this.hh - this.wid/10, this.hr, this.wid/5);
    
    fill(0,0,255);
    pushMatrix();
    translate(pSensR.x, pSensR.y);
    ellipse(this.wid/10, this.wid/10, this.leng/10, this.leng/10);
    line(0,0, this.sRIGHT*cos(HALF_PI), this.sRIGHT*sin(HALF_PI));
    popMatrix();
    
    pushMatrix();
    translate(pSensL.x, pSensL.y);
    ellipse(this.wid/10, this.wid/10, this.leng/10, this.leng/10);
    line(0,0, this.sLEFT*cos(-HALF_PI), this.sLEFT*sin(-HALF_PI));
    popMatrix();
    
    pushMatrix();
    translate(pSensF.x, pSensF.y);
    ellipse(this.wid/10, this.wid/10, this.leng/10, this.leng/10);
    line(0,0, this.sFRONT*cos(0), this.sFRONT*sin(0));
    popMatrix();
    
    pushMatrix();
    translate(pSensB.x, pSensB.y);
    ellipse(this.wid/10, this.wid/10, this.leng/10, this.leng/10);
     line(0,0, this.sBACK*cos(PI), this.sBACK*sin(PI));
    popMatrix();
    
    popMatrix();
    popStyle();
  }
}
