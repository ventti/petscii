// Editor-level image tracing: turn an arbitrary image into a generated charset
// AND reconstruct it on the canvas. This lives outside the Machine class on
// purpose — it mutates the document (cf) and talks to the UI (message/popup),
// which are editor concerns; it uses the Machine only for platform data (palette)
// and charset building.

// Load an arbitrary image and trace it into a generated charset, reconstructing
// the image on the canvas (see trace_image()).
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
    trace_image(img);
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
void trace_image(PImage img)
{
    int cols=img.width/8, rows=img.height/8;
    img.loadPixels();

    long blocksig[]=new long[cols*rows];      // b/w signature of each image block
    int blockfg[]=new int[cols*rows];         // best-matching foreground colour per block
    int bgpop[]=new int[machine.rgb.length];  // popularity of each paper colour (for global bg)
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
    for(int k=0;k<=machine.maxbg && k<bgpop.length;k++)
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

    // Persist and load it through the normal charset path (Machine owns the charset)
    String tmp=System.getProperty("java.io.tmpdir")+File.separator+"petscii-hirescharset.png";
    strip.save(tmp);
    machine.fontfile=tmp;
    machine.init_charset();

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
    for(int k=0;k<=machine.maxpen && k<machine.rgb.length;k++)
    {
        int d=rgbdistance(col, machine.rgb[k]);
        if(d<bestd){ bestd=d; best=k; }
    }
    return best;
}
