
// Pure Java UI elements, such as a file selector
// (this crap really makes me lose all my will to live, but it's needed now)

import java.awt.event.*;
import java.awt.GridLayout;
import javax.swing.*;
import javax.swing.filechooser.FileNameExtensionFilter;

void javatheme()
{
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
    
    Selector(String s) // Split string into options
    {
        Box box=Box.createVerticalBox();
        
        String splitz[]=splitTokens(s,",");
        b=new JButton[splitz.length];
        
        setLayout(new GridLayout(splitz.length,1,1,1));
        
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
    JFrame frame=new JFrame(title);
    frame.setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
    frame.setLocationRelativeTo(null);
    
    Selector s=new Selector(opt);
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
          MERGEPETSCII=3;

// File selector
String fileselector(String dir,int mode)
{
    JFileChooser fc=new JFileChooser(dir);
    
    fc.setPreferredSize(new Dimension(480, 500));
    fc.setDialogTitle("Select a File");
    
    if(mode==LOADPIX) // Show image files
        fc.setFileFilter(new FileNameExtensionFilter("Images (*.png,*.gif,*.jpg)",
                         "png","gif","jpg","jpeg"));
    else
        fc.setFileFilter(new FileNameExtensionFilter("PETSCII Images (*.c)","c")); // Show only .c
    
    if(mode<=LOADPETSCII)
        fc.setApproveButtonText("Load");
    if(mode==SAVEPETSCII)
        fc.setApproveButtonText("Save");
    if(mode==MERGEPETSCII)
        fc.setApproveButtonText("Merge");
    
    int returnVal = fc.showOpenDialog(this);
    
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
