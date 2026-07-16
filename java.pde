
// Pure Java UI elements, such as a file selector
// (this crap really makes me lose all my will to live, but it's needed now)

import java.awt.event.*;
import java.awt.GridLayout;
import javax.swing.*;
import javax.swing.filechooser.FileNameExtensionFilter;
import java.awt.*;
import java.io.*;
import java.nio.file.*;
import java.util.Collections;
import java.util.Comparator;

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

class Selector extends JPanel implements ActionListener
{
    int selection;
    protected JButton b[];
    
    Selector(String title,String s) // Split string into options
    {
        Box box=Box.createVerticalBox();
        
        String splitz[]=splitTokens(s,",");
        b=new JButton[splitz.length];
        
        setLayout(new GridLayout(splitz.length+1,1,1,1));
        
        add(new JLabel(title,SwingConstants.CENTER));
        
        for(int i=0;i<splitz.length;i++)
        {
            b[i]=new JButton(splitz[i]);
            b[i].setActionCommand(str(i+'0'));
            b[i].addActionListener(this);
            b[i].setPreferredSize(new Dimension(140,26));
            
            add(b[i]);
        }
        
        selection=-1;
    }
    public void actionPerformed(ActionEvent e)
    {
        for(int i=0;i<b.length;i++)
        {
            if(str(i+'0').equals(e.getActionCommand()))
                selection=i;
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
/*// Select from a list
int selector(String title,String opt)
{
    PSurfaceAWT awtSurface = (PSurfaceAWT) surface;
    SmoothCanvas canvas = (SmoothCanvas) awtSurface.getNative();
    JFrame frame = (JFrame) canvas.getFrame();
    //Frame frame = (Frame) (surface.getNative());
  //  JFrame frame=new JFrame("");
    frame.setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
    frame.setLocationRelativeTo(null);
    
    Selector s=new Selector(title,opt);
    s.setOpaque(true);
    frame.setContentPane(s);
 
    //Display the window.
    frame.pack();
    frame.setVisible(true);
    frame.setLocationRelativeTo(null); // About in the middle
    
    while(s.selection==-1)
    {
        frame.toFront(); // A bit of a kludge to force the window on top
        frame.repaint();
        try { Thread.sleep(200); }
        catch(Exception e){};
    }
    
    frame.setVisible(false);
    
    System.gc(); // It'll leak anyway...
    return(s.selection);
}
*/
final int LOADPIX=0,
          LOADPETSCII=1,
          SAVEPETSCII=2,
          MERGEPETSCII=3,
          LOADPRG=4;

void fileselector(String dir, int mode)
{
  selectInput("Select a file", "fileSelected");
}

// The selectInput/selectOutput callbacks below run on the AWT event thread, so
// they only queue the actual work via post(); it runs on the animation thread
// (requesters()), where it can't race draw().

void loadPetscii(File selection)
{
    if(selection==null) return;
    post(() -> {
        String fn = selection.getAbsolutePath();
        if(machine.load_c(fn, false))
        {
            message(fn + " opened");
            filename=fn;
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
    post(() -> machine.load_image_charset(selection.getAbsolutePath()));
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
/*
// File selector
String OLDfileselector(String dir,int mode)
{
    if(prefs.awtselector==1)
    {
        FileDialog fd;
        if(mode==SAVEPETSCII)
        {
            fd=new FileDialog(frame, "Select a file", FileDialog.SAVE);
            Path p=Paths.get(filename); // Extract the actual filename from the path
            fd.setFile(p.getFileName().toString());
        }
        else
            selectInput("Select a file", FileDialog.LOAD);
            //fd=new FileDialog(frame, "Select a file", FileDialog.LOAD);

        fd.setDirectory(dir);        
        if(mode==LOADPIX) // Show image files
        {
            fd.setFilenameFilter(new Filsu(new String[] {".png",".gif",".jpg",".jpeg"}));
        }
        else
        {
            if(mode==LOADPRG)
                fd.setFilenameFilter(new Filsu(new String[] {".prg"})); // Show only .prg
            else
                fd.setFilenameFilter(new Filsu(new String[] {".c"})); // Show only .c
        }
    
        delay(100); // Helps with clicks?

        fd.setAlwaysOnTop(true);
        fd.setSize(800,600);
        fd.setLocationRelativeTo(null);
        fd.pack();
        fd.toFront();
        fd.requestFocus();     
        fd.setVisible(true); // Show it
        
        // Trying to get the window back to focus after selection, but this is just guessing
        surface.setVisible(true);
        frame.toFront();
        frame.requestFocus();
        
        if(fd.getDirectory()==null || fd.getFile()==null)
            return null;
            
        if(mode==LOADPIX)
            prefs.refpath=fd.getDirectory();
        else
            prefs.path=fd.getDirectory();

        return fd.getDirectory()+fd.getFile();
    }
    else
    {
        JFileChooser fc=new JFileChooser(dir);
        
        fc.setPreferredSize(new Dimension(480, 500));
        fc.setDialogTitle("Select a File");
        
        if(mode==LOADPIX) // Show image files
        {
            fc.setFileFilter(new FileNameExtensionFilter("Images (*.png,*.gif,*.jpg)",
                             "png","gif","jpg","jpeg"));
        }
        else
        {
            if(mode==LOADPRG)
                fc.setFileFilter(new FileNameExtensionFilter("PRG files (*.prg)","prg")); // Show only .prg
            else
                fc.setFileFilter(new FileNameExtensionFilter("PETSCII Images (*.c)","c")); // Show only .c
        }
        
        if(mode<=LOADPETSCII)
            fc.setApproveButtonText("Load");
        if(mode==SAVEPETSCII)
            fc.setApproveButtonText("Save");
        if(mode==MERGEPETSCII)
            fc.setApproveButtonText("Merge");
        if(mode==LOADPRG)
            fc.setApproveButtonText("Import");
        
        int returnval=fc.showOpenDialog(null); // Should be showSaveDialog for SAVEPETSCII, but then the button text won't change... 
        
        if(returnval==JFileChooser.APPROVE_OPTION)
        {
            // Save cwd for next time
            if(mode==LOADPIX)
                prefs.refpath=fc.getCurrentDirectory().getPath();
            else
                prefs.path=fc.getCurrentDirectory().getPath();
            
            File file = fc.getSelectedFile();
            return file.getPath();
        }
        else
            return null;
    }
}
*/
class Filsu implements FilenameFilter // Had to hack something like this for the AWT FileDialog
{
    String patt[];
    
    Filsu(String s[])
    {
        patt=s;
    }   
    boolean accept(File dir,String name)
    {
        for(int i=0;i<patt.length;i++)
            if(name.toLowerCase().endsWith(patt[i]))
                return true;
            
        return false;
    }
}
