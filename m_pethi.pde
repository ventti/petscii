
// PET 80 character mode specific thingies. Asm or prg output not supported at the moment.

class Pethi extends Pet
{
    Pethi()
    {
        super();
        machine=PETHI;
        machinename=machinenames[machine];
        
        nativex=80;
        nativey=25;

        fontfile="petscii-pethi.png";
        remapfile="remap-vic20.txt";
        setfile="sets.txt";
        cset=new Petscii(fontfile,remapfile,setfile);
        
        charx=cset.xsize*prefs.zoom; // PET stretch (approximate)
        chary=cset.ysize*prefs.zoom;

        cset.initrender(charx,chary);
    }
        
    final String PETHI_CFOOTER=
    "\n"+
    "void main(void)\n"+
    "{\n"+
    "\n"+
    "  *(char *)0xe84c=12;\n"+
    "  memcpy((void *)32768u,img,2000);\n"+
    "\n"+
    "  while(1);\n"+
    "}";
    
    void save_c_viewer(String name)
    {
        PrintWriter f=createWriter(name);
        
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
    
        f.println(PETHI_CFOOTER);
        
        f.flush();
        f.close();
        
        message("Written "+name);
    }
    
    // Might not work on all PETs, can't test...
    void save_bas(String name)
    {
        if(X*Y!=2000)
        {
            message("Unsupported image size for this exporter");
            return;
        }
        
        PrintWriter f=createWriter(name);
        
        f.println("10 rem petcat -text -w4 -l 401 -o export.prg export.bas");
        f.println("20 print chr$(147)");
        f.println("30 poke 59468,12");
        f.println("40 for i=0 to 1999:read a:poke 32768+i,a:next");
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
