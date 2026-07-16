// Cohesive groupings of what used to be loose global variables. Processing
// concatenates every tab into one class, so this is namespacing/ownership rather
// than true encapsulation, but it shrinks the global surface and makes it clear
// which state belongs together. Instances are created below.
//
// NOTE: this file is intentionally excluded from the bulk sed renames used to
// introduce these groupings, so the field names below stay bare.

// Window size, UI layout coordinates and drag-to-zoom state.
class View
{
    int col1_start,col1_end,       // x
        col2_start,col2_end,
        buttons_start,
        canvas_start,canvas_end,   // y
        colorsel_start,
        charsel_start,charsel_end,
        anim_start,anim_end,       // anim frames
        winW,winH,                 // computed window size
        defaultzoom=2,             // zoom to restore with the "Zoom" button
        dragw,dragh,resizesettle=0; // drag-to-zoom: track a settled user resize
}
View view=new View();

// Marquee selection + clipboard of chars/colours.
class Sel
{
    int x,y,w,h,      // selection rectangle (was selx/sely/selw/selh)
        mode;         // was selectmode
    boolean add=true; // was selectadd
    int[] clip_chars, clip_colors;
}
Sel sel=new Sel();

// Text-entry cursor and typing/blink state.
class Cur
{
    int x,y,          // was cursorx/cursory
        typing,       // >0 = typing mode
        blink;
}
Cur cur=new Cur();
