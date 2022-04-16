class Maze
{
  public Cell cells[];
  private int rows, cols, num_of_cells;
  
  Maze(int xinit, int yinit, int wid, int hei)
  {
    this.rows = floor(hei/CELL_SIZE);
    this.cols = floor(wid/CELL_SIZE);
    this.num_of_cells = cols*rows;
    
    this.cells = new Cell[this.num_of_cells];
     
    for(int y = 0; y < this.rows; y++)
      for(int x = 0; x < this.cols; x++)
        this.cells[y*this.cols + x] = new Cell(floor(xinit + CELL_SIZE*x), floor(yinit + CELL_SIZE*y)); 
    
    int current = 0;
    IntList stack = new IntList();
    
    do
    {
      int next = checkNeighbours(int(current%this.cols), int(current/this.cols));
      
      if(next != -1 && !cells[next].isVisited())
      {
        stack.append(current);
        cells[next].visit();
        this.removeWalls(current, next);
        current = next; 
      } 
      else if(stack.size() != 0)
      {
        current = stack.get(stack.size()-1); 
        stack.remove(stack.size()-1);   
      }  
    } while(stack.size() > 0);
    
    if(random(2) > 1)
      cells[(cols-1) + int(random(rows-1))*cols].removeWall(0);
    else
      cells[(rows-1)*cols + int(random(cols-1))].removeWall(1);
  }
  
  private void removeWalls(int cur, int nxt)
  {
    int diff = cur - nxt;
   
    if(diff == -1)
    {
       cells[cur].removeWall(0);
       cells[nxt].removeWall(2);     
    }
    else if(diff == 1)
    {
      cells[cur].removeWall(2);
      cells[nxt].removeWall(0);          
    }
    else if(diff > 0)
    {
      cells[cur].removeWall(3);
      cells[nxt].removeWall(1);     
    }
    else if(diff < 0)
    {
      cells[cur].removeWall(1);
      cells[nxt].removeWall(3);     
    }
  }
 
  private int checkNeighbours(int x, int y)
  {
    IntList buf = new IntList();
    
    buf.append(index(x, y-1));
    buf.append(index(x+1, y));
    buf.append(index(x, y+1));
    buf.append(index(x-1, y));
    
    for (int i = 3; i >= 0; i--)
      if(buf.get(i) < 0 || cells[buf.get(i)].visited)
        buf.remove(i);
    
    if(buf.size() > 0)
       return buf.get(int(random(0, buf.size())));
    else 
       return -1;
  }
  
  private int index(int x, int y)
  {
    if(x < 0 || y < 0 || x > cols-1 || y > rows-1)
      return -1;
    else
      return y*this.cols + x;
  }
  
  public int getCellsNum()
  {
    return this.num_of_cells;
  }
  
  public void show()
  { 
    fill(0);
    for(int i = 0; i < this.num_of_cells; i++)
        this.cells[i].show();
  }
  
}
