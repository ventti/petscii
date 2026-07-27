
// Event handlers for mouse and keyboard interaction

import java.awt.event.KeyEvent;

final int COMMAND=157;

boolean tablethack=false;

void keyPressed() // Keyboard commands
{
    // Some typical special characters for the typing mode
    final int keytopetscii[]={'[',0x1b, ']',0x1d, '@',0};
    
    int blox=(mouseX-view.col1_start)/machine.charx, // Mouse coordinates in character blocks
        bloy=(mouseY-view.canvas_start)/machine.chary;

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
    
    if(keyCode==SHIFT)
    {
        java.awt.event.KeyEvent ke;
        ke=(java.awt.event.KeyEvent)keyEvent.getNative();
        
        if(ke.getKeyLocation()==KeyEvent.KEY_LOCATION_LEFT)
            shift=1;
        else
            shift=2;
    }
    
    if(showhelp) // The help overlay is modal: keys only page/close it
    {
        if(key=='?' || key==ESC || keyCode==KeyEvent.VK_F1)
            { showhelp=false; helppage=0; }
        else if(key==' ' || keyCode==RIGHT || keyCode==DOWN || key==ENTER)
            helppage=(helppage+1)%max(1,helppages);
        else if(keyCode==LEFT || keyCode==UP)
            helppage=(helppage+helppages-1)%max(1,helppages);
        if(key==ESC)
            key=0; // Don't let Processing quit on ESC
        repaint=true;
        return;
    }

    if(cur.typing>0) // A special mode where you can type
    {
        int petsciinum=-1;

        if(key==ESC)
        {
            cur.typing=0;
            if(!cf.changed()) // Remove the unnecessary undo step
                cf.undo_revoke();
        }

        if(key==ENTER)
        {
            cur.x=0;
            cur.y++;
        }
        if(key==TAB) // Align to 4 char columns
            cur.x=(cur.x+4)/4*4;
        if(keyCode==UP) cur.y--;
        if(keyCode==DOWN) cur.y++;
        if(keyCode==LEFT) cur.x--;
        if(keyCode==RIGHT) cur.x++;

        if(cur.x>=X) // Wrap the cursor
        {
            cur.x=0;
            cur.y++;
        }
        if(cur.x<0)
        {
            cur.x=X-1;
            cur.y--;
        }
        cur.y=(cur.y+Y)%Y;

        if(keyCode==KeyEvent.VK_HOME)
            cur.x=0;
        if(keyCode==KeyEvent.VK_END)
            cur.x=X-1;
        if(keyCode==KeyEvent.VK_PAGE_UP)
            cur.y=0;
        if(keyCode==KeyEvent.VK_PAGE_DOWN)
            cur.y=Y-1;
            
        if(key==DELETE || key==BACKSPACE) // Forward/backward delete
        {
            if(key==BACKSPACE)
            {
                cur.x--;
                if(cur.x<0)
                {
                    cur.x=X-1;
                    cur.y--;
                    cur.y=(cur.y+Y)%Y;
                }
            }
            
            for(int i=cur.x;i<X-1;i++)
            {
                cf.setchar(i,cur.y,cf.getchar(i+1,cur.y));
                cf.setcolor(i,cur.y,cf.getcolor(i+1,cur.y));
            }
            
            cf.setchar(X-1,cur.y,cset.erasechar);
            cf.setcolor(X-1,cur.y,machine.erasecolor);
        }
        
        if(keyCode==KeyEvent.VK_INSERT) // Insert space here. This is how it works on a C64 :)
        {
            for(int i=X-1;i>cur.x;i--)
            {
                cf.setchar(i,cur.y,cf.getchar(i-1,cur.y));
                cf.setcolor(i,cur.y,cf.getcolor(i-1,cur.y));
            }
            
            cf.setchar(cur.x,cur.y,cset.erasechar);
            cf.setcolor(cur.x,cur.y,machine.erasecolor);
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
            if(cur.typing==1)
                cf.setchar(cur.x,cur.y,petsciinum);
            else
                cf.setchar(cur.x,cur.y,petsciinum^128);
            cf.setcolor(cur.x,cur.y,tool.pen);
            
            cur.x++;
            if(cur.x>=X)
            {
                cur.x=0;
                cur.y++;
            }
            cur.y=(cur.y+Y)%Y;
        }
    }
    else // Normal drawing mode
    {
        // Table-driven dispatch for simple global shortcuts. Context-sensitive
        // keys are still handled inline below; these just run their registered
        // action (see shortcuts.pde).
        //
        // All table keys are bare letters, so they must not fire while Ctrl (or
        // Cmd on macOS) is held: the modifier combos belong to other commands
        // (Ctrl+D quit, Ctrl+E plugin) and AWT still reports the plain keyChar
        // for them, which would otherwise run both.
        if(!control)
            for(Shortcut sh: shortcuts)
                if(sh.dkey!=0 && key==sh.dkey && sh.action!=null)
                    sh.action.run();

        if(key=='f')
            floodfill=1;
        if(key=='F')
            floodfill=2;

        // Keyboard drawing commands
        if(key=='x') // Invert char
        {
            if(sel.w>0 && sel.h>0)
            {
                for(int i=0;i<sel.w*sel.h;i++)
                    if(sel.clip_chars[i]!=HOLE)
                        sel.clip_chars[i]=cset.invertchar(sel.clip_chars[i]);
            }
            else
            {
                tool.current=cset.invertchar(tool.current);
                for(int i=0;i<cset.remap.length;i++)
                    if(tool.current==cset.remap[i])
                        tool.curidx=i;
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
            if(sel.w>0 && sel.h>0) // Horizontal flip for selection
                hflip();
            else
            {
                tool.current=cset.hflip(tool.current); // Current char
                for(int i=0;i<cset.charactercount;i++)
                    if(cset.remap[i]==tool.current)
                        tool.curidx=i;
            }
        }
        if(key=='H' && infield())
        {
            cf.undo_save();
            cf.setchar(blox,bloy,cset.hflip(cf.getchar(blox,bloy)));
        }  
        if(key=='v')
        {
            if(sel.w>0 && sel.h>0) // Vertical flip for selection
                vflip();
            else
            {
                tool.current=cset.vflip(tool.current); // Current char
                for(int i=0;i<cset.charactercount;i++)
                    if(cset.remap[i]==tool.current)
                        tool.curidx=i;
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
            if(sel.w>0 && sel.h>0) // Rotate selection
                rrotate();
            else
            {
                tool.current=cset.rotate(tool.current); // Current char
                for(int i=0;i<cset.charactercount;i++)
                    if(cset.remap[i]==tool.current)
                        tool.curidx=i;
            }
        }
        if(key=='R' && infield())
        {
            cf.undo_save();
            cf.setchar(blox,bloy,cset.rotate(cf.getchar(blox,bloy)));
        }  
        
        if(key==' ') // Unselect
        {
            sel.w=-sel.w;
            sel.h=-sel.h;
        }
        if(key==ESC) // the help overlay consumes ESC in its own branch above
            sel.w=sel.h=0;
        
        if(keyCode==KeyEvent.VK_A && control) // Select all
        {
            sel.mode=1;
            sel.x=sel.y=0;
            sel.w=X;
            sel.h=Y;
            for(int i=0;i<X*Y;i++)
            {
                sel.clip_chars[i]=cf.getchar(i);
                sel.clip_colors[i]=cf.getcolor(i);
            }
        }

        if(key=='u' && !mousePressed) // guarded; kept inline (see shortcuts.pde)
            cmd_undo();

        if(key==TAB) // Walk through sets if any
        {
            if(sel.w>0 && sel.h>0)
            {
                for(int i=0;i<sel.w*sel.h;i++)
                    if(sel.clip_chars[i]!=HOLE && cset.findset(sel.clip_chars[i],true)!=-1) // Remap all the chars from a selection
                    {
                        int tmp=cset.findset(sel.clip_chars[i],true);
                        for(int j=0;j<cset.charactercount;j++)
                            if(cset.remap[j]==tmp)
                                sel.clip_chars[i]=tmp;
                    }
            }
            else // Current char
            {
                if(cset.findset(tool.current,true)!=-1)
                {
                    tool.current=cset.findset(tool.current,true);
                    for(int i=0;i<cset.charactercount;i++)
                        if(cset.remap[i]==tool.current)
                            tool.curidx=i;
                }
            }
        }

        // UI toggles
        if(key=='c')
            prefs.crosshair=!prefs.crosshair;
        if(key==ENTER)
        {
            if(shift>0)
                cur.typing=2; // inv. mode
            else
                cur.typing=1;
            cf.undo_save();
        }
        if(key=='i')
            prefs.info=!prefs.info;
        if(key=='?' || keyCode==KeyEvent.VK_F1) // Keyboard-shortcut overlay
            cmd_help();

        // Reference image
        if(key=='t' && ref>-1)
            ref=(ref+1)%4;
        if(key=='T' && ref>-1)
        {
            if(reftime!=timestamp(refname)) // Updated in the meanwhile!
            {
                if(loadreference(refname))
                    reftime=timestamp(refname);
                else
                    message(refname+" cannot be opened.");
            }
          
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
                    if((tool.current&0x7f)==cset.shift[j][i])
                    {
                        tool.current=(tool.current&0x80)+cset.shift[j][(i+plus)%8];
                        found=true;
                        break;
                    }
                }
            
            for(int i=0;i<cset.charactercount;i++)
                if(cset.remap[i]==tool.current)
                    tool.curidx=i;
        }
        
        if (control){
          int k = isKeyEventNumber(keyCode);
          if (k > 0 && k <= prefs.MAXZOOM) {
            apply_zoom(k); // Ctrl+<n> sets and applies the zoom level
          }
        }
        
        // And a similar one: grow characters by one line
        if(keyCode==UP || keyCode==DOWN)
        {
            int plus=1;
            if(keyCode==DOWN)
                plus=-1;
            
            for(int j=2;j<cset.grow.length;j++) // Replace identical chars first
                if(tool.current==cset.grow[j][0])
                    tool.current=cset.grow[j][1];
            
            boolean found=false;
            for(int j=0;!found && j<2;j++) // Check both slides
            {
                int k=lastgrow; // Use the previous working one first
                
                for(int i=0;i<cset.grow[k].length;i++)
                {
                    if(tool.current==cset.grow[k][i])
                    {
                        int idx=i+plus;
                        if(idx<0)
                          idx=cset.grow[k].length-1;
                        idx%=cset.grow[k].length;
                        tool.current=cset.grow[k][idx];
                        found=true;
                        break;
                    }
                }
                if(!found)
                    lastgrow=1-lastgrow;
            }
                
            for(int i=0;i<cset.charactercount;i++)
                if(cset.remap[i]==tool.current)
                    tool.curidx=i;
        }
        
        // A quick hack for one-button mice
        int m = machine.maxbg+1;
        
        if(key==',' && machine.palettemode)
            cf.setbg((cf.bg+1) % m);
        if(key=='.' && machine.palettemode)
            cf.setborder((cf.border+1) % m);
        if(key == ';' && machine.palettemode)  // TODO check this works with all keyboard layouts
            cf.setbg(((cf.bg-1) % m + m) % m);
        if(key == ':' && machine.palettemode)
            cf.setborder(((cf.border-1) % m + m) % m);

        if(key=='§' && infield())
        {
            tool.current=cf.getchar(blox,bloy);
            tool.pen=cf.getcolor(blox,bloy);
            for(int i=0;i<cset.charactercount;i++)
                if(cset.remap[i]==tool.current)
                    tool.curidx=i;
        }
        if((key=='°' || key=='½') && infield())
            tool.pen=cf.getcolor(blox,bloy);

        if(key=='C') // Fix colors after loading a C64 image. Not necessary with new files.
        {
            cf.undo_save();
            // Machine constructors overwrite the global charset and re-render it
            // at their own char size, so building this throwaway reference
            // machine would leave us drawing a C64-sized charset on any other
            // platform (out-of-bounds in drawchar on VIC-20/PET). Put ours back.
            Charset keep=cset;
            machine.remapcolors(new C64());
            cset=keep;
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
        if(key>='0' && key<='9' && !control) // Ctrl+digit sets the zoom instead
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
            if(f.locked)
                message("Frame locked");
            else
                message("Frame unlocked");
        }
        // Save & export keys. Note: s, e, p, P, d, g are table-dispatched at the
        // top of this branch (see shortcuts.pde); the rest stay inline here.
        if(key=='S')
            machine.save_c(ext(filename,"_export.c"),true);
        if(key=='b')
            machine.save_bas(ext(filename,".bas"));
        if(key=='a' && !control) // Ctrl+A is Select All; don't also write a .s file
            machine.save_asm(ext(filename,".s"),false);
        if(key=='A')
            machine.save_asm(ext(filename,".s"),true);
        // Only relevant/implemented for the C-64
        if(key=='q' && !control)
            machine.save_seq(ext(filename,".seq"));
        if(key=='E')
            machine.save_pet(ext(filename,".pet"));

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
    int blox=(mouseX-view.col1_start)/machine.charx, // Mouse coordinates in character blocks
        bloy=(mouseY-view.canvas_start)/machine.chary;
        
    // Only run when invoked from mouseReleased() (tablethack). The OS-generated
    // mouseClicked() is unreliable: AWT fires it only when the pointer doesn't
    // move between press and release, so the tiniest drag made toolbar buttons
    // (and floodfill / char remap / frame clicks) silently miss their click.
    // mouseReleased() always fires, so we route all click handling through it.
    if(!tablethack)
        return;

    if(showhelp) // Modal overlay: a click on Help closes it, elsewhere pages
    {
        if(help_b.mouseover())
            { showhelp=false; helppage=0; }
        else
            helppage=(helppage+1)%max(1,helppages);
        repaint=true;
        return;
    }

    // Button handling: thin dispatch to the shared commands (see commands.pde).
    if(load_b.mouseover())           cmd_load();
    if(merge_b.mouseover())          cmd_merge();
    if(save_b.mouseover())           cmd_save();
    if(saveas_b.mouseover())         cmd_saveas();
    if(ref_b.mouseover())            cmd_ref();
    if(import_prg_b.mouseover())     cmd_import_prg();
    if(export_prg_b.mouseover())     cmd_export_prg();
    if(export_png_b.mouseover())     cmd_export_png(true);
    if(preview_b.mouseover())        cmd_preview();
    if(undo_b.mouseover())           cmd_undo();
    if(redo_b.mouseover())           cmd_redo();
    if(clear_b.mouseover())          cmd_clear();
    if(grid_b.mouseover())           cmd_grid();
    if(case_b.mouseover())           cmd_case();
    if(charset_b.mouseover())        cmd_charset_load();
    if(charset_refresh_b.mouseover())cmd_charset_refresh();
    if(charset_save_b.mouseover())   cmd_charset_png();
    if(charset_prg_b.mouseover())    cmd_charset_prg();
    if(image_b.mouseover())          cmd_image();
    if(machine_b.mouseover())        cmd_machine();
    if(zoom_b.mouseover())           cmd_zoom_reset();
    if(help_b.mouseover())           cmd_help();
    if(dupleft_b.mouseover())        cmd_dup_left();
    if(dupright_b.mouseover())       cmd_dup_right();
    if(cut_b.mouseover())            cmd_cut();
    if(pasteleft_b.mouseover())      cmd_paste_left();
    if(pasteright_b.mouseover())     cmd_paste_right();


    if(floodfill>0 && cur.typing==0 && infield()) // Floodfill
    {
        int targetc=tool.current,
            targetcol=tool.pen;
        
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
        
        machine.init_charset();
        
        System.gc();
        message("Right click char selector to toggle case");
    }

    // Remap characters on ctrl-click on the selector
    if(incharsel() && mouseButton==LEFT && control)
    {
        int oldie=tool.current;

        tool.curidx=(mouseX-view.col2_start)/machine.charx+(mouseY-view.charsel_start)/machine.chary*16;
        tool.current=cset.remap[tool.curidx];

        if(oldie!=tool.current)
        {        
            if(sel.w>0 && sel.h>0)
            {
                for(int i=0;i<sel.w*sel.h;i++)
                    if(sel.clip_chars[i]==oldie)
                        sel.clip_chars[i]=tool.current;
            }
            else
            {
                cf.undo_save();
                for(int i=0;i<X*Y;i++)
                    if(cf.getchar(i)==oldie)
                        cf.setchar(i,tool.current);
            }
        }
    }
    
    // Check if frame clicked
    anim_clicks(view.anim_start,view.anim_end);

    repaint=true;
}

void mousePressed()
{
    if(showhelp) // Overlay is up: swallow the press (release handles paging)
        return;

    shadowPressed=true;
    shadowButton=mouseButton;
    
    // Catch quick presses on the color selector
    if(incolorsel())
        machine.colorselclicks();
    
    // Catch quick presses on the char selector
    if(incharsel() && (mouseButton==LEFT || mouseButton==prefs.PICKERBUTTON) && !control)
    {
        tool.curidx=(mouseX-view.col2_start)/machine.charx+(mouseY-view.charsel_start)/machine.chary*16;
        tool.current=cset.remap[tool.curidx];
        
        if(sel.w>0 && sel.h>0) // Make holes to selected char
        {
            boolean found=false;
            for(int i=0;i<sel.w*sel.h;i++)
            {
                if(sel.clip_chars[i]==tool.current)
                {
                    sel.clip_chars[i]=HOLE;
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
    // Drive click handling from here for ALL modes (not just tablet): a release
    // always fires, whereas mouseClicked() is suppressed by any drag between
    // press and release, which is what made buttons "not work on first click".
    tablethack=true;
    mouseClicked();
    tablethack=false;

    repaint=true;
}

void mouseWheel(processing.event.MouseEvent event)
{
    if(showhelp)
        return;
    if(!prefs.disablewheel)
        machine.wheelevent(event.getCount()); // Machine-specific mouse wheel handling
}

int isKeyEventNumber(int k) {
  if (k >= KeyEvent.VK_0 && k <= KeyEvent.VK_9) {
    return k - 48;  // VK_0 is 48, VK_9 is 57
  }
  return -1; // Return -1 if not in range
}
