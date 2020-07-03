; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS disk formatting utility (FORMAT.COM)
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

.INCLUDE "doscomhd.asm"

BEGINNING:
        ACC8
        LDA     $0080.W
        BEQ     @NODISK
        LDA     $0083.W
        BNE     @ILLDISK
        LDA     $0082.W
        CMP     #':'
        BNE     @ILLDISK
        LDA     $0081.W
        AND     #$DF
        CMP     #'A'
        BCC     @ILLDISK
        CMP     #'Z'+1
        BCS     @ILLDISK
        AND     #$1F
        ACC16
        BNE     @DISKOK
@NODISK:
        ACC16
        LDA     #$3E00
        DOSCALL
        BRA     @DISKOK
@ILLDISK:
        ACC16
        LDA     #$1900
        LDX     #BADDRIVE.W
        DOSCALL
        LDA     #$0000
        DOSCALL

@NOFMT:
        ACC16
        LDA     #$020D
        DOSCALL
        LDA     #$0000
        DOSCALL

@DISKOK:
        AND     #$00FF
        STA     FMTDRV.W

        JSL     $81FFF4         ; check if disk number is OK
        BCS     @ILLDISK
        STA     FMTMID.W
        STX     FMTTRK.W
        STY     FMTSEC.W

        LDA     FMTDRV.W
        ORA     #$0040
        ACC8
        STA     CONFIRMDRV.W
        STA     LABELDRV.W
        STA     CDPATH.W
        ACC16

        ; format
        LDA     #$1900
        LDX     #ENTERLABEL.W
        DOSCALL

        LDA     #$0A00
        LDX     #LABEL.W
        LDY     #16
        DOSCALL

        ACC8
        LDA     #' '
-       STA     LABEL.W,Y
        INY
        CPY     #16
        BCC     -
        ACC16

        LDA     #$1900
        LDX     #CONFIRM
        DOSCALL

-       LDA     #$0700
        DOSCALL
        BMI     @NOFMT
        AND     #$00DF
        CMP     #$004E.W ;'N'
        BEQ     @NOFMT
        CMP     #$0059.W ;'Y'
        BNE     -
+
        LDA     #$020D
        DOSCALL

        LDA     #$1900
        LDX     #FORMATTING
        DOSCALL

        ; construct identification sector
        ; partition table
        ACC8
        LDA     #$02
        STA     SECTOR+$1E0.W
        STZ     SECTOR+$1E1.W
        LDA     #$01
        STA     SECTOR+$1E6.W
        LDA     FMTSEC.W
        DEC     A
        STA     SECTOR+$1E7.W
        ACC16
        LDA     #$00
        STA     SECTOR+$1E2.W
        LDA     FMTTRK.W
        DEC     A
        STA     SECTOR+$1E4.W

        LDA     FMTDRV.W
        XBA
        LDX     #$00
        LDY     #SECTOR.W
        JSL     $81FFF8 ; write sector

        ; construct FSMB
        LDX     #512
-       DEX
        DEX
        STZ     SECTOR.W,X
        BPL     -

        ; compute number of chunks
        LDA     FMTSEC.W
        LSR     A
        TAX
        LDA     #0
-       CLC
        ADC     FMTTRK.W
        DEX
        BNE     -
        DEC     A
        DEC     A
        STA     FMTCNK.W

        ACC16
        LDA     #$4C45
        STA     SECTOR.W
        LDA     #$5346
        STA     SECTOR+$02.W
        STZ     SECTOR+$04.W
        STZ     SECTOR+$06.W

        LDA     FMTMID.W
        STA     SECTOR+$08.W

        JSL     $81FFF0 ; get internal tick
        EOR     $0004.W
        STA     SECTOR+$0A.W

        LDA     #$000A
        STA     SECTOR+$10.W

        ; number of ctable sectors
        LDA     FMTCNK.W
        XBA
        INC     A
        AND     #$00FF
        BIT     #1
        BEQ     +
        INC     A
+       STA     SECTOR+$16.W

        LDA     SECTOR+$16.W
        LSR     A
        STA     TMP1.W
        LDA     FMTCNK.W
        SEC
        SBC     TMP1.W
        STA     SECTOR+$12.W

        LDA     FMTSEC.W
        LSR     A
        STA     SECTOR+$14.W
        LDA     #$0002
        STA     SECTOR+$18.W

        LDX     #$0010
-       DEX
        DEX
        LDA     LABEL.W,X
        STA     SECTOR+$20.W,X
        CPX     #0
        BNE     -

        LDA     SECTOR+$12.W
        INC     A
        STA     SECTOR+$30.W
        STZ     SECTOR+$32.W

        LDX     #10
-       ASL     SECTOR+$30.W
        ROL     SECTOR+$32.W
        DEX
        BNE     -

        LDA     SECTOR+$30.W
        STA     TOTALSPACE.W
        SEC
        SBC     #$0400
        STA     SECTOR+$34.W
        STA     FREESPACE.W
        LDA     SECTOR+$32.W
        STA     TOTALSPACE+2.W
        SBC     #0
        STA     SECTOR+$36.W
        STA     FREESPACE+2.W

        LDA     SECTOR+$16.W
        STA     FMTCTABLESECS.W
        CLC
        ADC     #2
        STA     SECTOR+$38.W
        STA     FMTCSEC.W
        STA     FMTRSEC.W
        STZ     SECTOR+$3A.W

        LDA     FMTRSEC.W
-       CMP     FMTSEC.W
        BCC     +
        SEC
        SBC     FMTSEC.W
        STA     FMTRSEC.W
        INC     FMTRTRK.W
        BRA     -
+       
        LDA     FMTDRV.W
        XBA
        ORA     #$01
        LDX     #$00
        LDY     #SECTOR.W
        JSL     $81FFF8 ; write sector

        LDA     SECTOR+$12.W
        INC     A
        ASL     A
        STA     FMTMAXCNK.W
        
        LDA     SECTOR+$16.W
        XBA
        ASL     A
        ASL     A
        AND     #$FC00
        ASL     A
        STA     FMTMAXCNK2.W

        ; prepare chunk table
        LDA     #$FFFF
        STA     CTABLE.W
        LDX     #2
---     ; TODO: check if sector is bad
        LDA     #$0000
        STA     CTABLE.W,X
        INC     FMTCSEC.W
        INC     FMTCSEC.W
        LDA     FMTCSEC.W
-       CMP     FMTSEC.W
        BCC     +
        SEC
        SBC     FMTSEC.W
        STA     FMTCSEC.W
        INC     FMTCTRK.W
        BRA     -
+       INX
        INX
        CPX     FMTMAXCNK.W
        BCC     ---
        CPX     FMTMAXCNK2.W
        BCS     +++

        LDA     #$FFFF
---     STA     CTABLE.W,X
        INX
        INX
        CPX     FMTMAXCNK2.W
        BCC     ---
+++
        ; reserve root directory chunk
        LDA     #$FFFF
        STA     CTABLE+2.W

        LDA     #$FFFF
        LDX     #$0200
-       DEX
        DEX
        STA     SECTOR.W,X
        BNE     -

        LDA     FMTDRV.W
        XBA
        ORA     FMTRSEC.W
        INC     A
        LDX     FMTRTRK.W
        LDY     #SECTOR.W
        JSL     $81FFF8 ; write sector
        
        LDX     #$20
-       DEX
        DEX
        LDA     ROOTDIR.W,X
        STA     SECTOR.W,X
        CPX     #0
        BNE     -

        LDA     FMTDRV.W
        XBA
        ORA     FMTRSEC.W
        LDX     FMTRTRK.W
        LDY     #SECTOR.W
        JSL     $81FFF8 ; write sector

        ; write ctable
        LDA     #2
        STA     FMTCSEC.W
        STZ     FMTCTRK.W
        LDA     #CTABLE.W
        STA     FMTCTABLEPTR.W
        LDX     #0
-       PHX
        LDA     FMTDRV.W
        XBA
        ORA     FMTCSEC.W
        LDX     FMTCTRK.W
        LDY     FMTCTABLEPTR.W
@CT
        JSL     $81FFF8 ; write sector
        
        LDA     FMTCTABLEPTR.W
        CLC
        ADC     #$0200
        STA     FMTCTABLEPTR.W

        INC     FMTCSEC.W
        LDA     FMTCSEC.W
        CMP     FMTSEC.W
        BCC     +
        STZ     FMTCSEC.W
        INC     FMTCTRK.W
+
        PLX
        INX
        CPX     FMTCTABLESECS.W
        BCC     -

        LDA     #$3000
        LDX     #CDPATH
        DOSCALL

        LDA     #$1900
        LDX     #FORMATOK
        DOSCALL
        
        LDA     TOTALSPACE.W
        STA     WIDENUM1.W
        LDA     TOTALSPACE+2.W
        STA     WIDENUM2.W
        JSR     UNPACKWIDEBCD.W
        LDA     #$1900
        LDX     #BCDBUF
        DOSCALL

        LDA     #$1900
        LDX     #FORMATOK2
        DOSCALL
        
        LDA     FREESPACE.W
        STA     WIDENUM1.W
        LDA     FREESPACE+2.W
        STA     WIDENUM2.W
        JSR     UNPACKWIDEBCD.W
        LDA     #$1900
        LDX     #BCDBUF
        DOSCALL

        LDA     #$1900
        LDX     #FORMATOK3
        DOSCALL

        LDA     #$0000
        DOSCALL

; input value in WIDENUM1,WIDENUM2. will be modified!
; output in BCDBUF
UNPACKWIDEBCD:
        ACC16
        PHX
        PHY
        CLD

        LDA     #$3030
        STA     BCDBUF.W
        STA     BCDBUF+2.W
        STA     BCDBUF+4.W
        STA     BCDBUF+6.W
        STA     BCDBUF+8.W

        LDX     #0
        LDY     #0

@DIGITLOOP:
        ; WIDENUM2.WIDENUM1 > POWERSOF10(Y)?
        LDA     WIDENUM2.W
        CMP     POWERSOF10+2.W,Y
        BCC     @NEXTDIGIT
        BEQ     @TESTLWORD
        BCS     @SUBTRACT
@TESTLWORD:
        LDA     WIDENUM1.W
        CMP     POWERSOF10.W,Y
        BCC     @NEXTDIGIT

@SUBTRACT:
        LDA     WIDENUM1.W
        SEC
        SBC     POWERSOF10.W,Y
        STA     WIDENUM1.W
        LDA     WIDENUM2.W
        SBC     POWERSOF10+2.W,Y
        STA     WIDENUM2.W

        ACC8
        INC     BCDBUF.W,X
        ACC16
        BRA     @DIGITLOOP
@NEXTDIGIT:
        LDA     WIDENUM2.W
        BNE     @NONZERO
        LDA     WIDENUM1.W
        BNE     @NONZERO
        BRA     @RETURN
@NONZERO:
        INX
        INY
        INY
        INY
        INY
        CPX     #9
        BCC     @DIGITLOOP
@FINALDIGIT:
        ACC8
        LDA     WIDENUM1.W
        ORA     #$30
        STA     BCDBUF.W,X
        ACC16
@RETURN:
        ; remove leading zeroes
        ACC8
        LDX     #0
-       CPX     #9
        BCS     +
        LDA     BCDBUF.W,X
        CMP     #'0'
        BNE     +
        LDA     #' '
        STA     BCDBUF.W,X
        INX
        BRA     -

+       PLY
        PLX
        ACC16

        RTS

CONFIRM:
        .DB     "Are you sure you want to format drive "
CONFIRMDRV:
        .DB     "$:?", 13
        .DB     "All data on the drive will be lost!", 13
        .DB     "Confirm (Y/N)?", 0
ENTERLABEL:
        .DB     "Disk label for "
LABELDRV:
        .DB     "$: (maximum 16 characters): ", 0
BADDRIVE:
        .DB     "Invalid parameter", 13, 0
FORMATTING:
        .DB     "Formatting...", 0
FORMATOK:
        .DB     13, "Drive successfully formatted", 13, 13
        .DB     13, "  Total space on drive: ", 0
FORMATOK2:
        .DB     " bytes", 13, "   Free space on drive: ", 0
FORMATOK3:
        .DB     " bytes", 13, 0
CDPATH:
        .DB     "$:", $5C, 0
POWERSOF10:
.MACRO PO10
        .DW     (10^\1)&$FFFF
        .DW     ((10^\1)>>16)&$FFFF
.ENDM
.REPEAT 10 INDEX N
        PO10    9-N
.ENDR
BCDBUF:
        .DB     "$$$$$$$$$$", 0
FMTDRV:
        .DW     0
FMTMID:
        .DW     0
FMTTRK:
        .DW     0
FMTSEC:
        .DW     0
FMTCNK:
        .DW     0
FMTCTRK:
        .DW     0
FMTCSEC:
        .Dw     0
FMTMAXCNK:
        .DW     0
FMTMAXCNK2:
        .DW     0
FMTCTABLESECS:
        .DW     0
FMTRTRK:
        .DW     0
FMTRSEC:
        .DW     0
FMTCTABLEPTR:
        .DW     0
TMP1:
        .DW     0
WIDENUM1:
        .DW     0
WIDENUM2:
        .DW     0
TOTALSPACE:
        .DW     0
        .DW     0
FREESPACE:
        .DW     0
        .DW     0
LABEL:
.REPEAT 17
        .DB     0
.ENDR
.ORG $07E0
ROOTDIR:
        .DB     $40, $00
        .DB     ".         .   "
        .DB     0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .DW     0
        .DW     0
        .DW     1
SECTOR:
        .DB     "ELLIPSE@"
.REPEAT 504
        .DB     0
.ENDR
CTABLE:

