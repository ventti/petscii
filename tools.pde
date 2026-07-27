
// Assorted drawing/utility tools (moved from the main file)

// Rotate selection clockwise
void rrotate()
{
    int tmp[]=new int[X*Y];
    
    for(int i=0;i<sel.w*sel.h;i++) // Remap
    {
        if(sel.clip_chars[i]!=HOLE)
            sel.clip_chars[i]=cset.rotate(sel.clip_chars[i]);
    }
    
    arrayCopy(sel.clip_chars,tmp);
    for(int y=0;y<sel.h;y++) // Rotate right
    {
        for(int x=0;x<sel.w;x++)
            sel.clip_chars[(sel.h-y-1)+x*sel.h]=tmp[y*sel.w+x];
    }
    arrayCopy(sel.clip_colors,tmp);
    for(int y=0;y<sel.h;y++) // Colors, too
    {
        for(int x=0;x<sel.w;x++)
            sel.clip_colors[(sel.h-y-1)+x*sel.h]=tmp[y*sel.w+x];
    }
    
    int t=sel.w;
    sel.w=sel.h;
    sel.h=t;
    
    System.gc(); // This damn Java
}

// Flip the selection horizontally + remap chars
void hflip()
{
    for(int i=0;i<sel.w*sel.h;i++) // Remap
    {
        if(sel.clip_chars[i]!=HOLE)
            sel.clip_chars[i]=cset.hflip(sel.clip_chars[i]);
    }
    
    for(int y=0;y<sel.h;y++) // Swap chars & colors
    {
        for(int x=0;x<sel.w/2;x++)
        {
            int i1=y*sel.w+x,
                i2=y*sel.w+(sel.w-x-1);
            
            int tmp=sel.clip_chars[i1];
            sel.clip_chars[i1]=sel.clip_chars[i2];
            sel.clip_chars[i2]=tmp;
            
            tmp=sel.clip_colors[i1];
            sel.clip_colors[i1]=sel.clip_colors[i2];
            sel.clip_colors[i2]=tmp;
        }
    }
}

// Flip the selection vertically + remap chars
void vflip()
{
    for(int i=0;i<sel.w*sel.h;i++) // Remap
    {
        if(sel.clip_chars[i]!=HOLE)
            sel.clip_chars[i]=cset.vflip(sel.clip_chars[i]);
    }
    
    for(int y=0;y<sel.h/2;y++) // Swap chars & colors
    {
        for(int x=0;x<sel.w;x++)
        {
            int i1=y*sel.w+x,
                i2=(sel.h-1-y)*sel.w+x;
            
            int tmp=sel.clip_chars[i1];
            sel.clip_chars[i1]=sel.clip_chars[i2];
            sel.clip_chars[i2]=tmp;
            
            tmp=sel.clip_colors[i1];
            sel.clip_colors[i1]=sel.clip_colors[i2];
            sel.clip_colors[i2]=tmp;
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
                cf.setcolor(x,y,tool.pen);
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
    
    if(cur.typing>0)
    {
        infox=cur.x;
        infoy=cur.y;
    }
    else
    {
        infox=(mouseX-view.col1_start)/machine.charx;
        infoy=(mouseY-view.canvas_start)/machine.chary;
    }
    
    if(cur.typing>0 || infield())
    {
        if(prefs.ORIGOZERO)
            s+="("+str(infox)+","+str(infoy)+") ";
        else
            s+="("+str(infox+1)+","+str(infoy+1)+") ";
            
        s+=str(cf.getchar(infox,infoy))+"/$"+hex(cf.getchar(infox,infoy),2);
        
        if(prefs.showoff)
            text(str(infox+infoy*X)+"/$"+hex(infox+infoy*X,4),view.col1_start+128,view.canvas_end+16);
    }
    text(s,view.col1_start,view.canvas_end+16);
    
    s=str(tool.current)+"/$"+hex(tool.current,2);
    text(s,view.col2_start,view.charsel_end+16);
    
    if(machine.palettemode) // Color numbers
    {
        s="pen:"+str(tool.pen)+"  bg:"+str(cf.bg)+"  border:"+str(cf.border);
        if(machine.rgb.length%16==0)
            text(s,view.col2_start,view.colorsel_start+machine.rgb.length/16*machine.csheight+18);
        else
            text(s,view.col2_start,view.colorsel_start+(machine.rgb.length/16+1)*machine.csheight+18);
    }
    
    if(cset.findset(tool.current,false)!=-1) // Set if any
    {
        textAlign(RIGHT);
        if(prefs.zoom==1)
            text(cset.setnames[cset.findset(tool.current,false)],view.col2_end,view.charsel_end+16);
        else
            text(cset.setnames[cset.findset(tool.current,false)],view.col2_start+16*machine.charx,view.charsel_end+16);
        textAlign(LEFT);
    }
    
    if(sel.h>0 && sel.w>0) // Selection size
    {
        textAlign(RIGHT);
        if(sel.mode==2)
        {
            int cnt=0;
            for(int i=0;i<X*Y;i++)
                if(sel.clip_chars[i]!=HOLE)
                    cnt++;
            text(str(cnt)+" chars",view.col1_end,view.canvas_end+16);
        }
        else
        {
            text(str(sel.w)+"x"+str(sel.h),view.col1_end,view.canvas_end+16);
        }

        textAlign(LEFT);
    }
    
    int y=view.canvas_end+16;
        
    // Modifier keys
    int base=(view.col1_start+view.col2_start)/2+58;
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
    text(raami,view.col1_start,view.canvas_start-4);
}

// The transient message toast. Deliberately NOT part of showinfo(): it carries
// errors ("... cannot be opened.") and confirmations, which used to vanish
// entirely whenever the user turned the info display off with 'i'.
void show_message()
{
    if(messagecounter<=0)
        return;

    // Same border-brightness heuristic showinfo() uses, so the text stays legible
    if(red(machine.rgb[cf.border])*3+green(machine.rgb[cf.border])*5+blue(machine.rgb[cf.border])*2>1280)
        fill(0);
    else
        fill(210);
    noStroke();

    textAlign(CENTER);
    text(curmessage,width/2,height-5);
    textAlign(LEFT);
}

// --- Keyboard-shortcut help overlay -----------------------------------------
// One in-canvas panel listing every shortcut, grouped by context, built straight
// from the shortcut registry (shortcuts.pde) so it can never drift from the real
// bindings. Uses the normal UI font size (same as the buttons) and paginates:
// groups are packed into the window's columns, and whatever overflows spills
// onto the next page (Space / click / arrows page through, Esc closes).

// One shortcut inside a group: its key text and one-line description.
class HelpRow
{
    String keys, desc;
    HelpRow(String keys, String desc) { this.keys=keys; this.desc=desc; }
}

class HelpGroup
{
    String title;
    ArrayList<HelpRow> rows=new ArrayList<HelpRow>();

    void add(String keys, String desc) { rows.add(new HelpRow(keys, desc)); }
}

// One laid-out line of the overlay: either a group heading or a shortcut.
class HelpCell
{
    int page,col,line;
    String left,right; // heading title, or key text + description
    boolean heading;
}

HelpCell helpcell(int page,int col,int line,String left,String right,boolean heading)
{
    HelpCell c=new HelpCell();
    c.page=page; c.col=col; c.line=line;
    c.left=left; c.right=right; c.heading=heading;
    return c;
}

// Fold the flat registry into contiguous groups for rendering.
ArrayList<HelpGroup> helpGroups()
{
    build_shortcuts();
    ArrayList<HelpGroup> groups=new ArrayList<HelpGroup>();
    HelpGroup g=null;
    for(Shortcut s: shortcuts)
    {
        if(g==null || !g.title.equals(s.group))
        {
            g=new HelpGroup();
            g.title=s.group;
            groups.add(g);
        }
        g.add(s.keys, s.desc);
    }
    return groups;
}

// Help overlay layout (pixels, measured at the native UI font size).
final int HELP_MARGIN        = 16; // outer padding on every side
final int HELP_TOP           = 48; // y of the first content line
final int HELP_COL_GAP       = 24; // horizontal gap between columns
final int HELP_LINE_H        = 18; // vertical step per row
final int HELP_FOOTER_H      = 24; // vertical space reserved for the footer
final int HELP_MAX_COLS      = 3;  // most columns to ever lay out
final int HELP_KEY_GAP       = 18; // gap between the key column and the description
final int HELP_COL_PAD       = 10; // right padding inside a column
final int HELP_GROUP_GAP     = 1;  // blank lines between groups within a column
final int HELP_TEXT_BASELINE = 13; // text baseline offset within a row
final int HELP_TITLE_RISE    = 18; // title baseline above the first content line
final int HELP_FOOTER_RISE   = 8;  // footer baseline above the window bottom

// Help overlay colours.
final color HELP_BG      = color(16,18,26,242); // dimmed full-window backdrop
final color HELP_TITLE   = color(255);          // "Keyboard shortcuts"
final color HELP_HEADING = color(120,200,255);  // group headings
final color HELP_KEYS    = color(240,214,120);  // key text
final color HELP_DESC    = color(225);          // descriptions
final color HELP_FOOTER  = color(150);          // footer hint

void showhelp_panel()
{
    ArrayList<HelpGroup> groups=helpGroups();

    // Measure so the drawn layout matches: descriptions are drawn at a fixed
    // offset keyW from the column's left edge, so a column must be at least
    // keyW + widest-description wide (and at least the widest group title).
    float maxKeyW=0, maxDescW=0, maxTitleW=0;
    for(HelpGroup g: groups)
    {
        maxTitleW=max(maxTitleW, textWidth(g.title));
        for(HelpRow row: g.rows)
        {
            maxKeyW=max(maxKeyW, textWidth(row.keys));
            maxDescW=max(maxDescW, textWidth(row.desc));
        }
    }
    int keyW=(int)maxKeyW+HELP_KEY_GAP;
    int colW=(int)max(keyW+maxDescW, maxTitleW)+HELP_COL_PAD;

    int availW=width-HELP_MARGIN*2;
    int cols=(int)constrain((availW+HELP_COL_GAP)/(colW+HELP_COL_GAP), 1, HELP_MAX_COLS);
    int linesPerCol=max(1, (height-HELP_TOP-HELP_FOOTER_H-HELP_MARGIN)/HELP_LINE_H);

    // Flow the groups into columns one line at a time. Packing whole groups only
    // would overflow the panel whenever a single group is taller than a column
    // (e.g. "Drawing" in a short Dir Art window), so a group that does not fit
    // continues in the next column under a "(cont.)" heading.
    ArrayList<HelpCell> cells=new ArrayList<HelpCell>();
    int page=0, col=0, used=0;

    for(HelpGroup g: groups)
    {
        if(used>0)
            used+=HELP_GROUP_GAP;                     // blank line between groups
        if(used+2>linesPerCol)                        // no room for heading + a row
        {
            used=0;
            if(++col>=cols) { col=0; page++; }
        }

        boolean heading=true;
        for(int r=0;r<g.rows.size();r++)
        {
            if(heading)
            {
                cells.add(helpcell(page,col,used, r==0 ? g.title : g.title+" (cont.)", null, true));
                used++;
                heading=false;
            }

            cells.add(helpcell(page,col,used, g.rows.get(r).keys, g.rows.get(r).desc, false));
            used++;

            if(used>=linesPerCol && r<g.rows.size()-1) // column full, group unfinished
            {
                used=0;
                if(++col>=cols) { col=0; page++; }
                heading=true;
            }
        }
    }
    helppages=page+1;
    helppage=constrain(helppage, 0, helppages-1);

    // Dimmed full-window backdrop
    noStroke();
    fill(HELP_BG);
    rect(0,0,width,height);

    // Header
    textAlign(LEFT);
    fill(HELP_TITLE);
    text("Keyboard shortcuts", HELP_MARGIN, HELP_TOP-HELP_TITLE_RISE);

    // Only the lines on the current page
    for(HelpCell c: cells)
    {
        if(c.page!=helppage)
            continue;

        float x=HELP_MARGIN+c.col*(colW+HELP_COL_GAP),
              y=HELP_TOP+c.line*HELP_LINE_H+HELP_TEXT_BASELINE;

        if(c.heading)
        {
            fill(HELP_HEADING);
            text(c.left, x, y);
        }
        else
        {
            fill(HELP_KEYS);
            text(c.left, x, y);
            fill(HELP_DESC);
            text(c.right, x+keyW, y);
        }
    }

    // Footer: paging hint / page indicator
    fill(HELP_FOOTER);
    textAlign(LEFT);
    if(helppages>1)
        text("Page "+(helppage+1)+"/"+helppages+"  –  Space or click: next   Esc: close", HELP_MARGIN, height-HELP_FOOTER_RISE);
    else
        text("?  or  Esc  to close", HELP_MARGIN, height-HELP_FOOTER_RISE);
    textAlign(LEFT);
}

// Check whether the mouse cursor is inside the canvas
boolean infield()
{
    return inside(view.col1_start,view.canvas_start, canvasx(X),canvasy(Y));
}
// ... or the color selector
boolean incolorsel()
{
    return inside(view.col2_start,view.colorsel_start, view.col2_start+16*machine.charx,view.colorsel_start+machine.csrows*machine.csheight);
}
// ... or the char selector
boolean incharsel()
{
    return inside(view.col2_start,view.charsel_start, view.col2_start+16*machine.charx,view.charsel_end);
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
    
    String text, tooltip;
    Button(int px,int py,String txt)
    {
        x=px;
        y=py;
        w=(int)textWidth(txt)+9;
        h=20;
        prevstate=false;
        disabled=false;
        tooltip = null;
        text=txt;
        butts.add(this);
  }
    Button(int px,int py,String txt,String tip)
    {
        x=px;
        y=py;
        w=(int)textWidth(txt)+9;
        h=20;
        prevstate=false;
        disabled=false;
        tooltip = tip;
        
        text=txt;
        butts.add(this);
    }
    

    
    
    void draw()
    {
        if(mouseover())
        {
            if (tooltip != null)
                message(tooltip);
            fill(255);
            stroke(200,0,0,255);
        }
        else
            fill(220);
            stroke(40);
    
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
    if(sel.w<1 || sel.h<1)
        return;
    
    int tchar[]=new int[sel.w*sel.h],
        tcol[]=new int[sel.w*sel.h],
        first=-1,
        last=-1;

    // Find y bounds
    for(int y=0;y<sel.h;y++)
    {
        for(int x=0;x<sel.w;x++)
        {
            if(sel.clip_chars[y*sel.w+x]!=HOLE)
            {
                last=y;
                if(first==-1)
                    first=y;
            }
        }
    }
    if(last==-1) // None
    {
        sel.w=sel.h=0;
        return;
    }
    
    for(int y=first,i=0;y<=last;y++)
        for(int x=0;x<sel.w;x++,i++)
        {
            sel.clip_chars[i]=sel.clip_chars[y*sel.w+x];
            sel.clip_colors[i]=sel.clip_colors[y*sel.w+x];
        }
    sel.h=last-first+1;

    // Find x bounds
    last=first=-1;
    for(int x=0;x<sel.w;x++)
    {
        for(int y=0;y<sel.h;y++)
        {
            if(sel.clip_chars[y*sel.w+x]!=HOLE)
            {
                last=x;
                if(first==-1)
                    first=x;
            }
        }
    }
    
    for(int y=0,i=0;y<sel.h;y++)
        for(int x=first;x<=last;x++,i++)
        {
            sel.clip_chars[i]=sel.clip_chars[y*sel.w+x];
            sel.clip_colors[i]=sel.clip_colors[y*sel.w+x];
        }
    sel.w=last-first+1;
}

// Shortcuts for canvas character positions
int canvasx(int x)
{
    return view.col1_start+x*machine.charx;
}
int canvasy(int y)
{
    return view.canvas_start+y*machine.chary;
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
