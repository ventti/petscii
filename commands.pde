// Named user actions ("commands"). Each performs one editor operation, so the
// behaviour lives in exactly one place; buttons (mouseClicked) and keyboard
// shortcuts (keyPressed) both just call these. Dialog-based commands post() their
// work so it runs on the animation thread from requesters() (see runCommands()).

// --- File / charset / image dialogs (deferred to the animation thread) ---
void cmd_load()        { post(() -> selectInput("Select a .c or .petmate file", "loadPetscii")); }
void cmd_merge()       { post(() -> selectInput("Select a .c or .petmate file to merge", "mergePetscii")); }
void cmd_saveas()      { post(() -> selectOutput("Save PETSCII .c", "savePetscii")); }
void cmd_ref()         { post(() -> selectInput("Select a file", "loadPic")); }
void cmd_import_prg()  { post(() -> selectInput("Select a .prg file", "importPrg")); }
void cmd_image()       { post(() -> selectInput("Select an image .png (up to 320x200)", "loadImageCharset")); }
void cmd_charset_load(){ post(() -> selectInput("Select a charset .png", "loadCharset")); }

void cmd_charset_png()
{
    post(() -> {
        int cpr=askInt("Characters per row?", charsetSaveCPR);
        if(cpr>=1 && cpr<=256) { charsetSaveCPR=cpr; selectOutput("Save charset .png", "saveCharsetPng"); }
        else if(cpr!=-1) message("Characters per row must be 1..256");
    });
}

void cmd_charset_prg()
{
    post(() -> {
        int addr=askAddr("Load address? ($hex or decimal)", charsetPrgAddr);
        if(addr>=0 && addr<=0xffff) { charsetPrgAddr=addr; selectOutput("Save charset .prg", "saveCharsetPrg"); }
        else if(addr!=-1) message("Load address must be 0..65535");
    });
}

void cmd_machine() // Switch machine (destructive; confirm if there is unsaved work)
{
    post(() -> {
        boolean proceed = !dirty || selector("Discard unsaved changes and switch machine?","Yes,No")==0;
        if(proceed)
        {
            int m=selector("Select a platform","C-64,C-64 flicker,Dir Art,PET 40x25,PET 80x25,Plus/4,VIC-20");
            if(m<0 || m==prefs.machine)
                message(m==prefs.machine ? "Already on "+machinenames[m] : "Machine unchanged");
            else
                switch_machine(m);
        }
    });
}

// --- Immediate save/export (run on the calling thread) ---
void cmd_save()        { machine.save_c(filename,false); }
void cmd_export_prg()  { machine.save_prg(ext(filename,".prg")); }

// Export the image as .png. Exports every frame when animated, then runs the
// configured convert command (e.g. to build an animated gif).
void cmd_export_png(boolean border)
{
    if(framecount==1)
        machine.save_png(ext(filename,".png"),cf,border);
    else
    {
        for(int i=0;i<framecount;i++)
            machine.save_png(ext(filename,"_"+nf(i,3)+".png"),frames.get(i),border);

        if(!prefs.convertcommand.equals("")) // Run a command for the image sequence (e.g. make a gif)
        {
            try
            {
                String pathi="";
                if(prefs.path.equals(""))
                    pathi=sketchPath(""); // Must have some path or the command will fail
                String kommand=prefs.convertcommand+" "+pathi+ext(filename,"_*.png")+" "+pathi+ext(filename,".gif");
                Runtime.getRuntime().exec(kommand);
            }
            catch(IOException e) { message("Problem with command execution."); }
        }
    }
}

// --- Charset / view ---
void cmd_charset_refresh() { machine.init_charset(); System.gc(); message("Refreshed charset"); }
void cmd_case()            { machine.setcase(!machine.lowercase); machine.init_charset(); System.gc(); }
void cmd_zoom_reset()      { apply_zoom(view.defaultzoom); }
void cmd_preview()         { showPreview(); }
void cmd_help()            { showhelp=!showhelp; helppage=0; repaint=true; }

// --- Edit ---
void cmd_undo() { cf.undo(); cf.updatethumb(); }
void cmd_redo() { cf.redo(); cf.updatethumb(); }
void cmd_grid() { prefs.grid=!prefs.grid; }
void cmd_clear()
{
    cf.undo_save();
    for(int i=0;i<X*Y;i++)
    {
        cf.setchar(i,cset.erasechar);
        cf.setcolor(i,machine.erasecolor);
    }
    cf.updatethumb();
}

// --- Animation frames ---
void cmd_dup_left()  { addframe(currentframe);   copyframe(cf,frames.get(currentframe));   setframe(currentframe); }
void cmd_dup_right() { addframe(currentframe+1); copyframe(cf,frames.get(currentframe+1)); setframe(currentframe+1); }
void cmd_cut()
{
    if(framecount==1 || cf.locked)
        cutframe(true);
    else
    {
        cutframe(false);
        setframe(currentframe);
    }
}
void cmd_paste_left()  { if(scratch.bg!=-1) pasteframe(currentframe); setframe(currentframe); }
void cmd_paste_right() { if(scratch.bg!=-1) { pasteframe(currentframe+1); setframe(currentframe+1); } }
