
// Global setting constants and user-specified preferences

// Machine numbers and their corresponding names
final int C64=0,
          VIC20=1, 
          PET=2,
          PETHI=3,
          PLUS4=4;

final String machinenames[]={
          "C64",
          "VIC20",
          "PET",
          "PETHI",
          "PLUS4"
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
              aspect=PAL;
    
    final int BWIDTH=20,     // Border width
              UIWIDTH=15*16, // Approx total width for the UI buttons
              ANWIDTH=12*16+4*16, // Approx total width for the anim buttons plus frame counter
              UIROW=29,      // UI row size (text or button)
    
              ERASEBUTTON=RIGHT, // Feel free to swap these
              PICKERBUTTON=CENTER,
    
              UNDODEPTH=16, // Increase as you will
    
              BACKUP=60*2, // How many seconds until automatic backup
              MESSAGEDURATION=60*3, // How many frames messages last
    
              BWTHRESHOLD=128; // Your preferred threshold for b/w PET image conversion
                               // 0..255, the larger the darker images
    
    boolean   grid=true, // Default values for these
              crosshair=false, 
              info=true, 
              showoff=false, // Show memory offset
    
              miniwin=false,
              debug=false;
    
    final boolean ORIGOZERO=false,     // Show starting from (0,0) or (1,1)
                  PRINTMESSAGES=false; // Print messages to console, if false then to screen
    
    final String FILENAME="image.c",   // Default name for an image
                 SETFILE="sets.txt",
                 FONTFILE="arial.vlw", // UI font, 16 pix
                 PREFSFILE="prefs.txt";
    
    String    path="", // Default paths for files
              refpath="",
              convertcommand="";
    
    Preferences()
    {
    }
    
    // Read the preferences file
    void readprefs(String namn)
    {
        String row[]=loadStrings(namn);
        
        if(row==null)
            return;
            
        for(int i=0;i<row.length;i++) // Parse each line
        {
            if(row[i].length()>1)
            {
                String s[]=split(row[i],"=");
                
                if(s[0].equals("ZOOM"))
                {
                    zoom=int(s[1]);
                    if(zoom<1)
                        zoom=2;
                }
                if(s[0].equals("FRAMERATE"))
                    framerate=int(s[1]);
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
                    path=s[1];
                    message("Default path: "+path);
                }
                if(s[0].equals("OFFSET"))
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
            }
        }
    }
}