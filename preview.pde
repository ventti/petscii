
// New mini preview window code

SecondApplet sa=null;
boolean sa_visible=false;

void miniwin_init()
{
    if(sa==null) // No window yet
    {
        sa=new SecondApplet(X,Y);
        sa_visible=true;
    }
    else // Hide/show
    {
        sa_visible=!sa_visible;
        sa.getSurface().setVisible(sa_visible);
    }
    delay(200); // Seems to help with focus, maybe not needed any more?
}

void miniwin_refresh()
{
    if(sa==null)
        return;
    if(sa_visible)
        sa.redraw();
}

public class SecondApplet extends PApplet
{
  int x,y;
  
  SecondApplet(int xchars,int ychars)
  {
      super();
      x=xchars;
      y=ychars;
      runSketch(new String[]{this.getClass().getName()}, this);
  }
  public void settings()
  {
      size(x*cset.xsize+prefs.PREBORDER_X*2,y*cset.ysize+prefs.PREBORDER_Y*2);
  }
  public void setup()
  {
      surface.setTitle("1x1 Pixel CSDb Preview");
      noLoop();
  }
  public void draw()
  {
    loadPixels();
    
    for(int i=0;i<sa.pixels.length;i++) // Border
        pixels[i]=machine.rgb[cf.border];
        
    for(int j=0;j<y;j++)
        for(int i=0;i<x;i++)
            drawsmallchar(prefs.PREBORDER_X+i*cset.xsize,prefs.PREBORDER_Y+j*cset.ysize, cf.chars[j*x+i],cf.colors[j*x+i],cf.bg);

    updatePixels();
  }
  void exit()
  {
      sa_visible=false;
      surface.setVisible(false);
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
  void keyPressed()
  {
      if(key==ESC)
      {
          sa_visible=false;
          surface.setVisible(false);
          key=0;
      }
  }
}
