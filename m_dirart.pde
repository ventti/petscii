
// Directory art specific things. Mostly C64-oriented.

class Dirart extends Machine
{
    final int dirart_rgb[]={#352879,#6C5EB5};
    
    final int dirart_shift[][]={{111,82,70,64,67,68,69,119},
                                {101,84,71,66,93,72,89,103},
                                {116,84,71,66,93,72,89,106}};
    
    Dirart()
    {
        machine=DIRART;
        machinename=machinenames[machine];
        
        nativex=16;
        nativey=25;
        if(X!=16) // Don't try to override this
            X=16;
        
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
}
