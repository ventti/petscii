/* example js plugin to export PETSCII frame in binary format */

var fp = outputs.add_file("data.prg");  // returns output index
var output = outputs.get(fp).pwriter;

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
