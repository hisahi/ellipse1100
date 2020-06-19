; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS command interpreter (file name related stuff)
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

COMMAND_MOVE_CPDESTFN:
        ; FISBUF+2 contains "source filename"
        ; NAMEBUF will have the output
        ACC8
        LDX     #0
        LDY     #0
-       LDA     FISBUF+2.W,X
        CMP     #' '
        BEQ     +
        STA     NAMEBUF.W,Y
        INY
+       INX
        CPX     #$0E
        BCC     -
        LDA     #0
        STA     NAMEBUF.W,Y
        ACC16
        RTS

COMMAND_RENAME_MKDESTFN:
        ; XPATHBUF contains "destination mask"
        ; FISBUF+48 contains "source mask"
        ; FISBUF+2 contains "source filename"
        ; NAMEBUF will have the output
        ; TMPBUF used
        ; uses MKFNTMP1,MKFNTMP2,MKFNTMP3

        ; REMBUF = DOSINBUF
        LDA     #$4000
        DOSCALL
        STX     REMBUF+2.B
        STA     REMBUF.B
        ; copy REMBUF* to TMPBUF
        LDY     #0
        LDA     [REMBUF.B],Y
        AND     #$FF
        TAX
        STX     TMPBUF.W
        ACC8
        INY
        CPX     #0
        BEQ     +
-       LDA     [REMBUF.B],Y
        STA     TMPBUF.W,Y
        INY
        DEX
        BNE     -
+
        ; X = destination mask          (XPATHBUF)
        ; Y = destination filename      (NAMEBUF)
        ; MKFNTMP1 = source filename
        ; MKFNTMP2 = star index
        ; MKFNTMP3 = current star end
        ; TMPBUF = source mask star parameters

        LDX     WC2PATH.W
        LDY     #0
        STZ     MKFNTMP1.W
        STZ     MKFNTMP2.W
        STZ     MKFNTMP3.W
        INC     MKFNTMP2.W
        
        LDA     XPATHBUF.W,X
        BNE     @CHLOOP
        JMP     @COPYSFN
@CHLOOP
        LDA     XPATHBUF.W,X
        BEQ     @ENDLOOP
        CMP     #'.'
        BEQ     @DOT
        CMP     #'?'
        BEQ     @CPFN
        CMP     #'*'
        BEQ     @STAR
        JSR     CMDUPPERCASE.W
        STA     NAMEBUF.W,Y
        INY
        INX
        CPY     MKFNTMP1.W
        BCC     @EY
        STY     MKFNTMP1.W
@EY     CPY     #14
        BCC     @CHLOOP
@ENDLOOP
        LDA     #0
        STA     NAMEBUF.W,Y

        ACC16
        LDY     #NAMEBUF.W
        RTS
.ACCU 8
@DOT:
        STA     NAMEBUF.W,Y
        INY
        INX
        LDA     MKFNTMP1.W
        CMP     #10
        BCS     @EY
        STA     MKFNTMP1.W
        BRA     @EY
@CPFN:
        PHX
        LDX     MKFNTMP1.W
        LDA     FISBUF+2.W,X
        PLX
        INX
        CMP     #' '
        BEQ     +
        STA     NAMEBUF.W,Y
        INY
+       BRA     @EY   
@STAR:
        PHX
        LDA     MKFNTMP2.W
        CMP     TMPBUF.W
        BEQ     +
        BCS     @STARPLX
+       TAX
        INC     MKFNTMP2.W
        LDA     TMPBUF.W,X
        STA     MKFNTMP3.W

        LDX     MKFNTMP1.W
-       CPX     MKFNTMP3.W
        BCS     @STARPLX
        LDA     FISBUF+2.W,X
        CMP     #' '
        BEQ     +
        STA     NAMEBUF.W,Y
        INY
+       INX
        BRA     -

@STARPLX
        PLX
        INX
        BRA     @EY

; copy source filename
@COPYSFN:
        LDX     #$00
-       LDA     FISBUF+2.W,X
        CMP     #' '
        BEQ     +
        STA     NAMEBUF.W,Y
        INY
+       INX
        CPX     #$0E
        BCC     -
        LDA     #0
        STA     NAMEBUF.W,Y
        RTS

; merge NAMEBUF to WCBUF2
COMMAND_COPY_MERGENAMEBUF:
        LDX     #NAMEBUF.W
        JSR     CMDBUILDWC2PATHX.W
        TXY
        RTS

COMMAND_DO_MOVEFILE:
        ACC8
        LDA     $0000.W,X
        BEQ     ++
        LDA     $0000.W,Y
        BEQ     ++
        LDA     $0001.W,X
        CMP     #':'
        BEQ     +
        LDA     $0001.W,Y
        CMP     #':'
        BEQ     +
        BRA     ++
+       JMP     COMMAND_DO_MOVEFILE_HANDLES
++      ACC16
        PHX
        PHY
        ; check if target file exists
        TYX
        LDA     #$1100
        LDY     #TMPBUF.W
        DOSCALL
        BCS     @FAIL
@CONFIRM
        LDA     3,S
        TAX
        LDA     #$1900
        DOSCALL
        LDX     #DOSCOPYALREADYEXISTS
        LDA     #$1900
        DOSCALL
-       LDA     #$0700
        DOSCALL
        BMI     @CNO
        JSR     CMDUPPERCASE16.W
        CMP     #$004E.W ;'N'
        BEQ     @CNO
        CMP     #$0059.W ;'Y'
        BNE     -
@CYES   PLY
        PLX
        BRA     @DOMOVE
@CNO    PLY
        PLX
        LDA     #$FFFF
        SEC
        RTS
@FAIL   CMP     #DOS_ERR_FILE_NOT_FOUND.W
        BEQ     @CYES
@MVERR  PLY
        PLX
        SEC
        RTS
@DOMOVE:
        PHX
        PHY
        ACC16
        LDA     COPYTMP2.W
        BEQ     +
        LDA     #$1900
        DOSCALL
        LDA     #$0220
        DOSCALL
        LDA     #$023D
        DOSCALL
        LDA     #$023E
        DOSCALL
        LDA     #$0220
        DOSCALL
        LDA     1,S
        TAX
        LDA     #$1900
        DOSCALL
        LDA     #$020D
        DOSCALL
+       PLY
        PLX
        PHX
        PHY
        ACC8
        LDX     #0
        DEY
        DEX
-       INX
        INY
        LDA     $0000.W,Y
        BNE     -

-       DEX
        BMI     +
        DEY
        LDA     $0000.W,Y
        CMP     #'\'
        BNE     -
@TERM   LDA     #0
        STA     $0001.W,Y
+
        ACC16
        PLY
        PLX
        LDA     #$3700
        DOSCALL
        BCS     +
        INC     COPYTMP1.W
        CLC
+       RTS

COMMAND_DO_MOVEFILE_HANDLES:
        ACC16
        PHX
        JSR     COMMAND_DO_COPYFILE.W
        PLX
        BCS     @ERR
        LDA     #$1300
        DOSCALL
@ERR    RTS

; uses TMPBUF
COMMAND_DO_COPYFILE:
        STX     COPYTMP4.W
        STY     COPYTMP3.W
        ACC16
        LDA     COPYTMP2.W
        BEQ     +
        LDA     #$1900
        DOSCALL
        LDA     #$0220
        DOSCALL
        LDA     #$023D
        DOSCALL
        LDA     #$023E
        DOSCALL
        LDA     #$0220
        DOSCALL
        LDX     COPYTMP3.W
        LDA     #$1900
        DOSCALL
        LDA     #$020D
        DOSCALL

+       PHD
        ; check if target file exists
        LDA     #$1100
        LDX     COPYTMP3.W
        LDY     #TMPBUF.W
        DOSCALL
        BCS     @FAIL
@CONFIRM
        PHX
        LDX     COPYTMP3.W
        LDA     #$1900
        DOSCALL
        LDX     #DOSCOPYALREADYEXISTS
        LDA     #$1900
        DOSCALL
-       LDA     #$0700
        DOSCALL
        BMI     @CNO
        JSR     CMDUPPERCASE16.W
        CMP     #$004E.W ;'N'
        BEQ     @CNO
        CMP     #$0059.W ;'Y'
        BNE     -
@CYES   LDA     #$020D
        DOSCALL
        PLX
        BRA     @DOCOPY
@CNO    PLX
        LDA     #$FFFF
        SEC
        PLD
        RTS
@FAIL   CMP     #DOS_ERR_FILE_NOT_FOUND
        BNE     @RET
@DOCOPY
        ; COPYTMP3: dest fn/handle
        ; COPYTMP4: src fn/handle
        LDA     #$0F01
        LDX     COPYTMP4.W
        DOSCALL
        BCS     @RET
        STX     COPYTMP4.W
        
        LDA     #$1602
        LDX     COPYTMP3.W
        DOSCALL
        BCS     @CLR
        STX     COPYTMP3.W

        LDA     #FILEBUF.W
        TCD
        
@CP     LDA     #$2100
        LDX     COPYTMP4.W
        LDY     #FILEBUFSIZE.W
        DOSCALL
        BCS     @CLW
        CPY     #0
        BEQ     @CPOK

        LDA     #$2200
        LDX     COPYTMP3.W
        DOSCALL
        BCS     @CLW
        BRA     @CP

@CPOK   LDA     #$1000
        LDX     COPYTMP3.W
        DOSCALL
        BCS     @CLR
        INC     COPYTMP1.W
        CLC
        BRA     @CLR
@CLW    PHP
        PHA
        LDA     #$1000
        LDX     COPYTMP3.W
        DOSCALL
        PLA
        PLP
@CLR    PHP
        PHA
        LDA     #$10FF
        LDX     COPYTMP4.W
        DOSCALL
        PLA
        PLP
@RET    PLD
        RTS
