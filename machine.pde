
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
    
    void ownbuttons() // Disable not implemented buttons or change some if needed
    {
    }
    
    boolean validate(int c) // Check if this char is ok
    {
        return true;
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
        int cindex=(mouseX-view.col2_start)/charx%16 + (mouseY-(view.colorsel_start))/csheight*16;
        
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
            if(shadowButton==LEFT && cindex<=maxpen)
                pen=cindex;
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
                        case DIRART: sourcemachine=new Dirart(); break;
                        case PET:   sourcemachine=new Pet(); break;
                        case PETHI: sourcemachine=new Pethi(); break;
                        case PLUS4: sourcemachine=new Plus4(); break;
                        case VIC20: sourcemachine=new Vic20(); break;
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
            surface.setTitle(name+" ("+str(X)+"x"+str(Y)+")");
        
            anim_init();
            cf.undo_purge();
            currentframe=-1;
        }   
        
        String s[];
        int i=0,defaultcolor=erasecolor;
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
        if(merge)
            dirty=true;
        else
            dirty=false;
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
        
        // Metadata in a comment
        String keis="upper";
        if(lowercase)
            keis="lower";
        f.println("// META: "+str(X)+" "+str(Y)+" "+machinename+" "+keis);
        
        f.flush();
        f.close();
        
        if(!name.equals(prefs.backupfile))
            dirty=false;
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

    // Load an arbitrary image and trace it into a generated charset, reconstructing
    // the image on the canvas (see charset_from_hires).
    void load_image_charset(String name)
    {
        PImage img=loadImage(name);
        if(img==null)
        {
            message("Cannot open "+name);
            return;
        }
        if(img.width%8!=0 || img.height%8!=0)
        {
            message("Image dimensions must be multiples of 8 pixels");
            return;
        }
        if(img.width>320 || img.height>200)
        {
            message("Image must be at most 320x200 pixels");
            return;
        }
        charset_from_hires(img);
    }

    // Build a charset from an arbitrary hires image: split it into 8x8 blocks,
    // reduce each block to black/white (colours omitted; the darkest colour in a
    // block becomes background, everything else foreground, so the pixel shape is
    // preserved), and collect the unique blocks (identical blocks are reused).
    // The image is then reconstructed on the canvas with the generated charset
    // (like loading the charset and running Shift-T for the same image), each cell
    // in its best-matching palette colour.
    // If the image has more than 256 distinct characters it falls back to a
    // best-effort result: the 256 most frequent glyphs are kept and every other
    // block is drawn with its nearest kept glyph, producing an approximate image.
    void charset_from_hires(PImage img)
    {
        int cols=img.width/8, rows=img.height/8;
        img.loadPixels();

        long blocksig[]=new long[cols*rows]; // b/w signature of each image block
        int blockfg[]=new int[cols*rows];    // best-matching foreground colour per block
        int bgpop[]=new int[rgb.length];     // popularity of each paper colour (for global bg)
        HashMap<Long,Integer> freq=new HashMap<Long,Integer>(); // how often each glyph occurs
        ArrayList<Long> uniq=new ArrayList<Long>();             // distinct glyphs (first-appearance order)

        for(int by=0;by<rows;by++)
            for(int bx=0;bx<cols;bx++)
            {
                long sig=block_to_bw(img, bx*8, by*8);
                blocksig[by*cols+bx]=sig;
                if(!freq.containsKey(sig))
                    uniq.add(sig);
                freq.put(sig, (freq.containsKey(sig)?freq.get(sig):0)+1);

                // Best-possible colours: ink = nearest palette colour to the block's
                // lightest colour, paper = nearest to its darkest (voted into the bg).
                int mm[]=block_minmax(img, bx*8, by*8);
                blockfg[by*cols+bx]=nearest_pen(mm[1]);
                bgpop[nearest_pen(mm[0])]++;
            }

        // Choose the character set: all distinct glyphs, or (best effort) the 256
        // most frequent ones when there are more than 256.
        boolean besteffort = uniq.size()>256;
        ArrayList<Long> kept;
        if(!besteffort)
            kept=uniq;
        else
        {
            ArrayList<Long> all=new ArrayList<Long>(uniq);
            final HashMap<Long,Integer> f=freq;
            Collections.sort(all, new Comparator<Long>(){
                public int compare(Long a, Long b){ return f.get(b)-f.get(a); } // most frequent first
            });
            kept=new ArrayList<Long>(all.subList(0,256));
        }

        HashMap<Long,Integer> idx=new HashMap<Long,Integer>(); // glyph -> char index
        for(int k=0;k<kept.size();k++)
            idx.put(kept.get(k), k);

        // Map every block to a kept char (its own, or the nearest kept glyph)
        int blockchar[]=new int[cols*rows];
        HashMap<Long,Integer> nearest=new HashMap<Long,Integer>(); // cache for dropped glyphs
        for(int i=0;i<cols*rows;i++)
        {
            long sig=blocksig[i];
            Integer ix=idx.get(sig);
            if(ix==null)
            {
                ix=nearest.get(sig);
                if(ix==null){ ix=nearest_kept_index(sig, kept); nearest.put(sig, ix); }
            }
            blockchar[i]=ix;
        }

        // Global background = the most popular paper colour across the image
        int globalbg=0;
        for(int k=0;k<=maxbg && k<bgpop.length;k++)
            if(bgpop[k]>bgpop[globalbg])
                globalbg=k;

        // Render the kept glyphs into the internal 2048x8 strip (black bg, white fg)
        PImage strip=createImage(256*8, 8, RGB);
        strip.loadPixels();
        for(int i=0;i<strip.pixels.length;i++)
            strip.pixels[i]=color(0);
        for(int c=0;c<kept.size();c++)
        {
            long sig=kept.get(c);
            for(int y=0;y<8;y++)
                for(int x=0;x<8;x++)
                    if(((sig>>(63-(y*8+x)))&1L)==1L)
                        strip.pixels[(c*8+x)+y*strip.width]=color(255);
        }
        strip.updatePixels();

        // Persist and load it through the normal charset path
        String tmp=System.getProperty("java.io.tmpdir")+File.separator+"petscii-hirescharset.png";
        strip.save(tmp);
        fontfile=tmp;
        init_charset();

        // Reconstruct the image on the canvas using the generated charset, giving
        // each cell the palette colour that best matches its block's ink over the
        // shared best-matching background colour.
        cf.undo_save();
        cf.setbg(globalbg);
        int blank = idx.containsKey(0L) ? idx.get(0L) : cset.erasechar; // all-background char, if any
        for(int i=0;i<X*Y;i++)
        {
            cf.setchar(i, blank);
            cf.setcolor(i, globalbg);
        }
        for(int by=0;by<rows && by<Y;by++)
            for(int bx=0;bx<cols && bx<X;bx++)
            {
                cf.setchar(bx,by, blockchar[by*cols+bx]);
                cf.setcolor(bx,by, blockfg[by*cols+bx]);
            }
        cf.updatethumb();
        repaint=true;

        if(besteffort)
        {
            message("Best effort: "+uniq.size()+" unique chars reduced to 256");
            popup("The image has "+uniq.size()+" unique characters (more than 256).\n\n"+
                  "A best-effort 256-character set and an approximate image estimate were created.");
        }
        else
            message("Generated "+kept.size()+" chars and rendered the image");
    }

    // Index of the kept glyph closest to sig (fewest differing pixels).
    int nearest_kept_index(long sig, ArrayList<Long> kept)
    {
        int best=0, bestd=Integer.MAX_VALUE;
        for(int k=0;k<kept.size();k++)
        {
            int d=Long.bitCount(sig ^ kept.get(k));
            if(d<bestd){ bestd=d; best=k; }
        }
        return best;
    }

    // Reduce one 8x8 block to a black/white bitmap packed into a 64-bit signature
    // (bit 63 = top-left, row-major). The darkest colour present is background (0),
    // any other colour is foreground (1); a single-colour block becomes all-0.
    long block_to_bw(PImage img, int ox, int oy)
    {
        int bgcol=0;
        float bglum=1e9;
        for(int y=0;y<8;y++)
            for(int x=0;x<8;x++)
            {
                int col=img.pixels[(ox+x)+(oy+y)*img.width];
                float lum=0.299*red(col)+0.587*green(col)+0.114*blue(col);
                if(lum<bglum){ bglum=lum; bgcol=col; }
            }

        long sig=0;
        for(int y=0;y<8;y++)
            for(int x=0;x<8;x++)
            {
                int col=img.pixels[(ox+x)+(oy+y)*img.width];
                sig=(sig<<1) | ((col==bgcol)?0L:1L);
            }
        return sig;
    }

    // Darkest (min luminance) and lightest (max luminance) colours in an 8x8 block,
    // returned as {darkest, lightest}. Used to pick paper/ink colours.
    int[] block_minmax(PImage img, int ox, int oy)
    {
        int minc=0, maxc=0;
        float minl=1e9, maxl=-1;
        for(int y=0;y<8;y++)
            for(int x=0;x<8;x++)
            {
                int col=img.pixels[(ox+x)+(oy+y)*img.width];
                float lum=0.299*red(col)+0.587*green(col)+0.114*blue(col);
                if(lum<minl){ minl=lum; minc=col; }
                if(lum>maxl){ maxl=lum; maxc=col; }
            }
        return new int[]{minc,maxc};
    }

    // Palette index (0..maxpen) whose colour is closest to the given RGB colour.
    int nearest_pen(int col)
    {
        int best=0, bestd=Integer.MAX_VALUE;
        for(int k=0;k<=maxpen && k<rgb.length;k++)
        {
            int d=rgbdistance(col, rgb[k]);
            if(d<bestd){ bestd=d; best=k; }
        }
        return best;
    }
    void init_charset()
    {
        cset=new Petscii(fontfile,remapfile,setfile);
        cset.initrender(charx,chary);
        current=cset.remap[curidx];
        cset.shift=shift; // Need to do this properly later
        cset.grow=grow;
    }
}
