
// Character and font related bits

final int HOLE=-1;

class Charset
{
    PImage bitmap,pet[];
    
    int    blendfactor[], // character bg/fg pixel ratio for thumbnail
           sets[][],
           remap[],
           shift[][],
           grow[][],
           erasechar,
           charactercount,
           xsize,
           ysize,
           renderx,
           rendery;
           
    String setnames[];
    
    Charset(String fontfile,String remapfile,String setfile)
    {
        erasechar=0x20;
        charactercount=256;
        
        xsize=ysize=8;
        
        blendfactor=new int[charactercount];
        remap=new int[charactercount];

        loadfont(fontfile);
        loadremap(remapfile);
        loadsets(setfile);
    }
    
    // Find if a char is part of a set. If next is true, return next char idx, otherwise set number
    int findset(int c,boolean next)
    {
        for(int i=0;i<sets.length;i++)
            for(int j=0;j<sets[i].length;j++)
                if(c==sets[i][j])
                {
                    if(next)
                        return sets[i][(j+1)%sets[i].length];
                    else
                        return i;
                }
                        
        return -1;            
    }
    
    // Loads a char selector remap file
    boolean loadremap(String name)
    {
        if(name==null) // We can skip it too
        {
            remap=new int[charactercount];
            for(int i=0;i<charactercount;i++)
                remap[i]=i;
            return true;
        }
        
        String tmp[]=loadStrings(name);
        if(tmp==null)
            return false;
            
        for(int i=0;i<charactercount;i++)
            remap[i]=int(tmp[i]);
        
        return true;
    }
    
    // Load a set file
    boolean loadsets(String name)
    {
        if(name==null) // We can skip sets too
        {
            sets=new int[0][0];
            return true;
        }
        
        String setfile[]=loadStrings(name);
        if(setfile==null)
            return false;
        
        int setnum=setfile.length/2;
        setnames=new String[setnum];
        sets=new int[setnum][];
        for(int i=0;i<setnum;i++)
        {
            setnames[i]=setfile[i*2];
            String charnums[]=splitTokens(setfile[i*2+1],",");
            sets[i]=new int[charnums.length];
            for(int j=0;j<charnums.length;j++)
                sets[i][j]=int(charnums[j]);
        }
        
        return true;
    }
    
    boolean loadfont(String name)
    {
        if(name==null)
            return true;

        PImage img=loadImage(name);
        if(img==null)
            return false;

        // The renderer expects a single-row strip of 256 chars (each 8x8), i.e.
        // a 2048x8 image. Any image whose width and height are multiples of 8 and
        // that holds exactly 256 tiles is reflowed here into that strip, reading
        // tiles left-to-right then top-to-bottom. A 2048x8 file passes through
        // unchanged.
        PImage strip=tilestrip(img);
        bitmap = (strip!=null) ? strip : img;

        ysize=bitmap.height;

        return true;
    }

    // Rearrange an 8x8-tiled image into the internal single-row 256-char strip.
    // Returns null if the image is not 8px-aligned or does not hold exactly 256 tiles.
    PImage tilestrip(PImage img)
    {
        final int tw=8, th=8;

        if(img.width%tw!=0 || img.height%th!=0)
            return null;

        int cols=img.width/tw,
            rows=img.height/th;

        if(cols*rows!=charactercount) // must be exactly 256 tiles
            return null;

        PImage strip=createImage(charactercount*tw, th, ARGB);
        img.loadPixels();
        strip.loadPixels();

        for(int t=0;t<charactercount;t++)
        {
            int sx=(t%cols)*tw, // source tile origin, in reading order
                sy=(t/cols)*th;

            for(int y=0;y<th;y++)
                for(int x=0;x<tw;x++)
                    strip.pixels[t*tw+x +y*strip.width] = img.pixels[sx+x +(sy+y)*img.width];
        }
        strip.updatePixels();

        return strip;
    }
    
    void initrender(int targetx,int targety)
    {
        renderx=targetx;
        rendery=targety;
        
        bitmap.loadPixels();
        
        pet=new PImage[charactercount];
        
        for(int i=0;i<charactercount;i++)
        {
            pet[i]=new PImage(renderx,rendery,ARGB);
            pet[i].loadPixels();
    
            // Black=alpha. Do our own scaling to avoid blur.        
            for(int y=0;y<rendery;y++)
            {
                for(int x=0;x<renderx;x++)
                {
                    int idx;
                    
                    idx=i*xsize +x*xsize/renderx +(y*ysize/rendery)*bitmap.width;
                
                    if((bitmap.pixels[idx]&255)<20) // Black
                        pet[i].pixels[y*renderx+x]=0x00000000;
                    else
                        pet[i].pixels[y*renderx+x]=0xffffffff;
                }
            }
            
            // Count the pixels or each char
            int pixelcount=0;
            for(int y=0;y<ysize;y++)
            {
                for(int x=0;x<xsize;x++)
                if((bitmap.pixels[y*bitmap.width+x+i*8]&255)>20)
                    pixelcount++;
            }
            
            blendfactor[i]=4*(int)sqrt(pixelcount*64); // A bit of "gamma" correction to emphasize small chars
        }
    }
    
    // Plot a char here with this color
    void drawchar(int x,int y,int num,int fg,int bg)
    {
        if(num==HOLE)
            return;
        
        if(pet==null) // So there: trying to draw before calling initrender()
            return;
        
        PImage charri=pet[num];
        
        int a=machine.rgb[fg],
            b=machine.rgb[bg],
            idx;
        
        if(!machine.validate(num)) // Invalid char, oh no. Show in red.
        {
            a=#773333;
            b=#441111;
        }
        
        idx=x+y*width;
        for(int j=0,k=0;j<machine.chary;j++)
        {
            for(int i=0;i<machine.charx;i++,k++,idx++)
                if((charri.pixels[k]&0xff) > 20)
                    pixels[idx]=a;
                else
                    pixels[idx]=b;
            
            idx+=width-machine.charx;
        }
    }
    
    // 4x4 blocky pixel paint logic
    int pixellogic(int x,int y,int c,boolean erase)
    {
        if(erase)
            return erasechar;
        else
            return c;
    }
    
    // Invert a character if possible
    int invertchar(int c)
    {
        return c;
    }
    
    int graphic_chars(int keycode,boolean shift)
    {
        return -1;
    }
    
    // Rotate and flip functions for characters. Here just dummy implementations.
    int rotate(int c)
    {
        return c;
    }
    int hflip(int c)
    {
        return c;
    }
    int vflip(int c)
    {
        return c;
    }
}
