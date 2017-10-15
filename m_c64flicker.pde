
// Commodore 64 two-page flicker mode specific thingies

class C64flicker extends Machine
{
    // Pepto's murky C64 palette: http://www.pepto.de/projects/colorvic/
    final int c64_rgb[]={#000000,#FFFFFF,#68372B,#70A4B2,#6F3D86,#588D43,#352879,#B8C76F,
                         #6F4F25,#433900,#9A6759,#444444,#6C6C6C,#9AD284,#6C5EB5,#959595};
                         
    // Flicker color combinations
    final int flicker_pairs[]={0,0, 6,0, 6,6, 14,6, 14,14, 14,12, 11,6, 9,6, 6,4, 6,2, 8,6, 11,4, 4,4, 14,4, 14,10, 12,4,
                               4,2, 8,4, 2,2, 9,2, 9,9, 11,9, 8,2, 8,8, 10,10, 8,4, 9,4, 11,2, 12,2, 14,8, 12,8, 12,10,
                               15,10, 7,7, 13,7, 13,13, 7,3, 13,3, 3,3, 5,3, 5,5, 12,5, 11,11, 12,12, 15,15, 1,1};
   
    // Initial attempt
    //     {0,0, 1,1, 2,2, 3,3, 4,4, 5,5, 6,6, 7,7, 8,8, 9,9, 10,10, 11,11, 12,12, 13,13, 14,14, 15,15,
    //     4,2, 5,3, 6,0, 6,2, 6,4, 7,3, 8,2, 8,4, 8,6, 9,2, 9,4, 9,6, 0xb,2, 0xb,4, 0xb,6, 0xb,9, 0xc,2,
    //     0xc,4, 0xc,5, 0xc,8, 0xc,0xa, 0xd,3, 0xd,7, 0xe,4, 0xe,6, 0xe,8, 0xe,0xa, 0xe,0xc, 0xf,3, 0xf,0xa};
       
    int flicker_rgb[];

    final int c64_shift[][]={{111,82,70,64,67,68,69,119},
                             {101,84,71,66,93,72,89,103},
                             {116,84,71,66,93,72,89,106}};

    C64flicker()
    {
        machine=C64FLICKER;
        machinename=machinenames[machine];
        
        nativex=40;
        nativey=25;
        
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
        
        csheight=chary*3/2;
        csrows=flicker_pairs.length/2/16+1;

        palettemode=true;
        lowercase=false;
        
        // Calculate flicker colors
        flicker_rgb=new int[flicker_pairs.length/2];
        for(int i=0;i<flicker_rgb.length;i++)
        {   
            int r=(((c64_rgb[flicker_pairs[i*2]]>>16)&0xff)+((c64_rgb[flicker_pairs[i*2+1]]>>16)&0xff))/2,
                g=(((c64_rgb[flicker_pairs[i*2]]>>8)&0xff)+((c64_rgb[flicker_pairs[i*2+1]]>>8)&0xff))/2,
                b=(((c64_rgb[flicker_pairs[i*2]]>>0)&0xff)+((c64_rgb[flicker_pairs[i*2+1]]>>0)&0xff))/2;
            
            flicker_rgb[i]=0xff000000+(r<<16)+(g<<8)+b;
        }
        
        defaultborder=0;
        defaultbg=0;
        erasecolor=14;
        maxpen=flicker_rgb.length-1;
        maxborder=flicker_rgb.length-1;
        maxbg=flicker_rgb.length-1;
        green=5;
        
        rgb=flicker_rgb;
        shift=c64_shift;
    }
    
    // Set lower or upper case. True for lowercase, false for normal mode.
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
    
    final String C64_CHEADER=
    "// Compile with cc65: cl65 export.c -o export.prg\n"+
    "\n"+
    "#include <string.h>\n"+
    "#define waitline(x) while(*(unsigned char *)0xd012!=x);\n";
    
    final String C64_CFOOTER1=
    "\n"+
    "void main(void)\n"+
    "{\n"+
    "  *(char *)0xd011=8+3;\n";
    
    final String C64_CFOOTER2=
    "\n"+
    "  memcpy((void *)0x400,&img[4],1000);\n"+
    "\n"+
    "  *(char *)0xd020=img[0];\n"+
    "  *(char *)0xd021=img[1];\n"+
    "  *(char *)0xd011=16+8+3;\n"+
    "  __asm__(\"sei\");\n"+
    "\n"+
    "  while(1){\n"+
    "    waitline(254);\n"+
    "    waitline(255);\n"+
    "    if(img[0]!=img[2]) *(char *)0xd020=img[0];\n"+
    "    if(img[1]!=img[3]) *(char *)0xd021=img[1];\n"+
    "    memcpy((void *)0xd800,&img[4+1000],1000);\n"+ 
    "    waitline(254);\n"+
    "    waitline(255);\n"+
    "    if(img[0]!=img[2]) *(char *)0xd020=img[2];\n"+
    "    if(img[1]!=img[3]) *(char *)0xd021=img[3];\n"+
    "    memcpy((void *)0xd800,&img[4+2000],1000);\n"+ 
    "  }\n"+
    "}";
    
    void save_c_viewer(String name)
    {
        PrintWriter f=createWriter(name);
    
        f.println(C64_CHEADER);
       
        f.println("unsigned char img[]={ // (border, bg) x2,chars,colors x2");
        f.println(str(flicker_pairs[cf.border*2])+","+str(flicker_pairs[cf.bg*2])+",");
        f.println(str(flicker_pairs[cf.border*2+1])+","+str(flicker_pairs[cf.bg*2+1])+",");
        
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
                f.print(str(flicker_pairs[cf.getcolor(x,y)*2]));
                if(y!=Y-1 || x!=X-1)
                    f.print(",");
            }
            f.println();
        }
        f.println(",");
        for(int y=0;y<Y;y++)
        {
            for(int x=0;x<X;x++)
            {
                f.print(str(flicker_pairs[cf.getcolor(x,y)*2+1]));
                if(y!=Y-1 || x!=X-1)
                    f.print(",");
            }
            f.println();
        }
        f.println("};");
    
        f.print(C64_CFOOTER1);
        if(!lowercase)
            f.println("  *(char *)0xd018=0x14;");
        f.println(C64_CFOOTER2);
        
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
        byte b[]=loadBytes("template-c64.prg");
          
        // Replace some bytes
        if(lowercase)
            b[20]=23;
        else
            b[20]=20;
        b[25]=(byte)cf.border;
        b[30]=(byte)cf.bg;
        
        int offset=98;
        for(int i=0;i<X*Y;i++)
            b[offset++]=(byte)cf.getchar(i);
        for(int i=0;i<X*Y;i++)
            b[offset++]=(byte)cf.getcolor(i);
        
        saveBytes(name,b);
        
        message("Written "+name);
    }
}
