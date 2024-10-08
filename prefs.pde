
// Global setting constants and user-specified preferences

// Machine numbers and their corresponding names
final int C64=0,
          C64FLICKER=1,
          DIRART=2, 
          PET=3,
          PETHI=4,
          PLUS4=5,
          VIC20=6;

final String machinenames[]={
          "C64",
          "C64FLICKER",
          "DIRART",
          "PET",
          "PETHI",
          "PLUS4",
          "VIC20"
          };
          
// Video systems for aspect ratio calculation
final int PAL=0,
          NTSC=1,
          SQUARE=2;

class Preferences
{
    int       machine=-1,
              zoom=2,
              framerate=60,
              aspect=PAL,
              undodepth=33,   // Needs to be one bigger than the actual undo steps
              awtselector=-1, // Use AWT's file dialog instead of JFileChooser, -1 = platform default
              bwidth=12;      // Border width

    final int UIWIDTH=265, // Approx total width for the UI buttons
              ANWIDTH=17*16, // Approx total width for the anim buttons plus frame counter
              UIROW=24,      // UI row size (text or button)
              PREBORDER_X=32, // Preview window border width
              PREBORDER_Y=36, // Preview window border height
    
              ERASEBUTTON=RIGHT, // Feel free to swap these
              PICKERBUTTON=CENTER,
    
              BACKUP=60*2, // How many seconds until automatic backup
              MESSAGEDURATION=60*3, // How many frames messages last
    
              BWTHRESHOLD=128; // Your preferred threshold for b/w PET image conversion
                               // 0..255, the larger the darker images
    
    boolean   grid=true, // Default values for these
              crosshair=false, 
              info=true, 
              showoff=false, // Show memory offset

              debug=false,
              tablet=false,
              forcemetal=false, // Force use of Metal theme
              disablewheel=false; // Disable mouse wheel
    
    final boolean ORIGOZERO=false,     // Show starting from (0,0) or (1,1)
                  PRINTMESSAGES=false; // Print messages to console, if false then to screen
    
    final String FILENAME="image.c",   // Default name for an image
                 SETFILE="sets.txt",
                 FONTFILE="arial.vlw", // UI font, 16 pix
                 PREFSFILE="prefs.txt";
    
    String    path="", // Default paths for files
              refpath="",
              backupfile="_backup_.c",
              convertcommand="",
              inputfile="";  // image to be autoloaded

    Preferences()
    {
    }
    
    // Read the preferences file
    void readprefs(String namn)
    {
        UserFile prefsfile = new UserFile(namn);
        prefsfile.load();
        String row[] = prefsfile.data;

        if(row != null)
        {            
            for(int i=0;i<row.length;i++) // Parse each line
            {
                if(row[i].length()>1)
                {
                    String s[]=split(row[i],"=");
                    
                    if(s[0].equals("ZOOM") && s.length>1)
                    {
                        zoom=int(s[1]);
                        if(zoom<1 && zoom<=10)
                            zoom=2;
                    }
                    if(s[0].equals("FRAMERATE") && s.length>1)
                    {
                        framerate=int(s[1]);
                        if(framerate<1) // Can't be negative or 0
                            framerate=60;
                    }
                    if(s[0].equals("MACHINE") && s.length>1)
                    {
                        for(int j=0;j<machinenames.length;j++)
                            if(s[1].equals(machinenames[j]))
                                machine=j;
                    }
                    if(s[0].equals("ASPECT") && s.length>1)
                    {
                        if(s[1].equals("PAL")) aspect=PAL;
                        if(s[1].equals("NTSC")) aspect=NTSC;
                        if(s[1].equals("SQUARE")) aspect=SQUARE;
                    }
                    if(s[0].equals("PATH") && s.length>1)
                    {
                        path=refpath=s[1];
                        message("Default path: "+path);
                    }
                    if(s[0].equals("OFFSET") && s.length>1)
                    { 
                        if(s[1].equals("1"))
                            showoff=true;
                        else
                            showoff=false;
                    }
                    if(s[0].equals("XSIZE") && s.length>1)
                        X=int(s[1]);
                    if(s[0].equals("YSIZE") && s.length>1)
                        Y=int(s[1]);
                    if(s[0].equals("CONVERTER") && s.length>1)
                    {
                        convertcommand=s[1];
                        if(!convertcommand.equals(""))
                            message("Converter command: "+convertcommand);   
                    }
                    if(s[0].equals("UNDODEPTH") && s.length>1)
                    {
                        if(s[1].length()>0)
                        {
                            int u=int(s[1]);
                            if(u>0 && u<1000)
                                undodepth=u+1; // Needs +1 because the current frame is part of the buffer
                            else
                                message("Impossible undo depth");
                        }
                    }
                    if(s[0].equals("BACKUPFILE") && s.length>1)
                    {
                        if(s[1].length()>1)
                            backupfile=s[1];
                    }
                    if(s[0].equals("TABLET") && s.length>1)
                    {
                        if(s[1].equals("1"))
                            tablet=true;
                        else
                            tablet=false;
                    }
                    if(s[0].equals("FORCEMETAL") && s.length>1) // Prefer Metal instead of the "native" look for Win/Lin(GTK)
                    {
                        if(s[1].equals("1"))
                            forcemetal=true;
                        else
                            forcemetal=false;
                    }
                    if(s[0].equals("AWTSELECTOR") && s.length>1) // Use AWT's fileselector instead of Swing's
                    {
                        if(s[1].equals("1"))
                            awtselector=1;
                        if(s[1].equals("0"))
                            awtselector=0;
                    }
                    if(s[0].equals("DISABLEWHEEL") && s.length>1) // Disable mouse wheel actions
                    {
                        if(s[1].equals("1"))
                            disablewheel=true;
                        else
                            disablewheel=false;
                    }
                }
            }
        }
        
        // Parse the command line
        for(int i=0;args!=null && i<args.length;i++)
        {
            // Set the machine
            for(int j=0;j<machinenames.length;j++)
                if(args[i].equalsIgnoreCase("-"+machinenames[j]))
                    machine=j;

            if(args[i].equalsIgnoreCase("-zoom")) // Zoom
            {
                if(args.length>i+1)
                {
                    int z=int(args[i+1]);
                    
                    if(z>0 && z<=10)
                        zoom=z;
                }
            }
            
            if(args[i].equalsIgnoreCase("-size")) // Canvas size in chars
            {
                if(args.length>i+2)
                {
                    int x=int(args[i+1]),
                        y=int(args[i+2]);
                    
                    if(x>0 && y>0)
                    {
                        X=x;
                        Y=y;
                    }
                }
            }
            if(args[i].equalsIgnoreCase("-input")) // load file
            {
                if(args.length>i+1)
                {
                    inputfile = args[i+1];
                }
            }
        }
    }
}
