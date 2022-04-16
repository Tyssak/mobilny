class Cell
{
  private int x, y;
  private boolean wallsON[] = {true, true ,true, true};
  private Wall walls[] = new Wall[4];
  private boolean visited;
  
  Cell(int xi, int yi)
  {
    x = xi;
    y = yi;
    visited = false;
    walls[0] = new Wall(x+CELL_SIZE/2, y, WALL_WIDTH, CELL_SIZE);
    walls[1] = new Wall(x, y+CELL_SIZE/2, CELL_SIZE, WALL_WIDTH);
    walls[2] = new Wall(x-CELL_SIZE/2, y, WALL_WIDTH, CELL_SIZE);
    walls[3] = new Wall(x, y-CELL_SIZE/2, CELL_SIZE, WALL_WIDTH);
  }
  
  public void removeWall(int i)
  {
    if(i < 4)
      this.wallsON[i] = false;
  }
  
  public void visit()
  {
    this.visited = true;
  }
  
  public boolean isVisited()
  {
    return this.visited;
  }
  
  public boolean inside(PVector pt)
  { 
    for(int i = 0; i < 4; i++)
      if(this.wallsON[i] && this.walls[i].inside(pt))
        return true;
     
     return false;
  }
  
  public void show()
  {
    for(int i = 0; i < 4; i++)
      if(this.wallsON[i])
        this.walls[i].show();
  }
}
