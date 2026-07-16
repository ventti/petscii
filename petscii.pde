/*
  A PETSCII drawing app. Originally made for the Zoo'13 PETSCII compo, because I couln't find anything suitable for Linux/Mac. 
  
  See here: http://www.kameli.net/marq/?page_id=2717
  Changelog can be found on log.pde

  - Marq/Fit^L!T^Dkd, with additions from Dr. TerrorZ/L!T, further annihilated by Vent/Extend
*/

import processing.awt.*;
import java.awt.Frame;

PreviewWindow prevWin;
processing.awt.PSurfaceAWT pWin;

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
        dirty=false,         // Unsaved work
        exitpressed=false,   // Window close requested (handled in requesters())
        resizing=false;      // A machine switch resized the window; wait for it to settle

// Deferred UI commands. Buttons and file-dialog callbacks post() commands here;
// runCommands() drains them on the animation thread (from requesters()), so all
// dialogs and charset/canvas mutations happen off the AWT event thread, avoiding
// races with draw(). Replaces the old pile of boolean "event" flags.
java.util.ArrayList<Runnable> commandQueue=new java.util.ArrayList<Runnable>();

int charsetPrgAddr=0x3800; // Load address for the exported charset .prg

int charsetSaveCPR=16; // Chars per row for the saved charset .png

float   avgms=0; // For profiling
int     blink=0;

String filename="",refname="",
       curmessage="";

PImage reference;
PFont  font;

// Somewhat bad mouse hack to work around bad event handling that I did initially
boolean shadowPressed=false;
int shadowButton=0;

// UI parameters
int    col1_start,col1_end, // x
       col2_start,col2_end,
       buttons_start,
       canvas_start,canvas_end, // y
       colorsel_start,
       charsel_start,charsel_end,
       anim_start, // Anim frames
       anim_end,
       winW,winH,  // Computed window size (for size() and runtime resize)
       defaultzoom=2, // Zoom to restore with the "Zoom" button (set from prefs)
       dragw,dragh,resizesettle=0; // Drag-to-zoom: track a settled user window resize

// UI buttons
Button load_b,merge_b,save_b,saveas_b,ref_b,
       import_prg_b,export_prg_b,export_png_b,clear_b,preview_b,
       dupleft_b,dupright_b,cut_b,pasteleft_b,pasteright_b,
       undo_b,redo_b,grid_b,case_b,charset_b,charset_refresh_b,charset_save_b,charset_prg_b,image_b,machine_b,zoom_b;

void settings() // Need to have this in Processing 3.x
{
    // Load prefs
    prefs=new Preferences();
    prefs.readprefs(prefs.PREFSFILE);
    filename=prefs.FILENAME;
    defaultzoom=prefs.zoom; // Remember the configured zoom for the "Zoom" reset button

    javatheme(); // Choose look and feel for fileselectors and popups
    
    if(prefs.machine==-1)
        prefs.machine=selector("Select a platform","C-64,C-64 flicker,Dir Art,PET 40x25,PET 80x25,Plus/4,VIC-20");
    delay(200); // Superstition? 
    
    init_machine_instance(prefs.machine); // Builds machine + its charset

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

    prefs.bwidth=prefs.BWIDTH*prefs.zoom; // Border width scales with zoom
    compute_layout();
    size(winW, winH);
    noSmooth();
}

// Instantiate the machine (and, via its constructor, the charset) for a platform id.
void init_machine_instance(int m)
{
    switch(m)
    {
        case C64:   machine=new C64(); break;
        case C64FLICKER: machine=new C64flicker(); break;
        case DIRART: machine=new Dirart(); break;
        case PET:   machine=new Pet(); break;
        case PETHI: machine=new Pethi(); break;
        case PLUS4: machine=new Plus4(); break;
        case VIC20: machine=new Vic20(); break;
        default: machine=new C64();
    }
    cset.shift=machine.shift; // Need to do this properly later
    cset.grow=machine.grow;
}

// Compute all UI layout coordinates and the resulting window size (winW/winH)
// from the current machine, X and Y. Does not resize the window (see size()
// in settings() for startup and surface.setSize() in switch_machine()).
void compute_layout()
{
    // Various UI locations: x
    col1_start=prefs.bwidth;
    col1_end=col1_start+max(X*machine.charx,prefs.ANWIDTH); // fit 2 frames at least

    if(16*machine.charx>prefs.UIWIDTH) // Charsel wider than buttonbar
    {
        col2_start=col1_end+prefs.bwidth;
        buttons_start=col2_start+8*machine.charx-prefs.UIWIDTH/2;
    }
    else
    {
        buttons_start=col1_end+prefs.bwidth;
        col2_start=buttons_start+prefs.UIWIDTH/2-8*machine.charx;
    }
    col2_end=col1_end+prefs.bwidth+max(16*machine.charx,prefs.UIWIDTH);       // Buttons or char selector

    // y
    canvas_start=max(prefs.bwidth+Y, prefs.UIROW+prefs.bwidth); // Anim frame + border or buttons + border
    canvas_end=canvas_start+Y*machine.chary;
    colorsel_start=canvas_start+5*prefs.UIROW+5; // 5 button rows above the colour selector
    charsel_start=colorsel_start+machine.csheight*machine.csrows+prefs.UIROW+1;
    charsel_end=charsel_start+cset.charactercount/16*machine.chary;

    winW=col2_end+prefs.bwidth;
    winH=max(charsel_end+prefs.UIROW+prefs.bwidth, canvas_end+prefs.UIROW+prefs.bwidth);

    // Anim frames' location
    anim_start=col1_start+70;
    anim_end=col1_end-216;

    if((anim_end-anim_start)/X<6) // if we can't fit enough frames in the normal location
        if(anim_end-anim_start < col2_end-(col1_end+prefs.bwidth)) // And there is more space on the right...
        {
            anim_start=col1_end+prefs.bwidth+4; // Put the frames on the right
            anim_end=col2_end;
        }
}

void setup()
{
    // A hack required to catch window close events
    PSurfaceAWT.SmoothCanvas sur=(PSurfaceAWT.SmoothCanvas)surface.getNative();
    JFrame j=(JFrame)sur.getFrame();
    j.setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
    surface.setResizable(true); // Allow drag-to-zoom (handled in draw())
    dragw=winW; dragh=winH;

    frameRate(prefs.framerate);
    noStroke();
    
    font=loadFont(prefs.FONTFILE);
    textFont(font);
    
    anim_init();

    create_buttons();

    // autoload this image on startup
    if (prefs.inputfile != "")
    {
      filename = prefs.inputfile;
      machine.load_c(filename, false);
    }

    surface.setTitle(filename+" ("+str(X)+"x"+str(Y)+")");
    
    user_setup(); // Call users' own functions
    prevWin = new PreviewWindow(X,Y); // Build two, but show only one
    backupcounter=millis();
    loadPixels();
}

// (Re)create every UI button at the current layout coordinates. Buttons register
// themselves in the global butts list, so clear it first to avoid duplicates when
// switching machines. Fresh buttons are enabled; ownbuttons() re-disables the
// features the current machine does not support.
void create_buttons()
{
    butts.clear();

    load_b=new Button(buttons_start,canvas_start,"Load", "Load a PETSCII image (.c)");
    merge_b=new Button(buttons_start+49,canvas_start,"Merge", "Merge a PETSCII image (.c) into the current one");
    save_b=new Button(buttons_start+107,canvas_start,"Save", "Save the image over the current file (.c)  [s]");
    saveas_b=new Button(buttons_start+156,canvas_start,"Save as", "Save the image to a new file (.c)");
    ref_b=new Button(buttons_start+228,canvas_start,"Ref.", "Load a reference image to trace over");

    import_prg_b=new Button(buttons_start,canvas_start+prefs.UIROW,"Load .prg", "Import a C64 .prg screen");
    export_prg_b=new Button(buttons_start+79,canvas_start+prefs.UIROW,"Save .prg", "Export the image as a C64 .prg  [e]");
    export_png_b=new Button(buttons_start+158,canvas_start+prefs.UIROW,".png", "Export the image as a .png screenshot  [p]");
    preview_b=new Button(buttons_start+200,canvas_start+prefs.UIROW,"Preview", "Toggle the 1:1 pixel preview window");

    undo_b=new Button(buttons_start,canvas_start+prefs.UIROW*2,"Undo", "Undo the last change  [u]");
    redo_b=new Button(buttons_start+50,canvas_start+prefs.UIROW*2,"Redo", "Redo the last undone change  [Shift-U]");
    clear_b=new Button(buttons_start+113,canvas_start+prefs.UIROW*2,"Clear", "Clear the canvas");
    grid_b=new Button(buttons_start+175,canvas_start+prefs.UIROW*2,"Grid", "Toggle the character grid  [g]");
    case_b=new Button(buttons_start+218,canvas_start+prefs.UIROW*2,"Case", "Toggle upper/lower case charset");

    charset_b=new Button(buttons_start,canvas_start+prefs.UIROW*3,"Charset", "Load a charset .png (grid of up to 256 8x8 chars)");
    charset_refresh_b=new Button(buttons_start+68,canvas_start+prefs.UIROW*3, "Refresh", "Refresh (reload) the loaded charset");
    image_b=new Button(buttons_start+136,canvas_start+prefs.UIROW*3, "Image", "Trace an image into a generated charset and onto the canvas");
    charset_save_b=new Button(buttons_start+188,canvas_start+prefs.UIROW*3, "PNG", "Save the current charset as a .png");
    charset_prg_b=new Button(buttons_start+224,canvas_start+prefs.UIROW*3, "PRG", "Save the charset as a C64 .prg (load address + 2KB data)");

    machine_b=new Button(buttons_start,canvas_start+prefs.UIROW*4,"Machine", "Switch machine (discards unsaved work)");
    zoom_b=new Button(buttons_start+68,canvas_start+prefs.UIROW*4,"Zoom", "Reset zoom to default (Ctrl+1..8 to set); drag the window edge to zoom");

    dupleft_b=new Button(col1_end-207,canvas_start-26,"< Dup", "Duplicate this frame to the left");
    dupright_b=new Button(col1_end-152,canvas_start-26," >", "Duplicate this frame to the right  [d]");
    cut_b=new Button(col1_end-126,canvas_start-26,"Cut", "Cut this frame to the clipboard");
    pasteleft_b=new Button(col1_end-89,canvas_start-26,"< Paste", "Paste the clipboard frame to the left");
    pasteright_b=new Button(col1_end-22,canvas_start-26," >", "Paste the clipboard frame to the right");

    // Disable and change not implemented buttons
    machine.ownbuttons();
}

// Switch to another machine at runtime. This is destructive: it starts a fresh,
// native-sized document for the new platform (charset, colors, resolution, window
// size, layout and buttons are all rebuilt). Confirmation for unsaved work is
// handled by the caller (see requesters()).
void switch_machine(int m)
{
    init_machine_instance(m);   // New machine + charset
    prefs.machine=m;

    // Fresh, native-sized document for the new platform
    X=machine.nativex;
    Y=machine.nativey;
    current=cset.remap[curidx];

    cf=new Frame();
    cf.setbg(machine.defaultbg);
    cf.setborder(machine.defaultborder);
    pen=machine.erasecolor;

    clip_chars=new int[X*Y];
    clip_colors=new int[X*Y];
    anim_init(); // Rebuild the frame list around the new cf

    // Reset transient editing state that may reference the old geometry
    selw=selh=0;
    typing=0;
    floodfill=0;
    filename=prefs.FILENAME;
    dirty=false;

    compute_layout();
    surface.setSize(winW, winH);
    create_buttons();

    // Freeze any open preview: its buffer is sized for the old resolution and
    // references the now-resized frame. Stop it rendering; it is rebuilt at the
    // correct size the next time the user opens it (see showPreview()). We must
    // NOT dispose/recreate windows here: doing AWT window lifecycle work on the
    // animation thread while the main window is resizing corrupts the render
    // buffer strategy (IllegalStateException: Component must have a valid peer).
    if(prevWin!=null)
    {
        prevWin.vis=false;
        prevWin.noLoop();
    }

    surface.setTitle(filename+" ("+str(X)+"x"+str(Y)+")");
    // surface.setSize() is asynchronous: width/height and pixels[] are not updated
    // until the AWT resize is applied on a later frame. Defer touching pixels[]
    // (see the resize-settle guard in draw()) to avoid writing past a stale buffer.
    resizing=true;
    message("Switched to "+machinenames[m]);
    repaint=true;
}

// Open the 1:1 preview window, (re)creating it if its size no longer matches the
// current machine's resolution. Done lazily here (never during a machine switch)
// so window teardown/creation can't race the main window's resize.
void showPreview()
{
    if(prevWin==null || prevWin.x!=X || prevWin.y!=Y)
    {
        if(prevWin!=null)
            prevWin.dispose();
        prevWin=new PreviewWindow(X,Y);
    }
    prevWin.show();
}

// Re-render the current machine at a new integer zoom. Non-destructive: the
// artwork (frames), custom charset and case are all preserved; only the char
// size, charset render, layout and window size change.
void apply_zoom(int z)
{
    z=constrain(z,1,prefs.MAXZOOM);
    if(z==prefs.zoom && width==winW && height==winH)
        return; // nothing to do

    prefs.zoom=z;
    prefs.bwidth=prefs.BWIDTH*z;

    // Preserve charset customisation and case across the machine re-init
    String savedfont=machine.fontfile, savedremap=machine.remapfile, savedset=machine.setfile;
    boolean savedcase=machine.lowercase;

    init_machine_instance(prefs.machine); // Recomputes charx/chary for the new zoom

    machine.fontfile=savedfont;
    machine.remapfile=savedremap;
    machine.setfile=savedset;
    machine.lowercase=savedcase;
    machine.init_charset(); // Re-render the (custom) charset at the new char size

    compute_layout();
    surface.setSize(winW,winH);
    create_buttons();
    // Preview is 1:1 (zoom-independent), so it needs no rebuild here.
    resizing=true; // Wait for the async resize to settle before drawing (see draw())
    repaint=true;
    message("Zoom x"+z);
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
    
    requesters(); // File open/save and other dialogs

    // Drag-to-zoom: the window is resizable. While the actual window size differs
    // from our layout size the user is dragging its edge; we must NOT render then
    // (pixels[] would be stale vs width*height). Once the size settles for a few
    // frames, snap to the nearest integer zoom (or back to the exact layout size).
    if(!resizing && (width!=winW || height!=winH))
    {
        if(width==dragw && height==dragh)
            resizesettle++;
        else
        {
            resizesettle=0;
            dragw=width; dragh=height;
        }
        if(resizesettle>=4) // stable -> the drag has finished
        {
            resizesettle=0;
            float ratio=((float)width/winW + (float)height/winH)/2.0;
            int nz=constrain(round(prefs.zoom*ratio),1,prefs.MAXZOOM);
            if(nz!=prefs.zoom)
                apply_zoom(nz);             // rescale content to the new zoom
            else
            {
                surface.setSize(winW,winH); // no zoom change: snap back to exact size
                resizing=true;
            }
        }
        return; // don't draw while the window size is inconsistent
    }

    // A programmatic resize (zoom or machine switch) is in flight. Don't render
    // until the window and its pixel buffer are consistent at the target size,
    // otherwise the layout writes past a stale pixels[] array. Placed BEFORE the
    // repaint gate so it always runs while resizing (even if repaint is false).
    if(resizing)
    {
        loadPixels(); // grab whatever the (possibly mid-resize) graphics buffer is now
        if(width!=winW || height!=winH || pixels.length!=width*height)
        {
            surface.setSize(winW,winH); // re-assert target (a single setSize can be dropped)
            return;                     // not settled yet; check again next frame
        }
        resizing=false;
        repaint=true; // force a full redraw at the new size
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
            shadowPressed=true;
            shadowButton=0;
            return;    // And yield too
        }
    }
    else
        focuscount=0;
        
    if(mousePressed)
    {
        shadowPressed=true;
        shadowButton=mouseButton;
    }
    
    // Check if we need to actually refresh the screen
    if(infield())
    {
        if(oldblox!=blox || oldbloy!=bloy)
            repaint=true;
            
        boolean erasing=false;
        if(shadowPressed && shadowButton!=LEFT)
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
        if(incharsel() && shadowPressed)
            repaint=true;
        if(incolorsel() && shadowPressed)
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
    {
        shadowPressed=false;
        shadowButton=0;
        return;
    }
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
    if(shadowPressed && infield() && typing==0 && floodfill==0)
    {       
        if(firstclick)
        {
            // Save an undo step under certain conditions
            if(!control && shadowButton!=prefs.PICKERBUTTON)
                cf.undo_save();
            if(alt && shadowButton==prefs.PICKERBUTTON) // A kludge here 'coz of my window manager
                cf.undo_save();
            firstclick=false;
        }

        if(alt) // "Pixel" drawing mode
        {
            if(shadowButton==LEFT)
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
                if(shadowButton==LEFT) // Mark an area
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
                                clip_chars[i]=HOLE;
                            selw=X;
                            selh=Y;
                            selx=sely=-1;
                        }
                        
                        if(clip_chars[blox+bloy*X]==HOLE)
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
                        clip_chars[blox+bloy*X]=HOLE;
                    
                    selectmode=2;
                }
            }
            else // Normal operation
            {
                cursorx=blox; // Let's set this, too
                cursory=bloy;
                
                if(shadowButton==LEFT && !oldcontrol)
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
                if(shadowButton==prefs.PICKERBUTTON)
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
                if(shadowButton==prefs.ERASEBUTTON && !oldcontrol) // Erase
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
    if(shadowPressed && incolorsel())
        machine.colorselclicks();
    
    // Char selector
    if(shadowPressed && incharsel() && (shadowButton==LEFT || shadowButton==prefs.PICKERBUTTON) && !control)
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
                    clip_chars[i]=HOLE;
                    found=true;
                }
            }
            if(found)
                optimize_clip();
        }
    }
    
    if(shadowPressed && typing>0) // Only move the cursor
    {
        if(shadowButton==LEFT && infield())
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
    if(typing==0 && infield() && !prefs.tablet)
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
                    if(shadowPressed)
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
            if(infield() && !control && !prefs.tablet)
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
    
    anim_frames(anim_start,anim_end); // Draw animation frames
    
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
        
    shadowPressed=false; // Better reset now
    shadowButton=0;
    
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

    if (prevWin.vis)
      prevWin.redraw();

} // Draw end

// Queue a command to run on the animation thread. Safe to call from any thread
// (e.g. AWT file-dialog callbacks).
void post(Runnable c)
{
    synchronized(commandQueue) { commandQueue.add(c); }
}

// Run and clear all queued commands. Called from requesters() on the animation
// thread, so commands never run concurrently with draw().
void runCommands()
{
    java.util.ArrayList<Runnable> batch;
    synchronized(commandQueue)
    {
        if(commandQueue.isEmpty())
            return;
        batch=new java.util.ArrayList<Runnable>(commandQueue);
        commandQueue.clear();
    }
    for(Runnable c: batch)
    {
        c.run();
        repaint=true;
    }
}

void requesters() // Runs deferred UI commands (dialogs / heavy work) on the animation thread
{
    runCommands();

    if(exitpressed) // Trying to close the window, huh?
    {
        if(dirty) // Unsaved work?
        {
            int options=selector("Exit without saving?","Yes,No");
            if(options==0)
                super.exit();
        }
        else
            super.exit();
        
        exitpressed=false;
    }
}

void exit() // Override default exit()
{
    exitpressed=true;
}
