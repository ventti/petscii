; C-64 viewer template with an embedded charset, used by PETSCII's "Save .prg"
; when the picture uses a charset that is not in the C-64 ROM.
;
; The editor loads this file, patches three parameter bytes and appends the
; picture and the character data straight after the code, so the .prg it writes
; is one contiguous block with no padding in it:
;
;   file offset       contents
;   0                 load address ($0801)
;   2                 BASIC stub, SYS <start>
;   14 / 15 / 16      border / background / charset pages   (patched)
;   17...             code
;   <template size>   1000 bytes of screen codes            -> $0400
;   +1000             1000 bytes of colour RAM              -> $d800
;   +2000             pages*256 bytes of character data     -> $3800
;
; Only the character pages the picture actually uses are stored (pages is 1..8),
; so a picture that stays below character 128 saves a kilobyte.
;
; Build (from this directory):
;   64tass -o ../../data/template-c64font.prg template-c64font.s

screen  = $0400
colram  = $d800
chars   = $3800         ; charset base, VIC bank 0

zpsrc   = $fb           ; free zero page for the charset copy
zpdst   = $fd

        * = $0801

        .word eol       ; BASIC line: SYS <start>
        .word 2026
        .byte $9e
        .null format("%d", start)
eol     .word 0

border  .byte 0         ; patched by the editor: $d020
bg      .byte 0         ; patched by the editor: $d021
pages   .byte 8         ; patched by the editor: charset pages to copy

start   lda #$0b
        sta $d011       ; screen off while we shuffle memory around
        lda #$1e
        sta $d018       ; screen $0400, charset $3800
        lda border
        sta $d020
        lda bg
        sta $d021

        ; Screen codes and colour RAM, 4 x 250 bytes each so one index does.
        ldx #0
        ldy #250
copy    lda scrdat,x
        sta screen,x
        lda scrdat+250,x
        sta screen+250,x
        lda scrdat+500,x
        sta screen+500,x
        lda scrdat+750,x
        sta screen+750,x
        lda coldat,x
        sta colram,x
        lda coldat+250,x
        sta colram+250,x
        lda coldat+500,x
        sta colram+500,x
        lda coldat+750,x
        sta colram+750,x
        inx
        dey
        bne copy

        ; Character data, whole pages through a pointer pair: the count is a
        ; parameter, so short charsets make a shorter file. The loop above ran
        ; y down to zero, which is where this one wants to start.
        lda #<fntdat
        sta zpsrc
        lda #>fntdat
        sta zpsrc+1
        lda #<chars
        sta zpdst
        lda #>chars
        sta zpdst+1
        ldx pages
fcopy   lda (zpsrc),y
        sta (zpdst),y
        iny
        bne fcopy
        inc zpsrc+1
        inc zpdst+1
        dex
        bne fcopy

        lda #$1b
        sta $d011       ; screen on, and there we stay
halt    jmp halt

; The editor appends the picture and the charset here.
scrdat  = *
coldat  = scrdat+1000
fntdat  = coldat+1000
