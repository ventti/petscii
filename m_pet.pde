
// PET specific thingies. Asm or prg output not supported at the moment.

class Pet extends Machine
{
    final int pet_rgb[]={#000000,#00ee00};

    final int pet_shift[][]={{100,82,70,64,67,68,69,99},
                             {101,84,71,66,93,72,89,103}};

    Pet()
    {
        machine=PET;
        machinename=machinenames[machine];
        
        nativex=40;
        nativey=25;
        
        fontfile="petscii-pet.png";
        remapfile="remap-vic20.txt";
        setfile="sets.txt";
        cset=new Petscii(fontfile,remapfile,setfile);
        
        charx=cset.xsize*prefs.zoom; // PET stretch (approximate)
        if(prefs.zoom==1)
            chary=cset.ysize*prefs.zoom;
        else
        {
            if(prefs.aspect==SQUARE)
                chary=cset.ysize*prefs.zoom;
            else
                chary=cset.ysize*prefs.zoom*5/4;
        }
        cset.initrender(charx,chary);
            
        csheight=0;
        csrows=0;

        palettemode=false;
        lowercase=false;
        
        erasecolor=1;
        maxpen=0;
        maxborder=0;
        maxbg=0;
        defaultbg=0;
        defaultborder=0;
        green=1;
        
        rgb=pet_rgb;
        shift=pet_shift;
        grow=default_grow;
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
    
    final String PET_CHEADER=
    "// Compile with cc65: cl65 export.c -t pet -o export.prg\n"+
    "\n"+
    "#include <string.h>\n";
    
    final String PET_CFOOTER=
    "\n"+
    "void main(void)\n"+
    "{\n"+
    "\n"+
    "  *(char *)0xe84c=12;\n"+
    "  memcpy((void *)32768u,img,1000);\n"+
    "\n"+
    "  //while(1);\n"+
    "}";
    
    void save_c_viewer(String name)
    {
        PrintWriter f=safeWriter(name);
        if(f==null)
            return;
        
        f.println(PET_CHEADER);
       
        f.println("unsigned char img[]={");
        
        for(int y=0;y<Y;y++)
        {
            int x;
            for(x=0;x<X;x++)
            {
                f.print(str(cf.getchar(x,y)));
                if(x!=X-1 || y!=Y-1)
                    f.print(",");
            }
            f.println();
        }
        f.println("};"); 
    
        f.println(PET_CFOOTER);
        
        f.flush();
        f.close();
        
        message("Written "+name);
    }
    
    void save_bas(String name)
    {
        if(X*Y!=1000)
        {
            message("Unsupported image size for this exporter");
            return;
        }
        
        PrintWriter f=safeWriter(name);
        if(f==null)
            return;
        
        f.println("10 rem petcat -text -w4 -l 401 -o export.prg export.bas");
        f.println("20 print chr$(147)");
        f.println("40 for i=0 to 999:read a:poke 32768+i,a:next");
        f.println("50 goto 50");
        
        int line=60,idx=0;
        for(int i=0;i<cf.chars.length;i+=8)
        {
            f.print(str(line)+" data ");
            for(int j=0;j<8;j++,idx++)
            {
                f.print(str(cf.getchar(idx)));
                if(j!=7)
                    f.print(",");
            }
            
            f.println();
        
            line+=10;
        }

        f.println(str(line)+" end");

        f.flush();
        f.close();
        
        message("Written "+name);
    }
}
