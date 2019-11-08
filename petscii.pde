/*
  A PETSCII drawing app. Originally made for Zoo'13 PETSCII compo, because I couln't find anything suitable for Linux/Mac. 
  
  See here: http://www.kameli.net/marq/?page_id=2717
  Changelog can be found on log.pde

  - Marq/Fit^L!T^Dkd, with additions from Dr. TerrorZ/L!T
*/

// Global stuff
Preferences prefs;

Machine machine;

Charset cset;

int clip_chars[],clip_colors[];

int X=0,Y=0,                     // Picture size in chars
    pen=1,                       // Drawing colors
    current,curidx=0,            // Current character number and index in the selector
    backupcounter=0,
    selx=0,sely=0,selw=0,selh=0,     // Selection params
    cursorx=0,cursory=0,
    lastgrow=0,
    
    messagecounter=0,
    focuscount=0,
    
    oldblox=-1,oldbloy=-1,
    oldx=-1,oldy=-1;

int     ref=-1,                  // Various modes
        floodfill=0,
        typing=0,
        selectmode=0,
        shift=0;
        
long reftime=-1;

boolean control=false,
        oldcontrol=false,
        alt=false,
        
        firstsel=true,
        firstclick=true,
        repaint=true,
        infidel=true,
        selectadd=true,
        
        fileselect=false, // "Event" flags for file operations
        mergeselect=false,
        saveselect=false,
        refselect=false,
        importselect=false;
        
float   avgms=0; // For profiling
int     blink=0;

String filename="",refname="",
       curmessage="";

PImage reference;
PFont  font;

// UI parameters
int    col1_start,col1_end, // x
       col2_start,col2_end,
       canvas_start,canvas_end, // y
       colorsel_start,
       charsel_start,charsel_end;

// UI buttons
Button load_b,merge_b,save_b,saveas_b,ref_b,
       import_prg_b,export_prg_b,export_png_b,clear_b,preview_b,
       dupleft_b,dupright_b,cut_b,pasteleft_b,pasteright_b,
       undo_b,redo_b,grid_b,case_b;

void setup()
{
    javatheme();
    
    prefs=new Preferences();
    prefs.readprefs(prefs.PREFSFILE);
    filename=prefs.FILENAME;
    
    if(prefs.machine==-1)
        prefs.machine=selector("Select a platform","C-64,C-64 flicker,VIC-20,PET 40x25,PET 80x25,Plus/4");
    delay(200); // Superstition? 
    
    switch(prefs.machine)
    {
        case C64:   machine=new C64(); break;
        case C64FLICKER: machine=new C64flicker(); break;
        case VIC20: machine=new Vic20(); break;
        case PET:   machine=new Pet(); break;
        case PETHI: machine=new Pethi(); break;
        case PLUS4: machine=new Plus4(); break;
        default: ;
    }
    cset.shift=machine.shift; // Need to do this properly later
    cset.grow=machine.grow;
        
    // Create an empty image
    if(X==0 || Y==0)
    {
        X=machine.nativex;
        Y=machine.nativey;
    }
    
    current=cset.remap[curidx];
    
    cf=new Frame();
    cf.setbg(machine.defaultbg);
    cf.setborder(machine.defaultborder);
    pen=machine.erasecolor;
        
    clip_chars=new int[X*Y];
    clip_colors=new int[X*Y];

    // Various UI locations: x
    col1_start=prefs.BWIDTH;
    col1_end=col1_start+max(X*machine.charx,prefs.ANWIDTH+2*X+16); // fit 2 frames at least
    col2_start=col1_end+prefs.BWIDTH;
    col2_end=col2_start+max(16*machine.charx,prefs.UIWIDTH);       // Buttons or char selector

    // y
    canvas_start=max(prefs.BWIDTH+Y, prefs.UIROW+prefs.BWIDTH); // Anim frame + border or buttons + border
    canvas_end=canvas_start+Y*machine.chary;
    colorsel_start=canvas_start+3*prefs.UIROW+5;
    charsel_start=colorsel_start+machine.csheight*machine.csrows+prefs.UIROW+1;
    charsel_end=charsel_start+cset.charactercount/16*machine.chary;
    
    size(col2_end+prefs.BWIDTH, max(charsel_end+prefs.UIROW+prefs.BWIDTH, canvas_end+prefs.UIROW+prefs.BWIDTH));
    frameRate(prefs.framerate);
    noStroke();
    noSmooth();
    
    font=loadFont(prefs.FONTFILE);
    textFont(font);
    
    anim_init();

    // Create the UI buttons
    load_b=new Button(col2_start,canvas_start,"Load");
    merge_b=new Button(col2_start+49,canvas_start,"Merge");
    save_b=new Button(col2_start+107,canvas_start,"Save");
    saveas_b=new Button(col2_start+156,canvas_start,"Save as");
    ref_b=new Button(col2_start+228,canvas_start,"Ref.");
    
    import_prg_b=new Button(col2_start,canvas_start+prefs.UIROW,"Load .prg");
    export_prg_b=new Button(col2_start+79,canvas_start+prefs.UIROW,"Save .prg");
    export_png_b=new Button(col2_start+158,canvas_start+prefs.UIROW,".png");
    preview_b=new Button(col2_start+200,canvas_start+prefs.UIROW,"Preview");
    
    undo_b=new Button(col2_start,canvas_start+prefs.UIROW*2,"Undo");
    redo_b=new Button(col2_start+50,canvas_start+prefs.UIROW*2,"Redo");
    clear_b=new Button(col2_start+113,canvas_start+prefs.UIROW*2,"Clear");
    grid_b=new Button(col2_start+175,canvas_start+prefs.UIROW*2,"Grid");
    case_b=new Button(col2_start+218,canvas_start+prefs.UIROW*2,"Case");

    dupleft_b=new Button(col1_end-207,canvas_start-26,"< Dup");
    dupright_b=new Button(col1_end-152,canvas_start-26," >");
    cut_b=new Button(col1_end-126,canvas_start-26,"Cut");
    pasteleft_b=new Button(col1_end-89,canvas_start-26,"< Paste");
    pasteright_b=new Button(col1_end-22,canvas_start-26," >");
    
    frame.setTitle(filename+" ("+str(X)+"x"+str(Y)+")");
    
    user_setup(); // Call users' own functions
    
    if(prefs.miniwin)
        miniwin_init();
    
    backupcounter=millis();
    loadPixels();
}

void draw()
{
    int millis1=millis();
    
    int blox=(mouseX-col1_start)/machine.charx, // Mouse coordinates in character blocks
        bloy=(mouseY-canvas_start)/machine.chary,

        selectx=0,selecty=0;

    // The following things need to be handled even if the frame is not refreshed
    // Backup?
    if((millis()-backupcounter)/1000 >= prefs.BACKUP)
    {
        backupcounter=millis();
        machine.save_c(prefs.backupfile,false);
    }
        
    // Better do this at times or we might run out of memory
    if(frameCount%100==0)
        System.gc();
    
    // UI file operations
    if(fileselect) // Fileselect "event" for Load
    {
        String s=fileselector(prefs.path,LOADPETSCII);
        if(s!=null)
        {
            if(machine.load_c(s,false))
                filename=s;
            else
                message(s+" cannot be opened.");
        }
        fileselect=false;
        repaint=true;
    }
    if(mergeselect) // Fileselect "event" for Load
    {
        String s=fileselector(prefs.path,MERGEPETSCII);
        if(s!=null)
        {
            if(!machine.load_c(s,true))
                message(s+" cannot be opened.");
        }
        mergeselect=false;
        repaint=true;
    }
    if(saveselect) // Fileselect "event" for Save as
    {
        String s=fileselector(prefs.path,SAVEPETSCII);
        if(s!=null)
        {
            // Add extension if needed
            if(s.length()<=2)
                s+=".c";
            else
            {
                if(!s.substring(s.length()-2).equals(".c") &&
                   !s.substring(s.length()-2).equals(".C"))
                    s+=".c";
            }
            filename=s;
            
            int i=0;
            File f=new File(filename);
            if(f.exists())
            {
                i=selector("Overwrite?","Yes,No");
            }
            if(i==0)
                machine.save_c(filename,false);
        }
        saveselect=false;
        repaint=true;
    }
    if(refselect) // Fileselect "event" for Reference image
    {
        String s=fileselector(prefs.refpath,LOADPIX);
        if(s!=null)
        {
            if(loadreference(s))
            {
                refname=s;
                ref=1;
                reftime=timestamp(s);
            }
            else
                message(s+" cannot be opened.");
        }
        refselect=false;
        repaint=true;
    }
    if(importselect) // Fileselect "event" for Import (PRG)
    {
        String s=fileselector(prefs.path,LOADPRG);
        if(s!=null)
        {
            machine.import_prg(s);
        }
        cf.updatethumb();
        importselect=false;
        repaint=true;
    }
    
    // Better remove modifiers when switching a window
    if(!focused)
    {
        alt=false; // Esp. this, since Windows uses Alt-Tab for choosing apps
        control=false;
        shift=0;
        oldcontrol=false;
        floodfill=0;
        if(focuscount==0) // Need to draw one frame because of the preview window
        {
            focuscount++;
            repaint=true;
        }
        else
        {
            delay(200);
            return;    // And yield too
        }
    }
    else
        focuscount=0;
    
    // Check if we need to actually refresh the screen
    if(infield())
    {
        if(oldblox!=blox || oldbloy!=bloy)
            repaint=true;
            
        boolean erasing=false;
        if(mousePressed && mouseButton!=LEFT)
            erasing=true;
        if(alt && cset.pixellogic(mouseX,mouseY,cf.getchar(blox,bloy),erasing)!=cf.getchar(blox,bloy))
            repaint=true;
       
        oldblox=blox;
        oldbloy=bloy;
        
        infidel=true;
    }
    else
    {
        // Moving out of the field
        if(infidel)
        {
            repaint=true;
            infidel=false;
        }
        
        // Handle these separately
        if(incharsel() && mousePressed)
            repaint=true;
        if(incolorsel() && mousePressed)
            repaint=true;        
        
        // Another kludge to handle the UI buttons
        for(int i=0;i<butts.size();i++)
            if(butts.get(i).mouseover()!=butts.get(i).prevstate)
            {
                butts.get(i).prevstate=butts.get(i).mouseover();
                repaint=true;
            }
            
        // Always repaint when re-entering canvas
        oldblox=oldbloy=-1;
    }
    
    // Cursor needs repainting
    if(typing>0 && (millis()/250&1)!=blink)
    {
        repaint=true;
        blink=1-blink;
    }
    
    if(prefs.crosshair && (mouseX!=oldx || mouseY!=oldy)) // Try to avoid excessive repainting
    {
        if(frameCount%4==0)
        {
            repaint=true;
            oldx=mouseX;
            oldy=mouseY;
        }
    }
    
    if(prefs.debug)
        repaint=true;

    // Messages need to fade
    if(messagecounter>-1)
        messagecounter--;
    if(messagecounter==0)
        repaint=true;
    
    if(!repaint) // Let's leave it there, then
        return;
    repaint=false;
    
    // Border
    //background(rgb[border]); // We don't need loadPixels (I hope)
    //loadPixels();
    int t=machine.rgb[cf.border];
    for(int i=0;i<width*height;i++)
        pixels[i]=t;
    
    // Draw the chars
    for(int y=0;y<Y;y++)
        for(int x=0;x<X;x++)
            cset.drawchar(canvasx(x),canvasy(y), cf.getchar(x,y),cf.getcolor(x,y),cf.bg);

    // Draw the char selector
    noStroke();
    for(int y=0,i=0;y<cset.charactercount/16;y++)
        for(int x=0;x<16;x++,i++)
        {
            cset.drawchar(col2_start+x*machine.charx,charsel_start+y*machine.chary,cset.remap[i],pen,cf.bg);
            if(i==curidx)
            {
                selectx=col2_start+x*machine.charx;
                selecty=charsel_start+y*machine.chary;
            }
        }

    // Charsel grid
    for(int x=0;x<16;x++)
        vline(col2_start+x*machine.charx-1, charsel_start,charsel_start+cset.charactercount/16*machine.chary-1);
    vline(col2_start+16*machine.charx, charsel_start,charsel_start+cset.charactercount/16*machine.chary);
    
    for(int y=0;y<cset.charactercount/16;y++)
        hline(col2_start,col2_start+16*machine.charx-1, charsel_start+y*machine.chary-1);
    hline(col2_start,col2_start+16*machine.charx-1, charsel_start+cset.charactercount/16*machine.chary);

    boolean erasing=false;
    
    // User interaction(!)
    if(mousePressed && infield() && typing==0 && floodfill==0)
    {       
        if(firstclick)
        {
            // Save an undo step under certain conditions
            if(!control && mouseButton!=prefs.PICKERBUTTON)
                cf.undo_save();
            if(alt && mouseButton==prefs.PICKERBUTTON) // A kludge here 'coz of my window manager
                cf.undo_save();
            firstclick=false;
        }

        if(alt) // "Pixel" drawing mode
        {
            if(mouseButton==LEFT)
            {
                if(shift!=1)
                    cf.setchar(blox,bloy,cset.pixellogic(mouseX,mouseY,cf.getchar(blox,bloy),false));
                if(shift!=2)
                    cf.setcolor(blox,bloy,pen);
                erasing=false;
            }
            else
            {
                cf.setchar(blox,bloy,cset.pixellogic(mouseX,mouseY,cf.getchar(blox,bloy),true));
                erasing=true;
            }
        }
        else
        {
            if(control) // Selection going on
            {
                if(mouseButton==LEFT) // Mark an area
                {
                    if(firstsel || selectmode==2)
                    {
                        firstsel=false;
                        selx=blox;
                        sely=bloy;
                    }
                    selw=blox-selx+1;
                    selh=bloy-sely+1;
                    if(selw<0)
                        selw=0;
                    if(selh<0)
                        selh=0;
                    
                    if(selx==-1 || sely==-1) // Dunno when exactly this happens, but it does
                        selw=selh=0;
                     
                    // Copy automatically
                    for(int i=0,k=0;i<selh;i++)
                        for(int j=0;j<selw;j++,k++)
                        {
                            clip_chars[k]=cf.getchar(j+selx,i+sely);
                            clip_colors[k]=cf.getcolor(j+selx,i+sely);
                        }
                        
                    selectmode=1;
                }
                else // Pick individual characters
                {
                    if(firstsel || selectmode==1)
                    {
                        firstsel=false;
                        
                        if(selectmode!=2)
                        {
                            for(int i=0;i<X*Y;i++)
                                clip_chars[i]=-1;
                            selw=X;
                            selh=Y;
                            selx=sely=-1;
                        }
                        
                        if(clip_chars[blox+bloy*X]==-1)
                            selectadd=true;
                        else
                            selectadd=false;
                    }
                    
                    if(selectadd)
                    {
                        clip_chars[blox+bloy*X]=cf.getchar(blox,bloy);
                        clip_colors[blox+bloy*X]=cf.getcolor(blox,bloy);
                    }
                    else
                        clip_chars[blox+bloy*X]=-1;
                    
                    selectmode=2;
                }
            }
            else // Normal operation
            {
                cursorx=blox; // Let's set this, too
                cursory=bloy;
                
                if(mouseButton==LEFT && !oldcontrol)
                {
                    if(selw>0 && selh>0) // Draw with selection
                    {
                        for(int i=0,k=0;i<selh;i++)
                        {
                            for(int j=0;j<selw;j++,k++)
                            {
                                int x=blox-selw/2+j,
                                    y=bloy-selh/2+i;

                                if(x>=0 && y>=0 && x<X & y<Y && clip_chars[k]!=-1)
                                {
                                    if(shift==1) // Just color
                                    {
                                        cf.setcolor(x,y,pen);
                                    }
                                    else
                                    {
                                        cf.setchar(x,y,clip_chars[k]);
                                        if(shift!=2)
                                            cf.setcolor(x,y,clip_colors[k]);
                                    }
                               }
                            }
                        }
                    }
                    else // Plain normal char drawing
                    {
                        if(shift!=1)
                            cf.setchar(blox,bloy,current);
                        if(shift!=2)
                            cf.setcolor(blox,bloy,pen);
                    }
                }
                if(mouseButton==prefs.PICKERBUTTON)
                {
                    if(shift!=1)
                    {
                        current=cf.getchar(blox,bloy);
                        for(int i=0;i<cset.charactercount;i++)
                            if(cset.remap[i]==current)
                                curidx=i;
                    }
                    if(shift!=2)
                        pen=cf.getcolor(blox,bloy);
                }
                if(mouseButton==prefs.ERASEBUTTON && !oldcontrol) // Erase
                {
                    if(selw>0 && selh>0) // Erase with selection
                    {
                        for(int i=0;i<selh;i++)
                        {
                            for(int j=0;j<selw;j++)
                            {
                                int x=blox-selw/2+j,
                                    y=bloy-selh/2+i;
                                    
                                if(x>=0 && y>=0 && x<X & y<Y && clip_chars[i*selw+j]!=-1)
                                {
                                    cf.setchar(x,y,cset.erasechar);
                                    cf.setcolor(x,y,machine.erasecolor);
                                }
                            }
                        }
                        erasing=true;
                    }
                    else
                    {
                        cf.setchar(blox,bloy,cset.erasechar);
                        cf.setcolor(blox,bloy,machine.erasecolor);
                        erasing=true;
                    }
                }
            }
        }
    }
    else
    {
        if(!control || selectmode==2) // Let's not lose the selection
        {
            firstsel=true;
            firstclick=true;
            oldcontrol=false;
        }
    }
    
    // Color selector
    if(mousePressed && incolorsel())
        machine.colorselclicks();
    
    // Char selector
    if(mousePressed && incharsel() && (mouseButton==LEFT || mouseButton==prefs.PICKERBUTTON) && !control)
    {
        curidx=(mouseX-col2_start)/machine.charx+(mouseY-charsel_start)/machine.chary*16;
        current=cset.remap[curidx];
        
        if(selw>0 && selh>0) // Make holes to selected char
        {
            boolean found=false;
            for(int i=0;i<selw*selh;i++)
            {
                if(clip_chars[i]==current)
                {
                    clip_chars[i]=-1;
                    found=true;
                }
            }
            if(found)
                optimize_clip();
        }
    }
    
    if(mousePressed && typing>0) // Only move the cursor
    {
        if(mouseButton==LEFT && infield())
        {
            cursorx=blox;
            cursory=bloy;
        }
    }
    
    if(!control) // Hide the original selection
    {
        selx=-1;
        sely=-1;
        
        if(selectmode==2)
        {
            selw=X;
            selh=Y;
            optimize_clip(); 
        }
        selectmode=0;
    }
    else
        oldcontrol=true;
    
    // Show what's coming if you click
    if(typing==0 && infield())
    {
        // Show the upcoming character
        if(!control && (selw<=0 || selh<=0))
        {
            if(shift==1)
            {
                cset.drawchar(canvasx(blox),canvasy(bloy), cf.getchar(blox,bloy),pen,cf.bg);
            }
            else
            {
                int tmp=current;
                if(erasing)
                    tmp=cset.erasechar;
                
                if(shift==2)
                    cset.drawchar(canvasx(blox),canvasy(bloy), tmp,cf.getcolor(blox,bloy),cf.bg);
                else
                    cset.drawchar(canvasx(blox),canvasy(bloy), tmp,pen,cf.bg);
            }
        }
        
        // Show in pixel mode
        if(alt)
        {
            if(shift!=2)
                cset.drawchar(canvasx(blox),canvasy(bloy), cf.getchar(blox,bloy),pen,cf.bg);
            if(shift!=1)
                cset.drawchar(canvasx(blox),canvasy(bloy), cset.pixellogic(mouseX,mouseY,cf.getchar(blox,bloy),erasing),pen,cf.bg);
        }
        
        // Show selection
        if(selw>0 && selh>0 && !control)
        {
            int halfx=blox-selw/2,
                halfy=bloy-selh/2;
            
            for(int i=0,k=0;i<selh;i++)
            {
                for(int j=0;j<selw;j++,k++)
                {
                    int x=halfx+j,
                        y=halfy+i;
                        
                    if(x>=0 && y>=0 && x<X & y<Y && clip_chars[k]!=-1)
                    {   
                        if(shift==1) // Color with selection
                        {
                            cset.drawchar(canvasx(x),canvasy(y), cf.getchar(x,y),pen,cf.bg);
                        }
                        else
                        {
                            if(erasing)
                                cset.drawchar(canvasx(x),canvasy(y), cset.erasechar,pen,cf.bg);
                            else
                            {
                                if(shift==2)
                                    cset.drawchar(canvasx(x),canvasy(y), clip_chars[k],cf.getcolor(x,y),cf.bg);
                                else
                                    cset.drawchar(canvasx(x),canvasy(y), clip_chars[k],clip_colors[k],cf.bg);
                                    
                            }
                        }
                    }
                }
            }
        }
    }
    
    // The grid
    if(prefs.grid)
    {
        for(int x=0;x<X;x++)
            vline(canvasx(x)-1,canvas_start, canvas_end-1);
        vline(canvasx(X),canvas_start, canvas_end-1);
        
        for(int y=0;y<Y;y++)
            hline(col1_start,canvasx(X)-1, canvasy(y)-1);
        hline(col1_start,canvasx(X), canvas_end);
    }
    
    updatePixels();
    
    if(typing>0) // Show the cursor
    {
        if((millis()/250&1)==0)
        {
            fill(0x90ff0000);
            rect(canvasx(cursorx),canvasy(cursory), machine.charx,machine.chary);
        }
    }
    else
    {
        // Show selection
        if(selw>0 && selh>0)
        {
            if(control)
            {
                if(selectmode==1) // Normal selection
                {
                    noFill();
                    if(mousePressed)
                        stroke(255,30,30,160);
                    else
                        stroke(0,255,0,120);
                    rect(canvasx(selx)-1,canvasy(sely)-1, selw*machine.charx,selh*machine.chary);
                    noStroke();
                }
                if(selectmode==2) // Individual characters
                {
                    fill(0x80ff0000);
                    for(int y=0,i=0;y<Y;y++)
                        for(int x=0;x<X;x++,i++)
                            if(clip_chars[i]!=-1)
                                rect(canvasx(x),canvasy(y), machine.charx,machine.chary);
                }
            }
        
            // Show paste target
            if(infield() && !control)
            {
                int halfx=blox-selw/2,
                    halfy=bloy-selh/2;
                    
                int left=  max(canvasx(halfx)-1,    col1_start),
                    top=   max(canvasy(halfy)-1,    canvas_start),
                    right= min(canvasx(halfx+selw), col1_end),
                    bottom=min(canvasy(halfy+selh), canvas_end);
                
                noFill();
                stroke(0,255,0,160);
                rect(left,top,right-left-1,bottom-top-1);
            }
        }
    }
    
    if(ref>0) // Draw the reference image
    {
        tint(255,255,255,ref*255/3);
        image(reference,col1_start,canvas_start, X*machine.charx,Y*machine.chary);
        tint(255);
    }
    
    // Selected char
    stroke(#ff0000);
    noFill();
    rect(selectx-1,selecty-1,machine.charx,machine.chary);
    noStroke();
    
    // Color selector
    machine.drawcolorselector(col2_start,colorsel_start,pen,cf.bg,cf.border);

    if(prefs.info)
        showinfo();
    
    drawbuttons();
    
    anim_frames(canvas_start+3*16,col1_end-207);
    
    user_draw(); // Call user's additions
    
    // Crosshair!
    if(prefs.crosshair)
    {
        stroke(255,100,100,128);
        if(infield())
        {
            line(mouseX,canvas_start, mouseX,canvas_end);
            line(col1_start,mouseY, col1_end,mouseY);
        }
    }

    cf.updatethumb();
    
    if(secondframe!=null)
        miniwin_refresh();
    
    if(prefs.debug)
    {
        int millis2=millis();    
        avgms=(9*avgms+float(millis2-millis1))/10;
        
        if(frameCount%20==0)
            message(str(avgms)+" ms "+str(frameRate));
    }
     
    if(prefs.debug && (frameCount&60)==0)
    {
        println("max/total/free:");
        println(Runtime.getRuntime().maxMemory());
        println(Runtime.getRuntime().totalMemory());
        println(Runtime.getRuntime().freeMemory());
    }
}
