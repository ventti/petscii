
// Animation, frame and undo related definitions and functions

class Frame
{
    int chars[],
        colors[],
        bg,
        border,
        duration; // Not used so far
    
    boolean locked;
    
    PImage thumb;
    
    // Undo related data
    int undochars[][], // Ring buffers for undo
        undocolors[][],
        undobg[],      // We need to save these, too
        undoborder[];
    
    int head=0,tail=0,maxhead=0;
        
    Frame()
    {
        bg=0;
        border=0;
        duration=1;
        locked=false;

        chars=new int[X*Y];
        colors=new int[X*Y];
        
        for(int i=0;i<X*Y;i++) // Clear it too
        {
            chars[i]=cset.erasechar;
            colors[i]=machine.erasecolor;
        }
        
        thumb=new PImage(X,Y,RGB);
        
        // Undo related
        undochars=new int[prefs.undodepth][X*Y];
        if(machine.palettemode)
            undocolors=new int[prefs.undodepth][X*Y];
    
        undobg=new int[prefs.undodepth];
        undoborder=new int[prefs.undodepth];
        head=tail=maxhead=0;
    }
    
    void updatethumb()
    {
        thumb.loadPixels();
        for(int i=0;i<X*Y;i++)
        {
            int col1,col2;
            if(machine.palettemode)
            {
                col1=machine.rgb[colors[i]];
                col2=machine.rgb[bg];
            }
            else
            {
                col1=machine.rgb[1];
                col2=machine.rgb[0];
            }
            
            // Blend the two based on character bit count - quite an operation
            thumb.pixels[i]=(((col1>>16)&0xff)*cset.blendfactor[chars[i]]>>8<<16)+
                            (((col1>>8)&0xff) *cset.blendfactor[chars[i]]>>8<<8)+
                            ( (col1&0xff)     *cset.blendfactor[chars[i]]>>8)+
                            
                            (((col2>>16)&0xff)*(256-cset.blendfactor[chars[i]])>>8<<16)+
                            (((col2>>8)&0xff) *(256-cset.blendfactor[chars[i]])>>8<<8)+
                            ( (col2&0xff)     *(256-cset.blendfactor[chars[i]])>>8)+ 0xff000000;
        }
        thumb.updatePixels();
    }
    
    // Check if there's changes since the last undo     
    boolean changed()
    {
        int tmphead=head-1;
        if(tmphead<0)
            tmphead=prefs.undodepth-1;
        
        if(head==tail)
            return false;
            
        if(bg!=undobg[tmphead] || border!=undoborder[tmphead])
            return true;
            
        for(int i=0;i<X*Y;i++) // Check the chars for changes
        {
            if(getchar(i)!=undochars[tmphead][i])
                return true;
            if(getcolor(i)!=undocolors[tmphead][i])
                return true;
        }
        
        return false;
    }
    
    // Various set/get functions
    int getchar(int x,int y)
    {
        return chars[x+y*X];
    }
    int getchar(int offset)
    {
        return chars[offset];
    }
    void setchar(int x,int y,int c) // For coordinate pair
    {
        if(!locked)
            chars[x+y*X]=c;
    }
    void setchar(int offset,int c) // For offset
    {
        if(!locked)
            chars[offset]=c;
    }
    int getcolor(int x,int y)
    {
        return colors[x+y*X];
    }
    int getcolor(int offset)
    {
        return colors[offset];
    }
    void setcolor(int x,int y,int c) // Coordinate pair
    {
        if(!locked)
            colors[x+y*X]=c;
    }
    void setcolor(int offset,int c) // Offset
    {
        if(!locked)
            colors[offset]=c;
    }
    void setbg(int c)
    {
        if(!locked)
            bg=c;
    }
    void setborder(int c)
    {
        if(!locked)
            border=c;
    }
    
    // Undo functions   
    void undo_save()
    {
        if(locked)
            return;
            
        dirty=true; // Not saved since last edit
        
        arrayCopy(chars,undochars[head]);
        undobg[head]=bg;
        undoborder[head]=border;
        if(machine.palettemode)
            arrayCopy(colors,undocolors[head]);
            
        head=(head+1)%prefs.undodepth;
        if(head==tail)
            tail=(tail+1)%prefs.undodepth;
            
        maxhead=head;
    }
    
    void undo_purge()
    {
        head=tail=maxhead=0;
    }
    
    void undo()
    {
        if(locked)
            return;
        
        if(head!=tail)
        {
            arrayCopy(chars,undochars[head]); // For redo
            undobg[head]=cf.bg;
            undoborder[head]=cf.border;
            if(machine.palettemode)
                arrayCopy(colors,undocolors[head]);
            
            head--;
            if(head<0)
                head=prefs.undodepth-1;
            
            arrayCopy(undochars[head],chars);
            if(machine.palettemode)
                arrayCopy(undocolors[head],colors);
            bg=undobg[head];
            border=undoborder[head];
        }
    }
    
    // Kill the last step from the buffer without redo option
    void undo_revoke()
    {
        if(locked || head==tail)
            return;
            
        head--;
        if(head<0)
            head=prefs.undodepth-1;
    
        maxhead--;
        if(maxhead<0)
            maxhead=prefs.undodepth-1;
    }
    
    void redo()
    {
        if(locked)
            return;
        
        if(head!=maxhead)
        {
            head=(head+1)%prefs.undodepth;
            
            arrayCopy(undochars[head],chars);
            if(machine.palettemode)
                arrayCopy(undocolors[head],colors);
            cf.bg=undobg[head];
            cf.border=undoborder[head];
        }
    }
}

ArrayList<Frame> frames;

int framecount=0,
    currentframe=0;

Frame scratch,cf;

void anim_init()
{
    currentframe=0;
    framecount=1;
    frames=new ArrayList<Frame>();  
    frames.add(cf);
    
    scratch=new Frame();
    scratch.bg=-1; // Empty
    scratch.border=cf.border;
}

// Set current animation frame and do some checks while we're at it
void setframe(int frame)
{
    if(frame<0 || frame>=framecount)
        return;
    
    // Check some modes because they don't make sense when changing a frame
    if(typing>0 && !cf.changed()) // Trying to switch frame when typing
        cf.undo_revoke();
    
    currentframe=frame;
    cf=frames.get(frame);

    // More frame stuff
    if(typing>0)
        cf.undo_save();
    if(mousePressed && infield()) // Try to fix inter-frame drawing
      firstclick=true;
}

// Copy all frame content to another (except duration or locking)
void copyframe(Frame s,Frame d)
{
    arrayCopy(s.chars,d.chars);
    for(int i=0;i<prefs.undodepth;i++)
        arrayCopy(s.undochars[i],d.undochars[i]);
    
    arrayCopy(s.colors,d.colors);
    if(machine.palettemode)
    {
        for(int i=0;i<prefs.undodepth;i++)
            arrayCopy(s.undocolors[i],d.undocolors[i]);
        arrayCopy(s.undobg,d.undobg);
        arrayCopy(s.undoborder,d.undoborder);
    }
    
    d.bg=s.bg;
    d.border=s.border;
    
    d.head=s.head;
    d.tail=s.tail;
    d.maxhead=s.maxhead;
    
    d.updatethumb();
}

// Add a frame at a given position
void addframe(int pos)
{
    if(pos>framecount)
        return;
        
    Frame f=new Frame();
    
    f.bg=cf.bg;
    f.border=cf.border;
    
    frames.add(pos,f);
    f.updatethumb();
    framecount++;
    dirty=true;
}

// Cut current frame to scratch
void cutframe(boolean copyonly)
{
    copyframe(cf,scratch);
    
    if(copyonly)
        return;
    
    frames.remove(currentframe);
    framecount--;

    if(currentframe==framecount)
        currentframe--;
    dirty=true;
}

void pasteframe(int pos)
{
    addframe(pos);
    copyframe(scratch,frames.get(pos));
}

// Show anim frames
void anim_frames(int sx,int ex)
{
    int i,visible;
    Frame f;
    
    if(framecount==1)
        return;
    
    noFill();
    
    visible=0;
    for(int x=sx;x<=ex-X;x+=X+3)
        visible++;
    
    i=currentframe-visible/2;
    if(i<0)
        i=0;
        
    if(framecount>=visible && i>=framecount-visible)
        i=framecount-visible;
        
    if(framecount<=visible)
        i=0;
    
    for(int x=sx;x<=ex-X && i<frames.size();x+=X+3,i++)
    {
        if(i!=currentframe)
            stroke(128);
        else
            stroke(#ff0000);
        
        f=frames.get(i);
        image(f.thumb,x,canvas_start-Y-5);
        rect(x-1,canvas_start-Y-6, X+1,Y+1);
        
        if(f.locked)
        {
            noStroke();
            fill(#ff0000);
            triangle(x,canvas_start-5, x+6,canvas_start-5, x,canvas_start-11);
            noFill();
        }
        
        if(i==0) // First frame marker
        {
            strokeWeight(2);
            stroke(#ff0000);
            line(x-4,canvas_start-Y-6, x-4,canvas_start-5);
            strokeWeight(1);
        }
        
        if(i==framecount-1) // Last frame marker
        {
            strokeWeight(2);
            stroke(#ff0000);
            line(x+X+4,canvas_start-Y-6, x+X+4,canvas_start-5);
            strokeWeight(1);
        }
    }
}

// Check if a frame is clicked
void anim_clicks(int sx,int ex)
{
    int i,visible;
    Frame f;
    
    if(framecount==1)
        return;

    visible=0;
    for(int x=sx;x<=ex-X;x+=X+3)
        visible++;
    
    i=currentframe-visible/2;
    if(i<0)
        i=0;
        
    if(framecount>=visible && i>=framecount-visible)
        i=framecount-visible;
        
    if(framecount<=visible)
        i=0;
    
    for(int x=sx;x<=ex-X && i<frames.size();x+=X+3,i++)
    {
        f=frames.get(i);
        
        if(mouseX>x && mouseX<x+X && mouseY>canvas_start-Y-5 && mouseY<canvas_start-5) // We're in
        {
            if(mouseButton==LEFT)
            {
                setframe(i);
            }  
            if(mouseButton==RIGHT)
            {
                f.locked=!f.locked;
            } 
        }
    }
}
