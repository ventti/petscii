
// PETSCII-specific character set class

class Petscii extends Charset
{
    Petscii(String fontfile,String remapfile,String setfile)
    {
        super(fontfile,remapfile,setfile);
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
            
        for(int i=0;i<128;i++)
        {
            remap[i]=int(tmp[i]);
            remap[i+128]=remap[i]+128;
        }
        
        return true;
    }
    
    // 4x4 blocky pixel paint logic for PETSCII
    int pixellogic(int x,int y,int c,boolean erase)
    {
        int bitnum=0x1,foundchar=0,
            fourths[]={0x20,0x7e,0x7c,0xe2,0x7b,0x61,0xff,0xec,
                       0x6c,0x7f,0xe1,0xfb,0x62,0xfc,0xfe,0xe0};
        
        x-=col1_start;
        y-=canvas_start;
        
        if(c==0xa0) // Another full char
            c=0xe0;
        if(c==0x60)
            c=0x20;
        
        // Find the corresponding bit for the 1/4 char
        if(x%machine.charx >= machine.charx/2) // right side
        {
            bitnum=0x2;
            if(y%machine.chary > machine.chary/2) // bottom
                bitnum=0x8;
        }
        else
        {
            if(y%machine.chary > machine.chary/2) // bottom
               bitnum=0x4;
        }
    
        for(int i=0;i<16;i++)
            if(fourths[i]==c)
                foundchar=i;
    
        if(erase)
            return fourths[foundchar&(bitnum^0xf)];
        else
            return fourths[foundchar|bitnum];
    }  
    
    // Invert a character if possible
    int invertchar(int c)
    {
        return c^128;
    }
        
    // Keycode, char, char with shift
    int keycodes_to_gfx[]=
    {
       KeyEvent.VK_A, 112, 65,
       KeyEvent.VK_B, 127, 66,
       KeyEvent.VK_C, 124, 67,
       KeyEvent.VK_D, 108, 68,
       KeyEvent.VK_E, 113, 69,
       KeyEvent.VK_F, 123, 70,
       KeyEvent.VK_G, 101, 84,
       KeyEvent.VK_H, 116, 72,
       KeyEvent.VK_I, 98, 73,
       KeyEvent.VK_J, 117, 74,
       KeyEvent.VK_K, 97, 75,
       KeyEvent.VK_L, 118, 76,
       KeyEvent.VK_M, 103, 77,
       KeyEvent.VK_N, 106, 78,
       KeyEvent.VK_O, 121, 79,
       KeyEvent.VK_P, 111, 80,
       KeyEvent.VK_Q, 107, 81,
       KeyEvent.VK_R, 114, 82,
       KeyEvent.VK_S, 110, 83,
       KeyEvent.VK_T, 99, 84,
       KeyEvent.VK_U, 120, 85,
       KeyEvent.VK_V, 126, 86,
       KeyEvent.VK_W, 115, 87,
       KeyEvent.VK_X, 125, 88,
       KeyEvent.VK_Y, 120, 89,
       KeyEvent.VK_Z, 109, 90,
    
       521, 102, 91,
       45, 92, 93,
       44, 100, 122,
       46, 95, 64,
       222, 104, 105
    };
    
    // Map keycodes to gfx chars
    int graphic_chars(int keycode,boolean shift)
    {
        int found=-1;
    
        for(int i=0;i<keycodes_to_gfx.length;i+=3)
        {
            if(keycode==keycodes_to_gfx[i])
            {
                if(shift)
                    found=keycodes_to_gfx[i+2];
                else
                    found=keycodes_to_gfx[i+1];
            }
        }
        
        // Special cases
        if(keycode==KeyEvent.VK_9)
        {
            message("Reverse on");
            typing=2;
        }
        if(keycode==KeyEvent.VK_0)
        {
            message("Reverse off");
            typing=1;
        }
        
        if(machine.palettemode) // Change color in the typing mode
        {
            int tp=-1000;
            
            if(machine.machine==PLUS4) // Very different colors
            {
                if(keycode==KeyEvent.VK_1) { if(shift) tp=0x48; else tp=0; }
                if(keycode==KeyEvent.VK_2) { if(shift) tp=0x29; else tp=0x71; }
                if(keycode==KeyEvent.VK_3) { if(shift) tp=0x5a; else tp=0x32; }
                if(keycode==KeyEvent.VK_4) { if(shift) tp=0x6b; else tp=0x63; }
                if(keycode==KeyEvent.VK_5) { if(shift) tp=0x5c; else tp=0x44; }
                if(keycode==KeyEvent.VK_6) { if(shift) tp=0x6d; else tp=0x35; }
                if(keycode==KeyEvent.VK_7) { if(shift) tp=0x2e; else tp=0x46; }
                if(keycode==KeyEvent.VK_8) { if(shift) tp=0x5f; else tp=0x77; }
            }
            else
            {   
                if(keycode==KeyEvent.VK_1) tp=0;
                if(keycode==KeyEvent.VK_2) tp=1;
                if(keycode==KeyEvent.VK_3) tp=2;
                if(keycode==KeyEvent.VK_4) tp=3;
                if(keycode==KeyEvent.VK_5) tp=4;
                if(keycode==KeyEvent.VK_6) tp=5;
                if(keycode==KeyEvent.VK_7) tp=6;
                if(keycode==KeyEvent.VK_8) tp=7;
                
                if(shift && machine.maxpen>7)
                    tp+=8;
            }
            
            if(tp>=0)
                pen=tp;
        }
        
        return found;
    }
    
    // Remap table for rotate
    final int rotate_map[]={
        0,1,2,3,4,5,6,7,                 8,9,10,11,12,13,14,15,
        16,17,18,19,20,21,22,23,         24,25,26,27,28,29,30,31,
        32,33,34,35,36,37,38,39,         40,41,42,43,44,45,46,47,
        48,49,50,51,52,53,54,55,         56,57,58,59,60,61,62,63,
        66,65,67,93,72,89,71,68,         70,75,85,74,79,78,77,80,
        122,81,84,83,69,73,86,87,        88,82,90,91,92,64,94,233,
        96,226,97,103,101,99,230,100,    104,95,111,114,123,112,125,116,
        110,107,115,113,119,120,121,106, 118,117,76,126,108,109,124,255,
        
        128,129,130,131,132,133,134,135, 136,137,138,139,140,141,142,143,
        144,145,146,147,148,149,150,151, 152,153,154,155,156,157,158,159,
        160,161,162,163,164,165,166,167, 168,169,170,171,172,173,174,175,
        176,177,178,179,180,181,182,183, 184,185,186,187,188,189,190,191,
        194,193,195,221,200,217,199,196, 198,203,213,202,207,206,205,208,
        250,209,212,211,197,201,214,215, 216,210,218,219,220,192,222,105,
        224,98,225,231,229,227,102,228,  232,223,239,242,251,240,253,244,
        238,235,243,241,247,248,249,234, 246,245,204,254,236,237,252,127
    };
    final int rotate_lowercase[]={
        0,1,2,3,4,5,6,7,                 8,9,10,11,12,13,14,15,
        16,17,18,19,20,21,22,23,         24,25,26,27,28,29,30,31,
        32,33,34,35,36,37,38,39,         40,41,42,43,44,45,46,47,
        48,49,50,51,52,53,54,55,         56,57,58,59,60,61,62,63,
        93,65,66,67,68,69,70,71,         72,73,74,75,76,77,78,79,
        80,81,82,83,84,85,86,87,         88,89,90,91,92,64,102,233,
        96,226,97,103,101,99,230,100,    104,95,111,114,123,112,125,116,
        110,107,115,113,119,120,121,106, 118,117,122,126,108,109,124,255,
        
        128,129,130,131,132,133,134,135, 136,137,138,139,140,141,142,143,
        144,145,146,147,148,149,150,151, 152,153,154,155,156,157,158,159,
        160,161,162,163,164,165,166,167, 168,169,170,171,172,173,174,175,
        176,177,178,179,180,181,182,183, 184,185,186,187,188,189,190,191,
        221,193,194,195,196,197,198,199, 200,201,202,203,204,205,206,207,
        208,209,210,211,212,213,214,215, 216,217,218,219,220,192,230,105,
        224,98,225,231,229,227,102,228,  232,223,239,242,251,240,253,244,
        238,235,243,241,247,248,249,234, 246,245,250,254,236,237,252,127
    };
    
    int rotate(int c)
    {
        if(machine.lowercase)
            return rotate_lowercase[c];
        else
            return rotate_map[c];
    }
    
    // Remap tables for flips
    final int hflip_map[]={
        0,1,2,3,4,5,6,7,                 8,9,10,11,12,13,14,15,
        16,17,18,19,20,21,22,23,         24,25,26,29,47,27,30,31,
        32,33,34,35,36,37,38,39,         41,40,42,43,44,45,46,28,
        48,49,50,51,52,53,54,55,         56,57,58,59,62,61,60,63,
        64,65,93,67,68,69,70,72,         71,85,75,74,122,78,77,80,
        79,81,82,83,89,73,86,87,         88,84,90,91,92,66,94,105,
        96,225,98,99,100,103,230,101,    104,95,116,115,123,125,112,111,
        110,113,114,107,106,118,117,119, 120,121,76,108,126,109,124,255,

        128,129,130,131,132,133,134,135, 136,137,138,139,140,141,142,143,
        144,145,146,147,148,149,150,151, 152,153,154,157,175,155,158,159,
        160,161,162,163,164,165,166,167, 169,168,170,171,172,173,174,156,
        176,177,178,179,180,181,182,183, 184,185,186,187,190,189,188,191,
        192,193,221,195,196,197,198,200, 199,213,203,202,250,206,205,208,
        207,209,210,211,217,201,214,215, 216,212,218,219,220,194,222,233,
        224,97,226,227,228,231,102,229,  232,223,244,243,251,253,240,239,
        238,241,242,235,234,246,245,247, 248,249,204,236,254,237,252,127
    };
    final int hflip_lowercase[]={
        0,1,2,3,4,5,6,7,                 8,9,10,11,12,13,14,15,
        16,17,18,19,20,21,22,23,         24,25,26,29,28,27,30,31,
        32,33,34,35,36,37,38,39,         41,40,42,43,44,45,46,47,
        48,49,50,51,52,53,54,55,         56,57,58,59,62,61,60,63,
        64,65,66,67,68,69,70,71,         72,73,74,75,76,77,78,79,
        80,81,82,83,84,85,86,87,         88,89,90,91,92,93,102,105,
        96,225,98,99,100,103,230,101,    104,95,116,115,123,125,112,111,
        110,113,114,107,106,118,117,119, 120,121,122,108,126,109,124,255,

        128,129,130,131,132,133,134,135, 136,137,138,139,140,141,142,143,
        144,145,146,147,148,149,150,151, 152,153,154,157,156,155,158,159,
        160,161,162,163,164,165,166,167, 169,168,170,171,172,173,174,175,
        176,177,178,179,180,181,182,183, 184,185,186,187,190,189,188,191,
        192,193,194,195,196,197,198,199, 200,201,202,203,204,205,206,207,
        208,209,210,211,212,213,214,215, 216,217,218,219,220,221,94,233,
        224,97,226,227,228,231,102,229,  232,223,244,243,251,253,240,239,
        238,241,242,235,234,246,245,247, 248,249,250,236,254,237,252,127
    };
    
    final int vflip_map[]={
        0,1,2,3,4,5,6,7,                 8,9,10,11,12,23,14,15,
        16,17,18,19,20,21,22,13,         24,25,26,27,47,29,30,31,
        32,33,34,35,36,37,38,39,         40,41,42,43,44,45,46,28,
        48,49,50,51,52,53,54,55,         56,57,58,59,60,61,62,63,
        67,65,66,64,70,82,68,71,         72,75,85,73,79,78,77,76,
        122,81,69,83,84,74,86,87,        88,89,90,91,92,93,94,233,
        96,97,226,100,99,101,230,103,    104,223,106,107,124,112,125,119,
        109,114,113,115,116,117,118,111, 121,120,80,126,108,110,123,255,
        
        128,129,130,131,132,133,134,135, 136,137,138,139,140,151,142,143,
        144,145,146,147,148,149,150,141, 152,153,154,155,175,157,158,159,
        160,161,162,163,164,165,166,167, 168,169,170,171,172,173,174,156,
        176,177,178,179,180,181,182,183, 184,185,186,187,188,189,190,191,
        195,193,194,192,198,210,196,199, 200,203,213,201,207,206,205,204,
        250,209,197,211,212,202,214,215, 216,217,218,219,220,221,222,105,
        224,225,98,228,227,229,102,231,  232,95,234,235,252,240,253,247,
        237,242,241,243,244,245,246,239, 249,248,208,254,236,238,251,127
    };
    final int vflip_lowercase[]={
        0,1,2,3,4,5,6,7,                 8,9,10,11,12,23,14,15,
        16,17,18,19,20,21,22,13,         24,25,26,27,28,29,30,31,
        32,33,34,35,36,37,38,39,         40,41,42,43,44,45,46,47,
        48,49,50,51,52,53,54,55,         56,57,58,59,60,61,62,63,
        64,65,66,67,68,69,70,71,         72,73,74,75,76,87,78,79,
        80,81,82,83,84,85,86,77,         88,89,90,91,92,93,222,233,
        96,97,226,100,99,101,230,103,    104,223,106,107,124,112,125,119,
        109,114,113,115,116,117,118,111, 121,120,112,126,108,110,123,255,
        
        128,129,130,131,132,133,134,135, 136,137,138,139,140,151,142,143,
        144,145,146,147,148,149,150,141, 152,153,154,155,156,157,158,159,
        160,161,162,163,164,165,166,167, 168,169,170,171,172,173,174,175,
        176,177,178,179,180,181,182,183, 184,185,186,187,188,189,190,191,
        192,193,194,195,196,197,198,199, 200,201,202,203,204,215,206,207,
        208,209,210,211,212,213,214,205, 216,217,218,219,220,221,222,105,
        224,225,98,228,227,229,102,231,  232,95,234,235,252,240,253,247,
        237,242,241,243,244,245,246,239, 249,248,250,254,236,238,251,127
    };
    
    int hflip(int c)
    {
        if(machine.lowercase)
            return hflip_lowercase[c];
        else
            return hflip_map[c];
    }
    int vflip(int c)
    {
        if(machine.lowercase)
            return vflip_lowercase[c];
        else
            return vflip_map[c];
    }
}