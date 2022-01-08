/*

Example js plugin to export PETSCII frame to TASS64 format.

The sole purpose of this script is merely to demonstrate the usage of the export API.

*/

var fp = outputs.add_file(fileprefix + ".s");  // file index
var output = outputs.get(fp).pwriter;  // get PrintWriter

if (machine != "C64"){
    throw 'This plugin is designed to work with C64 only';
}

// var output=stdout;  // print to console

function hex(b){
    /* silly hex converter */
    var bhex = b.toString(16);
    return ("$" + "00".substr(bhex.length) + bhex);
}

function printArr(arr){
    output.print(".byte ");
    for (i in arr){
        output.print(hex(arr[i]));
        if (i == arr.length - 1){
            output.print("\n");
        }
        else if ((i + 1) % 40 == 0) {
            output.print("\n.byte ");
        }
        else {
            output.print(", ");
        }
    }
}

output.println("; example exporter from PETSCII to TASS64");
output.println("; frame " + currentframe + " from " + filename);

var asm = "* = $0801\n" +
          "   ; sys 2064\n" +
          "   .byte $0b ,$08 ,$00 ,$00 ,$9e ,$32 ,$30 ,$36 ,$34 ,$00 ,$00 ,$00 ,$00 ,$00 ,$00 ,$00\n\n" +
          "* = $0810\n" +
          "   lda border\n" +
          "   sta $d020\n" +
          "   lda bg\n" +
          "   sta $d021\n\n" +
          "   ldx #0\n" +
          "loop\n" +
          ".for i := 0, i < 4, i += 1\n" +
          "   lda chars + 250 * i, x\n" +
          "   sta $400 + 250 * i, x\n" +
          "   lda colors + 250 * i, x\n" +
          "   sta $d800 + 250 * i, x\n" +
          ".endfor\n\n" +
          "   inx\n" +
          "   cpx #250\n" +
          "   bne loop\n\n" +
          "done\n" +
          "  jmp done\n\n";

output.print(asm);
output.println("border .byte " + hex(border));
output.println("bg .byte " + hex(bg));

output.println("colors ");
printArr(colors);
output.println("chars ");
printArr(chars);

output.flush();
