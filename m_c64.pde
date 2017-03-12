
// Commodore 64 specific thingies

class C64 extends Machine
{
    // Pepto's murky C64 palette: http://www.pepto.de/projects/colorvic/
    final int c64_rgb[]={#000000,#FFFFFF,#68372B,#70A4B2,#6F3D86,#588D43,#352879,#B8C76F,
                         #6F4F25,#433900,#9A6759,#444444,#6C6C6C,#9AD284,#6C5EB5,#959595};

    // Pepto's new C64 palette, "Colodore": http://www.colodore.com/
//    final int c64_rgb[]={#000000,#FFFFFF,#813338,#75cec8,#8e3c97,#56ac4d,#2e2c9b,#edf171,
//                         #8e5029,#553800,#c46c71,#4a4a4a,#7b7b7b,#a9ff9f,#706deb,#b2b2b2};

    final int c64_shift[][]={{111,82,70,64,67,68,69,119},
                             {101,84,71,66,93,72,89,103},
                             {116,84,71,66,93,72,89,106}};

    C64()
    {
        machine=C64;
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
        
        csheight=chary*2;
        csrows=1;

        palettemode=true;
        lowercase=false;
        
        defaultborder=14;
        defaultbg=6;
        erasecolor=14;
        maxpen=15;
        maxborder=15;
        maxbg=15;
        green=5;
        
        rgb=c64_rgb;
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
    "#include <string.h>\n";
    
    final String C64_CFOOTER1=
    "\n"+
    "void main(void)\n"+
    "{\n"+
    "  *(char *)0xd011=8+3;\n"+
    "  *(char *)0xd020=img[0];\n"+
    "  *(char *)0xd021=img[1];\n";
    
    final String C64_CFOOTER2=
    "\n"+
    "  memcpy((void *)0x400,&img[2],1000);\n"+
    "  memcpy((void *)0xd800,&img[2+1000],1000);\n"+
    "\n"+
    "  *(char *)0xd011=16+8+3;\n"+
    "\n"+
    "  while(1);\n"+
    "}";
    
    void save_c_viewer(String name)
    {
        PrintWriter f=createWriter(name);
    
        f.println(C64_CHEADER);
       
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
    
        f.print(C64_CFOOTER1);
        if(!lowercase)
            f.println("  *(char *)0xd018=0x14;");
        f.println(C64_CFOOTER2);
        
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
        
        f.println("10 rem petcat -text -w2 -o export.prg export.bas");
        f.println("20 print chr$(147)");
        f.println("30 poke 53280,"+str(cf.border));
        if(lowercase)
            f.println("35 poke 53272,23");
        f.println("40 poke 53281,"+str(cf.bg));
        f.println("50 for i=0 to 999:read a:poke 1024+i,a:read a:poke 55296+i,a:next");
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
    
    // This is my first ever 6502 asm program, so gimme a break
    final String C64_HEADER=
    "; Compile with: acme -o export.prg -f cbm export.s\n"+
    "\n"+
    "\t*=$801\n"+
    "\t!byte $b,$08,$ef,$0,$9e,$32,$30,$36,$31,$0,$0,$0\n"+
    "\n"+
    "\tlda\t#11\n"+
    "\tsta\t$d011";
    
    final String C64_CODE=
    "\n"+
    "\tldx\t#0\n"+
    "\tldy\t#250\n"+
    "kopy:\n"+
    "\tlda\timg,x\n"+
    "\tsta\t$400,x\n"+
    "\tlda\timg+250,x\n"+
    "\tsta\t$400+250,x\n"+
    "\tlda\timg+500,x\n"+
    "\tsta\t$400+500,x\n"+
    "\tlda\timg+750,x\n"+
    "\tsta\t$400+750,x\n"+
    "\n"+
    "\tlda\timg+1000,x\n"+
    "\tsta\t$d800,x\n"+
    "\tlda\timg+1250,x\n"+
    "\tsta\t$d800+250,x\n"+
    "\tlda\timg+1500,x\n"+
    "\tsta\t$d800+500,x\n"+
    "\tlda\timg+1750,x\n"+
    "\tsta\t$d800+750,x\n"+
    "\n"+
    "\tinx\n"+
    "\tdey\n"+
    "\tbne\tkopy\n"+
    "\n"+
    "\tlda\t#27\n"+
    "\tsta\t$d011\n"+
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
        {
            f.println(C64_HEADER);
            if(lowercase)
            {
                f.println("\tlda\t#23");
                f.println("\tsta\t$d018");
            }
        }
        
        if(selfcontained)
        {
            f.println("\tlda\t#"+str(cf.border));
            f.println("\tsta\t$d020");
            f.println("\tlda\t#"+str(cf.bg));
            f.println("\tsta\t$d021");
            f.println(C64_CODE);
            
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
    
    void save_seq(String name)
    {
        int seq_colors[]={
            0x90, //black
            0x05, //white
            0x1c, //red
            0x9f, //cyan
            0x9c, //purple
            0x1e, //green
            0x1f, //blue
            0x9e, //yellow
            0x81, //orange
            0x95, //brown
            0x96, //pink
            0x97, //grey 1
            0x98, //grey 2
            0x99, //lt green
            0x9a, //lt blue
            0x9b //grey 3
        };
        
        int i=0,curcolor=-1;
        
        boolean currev=false;
        
        byte b[]=new byte[X*Y*3]; // Maximum needed size
        
        // Convert to seq
        for(int j=0;j<X*Y;j++)
        {
            // Color first
            if(cf.getcolor(j)!=curcolor) // Need new color
            {
                curcolor=cf.getcolor(j);
                b[i]=(byte)seq_colors[curcolor];
                i++;
            }
            
            int c=cf.getchar(j);
            if(c>=0x80) // Inverted char
            {
                if(!currev) // Change rev
                {
                    currev=true;
                    b[i]=0x12;
                    i++;
                }
                c&=0x7f;
            }
            else
            {
                if(currev) // Change rev
                {
                    currev=false;
                    b[i]=(byte)0x90;
                    i++;
                }
            }
            
            // Finally change screen code to PETSCII. Pretty much straight copypaste from Six.
            if ((c >= 0) && (c <= 0x1f))
            {
                c = c + 0x40;
            }
            else
            {
                if ((c >= 0x40) && (c <= 0x5d))
                {
                    c = c + 0x80;
                } 
                else
                {
                    if (c == 0x5e){
                        c = 0xff;
                    } 
                    else 
                    {
                        if (c == 0x95)
                        {
                            c = 0xdf;
                        } 
                        else
                        {
                            if ((c >= 0x60) && (c <= 0x7f))
                            {
                                c = c + 0x80;
                            }
                            else
                            {
                                if ((c >= 0x80) && (c <= 0xbf))
                                {
                                    c = c - 0x80;
                                }
                                else
                                {
                                    if ((c >= 0xc0) && (c <= 0xff))
                                    {
                                        c = c -0x40;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            b[i]=(byte)c; // And there it goes
            i++;
        }
        
        // Write the final file
        byte bb[]=new byte[i];
        for(int j=0;j<i;j++)
            bb[j]=b[j];
        saveBytes(name,bb);
        
        message("Written "+name);
    }
}
