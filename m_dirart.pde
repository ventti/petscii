
// Directory art specific things. Mostly C64-oriented.

class Dirart extends Machine
{
    final int dirart_rgb[]={#352879,#6C5EB5};
    
    final int dirart_shift[][]={{111,82,70,64,67,68,69,119},
                                {101,84,71,66,93,72,89,103},
                                {116,84,71,66,93,72,89,106}};
                                
    // Disabled chars because of listing limitations
    final int forbidden_chars[]={34,128,141,148,
                                 160,161,162,163,164,165,166,167,
                                 168,169,170,171,172,173,174,175,
                                 176,177,178,179,180,181,182,183,
                                 184,185,186,187,188,189,190,191,
                                 205,
                                 224,225,226,227,228,229,230,231,
                                 232,233,234,235,236,237,238,239,
                                 240,241,242,243,244,245,246,247,
                                 248,249,250,251,252,253,254,255};
    
    Dirart()
    {
        machine=DIRART;
        machinename=machinenames[machine];
        
        nativex=16;
        nativey=25;
        if(X!=16) // Don't try to override this
            X=16;
        if(Y>144) // Maximum of files
            Y=144;
        
        fontfile="petscii-c64.png";
        remapfile="remap-c64.txt";
        setfile="sets.txt";
        cset=new Petscii(fontfile,remapfile,setfile);
        
        charx=cset.xsize*prefs.zoom;
        if(prefs.zoom==1)
            chary=cset.ysize;
        else
        {
            switch(prefs.aspect)
            {
                case PAL: chary=cset.ysize*prefs.zoom*18/16; break;  // C64 PAL stretch
                case NTSC: chary=cset.ysize*prefs.zoom*4/3; break;   // C64 NTSC stretch
                case SQUARE: chary=cset.ysize*prefs.zoom; break;     // Lame square pixels
                default: ;
            }
        }
        cset.initrender(charx,chary);
        
        csheight=0;
        csrows=0;

        palettemode=false;
        lowercase=false;
        
        defaultborder=1;
        defaultbg=0;
        erasecolor=1;
        maxpen=0;
        maxborder=1;
        maxbg=0;
        green=1;
        
        rgb=dirart_rgb;
        shift=dirart_shift;
        grow=thick_grow;
    }
    
    void ownbuttons() // Not implemented features
    {
        import_prg_b.disabled=true;
        export_prg_b.disabled=true;
        case_b.disabled=true;
    }
    
    boolean validate(int c) // Dirart has plenty of disabled chars
    {
        if(c==HOLE)
            return true;
        
        for(int i=0;i<forbidden_chars.length;i++)
            if(c==forbidden_chars[i])
                return false;
        
        return true;
    }
    
    // Let's just strip the colors
    void remapcolors(Machine other)
    {
        if(other.palettemode)
        {
            cf.border=0;
            cf.bg=0;
            
            for(int i=0;i<X*Y;i++)
                cf.setcolor(i,erasecolor);
        }
    }
}
