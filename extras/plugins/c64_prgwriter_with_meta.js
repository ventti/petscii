/* example js plugin to export PETSCII frame in binary format */

var fi = outputs.add_file("data.prg");  // returns output index
var fj = outputs.add_file("data.txt");
var output = outputs.get(fi).pwriter;  // returns output printwriter
var meta = outputs.get(fj).pwriter;  //another printwriter for demonstrative purposes

function writeByte(b){
    output.write(b);
}

function writeWord(w){
    var lo = w & 255;
    var hi = (w >> 8) & 255;
    writeByte(lo);
    writeByte(hi);
}

// * = $1000
writeWord(4096);

for (i in chars){
    writeByte(chars[i]);
}

for (i in colors){
    writeByte(colors[i]);
}

writeByte(bg);
writeByte(border);

meta.println("Description of 'data.prg'");
meta.println("Source file: " + filename + ", frame: " + currentframe);
meta.println("Background: " + bg + ", border: " + border);
