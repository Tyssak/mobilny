void drawBot()
{
  pushMatrix();
  
  if(screen_lock)
    translate(2*offx-b_pos.x, 3.5*offy-b_pos.y);
  else
    translate(2*offx, 3.5*offy);
    
  pushMatrix();
  translate(b_pos.x, b_pos.y);
  rotate(b_ang);
  noStroke();
  fill(160);
  rect(-2*cm, 0, 22*cm, 10*cm);
  rect( 7.5*cm, 0, 3*cm,  16*cm);
  fill(40);
  rect(0,  6.5*cm, 6.5*cm, 3*cm);
  rect(0, -6.5*cm, 6.5*cm, 3*cm);
  popMatrix(); 
  popMatrix();
}

void drawMaze()
{
  pushMatrix();
  
  if(screen_lock)
    translate(2*offx-b_pos.x, 3.5*offy-b_pos.y);
  else
    translate(2*offx, 3.5*offy);
    
  pushStyle();
  fill(80);
  stroke(0);
  for(int i = wall_pts.size()-1; i >= 0; i--)
    rect(wall_pts.get(i).x, wall_pts.get(i).y, wall_w, wall_w);
  popStyle();
  popMatrix();
}

void drawInterface()
{
  pushStyle();
  noFill();
  strokeWeight(3);
  stroke(0);
  rect(2*offx, 3.5*offy, 4*offx, 7*offy);

  fill(200);
  rect(width - offx/2, 4*offy, offx, 8*offy);
  
  fill(140);
  if(mousePressed  && mouseX > width - offx && mouseY > 5*offy + offy/2 && mouseY < 6*offy)
    strokeWeight(3);
  else
    strokeWeight(1);
    
  rect(width - offx/2, 5*offy + 3*offy/4, offx, offy/2);
  
  if(mousePressed && mouseX > width - offx && mouseY > 6*offy && mouseY < 5*offy + 3*offy/2)
    strokeWeight(3);
  else
    strokeWeight(1);
    
  rect(width - offx/2, 5*offy + 5*offy/4, offx, offy/2);
  
  if(screen_lock)
    fill(220,0,0);
  else
    fill(140);
 
  if(mousePressed && mouseX > width - offx && mouseY > 5*offy + 3*offy/2 && mouseY < 7*offy)
     strokeWeight(3);
  else
    strokeWeight(1);
    
  rect(width - offx/2, 5*offy + 7*offy/4, offx, offy/2);
  strokeWeight(1);
  
  fill(200);
  rect(2.5*offx, 7.5*offy, 5*offx, offy);
  
  fill(140);
  rect(width-offx, 7.5*offy, 2*offx, offy);
  
  if(!manual)
  {
    fill(255,0,0);
    strokeWeight(6);
  }
  else
  {
    fill(140);
    strokeWeight(1);
  }
  
  quad(width, height, width, height - offy, 
    width - 0.8*offx, height - offy, width - 1.8*offx, height);
  
  if(manual)
  {
    fill(255,0,0);
    strokeWeight(6);
  }
  else
  {
    fill(140);
    strokeWeight(1);
  }
  
  quad(width - 2*offx, height, width - 1.2*offx, height, 
    width - 0.8*offx, height - offy, width - 2*offx, height - offy);
  
  strokeWeight(1);
  fill(0);
  
  textAlign(CENTER,CENTER);
  textSize(offy/3);
  text("MAN  AUTO", width-offx, 7.5*offy, 2*offx, offy);
  
  textSize(offy/5);
  text("RESET", width - offx/2, 5*offy + 3*offy/4, offx, offy/2);
  text("FIND", width - offx/2, 5*offy + 5*offy/4, offx, offy/2);
  text("LOCK", width - offx/2, 5*offy + 7*offy/4, offx, offy/2);
  textAlign(LEFT, CENTER);
 
  text("--Data--", width - offx/2, offy/4, offx, offy/2);
  text("-dir : " + str(b_data[0]), width - offx/2, 3*offy/4, offx, offy/2);
  text("-diF : " + str(b_data[1]), width - offx/2, 5*offy/4, offx, offy/2);
  text("-diR : " + str(b_data[2]), width - offx/2, 7*offy/4, offx, offy/2);
  text("-diL : " + str(b_data[3]), width - offx/2, 9*offy/4, offx, offy/2);
  text("-cR  : " + str(b_data[4]), width - offx/2, 11*offy/4, offx, offy/2);
  text("-cL  : " + str(b_data[5]), width - offx/2, 13*offy/4, offx, offy/2);
  text("-dcL : " + str(b_data[6]), width - offx/2, 15*offy/4, offx, offy/2);
  text("-dcR : " + str(b_data[7]), width - offx/2, 17*offy/4, offx, offy/2);
  text("--------", width - offx/2, 19*offy/4, offx, offy/2);

  if(manual)
  {
    fill(60);
    ellipse(offx+off_c ,height - 2*offy + off_c, 2.5*offy, 2.5*offy);
    fill(120);
    for(int r = 0; r < 3; r++)
      for(int c = 0; c < 3; c++)
      {
        if(dist(mouseX,mouseY,offx+c*off_c , height - 2*offy + r*off_c ) < off_c/2)
          strokeWeight(3);
        else
          strokeWeight(1);
        
        ellipse(offx+c*off_c , height - 2*offy + r*off_c, off_c ,off_c);
      }
      
     strokeWeight(1);
     fill(0,0,255);
     triangle(offx+1*off_c , height - 2*offy + 0*off_c - off_c/2, 
     offx+1*off_c - off_c/3 , height - 2*offy + 0*off_c + off_c/3,
     offx+1*off_c + off_c/3, height - 2*offy + 0*off_c + off_c/3);
     
     triangle(offx+off_c , height - 2*offy + 2*off_c + off_c/2, 
     offx+off_c - off_c/3, height - 2*offy + 2*off_c - off_c/3,
     offx+off_c + off_c/3, height - 2*offy + 2*off_c - off_c/3);
     
     triangle(offx - off_c/2, height - 2*offy + off_c, 
     offx + off_c/3, height - 2*offy + off_c - off_c/3,
     offx + off_c/3, height - 2*offy + off_c + off_c/3);
     
     triangle(offx+2*off_c + off_c/2 , height - 2*offy + off_c, 
     offx+2*off_c - off_c/3, height - 2*offy + off_c - off_c/3,
     offx+2*off_c - off_c/3, height - 2*offy + off_c + off_c/3);
     
  } else
  {  
    fill(255,0,0);
    textSize(offy/6);
    textAlign(LEFT, CENTER);
    if(looking)
      text("  ! - MODE: AUTOMATIC\n  ! - STATE: LOOKING", 2*offx, 7.25*offy, 4*offx, offy/2);
    else
      text("  ! - MODE: AUTOMATIC\n  ! - STATE: IDLE", 2*offx, 7.25*offy, 4*offx, offy/2);
  }
  
  popStyle();
}
