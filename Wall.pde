class Wall
{
  PVector p;
  float leng, widt;
  float maxx, maxy, minx ,miny;
  
  Wall(float x, float y, float lengi, float widti)
  {
    p = new PVector(x,y);
    leng = lengi;
    widt = widti;
    maxx = p.x + leng/2;
    maxy = p.y + widt/2;
    minx = p.x - leng/2;
    miny = p.y - widt/2; 
  }
  
  public boolean inside(PVector pt)
  { 
    return (pt.x > minx && pt.x < maxx && pt.y < maxy && pt.y > miny);
  }
 
  public void show()
  {
    pushMatrix();
    translate(this.p.x, this.p.y);
    fill(0);
    rect(0,0,this.leng, this.widt);
    popMatrix();
  }
  
  
}