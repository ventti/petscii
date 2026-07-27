
// Pure Java UI elements, such as a file selector
// (this crap really makes me lose all my will to live, but it's needed now)

import javax.swing.*;
import java.awt.*;
import java.io.*;

void javatheme()
{
    if(prefs.awtselector==-1) // Depending on the platform use either Swing or AWT fileselector (unless overridden in prefs)
        switch(platform)
        {
            case LINUX: prefs.awtselector=1; break; 
            case WINDOWS: prefs.awtselector=0; break; 
            case MACOSX: prefs.awtselector=1; break;
            default: prefs.awtselector=0; break;
        }
    
    if(prefs.forcemetal) // Don't even try a native look
        return;
    
    try // Let's try to set a native look
    {
        if(platform==LINUX)
        {
            UIManager.setLookAndFeel("com.sun.java.swing.plaf.gtk.GTKLookAndFeel");
        }
        else
        {
            if(platform==WINDOWS)
            {
                UIManager.setLookAndFeel("com.sun.java.swing.plaf.windows.WindowsLookAndFeel");
            }
            else // Others or Mac, better go with something generic (too bad)
            {
                UIManager.setLookAndFeel("javax.swing.plaf.metal.MetalLookAndFeel");
            }
        }
    }
    catch (Exception e) {};
    
    // scale the default swing font size (11px), which is awfully little with smallish 4K displays
    int fs = int(11 + 2.5 * float(prefs.zoom)); 
    setDefaultSize(fs);
}

void setDefaultSize(int size){
    int n = UIManager.getLookAndFeelDefaults().keySet().size();
    Object[] keys = UIManager.getLookAndFeelDefaults().keySet().toArray(new Object[n]);

    for (Object key : keys) {

        if (key != null && key.toString().toLowerCase().contains("font")) {

            Font font = UIManager.getDefaults().getFont(key);
            if (font != null) {
                font = font.deriveFont((float)size);
                UIManager.put(key, font);
            }
        }
    }
}

// Modal chooser: shows `title` with one button per comma-separated option in `opt`.
// Returns the chosen option's index (0-based), or -1 if the dialog was dismissed.
// Used for the startup platform picker and Yes/No confirmations.
int selector(String title, String opt)
{
    String[] options=splitTokens(opt, ",");
    return JOptionPane.showOptionDialog(
        null, title, "PETSCII",
        JOptionPane.DEFAULT_OPTION, JOptionPane.QUESTION_MESSAGE,
        null, options, options[0]);
}
// The selectInput/selectOutput callbacks below run on the AWT event thread, so
// they only queue the actual work via post(); it runs on the animation thread
// (requesters()), where it can't race draw().

void loadPetscii(File selection)  { load_or_merge(selection,false); }
void mergePetscii(File selection) { load_or_merge(selection,true); }

// Shared by the Load and Merge dialogs. Merging draws the opened image into the
// current one, so it keeps the current filename (and its dirty state); loading
// replaces the document and adopts the opened file as the save target.
void load_or_merge(File selection, boolean merge)
{
    if(selection==null) return;
    post(() -> {
        String fn = selection.getAbsolutePath();
        // load_any() picks the reader by format (.c or .petmate) and reports what
        // it loaded itself, so only the failure case and the save target are ours.
        if(load_any(fn, merge))
        {
            if(!merge)
            {
                filename=c_savename(fn); // exporters need a .c name (see ext())
                surface.setTitle(filename+" ("+str(X)+"x"+str(Y)+")");
            }
        }
        else
            message(selection.getName()+" cannot be opened.");
    });
}

void savePetscii(File selection)
{
    if(selection==null) return;
    post(() -> {
        filename = selection.getAbsolutePath();
        if (!filename.endsWith(".c") && !filename.endsWith(".C"))
            filename += ".c";

        int i=0;
        if(selection.exists() && prefs.awtselector==0)
            i=selector("Overwrite file?","Yes,No");
        if(i==0)
            machine.save_c(filename,false);
    });
}

void importPrg(File selection)
{
    if(selection==null) return;
    post(() -> {
        machine.import_prg(selection.getAbsolutePath());
        cf.updatethumb();
    });
}

void loadCharset(File selection)
{
    if(selection==null) return;
    post(() -> machine.load_charset(selection.getAbsolutePath()));
}

void loadImageCharset(File selection)
{
    if(selection==null) return;
    post(() -> load_image_charset(selection.getAbsolutePath()));
}

// Modal integer prompt. Returns the entered value, `def` on invalid input,
// or -1 if the dialog was cancelled.
int askInt(String prompt, int def)
{
    String s=JOptionPane.showInputDialog(null, prompt, ""+def);
    if(s==null)
        return -1; // cancelled
    try { return Integer.parseInt(s.trim()); }
    catch(Exception e){ return def; }
}

// Save the current charset (cset.bitmap, 256 chars of 8x8 b/w) as a .png,
// laid out charsetSaveCPR characters per row.
void saveCharsetPng(File selection)
{
    if(selection==null)
        return;
    post(() -> {
        String fn=selection.getAbsolutePath();
        if(!fn.toLowerCase().endsWith(".png"))
            fn+=".png";

        int cpr=charsetSaveCPR;
        int rows=(256+cpr-1)/cpr;

        PImage out=createImage(cpr*8, rows*8, RGB);
        out.loadPixels();
        for(int i=0;i<out.pixels.length;i++)
            out.pixels[i]=color(0);

        cset.bitmap.loadPixels();
        for(int c=0;c<256;c++)
        {
            int gx=(c%cpr)*8, gy=(c/cpr)*8;
            for(int y=0;y<8;y++)
                for(int x=0;x<8;x++)
                    out.pixels[(gx+x)+(gy+y)*out.width] = cset.bitmap.pixels[(c*8+x)+y*cset.bitmap.width];
        }
        out.updatePixels();
        out.save(fn);
        message("Saved charset ("+cpr+"/row) to "+fn);
    });
}

// Modal information popup.
void popup(String msg)
{
    JOptionPane.showMessageDialog(null, msg, "PETSCII", JOptionPane.INFORMATION_MESSAGE);
}

// Modal address prompt. Accepts $hex, 0xhex or decimal. Returns the value,
// `def` on invalid input, or -1 if the dialog was cancelled.
int askAddr(String prompt, int def)
{
    String s=JOptionPane.showInputDialog(null, prompt, "$"+hex(def,4));
    if(s==null)
        return -1;
    s=s.trim();
    try {
        if(s.startsWith("$"))  return Integer.parseInt(s.substring(1),16);
        if(s.startsWith("0x") || s.startsWith("0X")) return Integer.parseInt(s.substring(2),16);
        return Integer.parseInt(s);
    }
    catch(Exception e){ return def; }
}

// Save the current charset (256 chars, 8 bytes each) as a C64 .prg: a 2-byte
// little-endian load address followed by 2048 bytes of character bitmap data
// (bit 7 = leftmost pixel; a foreground/non-black pixel sets the bit).
void saveCharsetPrg(File selection)
{
    if(selection==null)
        return;
    post(() -> {
        String fn=selection.getAbsolutePath();
        if(!fn.toLowerCase().endsWith(".prg"))
            fn+=".prg";

        int addr=charsetPrgAddr;
        byte[] out=new byte[2+256*8];
        out[0]=(byte)(addr&0xff);        // load address, low byte
        out[1]=(byte)((addr>>8)&0xff);   // load address, high byte

        cset.bitmap.loadPixels();
        for(int c=0;c<256;c++)
            for(int y=0;y<8;y++)
            {
                int b=0;
                for(int x=0;x<8;x++)
                    if((cset.bitmap.pixels[(c*8+x)+y*cset.bitmap.width]&0xff)>20)
                        b|=(1<<(7-x));
                out[2+c*8+y]=(byte)b;
            }
        saveBytes(fn,out);
        message("Saved charset .prg to "+fn+" ($"+hex(addr,4)+")");
    });
}

void loadPic(File selection)
{
    if(selection==null) return;
    post(() -> {
        String fname = selection.getAbsolutePath();
        if(loadreference(fname))
        {
            refname = fname;
            ref = 1;
            reftime = selection.lastModified();
        }
        else
            message(fname + " cannot be opened.");
    });
}
