
// VIC-20 specific thingies. Thanks to Viznut for some tips.

class Vic20 extends Machine
{
    final int vic20_rgb[]={#000000,#ffffff,#b61f21,#4df0ff,#b43fff,#44e237,#1a34ff,#dcd71b,
                           #ca5400,#e9b072,#e79293,#9af7fd,#e09fff,#8fe493,#8290ff,#e5de85};
    
    int vic20_shift[][]={{100,82,70,64,67,68,69,99},
                         {101,84,71,66,93,72,89,103}};

    Vic20()
    {
        machine=VIC20;
        machinename=machinenames[machine];
        
        nativex=22;
        nativey=23;
        
        fontfile="petscii-vic20.png";
        remapfile="remap-vic20.txt";
        setfile="sets.txt";
        cset=new Petscii(fontfile,remapfile,setfile);
        
        if(prefs.aspect==SQUARE)
            charx=cset.xsize*prefs.zoom;     // If you wanna ruin it then go ahead
        else
            charx=cset.xsize*prefs.zoom*3/2; // VIC stretch (approximate)
        chary=cset.ysize*prefs.zoom;
        cset.initrender(charx,chary);
        
        csheight=chary*2;
        csrows=1;

        palettemode=true;
        lowercase=false;
        
        defaultborder=3;
        defaultbg=1;
        erasecolor=6;
        maxpen=7;
        maxborder=7;
        maxbg=15;
        green=5;
        
        rgb=vic20_rgb;
        shift=vic20_shift;
    }
    
    // VIC has asymmetric border/pen/bg color handling
    void remapcolors(Machine other)
    {
        if(machine==other.machine) // No need to do anything
            return;
        
        if(other.palettemode)
        {
            // Automatically find the closest colors
            int remaptable[]=new int[other.rgb.length],
                bgtable[]=new int[other.rgb.length];
    
            for(int i=0;i<remaptable.length;i++)
            {
                int diffi=10000000,
                    idx=0,idx2=0;
                for(int j=0;j<rgb.length;j++)
                    if(rgbdistance(other.rgb[i],rgb[j])<diffi)
                    {
                        diffi=rgbdistance(other.rgb[i],rgb[j]);
                        idx=j;
                        if(j<8)
                            idx2=j;
                    }
                remaptable[i]=idx2;
                bgtable[i]=idx;    
            }
            
            for(int i=0;i<X*Y;i++)
            {
                if(cf.getcolor(i)<remaptable.length)
                    cf.setcolor(i,remaptable[cf.getcolor(i)]);
            }
            
            cf.setbg(bgtable[cf.bg]);
            cf.setborder(remaptable[cf.border]);
        }
        else
            super.remapcolors(other);
    }
    
    final String VIC_CHEADER=
    "// Compile with cc65: cl65 export.c -t vic20 -o export.prg\n"+
    "\n"+
    "#include <string.h>\n";
    
    final String VIC_CFOOTER=
    "\n"+
    "void main(void)\n"+
    "{\n"+
    "  *(char *)0x900f=img[0];\n"+
    "  *(char *)0x9005=0xf0;\n"+
    "\n"+
    "  memcpy((void *)0x1e00,&img[1],506);\n"+
    "  memcpy((void *)0x9600,&img[507],506);\n"+
    "\n"+
    "  while(1);\n"+
    "}";
    
    void save_c_viewer(String name)
    {
        PrintWriter f=createWriter(name);
        
        f.println(VIC_CHEADER);
       
        f.println("unsigned char img[]={ // border+bg,chars,colors");
        f.println(str(cf.border+cf.bg*16+8)+",");
        
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
    
        f.println(VIC_CFOOTER);
        
        f.flush();
        f.close();
        
        message("Written "+name);
    }
    
    void save_bas(String name)
    {
        if(X*Y!=22*23)
        {
            message("Unsupported image size for this exporter");
            return;
        }
        
        PrintWriter f=createWriter(name);
        
        f.println("10 rem petcat -text -w2 -l 1001 -o export.prg export.bas");
        f.println("20 print chr$(147)");
        f.println("30 poke 36879,"+str(16*cf.bg+cf.border+8));
        f.println("40 for i=0 to 505:read a:poke 7680+i,a:read a:poke 38400+i,a:next");
        f.println("50 goto 50");
        
        int line=60,idx=0;
        for(int i=0;i<cf.chars.length;i+=11)
        {
            f.print(str(line)+" data ");
            for(int j=0;j<11;j++,idx++)
            {
                f.print(str(cf.getchar(idx))+",");
                f.print(cf.getcolor(idx));
                if(j!=10)
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
    
    // Stub by Lawrence Woodman
    final String VIC_HEADER=
    "; Compile with: acme -o export.prg -f cbm export.s\n"+
    "\n"+
    "\t*=$1001\n"+
    "\t!byte $0c,$10,$dd,$07,$9e, $20,$34,$31,$31,$30, $00,$00,$00\n";
    
    final String VIC_CODE=
    "\n"+
    "\tldx\t#0\n"+
    "\tldy\t#253\n"+
    "kopy:\n"+
    "\tlda\timg,x\n"+
    "\tsta\t$1e00,x\n"+
    "\tlda\timg+253,x\n"+
    "\tsta\t$1e00+253,x\n"+
    "\n"+
    "\tlda\timg+506,x\n"+
    "\tsta\t$9600,x\n"+
    "\tlda\timg+506+253,x\n"+
    "\tsta\t$9600+253,x\n"+
    "\n"+
    "\tinx\n"+
    "\tdey\n"+
    "\tbne\tkopy\n"+
    "\n"+
    "jumi:\tjmp jumi\n";
    
    void save_asm(String name,boolean selfcontained)
    {
        if(selfcontained && X*Y!=22*23)
        {
            message("Unsupported image size for this exporter");
            return;
        }
        
        PrintWriter f=createWriter(name);
        
        if(selfcontained) // Not yet
            f.println(VIC_HEADER);
        
        if(selfcontained)
        {
            f.println("\tlda\t#"+str(cf.border+cf.bg*16+8));
            f.println("\tsta\t$900f");
            f.println(VIC_CODE);
            
            f.println("img:");
        }
        else
        {
            f.println("; Border+bg byte, chars, colors");
            f.println("img:");
            f.println("\t!byte "+str(cf.border+cf.bg*16+8));
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
        int offset=387;
        
        if(X*Y!=22*23)
        {
            message("Unsupported image size for this exporter");
            return;
        }
        
        // Read template
        byte b[]=loadBytes("template-vic20.prg");  
        
        // Replace some bytes
        b[offset++]=(byte)(cf.border+cf.bg*16+8);
        
        for(int i=0;i<X*Y;i++)
        {
            b[offset+i]=(byte)cf.getchar(i);
            b[offset+X*Y+i]=(byte)cf.getcolor(i);
        }
        
        saveBytes(name,b);
        
        message("Written "+name);
    }
}
