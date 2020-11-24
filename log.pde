/*
   Changelog:
   
   24.11.2020: Some more security. Show a confirmation dialog if the user tries to exit without saving, feat. ugly JFrame kludge and boolean dirty
   22.11.2020: BASIC and C export hopefully too
   22.11.2020: Asm and prg export done for the lowercase-aware VIC
   22.11.2020: VIC-20 lowercase now available, will be saved and loaded, not exported yet
   21.11.2020: New non-recursive floodfill, doesn't crash with very large images any more
   20.11.2020: Fixed a long-standing small bug in thumbnail location calculations. ZOOM=1 better layout.
               If thumbnails don't fit on top of the canvas, put them on the right instead.
   20.11.2020: Center color/charsel if the buttonbar is wider
   20.11.2020: Scale borders based on zoom to allow for a smaller window at zoom 1 and more air at 3
   20.11.2020: Buttons are centered now in higher zoomlevels to look tidier
   20.11.2020: Machines can (and will) disable buttons that are not implemented on that platform
   20.11.2020: No need to ask about overwrite with the AWT selector, as it does it already on its own. Changed "Overwrite?" to "Overwrite file?".
   20.11.2020: Didn't work on a Mac. Let's try a fix by extracting the filename from the path first.
   20.11.2020: Offer the current name when "saving as" in the AWT selector. Also helps with the recent files view.
   18.11.2020: Let's NOT export a SEQ every time users press command-q on Mac to exit
   18.11.2020: AWT fileselector loses focus a bit less now
   18.11.2020: Use AWT or Swing fileselector based on the platform, can still be overridden using prefs
   18.11.2020: Framerate shouldn't be zero even if the prefs are broken.
   17.11.2020: Option to use AWT's fileselector with AWTSELECTOR, also implemented it
   17.11.2020: Removed the useless miniwin pref
   17.11.2020: Calling it FORCEAWT was a bad idea, let's go with FORCEMETAL
   17.11.2020: Probably cleaner to call redraw() rather than draw() for the preview window
   17.11.2020: Added the FORCEAWT pref to always go with the Java default look instead of "native" on Win/Lin
   16.11.2020: Managed to fix left/right shift handling for P3 too using a bit different kludge
   16.11.2020: args[] is null if empty these days, not just an empty array
   16.11.2020: Major rewrite of the preview window code
   15.11.2020: First steps toward migrating to Processing 3, some things are broken yet and had to start using settings()
   9.10.2020: Don't show the upcoming character or selection in the tablet mode because they'll just hang there
   4.10.2020: Properly integrated the .pet file format into machine.pde, removed from user.pde
   3.10.2020: Experimental support for exporting the binary .pet format (C64 only)
   3.10.2020: shadowPressed/Button kludge for catching missed quick mouse clicks. Should be done with event handlers, but it's pretty complicated.
   12.9.2020: Experimental tablet hack with mouseReleased() and a bit more robust prefs handling in a couple of cases
   25.5.2020: Use system-specific file separator for prefs, also look in the app folder
   14.5.2020: Look for prefs.txt also in the home directory as a little hack
   16.11.2019: Pressing esc removes selection
   8.11.2019: A bit improved button grouping
   7.11.2019: UIWIDTH was wrong after the changes
   7.11.2019: Growing sticks now remembers whether it was horizontal/vertical last
   7.11.2019: Save PRG and PNG work
   7.11.2019: Reorganized the buttons heavily
   7.11.2019: Some curious problem with C64 PRG export fixed
   7.11.2019: Minor fixes to thumbnail updates with undo/redo button and importing
   7.11.2019: Import for Plus/4 too, others probably not worth the hassle
   7.11.2019: "Import .prg" button and initial support for reading back exported PRGs (C64 only so far)
   6.11.2019: Up and down arrow grow and shrink stick characters
   6.11.2019: Reference image is reloaded if the timestamp is changed when converting
   5.11.2019: Make UI text stand better out from the border color bg
   5.11.2019: Toggle case also with ctrl/cmd-shift and show message about it
   5.11.2019: Locking and unlocking a frame produces a message
   5.11.2019: New UI buttons: undo, redo, grid toggle, crosshair toggle. "Ref" changed to "Reference".
   5.11.2019: Airier buttons and layout in general
   5.11.2019: Undo not done if mouse button down, as it messed up something
   1.3.2019: One more kludge fix to the SEQ output
   5.11.2018: Fixed a long-standing bug with nonstandard x/y size and frame selection
   12.11.2017: Sets work on selection
   11.11.2017: Picker button (middle by default) works in the char selector too
   7.11.2017: Let's not put the dialog text on the window title, as it may be partially hidden
   7.11.2017: Repaint preview frame after lifting it
   7.11.2017: Canvas size command line parameter -size x y
   7.11.2017: Much more robust text file writing, safeWriter() wraps createWriter() and the sketch won't crash
   2.11.2017: Some fixes in preferences handling
   2.11.2017: New pref BACKUPFILE, backup file and path can be changed
   31.10.2017: Nag dialog if the user tries to "save as" over an existing file. Dialogs can't be closed anymore.
   31.10.2017: Let's not crash if we can't open a file for writing ie. catch the exception
   29.10.2017: Zoom can be set on the command line like this: -zoom 3
   29.10.2017: 32 undo steps by default, also a new pref for them ("UNDODEPTH")
   28.10.2017: SEQ export possibly fixed, thanks to Tero
   20.10.2017: Default zoom=2 again, accept machine name from the command line (-c64, -vic20 and so on)
   20.10.2017: Minor fixes to flicker mode color defaults
   19.10.2017: (Hidden) Animation export works for the Plus/4. Check the platform for these exporters too.
   16.10.2017: Fixed C-64 Flicker import on other machines
   15.10.2017: Flicker color prg export
   15.10.2017: Flicker color C viewer export
   15.10.2017: Flicker colors making their appearance
   14.10.2017: An attempt at using native look for dialogs on Win/Lin (can't do that on Macs, I'm afraid)
   11.10.2017: Refpath now set to path if there's such thing in the preferences
   10.10.2017: Improved c/asm delta animation export (not officially supported) for the C-64
   12.7.2017: My 5yo son(!) discovered a long-standing selection bug which could crash the whole program. Should be ok now.
   10.7.2017: Well, that "fix" broke the by-character selection, which should work again
   9.7.2017: A half-assed fix to the slightly annoying behavior where you'd lose the selection when leaving the char area
   27.5.2016: Fixed a crashing bug when pressing both mouse buttons while selecting
   21.5.2016: Fixed a rare crashing bug in the bitmap converter
   21.5.2016: Shifting stick chars after loading an image crashed the whole thing. Not anymore.
   7.5.2016: Let's do things right: on Mac consider the Command key Ctrl and avoid many problems
   6.5.2016: Mac-specific kludge needed - ctrl-shift-mousebutton for free selection
   6.5.2016: There wasn't really any need for pressing o, since the selection is always auto-optimized
   6.5.2016: Fixed messed-up font when loading "wrong" machine's files
   3.5.2016: selector() is now vertical and better centered, other minor cleanups
   25.4.2016: Fixed a new bug which followed from not calling initrender() after loading a lowercase image
   25.4.2016: Scaled the PETHI font already in the file: preview and png export work fine again
   25.4.2016: Added initrender() to Charset, replaced that awful emptyline by a different PETHI font
   25.4.2016: ASPECT (PAL/NTSC/SQUARE) supported in the prefs on the relevant platforms
   25.4.2016: Moved character invert logic to Charset instead of the fixed ^128
   24.4.2016: Ironing out some hardwired dependencies on 8x8 chars and 256 characters
   24.4.2016: Ctrl-a to select the whole image, automatically optimize selection when removing chars from it
   24.4.2016: Fixed ctrl-click color remapping
   24.4.2016: Right shift for char-only painting, leaving color intact
   24.4.2016: Can now distinguish left and right shift (shift=1 or 2)
   24.4.2016: Fixed a crashing bug when setting cursor place in the typing mode
   24.4.2016: Ctrl-click on the character selector remaps a certain char to another
   23.4.2016: New color handling for the loaders: generic color mapping between machines (remapcolors()) and cleaner load_c()
   22.4.2016: charx and chary moved under the Machine. Convenience functions canvasx() and canvasy() for char pixel locations.
   22.4.2016: New hand-written C-64 color remap table for the Plus/4. Much closer to Pepto.
   22.4.2016: Free selection is starting to be reality. Ctrl+rmb paints/removes.
   22.4.2016: Added optimize_clip for removing unnecessary edges from the selection. Can be invoked with "o".
   22.4.2016: The grids are a tiny bit better placed now
   22.4.2016: Less error-prone selection: "oldcontrol" checks whether the user let ctrl slip when selecting
   21.4.2016: Some more rationalization of the quirky main logic. Perhaps marginally quicker drawchar().
   21.4.2016: Show outline even when mouse button released in the selection mode
   21.4.2016: Cleaned the main drawing logic from draw() a bit. More to come.
   21.4.2016: Clear doesn't restore border/bg anymore. Update thumbnail when clearing.
   21.4.2016: Less jumpy crosshair updates
   21.4.2016: Improved typing mode and crosshair screen updates
   21.4.2016: Improved 1/4 char screen updates, moved color selector click handling to Machine.colorselclicks(), improved UI updates
   20.4.2016: Update the UI buttons according to the new model
   20.4.2016: A dirty hack to catch very quick clicks on the char/color selector
   20.4.2016: First steps toward less power-hungry screen updates (boolean refresh)
   20.4.2016: A tiny bit rounded buttons(!) and one pixel more spacious
   20.4.2016: Don't show the selection when ctrl-clicking somewhere else than the canvas (a long-standing minor bug)
   19.4.2016: A merge button added plus initial merge functionality to load_c in Machine
   19.4.2016: Second button row for the UI. A new clear button/function added. Less crashing when loading other machines's pics.
   19.4.2016: Selection can be toggled with space
   19.4.2016: Brand new prg exporters for C-64/Plus4: smaller size and lowercase works
   19.4.2016: Lowercase BAS and C viewer exporters work on both the C-64 and Plus/4
   19.4.2016: A remap table for lowercase too, thanks to Dr. TerrorZ
   19.4.2016: Lowercase typing works better with shift for upper/lowercase
   19.4.2016: Lowercase flip and rotate tables are there
   19.4.2016: Lowercase is back! Right mouse button on char selector. Upper/lowercase is also saved on the files. Exporters still lacking.
   19.4.2016: Rotate and flips now under the charset
   19.4.2016: Goodbye fileops.pde. All loading / saving under the machine now.
   19.4.2016: Reference loading and extension handling moved to tools.pde. fileops.pde soon on the way out.
   19.4.2016: Machine now contains "green" for loading monochrome images
   19.4.2016: Goodbye undo.pde. Undo and redo moved to Frame where the belong.
   19.4.2016: Moved the color selector drawing code to Machine from draw()
   19.4.2016: Oldie goldie, public variable "borderw" is gone
   19.4.2016: Yet another class: Charset, which contains most character set / font related bits
   18.4.2016: save_c() moved under the Machine class
   18.4.2016: Preferences class used everywherse(?) instead of global defines/vars
   18.4.2016: settings.pde changed to prefs.pde and became a class
   18.4.2016: Findset moved to Machine. Might move again.
   18.4.2016: Quite massive overhaul of the machine system. Now they're classes (Machine, C64 and so on). Got rid of many public variables.
   18.4.2016: ERASECHAR replaced hardcoded 0x20 values
   14.4.2016: Tiny fixes to cope with inter-frame drawing, removed a new bug in frame switching
   14.4.2016: Rewritten thumbnail code that oversamples the characters instead of just on/off
   14.4.2016: Take into account the other empty char (96) when generating thumbnails
   13.4.2016: Moved info display away from petscii.pde. Changed some index-based character handling to x/y-based.
   13.4.2016: Yet another utility function: infield() for checking the mouse against the canvas
   13.4.2016: Added undo_revoke() to kill the last save without the option to redo. Undo history should now work better
              with typing even when switching frames in the middle.
   13.4.2016: Added setframe() to anim.pde to avoid errors and to do some checks automatically
   13.4.2016: Undo includes the border color from now on
   13.4.2016: Reworked the UI button system so that the parameters don't need to be repeated all the time
   12.4.2016: Java's arrayCopy does NOT copy multidimensional arrays properly, needed a loop in copyframe()
   12.4.2016: Setting ZOOM=0 doesn't crash the sketch anymore. Thumbnails updated properly after loading a C-64 pic on the Plus/4.
   12.4.2016: PNG series and C64 asm exporters were broken in the process. Less so now.
   12.4.2016: Reference image opacity doesn't affect anim frame display anymore
   12.4.2016: Hopefully finished changing all direct char/color access to set/get functions (except in undo or anim)
   12.4.2016: Fixed tiny bugs in the PET BASIC exporters
   12.4.2016: Some more fiddling with the preview window: raise the editor frame and give the preview frame a while to settle.
   12.4.2016: Changed most code to use set/get functions, ie. locking works again
   11.4.2016: Various set/get functions for frames to facilitate locking
   11.4.2016: Frame is cleared upon creation
   11.4.2016: Moved extra functions away from the main file (petscii.pde) to tools.pde
   11.4.2016: Catch the preview window exceptions. It's still not rock solid but should crash less.
   11.4.2016: Even on the PET colors need to be copied after all across frames
   11.4.2016: Fixed frame dup/cut/copy, locking is still broken. Fixed animation loading.
   10.4.2016: A big overhaul of the frame/undo system. Still not complete, but there's already separate undo for
              each frame and global chars/colors/bg/border are gone.
   10.4.2016: Moved buffer cleaning away from machine-specific init
   10.4.2016: Fixed a little undo inconsistency when pasting frames
   9.4.2016: Less CPU use when window inactive
   9.4.2016: Removed the useless non-gui functionality
   8.4.2016: Load new PET images (hopefully) correctly on other platforms. Keep fg colors to 0..7 on the VIC.
   8.4.2016: Detect when loading a color image in PET mode. Works only with new images that contain metadata.
   8.4.2016: Automatically convert recent C-64 files when loading them on a Plus/4.
   8.4.2016: Oops 2. Fixed PET loading again.
   8.4.2016: Most traces of the old fixed and problematic layout are gone by now
   8.4.2016: Oops. Fixed a bug in the OFFSET setting.
   8.4.2016: 1x1 images work now, but there's still stuff to fix here and there. Zoom=1 works better than before.
   8.4.2016: Big changes to better accommodate different canvas sizes. As small as 1x1 is the target.
   8.4.2016: Don't try to correct aspect ratio when zoom=1 for C-64/PET, as it's ugly and useless.
   6.4.2016: Some sort of SEQ exporter for the C-64 as people kept asking for it. Thanks to Six for the example code.
   6.4.2016: Checked the actual minimal canvas sizes for various platforms
   4.4.2016: A little kludge more for preview. May not actually do anything useful.
   4.4.2016: Added a kludge that MIGHT make the preview window not crash
   3.4.2016: Some safety networks when trying to export to various formats with a nonstandard image size
   3.4.2016: Can now load images smaller than canvas, too (rather untested)
   3.4.2016: Can now load images larger than the canvas, even though they're simply cropped
   3.4.2016: Show canvas size on title bar
   3.4.2016: Preliminary support for setting canvas size through prefs (XSIZE and YSIZE)
   3.4.2016: Changed file dialogs' title to "Select a File" from the default "Open"
   3.4.2016: Enlarged the file selector window, as it was annoyingly tiny by default
   3.4.2016: Added machinename that contains a string and metadata in a comment at the end of the file. Not used much yet.
   29.3.2016: Possible to set PET 80x25 as the default with MACHINE=PETHI
   29.3.2016: Read convertcommand (CONVERTER) from prefs if present
   29.3.2016: Some kind of hairy integration with ImageMagick for generating animated gifs (convertommand)
   26.3.2016: Line shifting works on C-64/Plus4 with chars 106 and 116 now. Largely changed the shifting code.
   26.3.2016: Show text cursor location and char instead of mouse in typing mode
   27.2.2016: Fixed a minor PET floodfill bug
   18.01.2016: Implemented PET 80 char mode, more border when zoom=1, disable preview for PET 80 (at least for now)
   25.10.2015: Errors opening a pic or ref produce error messages
   24.10.2015: The sketch won't die anymore if reference image can't be opened (plus fixed the years in this changelog)
   18.10.2015: Memory offset display can be toggled using prefs.txt
   17.10.2015: Little fix to preview & focus handling
   17.10.2015: Added readprefs(), which reads "prefs.txt". Selectable: framerate, zoom, machine, path.
   17.10.2015: Moved the changelog to a separate tab, no use keeping it in the main .pde
   17.10.2015: Possibly another optimization: even less loadPixels. Might be risky on some platforms.
   16.10.2015: Notable optimization: less unnecessary load/updatePixels
   14.10.2015: Don't update the window if it's not active in order to save CPU time
   4.10.2015: Eraser now clears with a machine-specific color (erasecolor) instead of the current pen color
   28.9.2015: Shorter lines for the BASIC exporters
   8.6.2015: Export each frame to a separate PNG
   4.9.2014: A bit better aspect ratio for the pixels. Now more like PAL, was somewhere inbetween.
   6.11.2013: Improved basic anim export (still bad and will stay so)
   6.11.2013: Not-so-great basic animation export in user.pde, dup frame right with d
   2.11.2013: Frame copypaste changed to more fluent logic: jump to pasted frames, Dup instead of Add
   2.11.2013: Some probably temporary experiments with animation viewing in user.pde
   28.10.2013: Fixed coloring mode when there are holes, fixed char 32 in rotation map
   28.10.2013: Chars can be deleted from the selection by clicking the char selector. Support for holes (-1).
   28.10.2013: Frames can be locked by rmb click or pressing l
   27.10.2013: Frame preview above the screen, made it clickable. If cutting and there's one frame then just copy.
   25.10.2013: Wrap with arrow keys
   25.10.2013: Load implemented
   25.10.2013: Save implemented
   25.10.2013: Improved edit functionality for frames: cut/paste instead of just add/delete
   24.10.2013: First steps of animation/frames. No save yet.
   24.10.2013: Fixed an unimportant bug with infield value calculation
   17.10.2013: Do not kill the preview window, just hide it
   17.10.2013: Don't let the user kill the window with the button
   17.10.2013: No Preview with m, it just caused trouble
   17.10.2013: Quitting preview shouldn't crash anymore (at least not easily). And even safer again.
   17.10.2013: Works on Processing 2 again
   17.10.2013: Mini 1x1 pixel preview window added. Plus a button for it.
   17.10.2013: Remove modifiers when focus is lost
   16.10.2013: One more speedup, faster drawchar(), Insert bugfix
   16.10.2013: Removed that Alt Gr support, coz it conflicts with the typing of some chars
   16.10.2013: PgUp/PgDn work in the text edit mode, Del, Backspace and Ins likewise
   16.10.2013: Bugfix for VIC initial screen
   16.10.2013: Wrap in typing mode, Esc to exit typing mode, Enter for newline
   16.10.2013: Timings based on clock (cursor blink, backup), not framerate
   16.10.2013: Pixel-level perfection of grid and selection lines
   16.10.2013: Disable unwanted drawing/selection in the typing mode, selection outline back to visible
   16.10.2013: A bit lighter grid
   16.10.2013: KeyEvent not keyEvent for Processing 2, plus needed an import
   15.10.2013: Fixed a HUGE slowdown that followed from drawing blended lines for the grid
   15.10.2013: Correct colors on Plus/4 in the typing mode, all the colors can be selected (shift)
   15.10.2013: Don't change pen color on PET, there's none...
   15.10.2013: Home and End keys work in the typing mode
   15.10.2013: Graphical typing mode, press alt (or alt gr) + shift in the typing mode
   15.10.2013: shifted, controlled, alted => shift, control, alt
   14.10.2013: Improved rotatemap, works better on VIC/PET (Dr. TerrorZ)
   14.10.2013: Redo (shift-u), cleaned undo code
   14.10.2013: Head and tail correctly named in undo. What was I thinking?
   14.10.2013: Shift-C converts C64 image colors to Plus/4. Undo works. Now doesn't even crash if done twice.
   13.10.2013: New color selection markers that work on Plus/4 too
   12.10.2013: Messages displayed onscreen instead of console (see PRINTMESSAGES in settings)
   12.10.2013: Color selector tweaks for Plus/4, asm export for Plus/4. About complete Plus/4 now?
   12.10.2013: Preliminary Plus/4 support coming up. Palette + bas + C export work now.
   11.10.2013: VIC-20 color remap non-fatal bugfix
   11.10.2013: Starting today there are UTF-8 chars in the source
   11.10.2013: Bugfix to the below
   11.10.2013: More kludges to improve the functionality a bit with one-button-mouse: § and °/½ 
   11.10.2013: A small kludge for owners of one-button mouse: ,/. change bg/border color
   9.10.2013: Show screen memory offset (see showoff in settings)
   9.10.2013: Inverted typing mode for situations where you want bg color text (shift-enter)
   7.10.2013: Fix VIC color selection again
   7.10.2013: Because of Mac the replace now works with all buttons
   7.10.2013: Color remapping: replace pen color by ctrl-lmb
   7.10.2013: A simple floodfill, show active modes at the bottom of the screen
   6.10.2013: Exported files now go to the same directory as the image, the extension is changed
   6.10.2013: PRG export for VIC-20, different dir for images and reference pics
   6.10.2013: PRG export (C64 only) - save the helpless graphicians! :)
   6.10.2013: Don't show _backup_.c on window title
   6.10.2013: Add the .c extension if it's omitted from the filename
   6.10.2013: Try to lift the initial selector window (bugs on a Mac). And another attempt.
   6.10.2013: Bugfix for reference (it overwrote the piccy filename)
   6.10.2013: Non-native file selector on all platforms, because Save as needs the name field
   6.10.2013: Save as implemented - time to release the app!
   6.10.2013: Show ref immediately after loading, undo loading possible
   6.10.2013: Don't crash if trying to load export.c, file selector shows extension options
   6.10.2013: Graphical file selector for loading & machine selector at startup, UI buttons
   5.10.2013: Rotate tool added (r), dither should save some memory, show selection size
   5.10.2013: Dither was broken on PET
   4.10.2013: Automatic reference image to PETSCII dither, undo saves bg
   4.10.2013: Tools separated to a new file, fixed a bug in pixel drawing
   4.10.2013: Even better horizontal flipping, vertical flipping, new keys. Thx again to Dr.T!
   4.10.2013: Support for a reference image (reference.png, t), some defaults moved to settings
   4.10.2013: Screenshot dump as png by pressing p/P
   2.10.2013: One more kludge before useful stuff: +/- for shifting vertical and horizontal sticks
   2.10.2013: Hopefully final mapping fixes, little extra check for loading colors
   2.10.2013: Again a bit improved flip map for VIC, and again, plus fixed char flip
   2.10.2013: Tab works in the typing mode, support for sets of chars (sets.txt) - jump with tab
   2.10.2013: Help no longer here, see the web page
   2.10.2013: ORIGOZERO define to show coordinates from (0,0) or (1,1)
   1.10.2013: Reorganized source file structure, somewhat complete undo
   1.10.2013: Another minor fix for flip, added info display (toggle with i)
   1.10.2013: Added a license, removed useless invert with i, improved f and x
   30.9.2013: Fixed a minor bug in flip
   30.9.2013: Crosshair, Typing mode (press enter), invert single char with i
   30.9.2013: Horizontal flip for selection (thanks to Dr.TerrorZ for remapping), fixed loading
   30.9.2013: User-specified hooks for setup/draw/key, coloring with shift-selection
   30.9.2013: A simple PET mode in there, too
   30.9.2013: Self-contained VIC-20 asm viewer and C viewer, a bit more robust loader
   30.9.2013: VIC-20 mode integrated(!), see the settings tab
   29.9.2013: General settings separated to settings.pde, defines in UPPERCASE, bugfixes
   29.9.2013: Bit of speedup, Own scaling of chars to avoid blur with GL
   29.9.2013: Another code cleanup, show real aspect ratio, no preview needed
   29.9.2013: x for char invert, s for save, S for C standalone export
   29.9.2013: Simple 1/4 char drawing mode with alt, bugfix for full/empty chars
   29.9.2013: Shifted rmb picks color only, invert clipboard, improved copypaste (cut removed)
   29.9.2013: Code remapping support for char selector (thanks to Dr.TerrorZ for the map)
   28.9.2013: Self-contained C export, BASIC export, asm export
   28.9.2013: Big cleanup, comments changed to English, improved paste
   27.9.2013: Border scales too, show target of paste, preview mode
   27.9.2013: Save, automatic backup, load, initial copy paste
   26.9.2013: The first version
*/
