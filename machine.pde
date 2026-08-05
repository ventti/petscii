
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
        id;

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
           
    final String NOT_IMPLEMENTED="Feature not implemented on this platform";
    
    boolean palettemode,
            lowercase;
    
    Machine()
    {
    }
    
    // Set lower or upper case
    void setcase(boolean keis)
    {
    }

    // True when fontfile names a charset the user brought in rather than one of
    // the fonts in data/: loading a charset .png, tracing an image and opening a
    // .petmate with its own font all set an absolute path (see load_charset,
    // trace_image and load_petmate_font), while the built-in fonts are plain
    // data/ filenames.
    boolean loadedfont()
    {
        return fontfile!=null && new File(fontfile).isAbsolute();
    }

    // True when the characters on screen are not the machine's own, whether they
    // came from a file or from a .c that carried its own charset. Exporters care:
    // such a charset is not in ROM, so it has to travel with the picture.
    boolean customfont()
    {
        return curfont!=null;
    }

    // Tail for the "Written ..." message of exporters that cannot carry a charset.
    String fontnote()
    {
        return customfont() ? " (custom charset NOT included)" : "";
    }
    
    void ownbuttons() // Disable not implemented buttons or change some if needed
    {
    }
    
    boolean validate(int c) // Check if this char is ok
    {
        return true;
    }

    // Draw the color selector and its markers
    // Which marker the pointer grabbed in the colour selector: 1 = background,
    // 2 = border, 0 = neither. Dragging a marker is the way to set those two
    // without a middle or right button; see colorselclicks().
    int grabbed=0;
    boolean selheld=false;

    // Marker size, scaled to the swatch so it stays proportional at every zoom
    // and on the machines with short colour rows (Plus/4 packs eight of them).
    int markersize()
    {
        int m=min(charx,csheight)*2/3;

        return m<8 ? 8 : m;
    }

    // Is the pointer on the marker drawn in a swatch's corner: top left for the
    // background, bottom right for the border? Hit-tested as a square, which is
    // both kinder to aim at than the triangle and enough to tell the two apart.
    boolean onmarker(int px,int py,int index,boolean topleft)
    {
        int m=markersize(),
            x=px+charx*(index%16),
            y=py+index/16*csheight;

        if(topleft)
            return mouseX>=x && mouseX<x+m && mouseY>=y && mouseY<y+m;

        return mouseX>x+charx-m && mouseX<=x+charx && mouseY>y+csheight-m && mouseY<=y+csheight;
    }

    void drawcolorselector(int px,int py,int pcol,int bg,int border)
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
        rect(px+charx*(pcol%16),py+(pcol/16)*csheight, charx,csheight);
        noStroke();

        // Both markers are grab handles, so they are drawn big enough to aim at
        fill(#ff0000);
        int m=markersize(),
            x=px+charx*(bg%16),
            y=py+bg/16*csheight;
        triangle(x,y, x,y+m, x+m,y);

        x=px+charx*(border%16)+charx;
        y=py+border/16*csheight+csheight; // the parameter, not cf.border
        triangle(x,y, x,y-m, x-m,y);
    }
    
    // Handle mouse on color selector
    void colorselclicks()
    {
        int cindex=(mouseX-view.col2_start)/charx%16 + (mouseY-(view.colorsel_start))/csheight*16;

        // Work out once per press whether it started on a marker. Held down, the
        // marker then follows the pointer, which is how a one-button mouse sets
        // the background and border - the middle and right button still work.
        if(!selheld)
        {
            selheld=true;
            grabbed=0;

            if(onmarker(view.col2_start,view.colorsel_start,cf.bg,true))
                grabbed=1;
            else if(onmarker(view.col2_start,view.colorsel_start,cf.border,false))
                grabbed=2;
        }

        if(grabbed>0)
        {
            if(grabbed==1 && cindex<=maxbg)
            {
                cf.setbg(cindex);
                dirty=true;
            }
            if(grabbed==2 && cindex<=maxborder)
            {
                cf.setborder(cindex);
                dirty=true;
            }
            return; // A grabbed marker never also sets the pen
        }

        if(control)
        {
            // Hidden feature! Remap current pen to clicked
            if(cindex<=maxpen && tool.pen!=cindex)
            {
                cf.undo_save();
                if(sel.w>0 && sel.h>0) // Selection
                {
                    for(int i=0;i<sel.w*sel.h;i++)
                        if(sel.clip_colors[i]==tool.pen)
                            sel.clip_colors[i]=cindex;
                }
                else // Whole piccy
                {
                    for(int i=0;i<X*Y;i++)
                        if(cf.getcolor(i)==tool.pen)
                            cf.setcolor(i,cindex);
                }
                tool.pen=cindex;
            }
        }
        else
        {
            if(shadowButton==LEFT && cindex<=maxpen)
                tool.pen=cindex;
            if(shadowButton==prefs.PICKERBUTTON && cindex<=maxborder)
            {
                cf.setborder(cindex);
                dirty=true;
            }
            if(shadowButton==prefs.ERASEBUTTON && cindex<=maxbg)
            {
                cf.setbg(cindex);
                dirty=true;
            }
        }
    }
    
    void wheelevent(float e) // Machine-specific wheel event handler
    {
        // Do nothing by default. Might change in the future.
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
            
        if(!lines[0].startsWith("unsigned char")) // Not an image! (bounds-safe on short lines)
        {
            message("Invalid image!");
            return false;
        }
        
        int fileformat=read_format(lines);
        if(fileformat>CFORMAT)
            message("Saved by a newer PETSCII (format "+str(fileformat)+"): loading what is understood");

        // Size, machine and case: a declaration since format 2, the trailing
        // comment before that (and still, for older PETSCII versions).
        String metadata[]=read_meta(lines);

        if(metadata!=null)
        {
            loadx=int(metadata[0]);
            loady=int(metadata[1]);

            for(int i=0;i<machinenames.length;i++)
                if(metadata[2].equals(machinenames[i]))
                {
                    switch(i)
                    {
                        case C64:   sourcemachine=new C64(); break;
                        case C64FLICKER: sourcemachine=new C64flicker(); break;
                        case DIRART: sourcemachine=new Dirart(); break;
                        case PET:   sourcemachine=new Pet(); break;
                        case PETHI: sourcemachine=new Pethi(); break;
                        case PLUS4: sourcemachine=new Plus4(); break;
                        case VIC20: sourcemachine=new Vic20(); break;
                        default: ;
                    }
                }

            if(metadata.length>3)
                if(metadata[3].equals("lower"))
                    lower=true;
        }
        else // Default sizes
        {
            loadx=nativex;
            loady=nativey;
        }

        if(!merge)
        {
            surface.setTitle(name+" ("+str(X)+"x"+str(Y)+")");
        
            anim_init();
            cf.undo_purge();
            currentframe=-1;
        }   
        
        String s[];
        int i=0,defaultcolor=erasecolor,
            firstframe=currentframe+1; // Where this file's frames start (merge!)
        boolean cont=true;

        while(cont)
        {            
            if(i<lines.length && lines[i].startsWith("unsigned char")) // Another frame
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
                
                    if(this.palettemode)
                    {
                        cf.setborder(int(s[0]));
                        cf.setbg(int(s[1]));
                    }
                    else
                    {
                        cf.setborder(this.defaultborder);
                        cf.setbg(this.defaultbg);
                    }
                }
                else
                {
                    cf.setborder(this.defaultborder);
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

                if(id!=sourcemachine.id)
                    remapcolors(sourcemachine);          
                   
                cf.updatethumb();
            }
            else
                cont=false;
        }
        
        // The case switch is picture-wide and resets every frame to the machine's
        // own font, so it has to happen before the file's own charsets are read.
        if(lowercase!=lower || id!=sourcemachine.id)
        {
            setcase(lower);
            init_charset();
        }
        cset.shift=shift; // Need to do this properly later
        cset.grow=grow;

        if(fileformat>=2) // Charsets arrived with format 2
            load_charsets(lines,firstframe,currentframe);

        setframe(0);

        message("Loaded "+name+", size "+str(loadx)+"x"+str(loady)+" chars");
        if(merge)
            dirty=true;
        else
            dirty=false;
        return true;
    }

    // Fix colors between machines
    void remapcolors(Machine other)
    {
        if(id==other.id) // No need to do anything
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
            surface.setTitle(name+" ("+str(X)+"x"+str(Y)+")");
    
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

        f.println(VERSION_DECL+str(CFORMAT)+";"); // What follows the frames

        save_charsets(f);

        String keis="upper";
        if(lowercase)
            keis="lower";
        String meta=str(X)+" "+str(Y)+" "+machinename+" "+keis;

        // Size and case as numbers; the machine stays a name, and the trailing
        // comment - written for PETSCII versions before 2 anyway - is where it
        // is read from.
        f.println(META_DECL+str(X)+","+str(Y)+","+str(lowercase?0:1)+"}; // width height case, 1 = upper");
        f.println("// META: "+meta); // Where PETSCII versions before 2 read it

        f.flush();
        f.close();
        
        if(!name.equals(prefs.backupfile))
            dirty=false;
        message("Written "+name);
    }
        
    // Everything a .c file holds beyond the frames is written as C: the format
    // version, one array per charset in use, which charset each frame is drawn
    // with, and the size/machine/case metadata. They are all declared "static
    // const" on purpose: PETSCII stops reading frames at the first line that
    // does not begin with "unsigned char", so a version older than format 2
    // loads the picture, draws it with the ROM charset and ignores the rest.
    // Such a version reads the metadata from the trailing "// META:" comment
    // only, which is why that line is still written, and still written last.
    final int CFORMAT=2; // 1 = frames and the META comment, 2 = added the above

    final String VERSION_DECL="static const int version=",
                 CHARSET_DECL="static const unsigned char charset",
                 FONTS_DECL="static const int fonts[]={",
                 META_DECL="static const int meta[]={";

    void save_charsets(PrintWriter f)
    {
        // One array per distinct charset: frames drawn with the same characters
        // share an array, frames on the machine's own font refer to none (-1).
        ArrayList<byte[]> fonts=new ArrayList<byte[]>();
        int used[]=new int[framecount];

        for(int i=0;i<framecount;i++)
        {
            byte font[]=frames.get(i).font;

            used[i]=-1;
            for(int j=0;font!=null && j<fonts.size();j++)
                if(Arrays.equals(fonts.get(j),font))
                    used[i]=j;

            if(font!=null && used[i]<0)
            {
                fonts.add(font);
                used[i]=fonts.size()-1;
            }
        }

        if(fonts.isEmpty()) // Nothing but the machine's own font: save as before
            return;

        for(int i=0;i<fonts.size();i++)
        {
            byte font[]=fonts.get(i); // Always 256*8, see Charset.tobytes

            f.println(CHARSET_DECL+hex(i,4)+"[]={// 256 characters, 8 bytes each");
            for(int c=0;c<256;c++)
            {
                for(int b=0;b<8;b++)
                {
                    f.print(str(font[c*8+b]&0xff));
                    if(c!=255 || b!=7)
                        f.print(",");
                }
                f.println();
            }
            f.println("};");
        }

        String map=FONTS_DECL; // Charset per frame, in frame order
        for(int i=0;i<framecount;i++)
            map+=(i>0 ? "," : "")+str(used[i]);
        f.println(map+"}; // charset per frame, -1 = the machine's own");
    }

    // The format version the file was written in. Files without the declaration
    // are the original format, which had frames and the META comment only.
    int read_format(String lines[])
    {
        for(int i=0;i<lines.length;i++)
            if(lines[i].startsWith(VERSION_DECL))
                return int(trim(lines[i].substring(VERSION_DECL.length()).replace(";","")));

        return 1;
    }

    // The "<x> <y> <machine> <case>" tokens, from the declaration if the file
    // has one and from the trailing comment otherwise. Null if it has neither.
    String[] read_meta(String lines[])
    {
        String decl[]=null,comment[]=null;

        for(int i=lines.length-1;i>=0 && (decl==null || comment==null);i--) // Both live at the end
        {
            if(decl==null && lines[i].startsWith(META_DECL))
                decl=splitTokens(between(lines[i],'{','}'),",");

            if(comment==null && lines[i].startsWith("// META:"))
                comment=subset(splitTokens(lines[i]," "),2); // drop "//" and "META:"
        }

        if(decl==null || decl.length<3) // Format 1, or a declaration too short to trust
            return comment;

        // Size and case from the numbers, machine from the comment beside them
        return new String[]{ trim(decl[0]),
                             trim(decl[1]),
                             comment!=null && comment.length>2 ? comment[2] : "",
                             int(trim(decl[2]))==0 ? "lower" : "upper" };
    }

    // What a line holds between the first open and the last close character.
    String between(String line,char open,char close)
    {
        int a=line.indexOf(open),
            b=line.lastIndexOf(close);

        return (a<0 || b<=a) ? "" : line.substring(a+1,b);
    }

    // Read back what save_charsets wrote and hand the charsets to the frames the
    // loader just filled in, frames first..last (a merge leaves the rest alone).
    void load_charsets(String lines[],int first,int last)
    {
        ArrayList<byte[]> fonts=new ArrayList<byte[]>();
        int map[]=null;

        for(int i=0;i<lines.length;i++)
        {
            if(lines[i].startsWith(FONTS_DECL))
            {
                String all=""; // Tolerate an array wrapped over several lines
                for(int j=i;j<lines.length;j++)
                {
                    all+=lines[j];
                    if(lines[j].contains("}"))
                        break;
                }

                String s[]=splitTokens(between(all,'{','}'),",");
                map=new int[s.length];
                for(int j=0;j<s.length;j++)
                    map[j]=int(s[j]);
            }

            if(!lines[i].startsWith(CHARSET_DECL))
                continue;

            byte font[]=new byte[256*8]; // A short block leaves the rest blank
            int n=0;
            for(i++;i<lines.length && !lines[i].startsWith("};");i++)
            {
                String s[]=splitTokens(lines[i],",");
                for(int j=0;j<s.length && n<font.length;j++)
                    font[n++]=(byte)int(s[j]);
            }
            fonts.add(font);
        }

        if(fonts.isEmpty())
            return;

        for(int i=first;i<=last && i<framecount;i++)
        {
            int idx=0; // Without a mapping one charset covers every frame
            if(map!=null && i-first<map.length)
                idx=map[i-first];

            Frame fr=frames.get(i);
            fr.font=(idx>=0 && idx<fonts.size()) ? fonts.get(idx) : null;

            apply_font(fr.font); // So the thumbnail blends the right characters
            fr.updatethumb();
        }
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
            rowlen+=prefs.PREBORDER_X*2;
            xoff=prefs.PREBORDER_X;
            yoff=prefs.PREBORDER_Y*rowlen;
            p=createImage(cset.xsize*X+prefs.PREBORDER_X*2,cset.ysize*Y+prefs.PREBORDER_Y*2,RGB);
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
    void save_pet(String name)
    {
        message(NOT_IMPLEMENTED);
    }
    void load_charset(String name)
    {
        PImage img=loadImage(name);
        if(img==null)
        {
            message("Cannot open "+name);
            return;
        }

        // Must be a grid of whole 8x8 tiles.
        if(img.width%8!=0 || img.height%8!=0)
        {
            message("Charset image dimensions must be multiples of 8 pixels");
            return;
        }

        int tiles=(img.width/8)*(img.height/8);

        // A charset grid: up to 256 tiles, loaded directly. Fewer than 256 tiles
        // leaves the remaining characters blank (see Charset.tilestrip).
        if(tiles<=256)
        {
            fontfile=name;
            init_charset(); // reflows the tiles into the internal strip
            message("Loaded charset "+name+" ("+tiles+" chars)");
            return;
        }

        message("Charset has "+tiles+" tiles (max 256). Use \"Image\" to trace a picture.");
    }

    // Build the charset from fontfile. This is the picture-wide charset change:
    // loading a charset .png, tracing an image, a .petmate font, a case toggle
    // or a refresh all end up here, and all of them apply to every frame.
    void init_charset()
    {
        build_charset();
        picture_font();
    }

    // The same rebuild, but without handing the charset to the frames.
    void build_charset()
    {
        use_charset(new Petscii(fontfile,remapfile,setfile));
    }

    // Build the charset from character data instead of from fontfile, for frames
    // that carry their own (see apply_font). Frames are left alone.
    void build_charset(byte font[])
    {
        use_charset(new Petscii(font,remapfile,setfile));
    }

    void use_charset(Charset c)
    {
        cset=c;
        cset.initrender(charx,chary);
        tool.current=cset.remap[tool.curidx];
        cset.shift=shift; // Need to do this properly later
        cset.grow=grow;
    }
}
