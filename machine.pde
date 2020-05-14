
// Generic class for machines

class Machine
{
    int rgb[],
        shift[][],
        grow[][];
        
    int erasecolor,
        defaultbg,
        defaultborder,
        green,         // For loading PET images
        maxpen,maxborder,maxbg,
        csheight,csrows,
        nativex,nativey,
        charx,chary,
        machine;

    String machinename,
           remapfile,
           fontfile,
           setfile;
           
    final int default_grow[][]={{32,100,111,121,98,248,247,227,160,228,239,249,226,120,119,99}, // For thin charset
                                {32,101,116,117,97,246,234,231,160,229,244,245,225,118,106,103},
                                {224,160}, // Replacements
                                {96,32}};
                                
    final int thick_grow[][]={{32,100,111,121,98,248,247,227,160,228,239,249,226,120,119,99}, // For thick charset
                                {32,101,117,97,246,231,160,229,245,225,118,103},
                                {224,160}, // Replacements
                                {96,32},
                                {116,101},
                                {106,103},
                                {244,229},
                                {234,231}};
           
    final String NOT_IMPLEMENTED="Feature not implemented for this machine.";
    
    boolean palettemode,
            lowercase;
    
    Machine()
    {
    }
    
    // Set lower or upper case
    void setcase(boolean keis)
    {
    }

    // Draw the color selector and its markers
    void drawcolorselector(int px,int py,int pen,int bg,int border)
    {
        if(!palettemode)
            return;

        for(int x=0;x<rgb.length;x++)
        {
            fill(rgb[x]);
            rect(px+(x%16)*charx,py+x/16*csheight, charx,csheight);
        }
    
        stroke(128);
        noFill();
        if(rgb.length<16)
            rect(px,py, rgb.length*charx,csrows*csheight);
        else
            rect(px,py, 16*charx,csrows*csheight);

        // Active color markers
        stroke(#ff0000);
        rect(px+charx*(pen%16),py+(pen/16)*csheight, charx,csheight);
        noStroke();

        fill(#ff0000);
        int x=px+charx*(bg%16),
            y=py+bg/16*csheight;
        triangle(x,y, x,y+6, x+6,y);
        
        x=px+charx*(border%16)+charx;
        y=py+cf.border/16*csheight+csheight;
        triangle(x,y, x,y-6, x-6,y);
    }
    
    // Handle mouse on color selector
    void colorselclicks()
    {
        int cindex=(mouseX-col2_start)/charx%16 + (mouseY-(colorsel_start))/csheight*16;
        
        if(control)
        {
            // Hidden feature! Remap current pen to clicked
            if(cindex<=maxpen && pen!=cindex)
            {
                cf.undo_save();
                if(selw>0 && selh>0) // Selection
                {
                    for(int i=0;i<selw*selh;i++)
                        if(clip_colors[i]==pen)
                            clip_colors[i]=cindex;
                }
                else // Whole piccy
                {
                    for(int i=0;i<X*Y;i++)
                        if(cf.getcolor(i)==pen)
                            cf.setcolor(i,cindex);
                }
                pen=cindex;
            }
        }
        else
        {
            if(mouseButton==LEFT && cindex<=maxpen)
                pen=cindex;
            if(mouseButton==prefs.PICKERBUTTON && cindex<=maxborder)
                cf.setborder(cindex);
            if(mouseButton==prefs.ERASEBUTTON && cindex<=maxbg)
                cf.setbg(cindex);
        }
    }
    
    // Load a piccy
    boolean load_c(String name,boolean merge)
    {
        String lines[]=loadStrings(name);
        
        int loadx=0,loady=0;                 // Load dimensions - might not be equal to the screen
            
        boolean lower=false;
        
        Machine sourcemachine=this;
        
        if(lines==null)
            return false;
            
        if(!lines[0].substring(0,13).equals("unsigned char")) // Not an image!
        {
            message("Invalid image!");
            return false;
        }
        
        // New images have metadata in the end
        if(lines[lines.length-1].length()>8 && lines[lines.length-1].substring(0,8).equals("// META:"))
        {
            String metadata[]=splitTokens(lines[lines.length-1]," ");
    
            loadx=int(metadata[2]);
            loady=int(metadata[3]);
            
            for(int i=0;i<machinenames.length;i++)
                if(metadata[4].equals(machinenames[i]))
                {
                    switch(i)
                    {
                        case C64:   sourcemachine=new C64(); break;
                        case C64FLICKER: sourcemachine=new C64flicker(); break;
                        case VIC20: sourcemachine=new Vic20(); break;
                        case PET:   sourcemachine=new Pet(); break;
                        case PETHI: sourcemachine=new Pethi(); break;
                        case PLUS4: sourcemachine=new Plus4(); break;
                        default: ;
                    }
                }
                    
            if(metadata.length>5)
                if(metadata[5].equals("lower"))
                    lower=true;
        }
        else // Default sizes
        {
            loadx=nativex;
            loady=nativey;
        }
        
        if(!merge)
        {
            frame.setTitle(name+" ("+str(X)+"x"+str(Y)+")");
        
            anim_init();
            cf.undo_purge();
            currentframe=-1;
        }
        
        String s[];
        int i=0,defaultcolor=erasecolor;
        boolean cont=true;
        
        while(cont)
        {            
            if(i<lines.length && lines[i].substring(0,13).equals("unsigned char")) // Another frame
            {
                currentframe++;
                if(currentframe!=0) // 1st one is there
                    addframe(currentframe);
                setframe(currentframe);
                
                i++;
                if(sourcemachine.palettemode)
                {
                    s=splitTokens(lines[i],",");
                    i++;
                
                    cf.setborder(int(s[0]));
                    cf.setbg(int(s[1]));
                }
                else
                {
                    cf.setborder(0);
                    cf.setbg(0);
                }
                
                // Clear the frame
                for(int j=0;j<X*Y;j++)
                {
                    cf.setchar(j,cset.erasechar);
                    cf.setcolor(j,defaultcolor);
                }
                
                for(int y=0;y<loady && i<lines.length;y++,i++)
                {
                    if(y<Y) // Crop too big images
                    {
                        s=splitTokens(lines[i],",");
                        for(int x=0;x<X && x<s.length;x++)
                            cf.setchar(x,y,int(s[x]));
                    }
                }
                for(int y=0;y<loady && i<lines.length && sourcemachine.palettemode;y++,i++)
                {
                    if(y<Y) // Crop too big images
                    {
                        s=splitTokens(lines[i],",");
                        for(int x=0;x<X && x<s.length;x++)
                            cf.setcolor(x,y,int(s[x]));
                    }
                }
                i++;

                if(machine!=sourcemachine.machine)
                    remapcolors(sourcemachine);                
                   
                cf.updatethumb();
            }
            else
                cont=false;
        }
        
        setframe(0);
        if(lowercase!=lower || machine!=sourcemachine.machine)
        {
            setcase(lower);
            cset=new Petscii(fontfile,remapfile,setfile);
            cset.initrender(charx,chary);
            current=cset.remap[curidx];
        }
        cset.shift=shift; // Need to do this properly later
        cset.grow=grow;
        
        message("Loaded "+name+", size "+str(loadx)+"x"+str(loady)+" chars");
        return true;
    }

    // Fix colors between machines
    void remapcolors(Machine other)
    {
        if(machine==other.machine) // No need to do anything
            return;
        
        if(palettemode && !other.palettemode)
        {
            cf.bg=0;
            cf.border=0;
            for(int i=0;i<X*Y;i++)
                cf.setcolor(i,green);
            
            return;
        }
        
        // Automatically find the closest colors
        int remaptable[]=new int[other.rgb.length];

        for(int i=0;i<remaptable.length;i++)
        {
            int diffi=10000000,idx=0;
            for(int j=0;j<rgb.length;j++)
                if(rgbdistance(other.rgb[i],rgb[j])<diffi)
                {
                    diffi=rgbdistance(other.rgb[i],rgb[j]);
                    idx=j;
                }
            remaptable[i]=idx;
        }
        
        for(int i=0;i<X*Y;i++)
        {
            if(cf.getcolor(i)<remaptable.length)
                cf.setcolor(i,remaptable[cf.getcolor(i)]);
        }
        
        cf.setbg(remaptable[cf.bg]);
        cf.setborder(remaptable[cf.border]);
    }
    
    // Save a piccy (C array)
    void save_c(String name,boolean selfcontained)
    {
        if(selfcontained)
        {
            save_c_viewer(name);
            return;
        }
        
        PrintWriter f=safeWriter(name);
        if(f==null)
            return;

        if(!name.equals(prefs.backupfile))
            frame.setTitle(name+" ("+str(X)+"x"+str(Y)+")");
    
        for(int i=0;i<framecount;i++) // Save each frame
        {
            Frame fr;
            fr=frames.get(i);
            
            f.print("unsigned char frame"+hex(i,4)+"[]={");
            if(palettemode)
            {
                f.println("// border,bg,chars,colors");
                f.println(str(fr.border)+","+str(fr.bg)+",");
            }
            else
                f.println();
            
            for(int y=0;y<Y;y++)
            {
                for(int x=0;x<X;x++)
                    f.print(str(fr.getchar(x,y))+",");
                f.println();
            }
            for(int y=0;palettemode && y<Y;y++)
            {
                for(int x=0;x<X;x++)
                {
                    f.print(str(fr.getcolor(x,y)));
                    if(y!=Y-1 || x!=X-1)
                        f.print(",");
                }
                f.println();
            }
            f.println("};");
        }
        
        // Metadata in a comment
        String keis="upper";
        if(lowercase)
            keis="lower";
        f.println("// META: "+str(X)+" "+str(Y)+" "+machinename+" "+keis);
        
        f.flush();
        f.close();
        
        message("Written "+name);
    }
        
    // Dump the image as PNG
    final int DBORDER=16; // Border width for screenshots
    
    void save_png(String name,Frame f,boolean borderi)
    {
        PImage p;
        int rowlen=cset.xsize*X,
            xoff=0,
            yoff=0;
        
        if(borderi)
        {
            rowlen+=DBORDER*2;
            xoff=DBORDER;
            yoff=DBORDER*rowlen;
            p=createImage(cset.xsize*X+DBORDER*2,cset.ysize*Y+DBORDER*2,RGB);
        }
        else
            p=createImage(cset.xsize*X,cset.ysize*Y,RGB);
        p.loadPixels();
        
        if(borderi)
            for(int i=0;i<p.pixels.length;i++)
                p.pixels[i]=rgb[f.border];
                
        cset.bitmap.loadPixels();
        
        for(int y=0;y<Y;y++) // Walk through chars
        {
            for(int x=0;x<X;x++)
            {
                int ch=f.getchar(x,y);
                for(int row=0;row<cset.ysize;row++)
                    for(int col=0;col<cset.xsize;col++)
                    {
                        int off=ch*cset.xsize+col+row*cset.charactercount*cset.xsize,
                            i=y*rowlen*cset.ysize +row*rowlen+ x*cset.xsize +col +xoff+yoff;
                            
                        if((cset.bitmap.pixels[off]&0xff) > 20) // Pixel on
                            p.pixels[i]=rgb[f.getcolor(x,y)];
                        else                    
                            p.pixels[i]=rgb[f.bg];
                    }
            }
        }
        
        p.updatePixels();
        p.save(name);
        
        message("Written "+name);
    }
    
    // Importer stub
    void import_prg(String name)
    {
        message(NOT_IMPLEMENTED);
    }
    
    // Various exporter stubs
    void save_c_viewer(String name)
    {
        message(NOT_IMPLEMENTED);
    }
    void save_bas(String name)
    {
        message(NOT_IMPLEMENTED);
    }   
    void save_asm(String name,boolean selfcontained)
    {
        message(NOT_IMPLEMENTED);
    }    
    void save_prg(String name)
    {
        message(NOT_IMPLEMENTED);
    }    
    void save_seq(String name)
    {
        message(NOT_IMPLEMENTED);
    }
}
