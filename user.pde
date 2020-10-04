
// User-specified own hooks here, so that they don't get overwritten all the time

// Setup hook
void user_setup()
{
}

// Frame draw hook
void user_draw()
{
}

final String ANAME="delta";

// Keyboard hook
void user_key()
{   
    if(key=='w') // So far undocumented animation speedcode generator
    {
        if(prefs.machine!=C64 && prefs.machine!=PLUS4)
        {
            message("Not implemented on this platform");
            return;
        }
        
        PrintWriter f=safeWriter(ext(filename,"_decl.c"));
        if(f==null)
            return;
        
        f.println("// C declarations");
        f.println();
        
        f.println("extern char delta[];");
        f.println();
        for(int i=0;i<framecount;i++)
            f.println("extern void "+ANAME+hex(i,4)+"(void);");
        f.println();
            
        f.println("void (*"+ANAME+"fp[])(void)={");
        for(int i=0;i<framecount;i++)
        {
            f.print(ANAME+hex(i,4));
            if(i!=framecount-1)
                f.println(",");
            else
                f.println();
        }
        f.println("};");
        
        f.flush();
        f.close();
        
        f=safeWriter(ext(filename,"_delta.s"));
        if(f==null)
            return;
        
        f.println("\t.global _"+ANAME);
        for(int i=0;i<framecount;i++)
            f.println("\t.global _"+ANAME+hex(i,4));
        f.println();
        
        for(int i=1;i<=framecount;i++) // Write deltas
        {
            Frame f1=frames.get(i-1),
                  f2;
                  
            if(i<framecount)
                f2=frames.get(i);
            else
                f2=frames.get(0); // Wrap

            f.println("_"+ANAME+hex(i-1,4)+":");
            
            int preva=-1;
            for(int j=0;j<X*Y;j++)
            {
                if(f1.getchar(j)!=f2.getchar(j))
                {
                    if(preva!=f2.getchar(j))
                        f.println("\tlda\t#"+str(f2.getchar(j)));
                    
                    if(prefs.machine==C64)
                        f.println("\tsta\t"+str(0x400+j));
                    else
                        f.println("\tsta\t"+str(0xc00+j));
                    preva=f2.getchar(j);
                }
                if(f1.getcolor(j)!=f2.getcolor(j))
                {
                    if(preva!=f2.getcolor(j))
                        f.println("\tlda\t#"+str(f2.getcolor(j)));
                    if(prefs.machine==C64)
                        f.println("\tsta\t"+str(0xd800+j));
                    else
                        f.println("\tsta\t"+str(0x800+j));
                    preva=f2.getcolor(j);
                }
            }
            f.println("\trts");
            f.println();
        }
        
        // Full piccy
        Frame r=frames.get(0);
        
        f.println("_"+ANAME+":");
        f.println("; Border, bg");
        f.println("\t.byte\t"+str(r.border)+","+str(r.bg));
        
        f.println("; Character data");
        for(int y=0;y<Y;y++)
        {
            f.print("\t.byte\t");
            for(int x=0;x<X;x++)
            {
                f.print(r.getchar(x,y));
                if(x!=X-1)
                    f.print(",");
            }
            f.println();
        }
        f.println("; Color data");
        for(int y=0;y<Y;y++)
        {
            f.print("\t.byte\t");
            for(int x=0;x<X;x++)
            {
                f.print(r.getcolor(x,y));
                if(x!=X-1)
                    f.print(",");
            }
            f.println();
        }
        
        f.flush();
        f.close();
        
        message("Wrote "+ext(filename,"_decl.c")+" and "+ext(filename,"_delta.s"));
    }
    
    if(key=='B')
    {
        if(prefs.machine!=C64)
        {
            message("Only implemented for the C-64 for now");
            return;
        }
        
        PrintWriter f=safeWriter(ANAME+".bas");
        if(f==null)
            return;

        f.println("10 rem petcat -text -w3 -o delta.prg delta.bas");
        f.println("20 poke 65305,"+str(cf.border));
        f.println("30 print chr$(147)");
        f.println("40 poke 65301,"+str(cf.bg));
        f.println("50 fori=2048to3047:pokei,"+str(pen)+":next");
        f.println("55 fori=3072to4071:pokei,"+160+":next");
        f.println("60 reada,b:ifa=-1thengoto80");
        f.println("70 pokea,b:goto60");
        f.println("80 goto 80");
        
        int line=90;
        
        int b=0;
        for(int i=1;i<framecount;i++) // Write deltas
        {
            Frame f1=frames.get(i-1),
                  f2=frames.get(i);

            for(int j=0;j<X*Y;j++)
            {
                if(f1.getchar(j)!=f2.getchar(j))
                {
                    if(b%8==0)
                    {
                        f.print("\n"+str(line)+" data 90,4");line+=10;
                        f.print("\n"+str(line)+" data ");
                        line+=10;
                    }
                    else
                        f.printf(",");
                    f.print(str(0xc00+j)+","+f2.getchar(j));
                    b++;
                }
                    
                if(f1.getcolor(j)!=f2.getcolor(j))
                {
                    if(b%8==0)
                    {
                        f.println("\n"+str(line)+" data 90,4");line+=10;
                        f.print("\n"+str(line)+" data ");
                        line+=10;
                    }
                    else
                        f.printf(",");
                    f.print(str(0x800+j)+","+f2.getcolor(j));
                    b++;
                }
            }
        }
        
        f.println();
        f.println(str(line)+" data -1,-1");
        f.println(str(line+10)+" end");
        f.flush();
        f.close();
        
        message("Wrote "+ANAME+".bas");
    }
    
//    if(key=='B')
//    {
//        PrintWriter f=createWriter(ANAME+".bas");
//
//        f.println("10 rem petcat -text -w2 -o delta.prg delta.bas");
//        f.println("20 poke 53280,"+str(border));
//        f.println("30 print chr$(147)");
//        f.println("40 poke 53281,"+str(bg));
//        f.println("50 fori=55296to56295:pokei,"+str(pen)+":next");
//        f.println("60 reada,b:ifa=-1thenrestore:goto60");
//        f.println("70 pokea,b:goto60");
//        
//        int line=70;
//        
//        int b=0;
//        for(int i=1;i<framecount;i++) // Write deltas
//        {
//            Frame f1=(Frame)(frames.get(i-1)),
//                  f2=(Frame)(frames.get(i));
//
//            for(int j=0;j<X*Y;j++)
//            {
//                if(f1.chars[j]!=f2.chars[j])
//                {
//                    if(b%8==0)
//                    {
//                        f.print("\n"+str(line)+" data ");
//                        line+=10;
//                    }
//                    else
//                        f.printf(",");
//                    f.print(str(0x400+j)+","+f2.chars[j]);
//                    b++;
//                }
//                    
//                if(f1.colors[j]!=f2.colors[j])
//                {
//                    if(b%8==0)
//                    {
//                        f.print("\n"+str(line)+" data ");
//                        line+=10;
//                    }
//                    else
//                        f.printf(",");
//                    f.print(str(0x0d800+j)+","+f2.colors[j]);
//                    b++;
//                }
//            }
//        }
//        
//        f.println();
//        f.println(str(line)+" data -1,-1");
//        f.println(str(line+10)+" end");
//        f.flush();
//        f.close();
//        
//        message("Wrote "+ANAME+".bas");
//    }
}
