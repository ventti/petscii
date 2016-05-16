
// Commodore Plus/4 specific thingies

class Plus4 extends Machine
{
    // Grabbed this from VICE screen:
    final int plus4_rgb[]={
        #000000,#2C2C2C,#621307,#00424C,#510378,#004E00,#27188E,#303E00,#582100,#463000,#244400,#630448,#004E0C,#0E2784,#33118E,#184800,
        #000000,#3B3B3B,#702419,#00505A,#601685,#125D00,#36289B,#3F4C00,#663100,#553F00,#345200,#711656,#005C1D,#1F3691,#42229B,#285700,
        #000000,#424242,#772C21,#055861,#661E8C,#1B6400,#3E30A2,#475400,#6D3900,#5C4700,#3B5900,#771F5D,#046325,#273E98,#492AA1,#305E00,
        #000000,#515151,#843B31,#17656F,#742E99,#2B7100,#4C3FAF,#556200,#7A4709,#6A5500,#4A6700,#852F6B,#177135,#364CA5,#5739AE,#3F6B00,
        #000000,#7A7A7A,#AC665C,#468E97,#9C5AC0,#57992E,#766AD5,#7E8A13,#A2713A,#927E20,#748F14,#AC5A93,#459960,#6276CB,#8064D4,#6A9419,
        #000000,#959595,#C58178,#62A8B1,#B675D9,#73B34C,#9185ED,#99A433,#BB8C57,#AC993E,#8FAA34,#C676AD,#62B37B,#7D91E4,#9B80ED,#85AE38,
        #000000,#AFAFAF,#DE9B93,#7DC2CA,#CF90F2,#8DCD68,#AB9FFF,#B3BE51,#D5A673,#C6B35B,#A9C351,#DF91C7,#7DCC96,#97ABFD,#B59AFF,#9FC755,
        #000000,#E1E1E1,#FFCFC6,#B2F4FC,#FFC4FF,#C1FE9D,#DDD2FF,#E5F088,#FFD9A8,#F7E591,#DBF588,#FFC4F9,#B1FEC9,#CBDDFF,#E7CDFF,#D2F98C
    };
    
    // A brighter one: http://en.wikipedia.org/wiki/List_of_8-bit_computer_hardware_palettes
    /*final int plus4_rgb[]={
        #000000,#202020,#5D0800,#003746,#5D006D,#004E00,#20116D,#202F00,#5D1000,#3E1F00,#013E00,#5D0120,#003F20,#00306D,#3E016D,#004600,
        #000000,#404040,#7D2819,#035766,#7D128D,#036E00,#40318D,#404F00,#7D3000,#5E3F00,#215E00,#7D2140,#035F40,#03508D,#5E218D,#036619,
        #000000,#606060,#9C4839,#237786,#9C32AC,#238E13,#6051AC,#606F13,#9C5013,#7E5F13,#417E13,#9C4160,#237F60,#2370AC,#7E41AC,#238639,
        #000000,#808080,#BC6859,#4397A6,#BC52CC,#43AD33,#8071CC,#808E33,#BC6F33,#9E7F33,#619E33,#BC6180,#439E80,#4390CC,#9E61CC,#43A659,
        #000000,#9F9F9F,#DC8879,#63B7C6,#DC71EC,#63CD53,#9F90EC,#9FAE53,#DC8F53,#BE9F53,#81BE53,#DC809F,#63BE9F,#63AFEC,#BE81EC,#63C679,
        #000000,#BFBFBF,#FCA899,#82D7E6,#FC91FF,#82ED72,#BFB0FF,#BFCE72,#FCAF72,#DEBF72,#A1DE72,#FCA0BF,#82DEBF,#82CFFF,#DEA1FF,#82E699,
        #000000,#DFDFDF,#FFC8B9,#A2F7FF,#FFB1FF,#A2FF92,#DFD0FF,#DFEE92,#FFCF92,#FEDF92,#C1FE92,#FFC0DF,#A2FEDF,#A2EFFF,#FEC1FF,#A2FFB9,
        #000000,#FFFFFF,#FFE8D9,#C2FFFF,#FFD1FF,#C2FFB2,#FFF0FF,#FFFFB2,#FFEFB2,#FFFEB2,#E1FFB2,#FFE0FF,#C2FFFF,#C2FFFF,#FFE1FF,#C2FFD9
    };*/
    
    final int plus4_shift[][]={{111,82,70,64,67,68,69,119},
                               {101,84,71,66,93,72,89,103},
                               {116,84,71,66,93,72,89,106}};

    Plus4()
    {
        machine=PLUS4;
        machinename=machinenames[machine];
        
        nativex=40;
        nativey=25;
        
        fontfile="petscii-c64.png";
        remapfile="remap-c64.txt";
        setfile="sets.txt";
        cset=new Petscii(fontfile,remapfile,setfile);
        
        charx=cset.xsize*prefs.zoom;
        if(prefs.aspect==NTSC)
            chary=cset.ysize*prefs.zoom*5/4; // This is a bit of a guess, but could be right
        else
            chary=cset.ysize*prefs.zoom;     // They are quite square on PAL, aren't they?
        cset.initrender(charx,chary);
        
        csheight=chary*2/3;
        csrows=plus4_rgb.length/16;
        
        palettemode=true;
        lowercase=false;
        
        erasecolor=16;
        maxpen=127;
        maxborder=127;
        maxbg=127;
        defaultborder=110;
        defaultbg=113;
        green=85;
        
        rgb=plus4_rgb;
        shift=plus4_shift;
    }
    
    // Set lower or upper case
    void setcase(boolean keis)
    {
        lowercase=keis;
        if(lowercase)
        {
            fontfile="shifted-c64.png";
            remapfile="remap-lowercase.txt";
            setfile="sets-lowercase.txt";
        }
        else
        {
            fontfile="petscii-c64.png";
            remapfile="remap-c64.txt";
            setfile="sets.txt";
        }
    }
       
    // Deal with C-64 differently
    void remapcolors(Machine other)
    {
        if(other.machine==C64)
        {
            // This is no rocket science: let's just hand pick the best matches
            int remaptable[]={0,113,24,83, 36,69,14,103, 41,9,66,33, 65,101,70,81};
            
            for(int i=0;i<X*Y;i++)
                if(cf.getcolor(i)<remaptable.length)
                    cf.setcolor(i,remaptable[cf.getcolor(i)]);

            if(cf.bg<remaptable.length)
                cf.setbg(remaptable[cf.bg]);
            if(cf.border<remaptable.length)
                cf.setborder(remaptable[cf.border]);
        }
        else
            super.remapcolors(other);
    }
    
    final String PLUS4_CHEADER=
    "// Compile with cc65: cl65 -t plus4 export.c -o export.prg\n"+
    "\n"+
    "#include <string.h>\n";
    
    final String PLUS4_CFOOTER1=
    "\n"+
    "void main(void)\n"+
    "{\n"+
    "  *(char *)0xff19=img[0];\n"+
    "  *(char *)0xff15=img[1];\n";
    
    final String PLUS4_CFOOTER2=
    "\n"+
    "  memcpy((void *)0xc00,&img[2],1000);\n"+
    "  memcpy((void *)0x800,&img[2+1000],1000);\n"+
    "\n"+
    "  while(1);\n"+
    "}";
    
    void save_c_viewer(String name)
    {
        PrintWriter f=createWriter(name);
    
        f.println(PLUS4_CHEADER);
       
        f.println("unsigned char img[]={ // border,bg,chars,colors");
        f.println(str(cf.border)+","+str(cf.bg)+",");
        
        for(int y=0;y<Y;y++)
        {
            for(int x=0;x<X;x++)
                f.print(str(cf.getchar(x,y))+",");
            f.println();
        }
        for(int y=0;y<Y;y++)
        {
            for(int x=0;x<X;x++)
            {
                f.print(str(cf.getcolor(x,y)));
                if(y!=Y-1 || x!=X-1)
                    f.print(",");
            }
            f.println();
        }
        f.println("};");    
    
        f.print(PLUS4_CFOOTER1);
        if(!lowercase)
            f.println("  *(char *)0xff13=0xd0;");
        f.print(PLUS4_CFOOTER2);
        
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
        
        PrintWriter f=createWriter(name);
        
        f.println("10 rem petcat -text -w3 -o export.prg export.bas");
        f.println("20 print chr$(147)");
        f.println("30 poke 65305,"+str(cf.border));
        f.println("40 poke 65301,"+str(cf.bg));
        if(lowercase)
            f.println("45 poke 65299,212");
        f.println("50 for i=0 to 999:read a:poke 3072+i,a:read a:poke 2048+i,a:next");
        f.println("60 goto 60");
        
        int line=70,idx=0;
        for(int i=0;i<cf.chars.length;i+=4)
        {
            f.print(str(line)+" data ");
            for(int j=0;j<4;j++,idx++)
            {
                f.print(str(cf.getchar(idx))+",");
                f.print(cf.getcolor(idx));
                if(j!=3)
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
    
    // Plus/4 asm viewer, ACME format
    final String PLUS4_HEADER=
    "; Compile with: acme -o export.prg -f cbm export.s\n"+
    "\n"+
    "\t*=$1001\n"+
    "\t!byte $0b,$10,$0a, $00,$9e,$34,$31, $30,$39,$00,$00,$00\n";
    //"\t!byte $0c,$10,$dd,$07,$9e,$20,$34,$31,$31,$30, $00,$00,$00\n";
    
    final String PLUS4_CODE=
    "\n"+
    "\tldx\t#0\n"+
    "\tldy\t#250\n"+
    "kopy:\n"+
    "\tlda\timg,x\n"+
    "\tsta\t$c00,x\n"+
    "\tlda\timg+250,x\n"+
    "\tsta\t$c00+250,x\n"+
    "\tlda\timg+500,x\n"+
    "\tsta\t$c00+500,x\n"+
    "\tlda\timg+750,x\n"+
    "\tsta\t$c00+750,x\n"+
    "\n"+
    "\tlda\timg+1000,x\n"+
    "\tsta\t$800,x\n"+
    "\tlda\timg+1250,x\n"+
    "\tsta\t$800+250,x\n"+
    "\tlda\timg+1500,x\n"+
    "\tsta\t$800+500,x\n"+
    "\tlda\timg+1750,x\n"+
    "\tsta\t$800+750,x\n"+
    "\n"+
    "\tinx\n"+
    "\tdey\n"+
    "\tbne\tkopy\n"+
    "\n"+
    "jumi:\tjmp jumi\n";
    
    void save_asm(String name,boolean selfcontained)
    {
        if(selfcontained && X*Y!=1000)
        {
            message("Unsupported image size for this exporter");
            return;
        }
        
        PrintWriter f=createWriter(name);
    
        if(selfcontained)
            f.println(PLUS4_HEADER);
        
        if(selfcontained)
        {
            if(lowercase)
            {
                f.println("\tlda\t#212");
                f.println("\tsta\t$ff13");
            }
            f.println("\tlda\t#"+str(cf.border));
            f.println("\tsta\t$ff19");
            f.println("\tlda\t#"+str(cf.bg));
            f.println("\tsta\t$ff15");
            f.println(PLUS4_CODE);
            
            f.println("img:");
        }
        else
        {
            f.println("; Border, bg, chars, colors");
            f.println("img:");
            f.println("\t!byte "+str(cf.border)+","+str(cf.bg));
        }
        
        f.println("; Character data");
        for(int y=0;y<Y;y++)
        {
            f.print("\t!byte ");
            for(int x=0;x<X;x++)
            {
                f.print(cf.getchar(x,y));
                if(x!=X-1)
                    f.print(",");
            }
            f.println();
        }
        f.println("; Color data");
        for(int y=0;y<Y;y++)
        {
            f.print("\t!byte ");
            for(int x=0;x<X;x++)
            {
                f.print(cf.getcolor(x,y));
                if(x!=X-1)
                    f.print(",");
            }
            f.println();
        }
        
        f.flush();
        f.close();
        
        message("Written "+name);
    }
    
    void save_prg(String name)
    {
        if(X*Y!=1000)
        {
            message("Unsupported image size for this exporter");
            return;
        }
        
        // Read template
        byte b[]=loadBytes("template-plus4.prg");
          
        // Replace some bytes
        if(lowercase)
            b[15]=(byte)212;
        else
            b[15]=(byte)208;
        b[20]=(byte)cf.border;
        b[25]=(byte)cf.bg;
        
        int offset=88;
        for(int i=0;i<X*Y;i++)
            b[offset++]=(byte)cf.getchar(i);
        for(int i=0;i<X*Y;i++)
            b[offset++]=(byte)cf.getcolor(i);
        
        saveBytes(name,b);
        
        message("Written "+name);
    }
}
