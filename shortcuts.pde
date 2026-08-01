// Single source of truth for keyboard shortcuts.
//
// Every shortcut is registered once here with its context group, the key text to
// show, and a one-line description. Three things read this one table:
//   - the Help overlay (showhelp_panel) dumps it, grouped, so the help can never
//     drift from the actual bindings;
//   - button-backed commands carry their cmd_ action, so a button's tooltip is
//     generated from the same entry (sctip) instead of a hand-written string;
//   - simple global keys carry a dispatch key (dkey), so keyPressed() runs them
//     straight from the table rather than an inline if (see events.pde).
//
// Context-sensitive keys (flips, pickers, typing-mode navigation, ...) keep their
// inline handling but are still registered desc-only so they show up in Help.

class Shortcut
{
    String group,   // context section, e.g. "Drawing" (also the Help heading)
           keys,    // key text to display, e.g. "Shift+U"
           desc,    // one-line explanation
           id;      // stable id for button/tooltip lookup (null if none)
    Runnable action;// what it does (null for desc-only entries)
    char dkey;      // key char for table dispatch in keyPressed (0 = handled inline)
}

ArrayList<Shortcut> shortcuts=new ArrayList<Shortcut>();

// desc-only
void reg(String group,String keys,String desc)
{ add(group,keys,desc,null,null,(char)0); }
// wired to a button/command but dispatched inline (0 dkey), e.g. guarded keys
void reg(String group,String keys,String desc,String id,Runnable action)
{ add(group,keys,desc,id,action,(char)0); }
// fully wired: also dispatched from the shortcut table on key==dkey
void reg(String group,String keys,String desc,String id,Runnable action,char dkey)
{ add(group,keys,desc,id,action,dkey); }

void add(String group,String keys,String desc,String id,Runnable action,char dkey)
{
    Shortcut s=new Shortcut();
    s.group=group; s.keys=keys; s.desc=desc; s.id=id; s.action=action; s.dkey=dkey;
    shortcuts.add(s);
}

Shortcut scById(String id)
{
    for(Shortcut s: shortcuts)
        if(id.equals(s.id)) return s;
    return null;
}

// Tooltip text for a button, built from its shortcut entry: "desc  [keys]".
String sctip(String id)
{
    Shortcut s=scById(id);
    if(s==null) return "";
    return s.keys.equals("") ? s.desc : s.desc+"  ["+s.keys+"]";
}

void build_shortcuts()
{
    if(!shortcuts.isEmpty()) return; // built once; survives machine switches

    reg("Mouse","Left","Draw / pick pen colour or char");
    reg("Mouse","Middle","Pick char+colour, or border colour");
    reg("Mouse","Right","Erase / pick bg / lock / toggle case");
    reg("Mouse","Wheel","Darken or lighten shade (Plus/4)");

    reg("Modifiers (hold)","Ctrl","Selection: drag LMB=box, RMB=free");
    reg("Modifiers (hold)","Ctrl+A","Select the whole image");
    reg("Modifiers (hold)","Alt","Quarter-character pixel drawing");
    reg("Modifiers (hold)","L-Shift","Colouring: replace colour only");
    reg("Modifiers (hold)","R-Shift","Character-only: replace char only");

    reg("Drawing","f","Floodfill char+colour (hold+click)");
    reg("Drawing","Shift+F","Floodfill colour only");
    reg("Drawing","x","Invert current char or selection");
    reg("Drawing","Shift+X","Invert char under the cursor");
    reg("Drawing","h","H-flip selection or current char");
    reg("Drawing","Shift+H","H-flip char under the cursor");
    reg("Drawing","v","V-flip selection or current char");
    reg("Drawing","Shift+V","V-flip char under the cursor");
    reg("Drawing","r","Rotate selection/char clockwise");
    reg("Drawing","Shift+R","Rotate char under the cursor");
    reg("Drawing","Tab","Walk related character sets");
    reg("Drawing","Up/Down","Grow / shrink stick characters");
    reg("Drawing","+ / -","Nudge stick char (horiz. / vert.)");
    reg("Drawing","Space","Toggle the selection on/off");
    reg("Drawing","u","Undo","undo",() -> cmd_undo());            // inline (guarded by !mousePressed)
    reg("Drawing","Shift+U","Redo","redo",() -> cmd_redo(),'U');

    reg("Typing mode","Enter","Typing mode (Shift+Enter=inverse)");
    reg("Typing mode","Esc","Exit typing mode");
    reg("Typing mode","Alt","Hold to type graphic characters");
    reg("Typing mode","Arrows","Move cursor (wraps at edges)");
    reg("Typing mode","Home/End","Cursor to line start / end");
    reg("Typing mode","PgUp/PgDn","Cursor to first / last row");
    reg("Typing mode","Tab","Cursor to next 4-char column");
    reg("Typing mode","Insert","Insert space, shift line right");
    reg("Typing mode","Del/Bksp","Delete forward / backward");

    reg("View","g","Toggle the character grid","grid",() -> cmd_grid(),'g');
    reg("View","c","Toggle the crosshair");
    reg("View","i","Toggle the info display");
    reg("View","t","Cycle reference transparency");
    reg("View","Shift+T","Reload & re-trace reference");
    reg("View","Ctrl+1-8","Set zoom (drag edge to zoom)");
    reg("View","? / F1","Toggle this help overlay","help",() -> cmd_help());

    reg("Colours (palette machines)",",","Next background colour");
    reg("Colours (palette machines)",".","Next border colour");
    reg("Colours (palette machines)",";","Previous background colour");
    reg("Colours (palette machines)",":","Previous border colour");
    reg("Colours (palette machines)","§","Pick char+colour under cursor");
    reg("Colours (palette machines)","° or 1/2","Pick pen colour only"); // ½ is not in the UI font
    reg("Colours (palette machines)","C","Remap colours (after C64 load)");

    reg("Animation","Left/Right","Previous / next frame");
    reg("Animation","Home/End","First / last frame");
    reg("Animation","1 .. 0","Jump to frame 1..10");
    reg("Animation","l","Lock / unlock current frame");
    reg("Animation","d","Duplicate frame to the right","dupright",() -> cmd_dup_right(),'d');

    reg("File & export","s","Save over current file (.c)","save",() -> cmd_save(),'s');
    reg("File & export","Shift+S","Self-contained C viewer (cc65)");
    reg("File & export","a","Export asm data (.s)");
    reg("File & export","Shift+A","Self-contained asm viewer (ACME)");
    reg("File & export","b","Self-contained BASIC viewer");
    reg("File & export","e","Runnable .prg (charset included)","exportprg",() -> cmd_export_prg(),'e');
    reg("File & export","Shift+E","Export a .pet file");
    reg("File & export","q","Export as SEQ (C-64 only)");
    reg("File & export","p","Export all frames as .png","exportpng",() -> cmd_export_png(false),'p');
    reg("File & export","Shift+P",".png including borders","exportpngb",() -> cmd_export_png(true),'P');
    reg("File & export","å","Save chars & colours separately");
    reg("File & export","Ctrl+E","Run the plugin script");
    reg("File & export","Ctrl+D","Quit");
}
