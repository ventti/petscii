
// Mini preview window code. Grabbed this 2nd window code from here:
// http://forum.processing.org/one/topic/popup-how-to-open-a-new-window.html

import javax.swing.JFrame;
import java.awt.Dimension;

PFrame secondframe=null;
SecondApplet sa;

void miniwin_init()
{
    if(secondframe==null)
        secondframe = new PFrame();
    else
        secondframe.setVisible(true);
        
    frame.toFront();
    frame.repaint(); // Might help
    delay(200); // A kludge to give it some time to init (I hope)
}

void miniwin_refresh()
{
    if(sa==null || secondframe==null)
        return;
        
    sa.noStroke();
    sa.fill(machine.rgb[cf.border]);
    sa.rect(0,0,                                    prefs.BWIDTH*2+X*cset.xsize,prefs.BWIDTH);
    sa.rect(0,0,                                    prefs.BWIDTH,prefs.BWIDTH*2+Y*cset.ysize);
    sa.rect(X*cset.xsize+prefs.BWIDTH,0,            prefs.BWIDTH,prefs.BWIDTH*2+Y*cset.ysize);
    sa.rect(prefs.BWIDTH,prefs.BWIDTH+Y*cset.ysize, X*cset.xsize,prefs.BWIDTH);

    try 
    {
        sa.loadPixels();
    }
    catch(NullPointerException e)
    {
        if(prefs.debug)
            println("Miniwin null pointer.");
        return;
    }
    catch(ArrayIndexOutOfBoundsException e)
    {
        if(prefs.debug)
            println("Miniwin out of bounds.");
        return;
    }
    
    if(sa.pixels.length<(X*cset.xsize+2*prefs.BWIDTH)*(prefs.BWIDTH*2+Y*cset.ysize)) // Something wrong with memory allocation
        return;
    for(int j=0;j<Y;j++)
        for(int i=0;i<X;i++)
            drawsmallchar(sa,prefs.BWIDTH+i*cset.xsize,prefs.BWIDTH+j*cset.ysize, cf.chars[j*X+i],cf.colors[j*X+i],cf.bg);
    sa.updatePixels();
    sa.redraw();
}

void drawsmallchar(SecondApplet sa,int x,int y,int num,int fg,int bg)
{
    int a=machine.rgb[fg],
        b=machine.rgb[bg],
        idx;
    
    idx=x+y*sa.width;
    for(int j=0;j<cset.ysize;j++)
        for(int i=0;i<cset.xsize;i++)
        {
            if((cset.bitmap.pixels[num*cset.xsize+i+j*cset.charactercount*cset.xsize]&0xff) > 20)
                sa.pixels[idx+i+j*sa.width]=a;
            else
                sa.pixels[idx+i+j*sa.width]=b;
        }
}

public class SecondApplet extends PApplet
{
  int x,y;
  
  SecondApplet(int xchars,int ychars)
  {
      x=xchars;
      y=ychars;
  }
  public void setup()
  {
      size(x*cset.xsize+prefs.BWIDTH*2,y*cset.ysize+prefs.BWIDTH*2);
      background(cf.border);
      noLoop();
  }
  public void draw()
  {
  }
  void keyPressed()
  {
      if(key==ESC)
      {
          secondframe.setVisible(false);
          key=0;
      }
  }
}

public class PFrame extends JFrame
{
    public PFrame()
    {
        setBounds(0,0, X*cset.xsize+prefs.BWIDTH*2,Y*cset.ysize+prefs.BWIDTH*2);
        getContentPane().setPreferredSize(new Dimension(X*cset.xsize+prefs.BWIDTH*2,Y*cset.ysize+prefs.BWIDTH*2)); // Another kludge!
        pack();
        setResizable(false);
        setDefaultCloseOperation(DO_NOTHING_ON_CLOSE);
        setTitle("1x1 Pixel CSDb Preview");
        show();

        sa=new SecondApplet(X,Y);
        sa.init();
        add(sa);
        
        addWindowListener(new java.awt.event.WindowAdapter() {
            public void windowClosing(java.awt.event.WindowEvent e) {
                setVisible(false);
            }
        });
    }
}
