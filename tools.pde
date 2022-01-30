
// Assorted drawing/utility tools (moved from the main file)

// Rotate selection clockwise
void rrotate()
{
    int tmp[]=new int[X*Y];
    
    for(int i=0;i<selw*selh;i++) // Remap
    {
        if(clip_chars[i]!=HOLE)
            clip_chars[i]=cset.rotate(clip_chars[i]);
    }
    
    arrayCopy(clip_chars,tmp);
    for(int y=0;y<selh;y++) // Rotate right
    {
        for(int x=0;x<selw;x++)
            clip_chars[(selh-y-1)+x*selh]=tmp[y*selw+x];
    }
    arrayCopy(clip_colors,tmp);
    for(int y=0;y<selh;y++) // Colors, too
    {
        for(int x=0;x<selw;x++)
            clip_colors[(selh-y-1)+x*selh]=tmp[y*selw+x];
    }
    
    int t=selw;
    selw=selh;
    selh=t;
    
    System.gc(); // This damn Java
}

// Flip the selection horizontally + remap chars
void hflip()
{
    for(int i=0;i<selw*selh;i++) // Remap
    {
        if(clip_chars[i]!=HOLE)
            clip_chars[i]=cset.hflip(clip_chars[i]);
    }
    
    for(int y=0;y<selh;y++) // Swap chars & colors
    {
        for(int x=0;x<selw/2;x++)
        {
            int i1=y*selw+x,
                i2=y*selw+(selw-x-1);
            
            int tmp=clip_chars[i1];
            clip_chars[i1]=clip_chars[i2];
            clip_chars[i2]=tmp;
            
            tmp=clip_colors[i1];
            clip_colors[i1]=clip_colors[i2];
            clip_colors[i2]=tmp;
        }
    }
}

// Flip the selection vertically + remap chars
void vflip()
{
    for(int i=0;i<selw*selh;i++) // Remap
    {
        if(clip_chars[i]!=HOLE)
            clip_chars[i]=cset.vflip(clip_chars[i]);
    }
    
    for(int y=0;y<selh/2;y++) // Swap chars & colors
    {
        for(int x=0;x<selw;x++)
        {
            int i1=y*selw+x,
                i2=(selh-1-y)*selw+x;
            
            int tmp=clip_chars[i1];
            clip_chars[i1]=clip_chars[i2];
            clip_chars[i2]=tmp;
            
            tmp=clip_colors[i1];
            clip_colors[i1]=clip_colors[i2];
            clip_colors[i2]=tmp;
        }
    }
}

// A simple dither that finds one character representation for the reference image
void dither()
{
    int popularity[]=new int[machine.rgb.length];
    
    boolean blok[]=new boolean[cset.xsize*cset.ysize];
    
    reference.loadPixels();
    cset.bitmap.loadPixels();
    
    // Walk through the blocks
    for(int y=0;y<Y;y++)
    {
        // This damn Java
        System.gc();
        for(int x=0;x<X;x++)
        {
            for(int k=0;k<machine.rgb.length;k++)
                popularity[k]=0;
            
            // Find best matching colors
            for(int i=0;i<cset.ysize;i++)
            {
                for(int j=0;j<cset.xsize;j++)
                {
                    // Sample one pixel from the reference image. A bit tricky?
                    int index=(y*reference.height/Y)*reference.width
                              +(i*reference.height/Y/cset.ysize)*reference.width
                              +(x*reference.width/X)
                              +(j*reference.width/X/cset.xsize);
                              
                    int p=reference.pixels[index];
                    
                    // Find the nearest color in palette
                    int best=0,
                        bestdiff=10000000;
                    for(int k=0;k<=machine.maxpen;k++)
                    {
                        if(rgbdistance(p,machine.rgb[k])<bestdiff)
                        {
                            best=k;
                            bestdiff=rgbdistance(p,machine.rgb[k]);
                        }
                    }
                    popularity[best]++;
                }
            }
            
            // Best second color
            int best=-1,bestpop=0;
            
            for(int k=0;k<=machine.maxpen;k++)
            {
                if(k!=cf.bg && popularity[k]>bestpop)
                {
                    best=k;
                    bestpop=popularity[k];
                }
            }
            
            if(best==-1 && machine.palettemode) // Directly bg color
            {
                cf.setchar(x,y,cset.erasechar);
                cf.setcolor(x,y,pen);
            }
            else // Form a binary b/w character based on bg and best match
            {
                for(int i=0;i<cset.ysize;i++)
                {
                    for(int j=0;j<cset.xsize;j++)
                    {
                        // Sample one pixel from the reference image. A bit tricky?
                        int index=(y*reference.height/Y)*reference.width
                                  +(i*reference.height/Y/cset.ysize)*reference.width
                                  +(x*reference.width/X)
                                  +(j*reference.width/X/cset.xsize);
                                  
                        int p=reference.pixels[index];
                        
                        if(machine.palettemode)
                        {
                            if(rgbdistance(p,machine.rgb[cf.bg]) < rgbdistance(p,machine.rgb[best]))
                                blok[i*cset.xsize+j]=false;
                            else
                                blok[i*cset.xsize+j]=true;
                        }
                        else
                        {
                            if(rgbdistance(p,0)<(prefs.BWTHRESHOLD*prefs.BWTHRESHOLD)*3)
                                blok[i*cset.xsize+j]=false;
                            else
                                blok[i*cset.xsize+j]=true;
                        }
                    }
                }
                
                int bestchar=0,
                    bestdiff=100000000;
                // Walk through the charset and find the best match
                for(int i=0;i<cset.charactercount;i++)
                {
                    if(differentbits(i,blok)<bestdiff)
                    {
                        bestchar=i;
                        bestdiff=differentbits(i,blok);
                    }
                }
                
                if(machine.palettemode)
                    cf.setcolor(x,y,best);
                else
                    cf.setcolor(x,y,machine.erasecolor);
                cf.setchar(x,y,bestchar);
            }
        }
    }
    
    reference.updatePixels();
}

// Find how many bits match
int differentbits(int charnum,boolean bits[])
{
    int differentbits=0;
    
    for(int i=0;i<cset.ysize;i++)
    {
        for(int j=0;j<cset.xsize;j++)
        {
            int index=charnum*cset.xsize +i*cset.bitmap.width +j;
            
            boolean bitti=bits[i*cset.xsize+j];
            
            if((cset.bitmap.pixels[index]&0xff)<20) // Black
            {
                if(bitti)
                    differentbits++;
            }
            else // White
            {
                if(!bitti)
                    differentbits++;
            }
        }
    }
    
    return differentbits;
}

// Calculate the RGB distance of two colors
int rgbdistance(int p1,int p2)
{
    int r1=(p1>>16)&255,
        g1=(p1>>8)&255,
        b1=p1&255,
        r2=(p2>>16)&255,
        g2=(p2>>8)&255,
        b2=p2&255;
        
    return (r1-r2)*(r1-r2)+(g1-g2)*(g1-g2)+(b1-b2)*(b1-b2);
}

// Floodfill
void ffill(int x,int y,int c,int col,int tchar,int tcol,boolean coloronly)
{
    if(cf.locked)
        return;
    
    IntList list=new IntList();
    int maxlength=0;
    
    list.append(x);
    list.append(y);
    
    while(list.size()>0)
    {
        if(prefs.debug)
        {
            if(list.size()>maxlength)
            {
                maxlength=list.size();
                println("List max length: "+str(maxlength));
            }
        }
        
        x=list.get(0); // Next position and remove this
        list.remove(0);
        y=list.get(0);
        list.remove(0);

        if(x>=0 && x<X && y>=0 && y<Y) // Sensible place?
        {
            if(coloronly)
            {
                if(cf.getchar(x,y)!=cset.erasechar && cf.getcolor(x,y)==tcol) // Yes, change color
                {
                    cf.setcolor(x,y,col);
                    list.append(x-1); list.append(y);
                    list.append(x+1); list.append(y);
                    list.append(x);   list.append(y-1);
                    list.append(x);   list.append(y+1);
                }
            }
            else
            {
                if(cf.getchar(x,y)==tchar) // Yes, change color+char
                {
                    if(machine.maxpen==0 || cf.getcolor(x,y)==tcol) // For color modes consider color too
                    {            
                        cf.setchar(x,y,c);
                        cf.setcolor(x,y,col);
                        list.append(x-1); list.append(y);
                        list.append(x+1); list.append(y);
                        list.append(x);   list.append(y-1);
                        list.append(x);   list.append(y+1);
                    }
                }
            }
        }
    }
}

// Quick lines for the grid
void hline(int x1,int x2,int y)
{
    if(machine.palettemode)
    {
        for(int i=x1;i<=x2;i++)
        {
            int c=pixels[i+y*width];
            if(((c>>16)&0xff) + ((c>>8)&0xff) + ((c>>0)&0xff) > 384)
                pixels[i+y*width]=(c-0x1a1a1a)|0xff000000;
            else
                pixels[i+y*width]=(c+0x1a1a1a)|0xff000000;
        }
    }
    else // This can and should be simpler to not hide the edge
    {
        for(int i=x1;i<=x2;i++)
            pixels[i+y*width]|=0x303030;
    }
}

void vline(int x,int y1,int y2)
{
    if(machine.palettemode)
    {
        for(int i=y1;i<=y2;i++)
        {
            int c=pixels[x+i*width];
            if(((c>>16)&0xff) + ((c>>8)&0xff) + ((c>>0)&0xff) > 384)
                pixels[x+i*width]=(c-0x1a1a1a)|0xff000000;
            else
                pixels[x+i*width]=(c+0x1a1a1a)|0xff000000;
        }
    }
    else // Likewise, a bit simpler
    {
        for(int i=y1;i<=y2;i++)
            pixels[x+i*width]|=0x303030;
    }
}

// Handle message printing
void message(String s)
{
    if(prefs.PRINTMESSAGES) // Normal printing to console
    {
        println(s);
    }
    else
    {
        curmessage=s;
        messagecounter=prefs.MESSAGEDURATION;
        repaint=true;
    }
}

// Display color/char numbers, locations and more
void showinfo()
{
    // Decide text color based on border color, somewhat psychovisual (green matters most)
    if(red(machine.rgb[cf.border])*3+green(machine.rgb[cf.border])*5+blue(machine.rgb[cf.border])*2>1280)
        fill(0);
    else
        fill(210);
    noStroke();
    
    String s="";
    
    int infox=0,infoy=0;
    
    if(typing>0)
    {
        infox=cursorx;
        infoy=cursory;
    }
    else
    {
        infox=(mouseX-col1_start)/machine.charx;
        infoy=(mouseY-canvas_start)/machine.chary;
    }
    
    if(typing>0 || infield())
    {
        if(prefs.ORIGOZERO)
            s+="("+str(infox)+","+str(infoy)+") ";
        else
            s+="("+str(infox+1)+","+str(infoy+1)+") ";
            
        s+=str(cf.getchar(infox,infoy))+"/$"+hex(cf.getchar(infox,infoy),2);
        
        if(prefs.showoff)
            text(str(infox+infoy*X)+"/$"+hex(infox+infoy*X,4),col1_start+128,canvas_end+16);
    }
    text(s,col1_start,canvas_end+16);
    
    s=str(current)+"/$"+hex(current,2);
    text(s,col2_start,charsel_end+16);
    
    if(machine.palettemode) // Color numbers
    {
        s="pen:"+str(pen)+"  bg:"+str(cf.bg)+"  border:"+str(cf.border);
        if(machine.rgb.length%16==0)
            text(s,col2_start,colorsel_start+machine.rgb.length/16*machine.csheight+18);
        else
            text(s,col2_start,colorsel_start+(machine.rgb.length/16+1)*machine.csheight+18);
    }
    
    if(cset.findset(current,false)!=-1) // Set if any
    {
        textAlign(RIGHT);
        if(prefs.zoom==1)
            text(cset.setnames[cset.findset(current,false)],col2_end,charsel_end+16);
        else
            text(cset.setnames[cset.findset(current,false)],col2_start+16*machine.charx,charsel_end+16);
        textAlign(LEFT);
    }
    
    if(selh>0 && selw>0) // Selection size
    {
        textAlign(RIGHT);
        if(selectmode==2)
        {
            int cnt=0;
            for(int i=0;i<X*Y;i++)
                if(clip_chars[i]!=HOLE)
                    cnt++;
            text(str(cnt)+" chars",col1_end,canvas_end+16);
        }
        else
        {
            text(str(selw)+"x"+str(selh),col1_end,canvas_end+16);
        }

        textAlign(LEFT);
    }
    
    int y=canvas_end+16;
        
    // Modifier keys
    int base=(col1_start+col2_start)/2+58;
    if(shift==1) text("S",base,y);
    if(shift==2) text("s",base,y);
    if(alt) text("A",base+12,y);
    if(control) text("C",base+24,y);
    if(floodfill>0) text("F",base+38,y);
    
    if(messagecounter>0)
    {
        //messagecounter--;
        textAlign(CENTER);
        text(curmessage,width/2,height-5);
        textAlign(LEFT);
    }
    
    // Animation frame etc
    String raami=str(currentframe+1)+"/"+str(framecount);
    if(cf.locked)
        raami+="*";
    text(raami,col1_start,canvas_start-4);
}

// Check whether the mouse cursor is inside the canvas
boolean infield()
{
    return inside(col1_start,canvas_start, canvasx(X),canvasy(Y));
}
// ... or the color selector
boolean incolorsel()
{
    return inside(col2_start,colorsel_start, col2_start+16*machine.charx,colorsel_start+machine.csrows*machine.csheight);
}
// ... or the char selector
boolean incharsel()
{
    return inside(col2_start,charsel_start, col2_start+16*machine.charx,charsel_end);
}

// Mouse inside this rect?
boolean inside(int left,int top,int right,int bottom)
{
    if(mouseX>left && mouseY>top && mouseX<right && mouseY<bottom)
        return true;
    else
        return false;
}

// Simple UI buttons
ArrayList<Button> butts=new ArrayList<Button>();

class Button
{
    int x,y,w,h;
    
    boolean prevstate, // Was there mouseover or not?
            disabled;  // Don't do anything
    
    String text;
    
    Button(int px,int py,String txt)
    {
        x=px;
        y=py;
        w=(int)textWidth(txt)+9;
        h=20;
        prevstate=false;
        disabled=false;

        text=txt;
        
        butts.add(this);
    }
    
    void draw()
    {
        if(mouseover())
            stroke(200,0,0,255);
        else
            stroke(40);
        fill(220);
        rect(x,y,w,h,3,3,3,3);
        fill(40);
        text(text,x+5,y+16);
        
        stroke(40,100); // Stroke over disabled buttons
        if(disabled)
            line(x,y+h/2,x+w,y+h/2);
        noStroke();
    }
    
    boolean mouseover()
    {
        if(disabled)
            return false;
            
        if(mouseX>x && mouseY>y && mouseX<=x+w && mouseY<=y+20)
            return true;
        else
            return false;        
    }
}

void drawbuttons()
{
    for(Button butt: butts)
        butt.draw();
}

// Load the reference image
boolean loadreference(String name)
{
    PImage tmpimg=loadImage(name);
    
    if(tmpimg!=null)
    {
        reference=new PImage(tmpimg.width,tmpimg.height,ARGB); // Make sure it's ARGB
        tmpimg.loadPixels();
        reference.loadPixels();
        
        for(int i=0;i<tmpimg.pixels.length;i++)
            reference.pixels[i]=tmpimg.pixels[i];
        reference.updatePixels();
        
        // Don't scale 1:1 pics
        if(reference.width!=X*cset.xsize || reference.height!=Y*cset.ysize)
            reference.resize(X*machine.charx,Y*machine.chary);
        
        ref=0;
    }
    else
        return false;
    
    System.gc(); // Eh...
    return true;
}

// Change extension from .c to something else
String ext(String name,String newext)
{
    // Bad filename?
    if(name.length()<3 || (!name.substring(name.length()-2).equals(".c") &&
                           !name.substring(name.length()-2).equals(".C")))
    {
        message("Bad bad bad file extension!");
        return null;
    }
    
    return name.substring(0,name.length()-2)+newext;
}

// Optimize the clipboard
void optimize_clip()
{
    if(selw<1 || selh<1)
        return;
    
    int tchar[]=new int[selw*selh],
        tcol[]=new int[selw*selh],
        first=-1,
        last=-1;

    // Find y bounds
    for(int y=0;y<selh;y++)
    {
        for(int x=0;x<selw;x++)
        {
            if(clip_chars[y*selw+x]!=HOLE)
            {
                last=y;
                if(first==-1)
                    first=y;
            }
        }
    }
    if(last==-1) // None
    {
        selw=selh=0;
        return;
    }
    
    for(int y=first,i=0;y<=last;y++)
        for(int x=0;x<selw;x++,i++)
        {
            clip_chars[i]=clip_chars[y*selw+x];
            clip_colors[i]=clip_colors[y*selw+x];
        }
    selh=last-first+1;

    // Find x bounds
    last=first=-1;
    for(int x=0;x<selw;x++)
    {
        for(int y=0;y<selh;y++)
        {
            if(clip_chars[y*selw+x]!=HOLE)
            {
                last=x;
                if(first==-1)
                    first=x;
            }
        }
    }
    
    for(int y=0,i=0;y<selh;y++)
        for(int x=first;x<=last;x++,i++)
        {
            clip_chars[i]=clip_chars[y*selw+x];
            clip_colors[i]=clip_colors[y*selw+x];
        }
    selw=last-first+1;
}

// Shortcuts for canvas character positions
int canvasx(int x)
{
    return col1_start+x*machine.charx;
}
int canvasy(int y)
{
    return canvas_start+y*machine.chary;
}

// Open a file for writing without dying if it can't be opened
PrintWriter safeWriter(String name)
{
    PrintWriter f;
    
    try
    {
        f=createWriter(name);
    }
    catch(Exception e)
    {
        message("Error writing "+name);
        return null;
    }
    
    return f;
}

long timestamp(String name) // Get file date
{
    File f=new File(name);
    return f.lastModified();
}

class UserFile
// enables to have project- and user account -specific files such as preferences and plugins
{
  public String name;  // name of the file without path
  public String[] data;  // file contents
  public String path;  // file name with path
  
  UserFile(String name)
  {
      this.name = name;
  }
  
  void load()
  // load a file from priority list of directories
  {
      String row[] = null;
      // priority list of the preference paths
      ArrayList<String> file_paths = new ArrayList<String>();
  
      file_paths.add(name);  // By default, highest priority for prefs is from current dir
      if (System.getProperty("os.name").contains("Linux"))  // Linux-specific priority list
      {
          file_paths.add(System.getProperty("user.home") + "/.petscii/" + name);  // User-specific: $HOME/.petscii/<name>
          file_paths.add("/etc/petscii/" + name);  // Global: /etc/petscii/<name>
      }
      // legacy preferences
      file_paths.add(System.getProperty("user.home")+File.separator+name);  // Prefs from home
      file_paths.add(sketchPath("") + name);  // Prefs from sketch path
  
      for (String path : file_paths)
      {
          row = loadStrings(path);
          if (row != null)
          {
            this.path = path;
            break;
          }
      }
      this.data = row;
  }
  
  String as_string(){
    return join(this.data, "\n");
  }
}
