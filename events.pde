
// Event handlers for mouse and keyboard interaction

import java.awt.event.KeyEvent;

final int COMMAND=157;

// This is here just to tell right/left shift apart
void keyPressed(java.awt.event.KeyEvent ke)
{
    if(ke.getKeyCode()==SHIFT)
    {
        if(ke.getKeyLocation()==KeyEvent.KEY_LOCATION_LEFT)
            shift=1;
        else
            shift=2;
    }
    nativeKeyEvent(ke);
}

void keyPressed()//java.awt.event.KeyEvent ke) // Keyboard commands
{
    // Some typical special characters for the typing mode
    final int keytopetscii[]={'[',0x1b, ']',0x1d, '@',0};
    
    int blox=(mouseX-col1_start)/machine.charx, // Mouse coordinates in character blocks
        bloy=(mouseY-canvas_start)/machine.chary;

// THhe old simpler version
//    if(keyCode==SHIFT)
//        shift=1;
    if(platform==MACOSX)
    {
        if(keyCode==COMMAND)
            control=true;
    }
    else
    {
        if(keyCode==CONTROL)
            control=true;
    }
    if(keyCode==ALT)
        alt=true;
    
    if(typing>0) // A special mode where you can type
    {
        int petsciinum=-1;

        if(key==ESC)
        {
            typing=0;
            if(!cf.changed()) // Remove the unnecessary undo step
                cf.undo_revoke();
        }

        if(key==ENTER)
        {
            cursorx=0;
            cursory++;
        }
        if(key==TAB) // Align to 4 char columns
            cursorx=(cursorx+4)/4*4;
        if(keyCode==UP) cursory--;
        if(keyCode==DOWN) cursory++;
        if(keyCode==LEFT) cursorx--;
        if(keyCode==RIGHT) cursorx++;

        if(cursorx>=X) // Wrap the cursor
        {
            cursorx=0;
            cursory++;
        }
        if(cursorx<0)
        {
            cursorx=X-1;
            cursory--;
        }
        cursory=(cursory+Y)%Y;

        if(keyCode==KeyEvent.VK_HOME)
            cursorx=0;
        if(keyCode==KeyEvent.VK_END)
            cursorx=X-1;
        if(keyCode==KeyEvent.VK_PAGE_UP)
            cursory=0;
        if(keyCode==KeyEvent.VK_PAGE_DOWN)
            cursory=Y-1;
            
        if(key==DELETE || key==BACKSPACE) // Forward/backward delete
        {
            if(key==BACKSPACE)
            {
                cursorx--;
                if(cursorx<0)
                {
                    cursorx=X-1;
                    cursory--;
                    cursory=(cursory+Y)%Y;
                }
            }
            
            for(int i=cursorx;i<X-1;i++)
            {
                cf.setchar(i,cursory,cf.getchar(i+1,cursory));
                cf.setcolor(i,cursory,cf.getcolor(i+1,cursory));
            }
            
            cf.setchar(X-1,cursory,cset.erasechar);
            cf.setcolor(X-1,cursory,machine.erasecolor);
        }
        
        if(keyCode==KeyEvent.VK_INSERT) // Insert space here. This is how it works on a C64 :)
        {
            for(int i=X-1;i>cursorx;i--)
            {
                cf.setchar(i,cursory,cf.getchar(i-1,cursory));
                cf.setcolor(i,cursory,cf.getcolor(i-1,cursory));
            }
            
            cf.setchar(cursorx,cursory,cset.erasechar);
            cf.setcolor(cursorx,cursory,machine.erasecolor);
        }

        if(!alt)
        {
            if(key>='a' && key<='z')
                petsciinum=key-'a'+1;
            if(key>=' ' && key<='?')
                petsciinum=key;
            if(key>='A' && key<='Z')
            {
                if(machine.lowercase)
                    petsciinum=key-'A'+65;
                else
                    petsciinum=key-'A'+0x81;
            }
            
            // Check special chars
            for(int i=0;i<keytopetscii.length;i+=2)
                if(keytopetscii[i]==key)
                    petsciinum=keytopetscii[i+1];
        }
        else
            petsciinum=cset.graphic_chars(keyCode,shift>0);
        
        if(petsciinum>=0) // Found a char!
        {
            if(typing==1)
                cf.setchar(cursorx,cursory,petsciinum);
            else
                cf.setchar(cursorx,cursory,petsciinum^128);
            cf.setcolor(cursorx,cursory,pen);
            
            cursorx++;
            if(cursorx>=X)
            {
                cursorx=0;
                cursory++;
            }
            cursory=(cursory+Y)%Y;
        }
    }
    else // Normal drawing mode
    {
        if(key=='f')
            floodfill=1;
        if(key=='F')
            floodfill=2;

        // Keyboard drawing commands
        if(key=='x') // Invert char
        {
            if(selw>0 && selh>0)
            {
                for(int i=0;i<selw*selh;i++)
                    if(clip_chars[i]!=-1)
                        clip_chars[i]=cset.invertchar(clip_chars[i]);
            }
            else
            {
                current=cset.invertchar(current);
                for(int i=0;i<cset.remap.length;i++)
                    if(current==cset.remap[i])
                        curidx=i;
            }
        }
        if(key=='X' && infield())
        {
            cf.undo_save();
            cf.setchar(blox,bloy,cset.invertchar(cf.getchar(blox,bloy)));
        }
        
        // H/V flips    
        if(key=='h')
        {
            if(selw>0 && selh>0) // Horizontal flip for selection
                hflip();
            else
            {
                current=cset.hflip(current); // Current char
                for(int i=0;i<cset.charactercount;i++)
                    if(cset.remap[i]==current)
                        curidx=i;
            }
        }
        if(key=='H' && infield())
        {
            cf.undo_save();
            cf.setchar(blox,bloy,cset.hflip(cf.getchar(blox,bloy)));
        }  
        if(key=='v')
        {
            if(selw>0 && selh>0) // Vertical flip for selection
                vflip();
            else
            {
                current=cset.vflip(current); // Current char
                for(int i=0;i<cset.charactercount;i++)
                    if(cset.remap[i]==current)
                        curidx=i;
            }
        }
        if(key=='V' && infield())
        {
            cf.undo_save();
            cf.setchar(blox,bloy,cset.vflip(cf.getchar(blox,bloy)));
        }
        
        // Rotate
        if(key=='r')
        {
            if(selw>0 && selh>0) // Rotate selection
                rrotate();
            else
            {
                current=cset.rotate(current); // Current char
                for(int i=0;i<cset.charactercount;i++)
                    if(cset.remap[i]==current)
                        curidx=i;
            }
        }
        if(key=='R' && infield())
        {
            cf.undo_save();
            cf.setchar(blox,bloy,cset.rotate(cf.getchar(blox,bloy)));
        }  
        
        if(key==' ') // Unselect
        {
            selw=-selw;
            selh=-selh;
        }
        if(keyCode==KeyEvent.VK_A && control) // Select all
        {
            selectmode=1;
            selx=sely=0;
            selw=X;
            selh=Y;
            for(int i=0;i<X*Y;i++)
            {
                clip_chars[i]=cf.getchar(i);
                clip_colors[i]=cf.getcolor(i);
            }
        }

        if(key=='u')
            cf.undo();
        if(key=='U')
            cf.redo();

        if(key==TAB) // Walk through sets if any
        {
            if(selw>0 && selh>0)
            {
                for(int i=0;i<selw*selh;i++)
                    if(clip_chars[i]!=-1 && cset.findset(clip_chars[i],true)!=-1) // Remap all the chars from a selection
                    {
                        int tmp=cset.findset(clip_chars[i],true);
                        for(int j=0;j<cset.charactercount;j++)
                            if(cset.remap[j]==tmp)
                                clip_chars[i]=tmp;
                    }
            }
            else // Current char
            {
                if(cset.findset(current,true)!=-1)
                {
                    current=cset.findset(current,true);
                    for(int i=0;i<cset.charactercount;i++)
                        if(cset.remap[i]==current)
                            curidx=i;
                }
            }
        }

        // UI toggles
        if(key=='g')
            prefs.grid=!prefs.grid;
        if(key=='c')
            prefs.crosshair=!prefs.crosshair;
        if(key==ENTER)
        {
            if(shift>0)
                typing=2; // inv. mode
            else
                typing=1;
            cf.undo_save();
        }
        if(key=='i')
            prefs.info=!prefs.info;
            
        // Reference image
        if(key=='t' && ref>-1)
            ref=(ref+1)%4;
        if(key=='T' && ref>-1)
        {
            cf.undo_save();
            ref=0;
            dither();
        }
            
        // One kludge more: shift horizontal/vertical lines by one
        if((key=='+' || key=='-') && !machine.lowercase)
        {
            int plus=1;
            if(key=='-')
                plus=7;
            
            boolean found=false;
            for(int j=0;!found && j<cset.shift.length;j++)
                for(int i=0;i<8;i++)
                {
                    if((current&0x7f)==cset.shift[j][i])
                    {
                        current=(current&0x80)+cset.shift[j][(i+plus)%8];
                        found=true;
                        break;
                    }
                }
            
            for(int i=0;i<cset.charactercount;i++)
                if(cset.remap[i]==current)
                    curidx=i;
        }
        
        // A quick hack for one-button mice
        if(key==',' && machine.palettemode)
            cf.setbg((cf.bg+1)%(machine.maxbg+1));
        if(key=='.' && machine.palettemode)
            cf.setborder((cf.border+1)%(machine.maxborder+1));
        if(key=='§' && infield())
        {
            current=cf.getchar(blox,bloy);
            pen=cf.getcolor(blox,bloy);
            for(int i=0;i<cset.charactercount;i++)
                if(cset.remap[i]==current)
                    curidx=i;
        }
        if((key=='°' || key=='½') && infield())
            pen=cf.getcolor(blox,bloy);

        if(key=='C') // Fix colors after loading a C64 image. Not necessary with new files.
        {
            cf.undo_save();
            machine.remapcolors(new C64());
        }
        
        // Anim-related
        if(keyCode==RIGHT)
            setframe((currentframe+1)%framecount);
        if(keyCode==LEFT)
            setframe((currentframe+framecount-1)%framecount);
        if(keyCode==KeyEvent.VK_HOME)
            setframe(0);
        if(keyCode==KeyEvent.VK_END)
            setframe(framecount-1);
        if(key>='0' && key<='9')
        {
            int nframe=key-'1';
            if(key=='0')
                nframe=9;
            
            setframe(nframe);
        }
        if(key=='l') // Lock frame
        {
            Frame f=frames.get(currentframe);
            f.locked=!f.locked;
        }
        if(key=='d') // Dup
        {
            addframe(currentframe+1);
            copyframe(cf,frames.get(currentframe+1));
            setframe(currentframe+1);
        }

        // Save & export keys
        if(key=='s')
            machine.save_c(filename,false);
        if(key=='S')
            machine.save_c(ext(filename,"_export.c"),true);
        if(key=='b')
            machine.save_bas(ext(filename,".bas"));
        if(key=='a')
            machine.save_asm(ext(filename,".s"),false);
        if(key=='A')
            machine.save_asm(ext(filename,".s"),true);
        // Only relevant/implemented for the C-64
        if(key=='q')
            machine.save_seq(ext(filename,".seq"));
        if(key=='p' || key=='P')
        {
            if(framecount==1) // Simple piccy
            {
                if(key=='p')
                    machine.save_png(ext(filename,".png"),cf,false);
                if(key=='P')
                    machine.save_png(ext(filename,".png"),cf,true);
            }
            else // Multiple frames
            {
                for(int i=0;i<framecount;i++)
                {
                    if(key=='p')
                        machine.save_png(ext(filename,"_"+nf(i,3)+".png"),frames.get(i),false);
                    if(key=='P')
                        machine.save_png(ext(filename,"_"+nf(i,3)+".png"),frames.get(i),true);
                }
            
                // Run a command for the image sequence if set in the prefs (make animgif or something)
                if(!prefs.convertcommand.equals(""))
                {
                    try
                    {
                        String pathi="";
                        if(prefs.path.equals(""))
                            pathi=sketchPath(""); // Must have some path or the command will fail
                        
                        String kommand=prefs.convertcommand+" "+pathi+ext(filename,"_*.png")+" "+pathi+ext(filename,".gif");
                        Runtime.getRuntime().exec(kommand);
                    }
                    catch (IOException e)
                    {
                        message("Problem with command execution.");
                    }
                }
            }
        }
        if(key=='e')
            machine.save_prg(ext(filename,".prg"));
            
        user_key(); // Call user's keyboard handler
    }

    // Don't propagate this anywhere
    if(key==ESC)
        key=0;

    repaint=true;
}

void keyReleased()
{   
    if(keyCode==SHIFT)
        shift=0;
    
    if(platform==MACOSX)
    {
        if(keyCode==COMMAND)
            control=false;
    }
    else
    {
        if(keyCode==CONTROL)
            control=false;
    }
        
    if(keyCode==ALT)
        alt=false;
        
    if(key=='f' || key=='F')
        floodfill=0;

    repaint=true;
}

void mouseClicked()
{
    int blox=(mouseX-col1_start)/machine.charx, // Mouse coordinates in character blocks
        bloy=(mouseY-canvas_start)/machine.chary;
    
    // Load, save etc. button handling
    if(load_b.mouseover())
        fileselect=true;
    if(save_b.mouseover())
        machine.save_c(filename,false);
    if(saveas_b.mouseover())
        saveselect=true;
    if(ref_b.mouseover())
        refselect=true;
    if(merge_b.mouseover())
        mergeselect=true;
    if(preview_b.mouseover()) // Preview window in or out
        miniwin_init();
        
    if(clear_b.mouseover())
    {
        cf.undo_save();
        
        for(int i=0;i<X*Y;i++)
        {
            cf.setchar(i,cset.erasechar);
            cf.setcolor(i,machine.erasecolor);
        }
        cf.updatethumb();
    }
    
    // Animation related items
    if(dupleft_b.mouseover())
    {
        addframe(currentframe);
        copyframe(cf,frames.get(currentframe));
        setframe(currentframe);
    }
    if(dupright_b.mouseover())
    {
        addframe(currentframe+1);
        copyframe(cf,frames.get(currentframe+1));
        setframe(currentframe+1);
    }
    if(cut_b.mouseover())
    {
        if(framecount==1 || cf.locked)
        {
            cutframe(true);
        }
        else
        {
            cutframe(false);
            setframe(currentframe);
        }
    }
    if(pasteleft_b.mouseover())
    {
        if(scratch.bg!=-1)
            pasteframe(currentframe);
        setframe(currentframe);
    }
    if(pasteright_b.mouseover())
    {
        if(scratch.bg!=-1)
        {
            pasteframe(currentframe+1);
            setframe(currentframe+1);
        }
    }
    
    if(floodfill>0 && typing==0 && infield()) // Floodfill
    {
        int targetc=current,
            targetcol=pen;
        
        if(mouseButton==prefs.ERASEBUTTON)
        {
            targetc=cset.erasechar;
            targetcol=machine.erasecolor;
        }

        if(floodfill==1) // Replace color and char
        {        
            // Don't fill if already done
            if(cf.getcolor(blox,bloy)!=targetcol || cf.getchar(blox,bloy)!=targetc)
            {
                cf.undo_save();
                ffill(blox,bloy,targetc,targetcol,cf.getchar(blox,bloy),cf.getcolor(blox,bloy),false);
            }
        }
        else // Replace color only
        {
            // Don't fill if already done
            if(cf.getcolor(blox,bloy)!=targetcol && cf.getchar(blox,bloy)!=cset.erasechar)
            {
                cf.undo_save();
                ffill(blox,bloy,targetc,targetcol,cf.getchar(blox,bloy),cf.getcolor(blox,bloy),true);
            }
        }
        
        System.gc(); // I guess the memory is pretty trashed at this point
    }
    
    // Switch between lowercase and uppercase
    if(incharsel() && mouseButton==RIGHT)
    {
        machine.setcase(!machine.lowercase);
        
        cset=new Petscii(machine.fontfile,machine.remapfile,machine.setfile);
        cset.initrender(machine.charx,machine.chary);
        current=cset.remap[curidx];
        cset.shift=machine.shift; // Need to do this properly later
        
        System.gc();
    }

    // Remap characters on ctrl-click on the selector
    if(incharsel() && mouseButton==LEFT && control)
    {
        int oldie=current;

        curidx=(mouseX-col2_start)/machine.charx+(mouseY-charsel_start)/machine.chary*16;
        current=cset.remap[curidx];

        if(oldie!=current)
        {        
            if(selw>0 && selh>0)
            {
                for(int i=0;i<selw*selh;i++)
                    if(clip_chars[i]==oldie)
                        clip_chars[i]=current;
            }
            else
            {
                cf.undo_save();
                for(int i=0;i<X*Y;i++)
                    if(cf.getchar(i)==oldie)
                        cf.setchar(i,current);
            }
        }
    }
    
    // Check if frame clicked
    anim_clicks(col1_start+75,col2_start-prefs.BWIDTH-180);

    repaint=true;
}

void mousePressed()
{
    // Catch quick presses on the color selector
    if(incolorsel())
        machine.colorselclicks();
    
    // Catch quick presses on the char selector
    if(incharsel() && (mouseButton==LEFT || mouseButton==prefs.PICKERBUTTON) && !control)
    {
        curidx=(mouseX-col2_start)/machine.charx+(mouseY-charsel_start)/machine.chary*16;
        current=cset.remap[curidx];
        
        if(selw>0 && selh>0) // Make holes to selected char
        {
            boolean found=false;
            for(int i=0;i<selw*selh;i++)
            {
                if(clip_chars[i]==current)
                {
                    clip_chars[i]=-1;
                    found=true;
                }
            }
            if(found)
                optimize_clip();
        }
    }

    repaint=true;
}
void mouseReleased()
{
    repaint=true;
}
