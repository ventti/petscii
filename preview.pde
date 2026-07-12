public class PreviewWindow extends PApplet //<>// //<>//
{
  int x,y, scale;
  boolean vis;
  
  PreviewWindow(int xchars,int ychars)
  {
      scale=1;
      x=xchars;
      y=ychars;
      String[] a=new String[] {this.getClass().getName()};
      PApplet.runSketch(a, this);
      pWin = (PSurfaceAWT)surface;
      pWin.setTitle("1x1 Pixel CSDb Preview");
      vis = false;
      pWin.setVisible(vis);
      
  }
  public void settings()
  {
      int xdim=x*cset.xsize+prefs.PREBORDER_X*2;
      int ydim=y*cset.ysize+prefs.PREBORDER_Y*2;
      size(xdim,ydim);
  }
  public void setup()
  {
      noLoop();
  }
  public void draw()
  {
//    if (!vis)
  //    return;
    loadPixels();
    for(int i=0;i<this.pixels.length;i++) // Border
        pixels[i]=machine.rgb[cf.border];
        
    for(int j=0;j<y;j++)
        for(int i=0;i<x;i++)
            drawsmallchar(prefs.PREBORDER_X+i*cset.xsize,prefs.PREBORDER_Y+j*cset.ysize, cf.chars[j*x+i],cf.colors[j*x+i],cf.bg);
    updatePixels();
  }
  void exit()
  {
      pWin.setVisible(false);
//      surface.setVisible(false);
  }

  // Tear down this preview window and its frame (used when rebuilding for a
  // different machine resolution in switch_machine()).
  void dispose()
  {
      noLoop();
      try
      {
          processing.awt.PSurfaceAWT.SmoothCanvas c=(processing.awt.PSurfaceAWT.SmoothCanvas)pWin.getNative();
          javax.swing.JFrame f=(javax.swing.JFrame)c.getFrame();
          f.setVisible(false);
          f.dispose();
      }
      catch(Exception e){}
  }
  
  void drawsmallchar(int x,int y,int num,int fg,int bg)
  {
    int a=machine.rgb[fg],
        b=machine.rgb[bg],
        idx;
    
    if(!machine.validate(num)) // Invalid char, oh no. Show in red.
    {
        a=#773333;
        b=#441111;
    }
    
    idx=x+y*width;
    for(int j=0;j<cset.ysize;j++)
        for(int i=0;i<cset.xsize;i++)
        {
            if((cset.bitmap.pixels[num*cset.xsize+i+j*cset.charactercount*cset.xsize]&0xff) > 20)
                pixels[idx+i+j*width]=a;
            else
                pixels[idx+i+j*width]=b;
        }
  }
  void show()
  {
    pWin.setVisible(true);
    redraw();
    loop();
  }
  void keyPressed()
  {
      if(key==ESC)
      {
          vis = false;
          pWin.setVisible(vis);
          key=0;
      }
  }
}
