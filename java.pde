
// Pure Java UI elements, such as a file selector
// (this crap really makes me lose all my will to live, but it's needed now)

import java.awt.event.*;
import java.awt.GridLayout;
import javax.swing.*;
import javax.swing.filechooser.FileNameExtensionFilter;
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

// Select from a list
int selector(String title,String opt)
{
    JFrame frame=new JFrame("");
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

final int LOADPIX=0,
          LOADPETSCII=1,
          SAVEPETSCII=2,
          MERGEPETSCII=3,
          LOADPRG=4;

// File selector
String fileselector(String dir,int mode)
{
    if(prefs.awtselector==1)
    {
        FileDialog fd;
        if(mode==SAVEPETSCII)
        {
            fd=new FileDialog(frame, "Select a file", FileDialog.SAVE);
            fd.setFile(filename);
        }
        else
            fd=new FileDialog(frame, "Select a file", FileDialog.LOAD);

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
        
        int returnVal = fc.showOpenDialog(null);
        
        if(returnVal==JFileChooser.APPROVE_OPTION)
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
