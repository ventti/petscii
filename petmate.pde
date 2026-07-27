// Loader for Petmate workspaces (.petmate), the native format of nurpax/petmate
// and its petmate9 fork. Plain single-line UTF-8 JSON, no compression:
//
//   { "version": 1|2|3,
//     "screens": [0,1,...],                     // tab order; framebufs is already in it
//     "framebufs": [ { "width":40, "height":25,
//                      "backgroundColor":0, "borderColor":3,
//                      "charset":"upper"|"lower"|"custom_1",
//                      "name":"screen_001",
//                      "framebuf":[ [ {"code":32,"color":14}, ... ] ] } ],  // [row][col]
//     "customFonts": { "custom_1": { "name":"...",
//                                    "font":{ "bits":[2048 ints], "charOrder":[256] } } } }
//
// The cells hold C-64 screen codes (0-255) and C-64 colour indices (0-15), which
// is exactly this editor's internal representation, so characters need no
// conversion at all; only the colours are remapped, and only when the current
// machine is not a C-64. Each framebuf becomes one animation frame.
//
// "screens" is deliberately ignored: it only holds tab ordering, and framebufs is
// always dense and already in screen order (petmate builds it as screens.map()).

final int PETMATE_FONT_BYTES=2048; // 256 chars * 8 rows, 1 bit per pixel

// Read a .petmate file into the current document. Returns false (with a message)
// on anything unreadable, so a bad file can never leave a half-loaded canvas.
boolean load_petmate(String name,boolean merge)
{
    JSONObject ws=null;
    try
    {
        ws=loadJSONObject(name);
    }
    catch(Exception e) // not JSON at all
    {
        ws=null;
    }

    if(ws==null)
    {
        message(name+" is not a readable Petmate file.");
        return false;
    }

    JSONArray framebufs=ws.getJSONArray("framebufs");
    if(framebufs==null || framebufs.size()==0)
    {
        message("No screens in "+name);
        return false;
    }

    // Petmate is a C-64 tool. Building the reference machine we remap colours
    // from would overwrite the global charset (every Machine constructor does),
    // so keep ours and put it straight back.
    Machine c64ref=null;
    if(machine.id!=C64)
    {
        Charset keep=cset;
        c64ref=new C64();
        cset=keep;
    }

    // The charset is per screen in the format, but this editor has one charset
    // per document, so the first screen decides upper/lower case.
    JSONObject first=framebufs.getJSONObject(0);
    String charsetname=first.getString("charset","upper");
    boolean lower=charsetname.equals("lower");

    if(!merge)
    {
        anim_init();
        cf.undo_purge();
        currentframe=-1;
    }

    int loadx=0,loady=0,screens=0;

    for(int f=0;f<framebufs.size();f++)
    {
        JSONObject fb=framebufs.getJSONObject(f);
        if(fb==null)
            continue;

        JSONArray rows=fb.getJSONArray("framebuf");
        if(rows==null)
            continue;

        currentframe++;
        if(currentframe!=0) // the first frame already exists
            addframe(currentframe);
        setframe(currentframe);

        if(machine.palettemode)
        {
            cf.setborder(petmate_color(fb.getInt("borderColor",14)));
            cf.setbg(petmate_color(fb.getInt("backgroundColor",6)));
        }
        else
        {
            cf.setborder(machine.defaultborder);
            cf.setbg(machine.defaultbg);
        }

        for(int i=0;i<X*Y;i++) // start from a blank frame, then crop the file into it
        {
            cf.setchar(i,cset.erasechar);
            cf.setcolor(i,machine.erasecolor);
        }

        // Trust the actual array lengths over the declared width/height: the
        // file's own header can disagree with its data, and a short row must not
        // read past the end.
        loady=max(loady,rows.size());
        for(int y=0;y<rows.size() && y<Y;y++)
        {
            JSONArray row=rows.getJSONArray(y);
            if(row==null)
                continue;

            loadx=max(loadx,row.size());
            for(int x=0;x<row.size() && x<X;x++)
            {
                JSONObject cell=row.getJSONObject(x);
                if(cell==null)
                    continue;

                cf.setchar(x,y,constrain(cell.getInt("code",cset.erasechar),0,cset.charactercount-1));
                cf.setcolor(x,y,petmate_color(cell.getInt("color",machine.erasecolor)));
            }
        }

        if(c64ref!=null)
            machine.remapcolors(c64ref);

        cf.updatethumb();
        screens++;
    }

    if(screens==0)
    {
        message("No usable screens in "+name);
        return false;
    }

    setframe(0);

    // A custom font travels inside the file; fall back to the ROM charset (with a
    // warning) rather than silently drawing the art with the wrong glyphs.
    boolean customfont=false;
    if(!charsetname.equals("upper") && !charsetname.equals("lower"))
        customfont=load_petmate_font(ws,charsetname);

    if(!customfont && (machine.lowercase!=lower || c64ref!=null))
    {
        machine.setcase(lower);
        machine.init_charset();
    }

    message("Loaded "+screens+" screen"+(screens==1?"":"s")+" from Petmate, "+
            str(loadx)+"x"+str(loady)+" chars"+(customfont?" (custom font)":""));
    dirty=merge;
    return true;
}

// C-64 colour index from the file, clamped into the current machine's palette.
// Petmate only ever writes 0-15; a hand-edited file must not reach rgb[] with a
// value that would throw while drawing.
int petmate_color(int c)
{
    return constrain(c,0,machine.rgb.length-1);
}

// Rebuild the charset from a workspace's embedded font ("customFonts"), by
// rendering its 1bpp bits into the same 2048x8 strip the image tracer produces
// and loading it through the normal Machine charset path. Returns false if the
// font is missing or malformed, in which case the caller keeps the ROM charset.
boolean load_petmate_font(JSONObject ws,String id)
{
    JSONObject fonts=ws.getJSONObject("customFonts");
    JSONObject entry=fonts==null ? null : fonts.getJSONObject(id);
    JSONObject font=entry==null ? null : entry.getJSONObject("font");
    JSONArray bits=font==null ? null : font.getJSONArray("bits");

    if(bits==null || bits.size()<PETMATE_FONT_BYTES)
    {
        message("Petmate font \""+id+"\" is missing; using the built-in charset.");
        return false;
    }

    PImage strip=createImage(256*8, 8, RGB);
    strip.loadPixels();
    for(int i=0;i<strip.pixels.length;i++)
        strip.pixels[i]=color(0);

    for(int c=0;c<256;c++)
        for(int y=0;y<8;y++)
        {
            int b=bits.getInt(c*8+y);
            for(int x=0;x<8;x++)
                if(((b>>(7-x))&1)==1) // byte is 8 pixels, most significant is leftmost
                    strip.pixels[(c*8+x)+y*strip.width]=color(255);
        }
    strip.updatePixels();

    String tmp=System.getProperty("java.io.tmpdir")+File.separator+"petscii-petmatefont.png";
    strip.save(tmp);
    machine.fontfile=tmp;
    machine.init_charset();
    return true;
}

// --- Format dispatch ---------------------------------------------------------

// Load whichever supported format this file actually is.
boolean load_any(String name,boolean merge)
{
    if(is_petmate(name))
        return load_petmate(name,merge);

    return machine.load_c(name,merge);
}

// Petmate workspaces are JSON, our own images are C source. Go by extension
// first, then sniff the first non-blank character so a renamed file still loads.
boolean is_petmate(String name)
{
    if(name.toLowerCase().endsWith(".petmate"))
        return true;

    String lines[]=loadStrings(name);
    return lines!=null && lines.length>0 && lines[0].trim().startsWith("{");
}

// Save target for a freshly loaded file. Every exporter derives its output name
// from the current filename through ext(), which insists on a .c extension, so a
// document opened from .petmate saves alongside it as .c instead of failing.
String c_savename(String name)
{
    String low=name.toLowerCase();

    if(low.endsWith(".petmate"))
        return name.substring(0,name.length()-8)+".c"; // drop ".petmate" (8 chars), add ".c"
    if(low.endsWith(".c"))
        return name;

    return name+".c";
}
