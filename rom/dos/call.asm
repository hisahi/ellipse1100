; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS call vector
; 
; Copyright (c) 2020 Sampo Hippeläinen (hisahi)
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
; 
; Written for the WLA-DX assembler
;

DOSCALLENTRY:
        AXY16
        CLD
        PHP
        PHB
        PHA
        SETBANK16       $80
        LDA     #$FFFF
        ACC8
        BIT     DOSPAGE|DOSBUSY.W
        STA     DOSPAGE|DOSBUSY.W
        ACC16
        PLA
        PLB
        BVS     DOSISBUSY
        PHA
        PHX
        XBA
        AND     #$FF
        CMP     #$40
        BCS     DOSUNKFUNCPLXPLA
        ASL     A
        TAX
        ; stack:        K PC16 X16 A16 P8
        ACC8
        LDA     8,S
        STA     DOSLD|DOSPROGBANK.L
        ACC16
        LDA     DOSBANKC|DOSCALLTABLE.L,X
        STA     DOSLC|DOSICALLVEC+1.L
        PLX
        PLA
        PLP
        JML     DOSLC|DOSICALLVEC.L
DOSCALLEXIT:
        PHP
        ACC16
        PHA
        ACC8
        LDA     #$00
        STA     DOSLD|DOSBUSY.L
        ACC16
        PLA
        PLP
        RTL

DOSUNKFUNCPLXPLA:
        PLX
        PLA
        PLP
DOSUNKFUNC:
        LDA     #DOS_ERR_UNK_FUNCTION
        SEC
        RTL

DOSISBUSY:
        PLP
        LDA     #DOS_ERR_DOS_BUSY
        SEC
        RTL

DOSCALLTABLE:
        .DW     DOSTERMINATE.W          ; $00 = terminate program
        .DW     DOSSTDINREAD.W          ; $01 = read char from STDIN
        .DW     DOSSTDOUTWRITE.W        ; $02 = write char to STDOUT
        .DW     DOSUNKFUNC.W            ; $03 = 
        .DW     DOSUNKFUNC.W            ; $04 = 
        .DW     DOSUNKFUNC.W            ; $05 = 
        .DW     DOSUNKFUNC.W            ; $06 = direct console I/O
        .DW     DOSSTDINREADQUIET.W     ; $07 = read char from STDIN w/ echo
        .DW     DOSSTDINREADRAW.W       ; $08 = raw read char from STDIN
        .DW     DOSOUTPUTSTRING24.W     ; $09 = output string ending in '$'
        .DW     DOSREADLINEINPUT.W      ; $0A = read line of input
        .DW     DOSINPUTSTATUS.W        ; $0B = get input status
        .DW     DOSFLUSHSTDIN.W         ; $0C = flush stdin
        .DW     DOSFLUSHFILES.W         ; $0D = flush all open files
        .DW     DOSSETDRIVE.W           ; $0E = set active drive
        .DW     DOSOPENFILE.W           ; $0F = open file
        .DW     DOSCLOSEFILE.W          ; $10 = close file
        .DW     DOSFINDFIRST.W          ; $11 = find first matching file
        .DW     DOSFINDNEXT.W           ; $12 = find next matching file
        .DW     DOSDELETEFILE.W         ; $13 = delete files
        .DW     DOSUNKFUNC.W            ; $14 = 
        .DW     DOSUNKFUNC.W            ; $15 = 
        .DW     DOSCREATEFILE.W         ; $16 = create/truncate file
        .DW     DOSRENAMEFILE.W         ; $17 = rename file
        .DW     DOSGETDRIVEINFO.W       ; $18 = get drive info
        .DW     DOSOUTPUTSTRING00.W     ; $19 = output string ending in '\0'
        .DW     DOSUNKFUNC.W            ; $1A = set DTA
        .DW     DOSUNKFUNC.W            ; $1B = get DTA
        .DW     DOSUNKFUNC.W            ; $1C = 
        .DW     DOSUNKFUNC.W            ; $1D = 
        .DW     DOSSETATTRS.W           ; $1E = set file attributes
        .DW     DOSGETATTRS.W           ; $1F = get file attributes
        .DW     DOSUNKFUNC.W            ; $20 = 
        .DW     DOSFILEREAD.W           ; $21 = read from file
        .DW     DOSFILEWRITE.W          ; $22 = write to file
        .DW     DOSFILEGETSIZE.W        ; $23 = get file size
        .DW     DOSFILESEEK.W           ; $24 = seek file
        .DW     DOSUNKFUNC.W            ; $25 = 
        .DW     DOSUNKFUNC.W            ; $26 = 
        .DW     DOSUNKFUNC.W            ; $27 = 
        .DW     DOSUNKFUNC.W            ; $28 = 
        .DW     DOSUNKFUNC.W            ; $29 = 
        .DW     DOSGETDATE.W            ; $2A = get system date
        .DW     DOSSETDATE.W            ; $2B = set system date
        .DW     DOSGETTIME.W            ; $2C = get system time
        .DW     DOSSETTIME.W            ; $2D = set system time
        .DW     DOSUNKFUNC.W            ; $2E = 
        .DW     DOSUNKFUNC.W            ; $2F = 
        .DW     DOSSETDIR.W             ; $30 = set current directory
        .DW     DOSGETDIR.W             ; $31 = get current directory
        .DW     DOSUPDDIRENT.W          ; $32 = update file entry
        .DW     DOSMKDIR.W              ; $33 = create directory
        .DW     DOSUNKFUNC.W            ; $34 = 
        .DW     DOSUNKFUNC.W            ; $35 = 
        .DW     DOSRMDIR.W              ; $36 = delete (empty) directory
        .DW     DOSMOVEENT.W            ; $37 = move file entry
        .DW     DOSLAUNCH.W             ; $38 = launch program
        .DW     DOSGETEXITCODE.W        ; $39 = get exit code
        .DW     DOSALLOCMEM.W           ; $3A = allocate memory
        .DW     DOSFREEMEM.W            ; $3B = free memory allocation
        .DW     DOSUNKFUNC.W            ; $3C = read drive FSMB
        .DW     DOSUNKFUNC.W            ; $3D = write drive FSMB
        .DW     DOSGETDRIVE.W           ; $3E = get active drive
        .DW     DOSGETVER.W             ; $3F = get Ellipse DOS version
