; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS command interpreter (CONSOLE.COM) commands
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

.ACCU 16
COMMAND_EXIT:
        LDA     #$0000
        DOSCALL

.ACCU 16
COMMAND_VER:
        LDX     #CONSOLEMESSAGE
        LDA     #$1900
        DOSCALL
COMMAND_REM:
        RTS

.ACCU 16
COMMAND_CLS:
        SEC
        JSL     $013FEC ; clear screen
        CLC
        LDX     #0
        LDY     #0
        JSL     $013FFC ; move cursor
        ACC16
        RTS

.ACCU 16
COMMAND_ECHO:
        ACC8
        LDA     CONBUF.W,X
        BEQ     @ECHOST
        LDA     CONBUF+1.W,X
        BNE     +
        LDA     CONBUF.W,X
        CMP     #'.'
        BEQ     @ECNL
+       LDA     CONBUF.W,X
        AND     #$DF
        CMP     #'O'
        BEQ     @ECO
@ECSTD:
        ACC16
        TXA
        CLC
        ADC     #CONBUF.W
        TAX
        LDA     #$1900
        DOSCALL
@ECNL:
        ACC16
        LDA     #$020D
        DOSCALL
        RTS
.ACCU 8
@ECO:
        LDA     CONBUF+1.W,X
        AND     #$DF
        CMP     #'N'
        BEQ     @ECON
        CMP     #'F'
        BNE     @ECSTD
@ECOF:
        LDA     CONBUF+2.W,X
        AND     #$DF
        CMP     #'F'
        BNE     @ECSTD
@ECOFF:
        LDA     CONBUF+3.W,X
        BNE     @ECSTD
        BRA     @ECOFF0
@ECON:
        LDA     CONBUF+2.W,X
        BEQ     @ECON0
        BNE     @ECSTD
.ACCU 8
@ECHOST:
        ACC16
        LDA     #$1900
        LDX     #CMDMSGECHO
        DOSCALL

        LDA     ECHOON.W
        BNE     +
        LDX     #CMDMSGECHOTOFF
        BRA     ++
+       LDX     #CMDMSGECHOTON
++      LDA     #$1900
        DOSCALL

        LDA     #$020D
        DOSCALL

        RTS
@ECON0:
        ACC16
        LDA     #1
        STA     ECHOON.W
        RTS
@ECOFF0:
        ACC16
        LDA     #0
        STA     ECHOON.W
        RTS

.ACCU 16
COMMAND_DATE:
        LDA     #$2A00
        DOSCALL

        JSR     UNPACK_DATE

        ACC16
        LDX     #CMDDATEMSG
        LDA     #$1900
        DOSCALL

        LDA     #$020D
        DOSCALL

@LOOP   LDX     #CMDDATEMSGNEW
        LDA     #$1900
        DOSCALL

        ; read line to CONBUF
        LDX     #CONBUF
        LDY     #256
        LDA     #$0A00
        DOSCALL

        CPY     #0
        BEQ     +
        ACC8
        LDA     #0
        STA     CONBUF.W,Y
        ACC16
        LDX     #0
        JSR     COMMAND_DATE_PARSE.W
        BCS     @FAIL

@GOT    LDY     #0
        JSR     COMMANDNUMTMPBCD8TOBIN.W
        LDY     #1
        JSR     COMMANDNUMTMPBCD8TOBIN.W
        LDY     #2
        JSR     COMMANDNUMTMPBCD16TOBIN.W

        AXY16
        LDA     NUMTMP+2.W
        SEC
        SBC     #1980
        TAY
        LDA     #$2B00
        LDX     #0
        AXY8
        LDA     NUMTMP+1.W
        LDX     NUMTMP.W
        AXY16
        DOSCALL
        BCS     @FAIL
+       AXY16
        RTS
@FAIL   LDA     #$1900
        LDX     #CMDDATEMSGINVALID
        DOSCALL
        BRA     @LOOP

.ACCU 16
COMMAND_TIME:
        LDA     #$2C00
        DOSCALL

        JSR     UNPACK_TIME

        ACC16
        LDX     #CMDTIMEMSG
        LDA     #$1900
        DOSCALL

        LDA     #$020D
        DOSCALL

@LOOP   LDX     #CMDTIMEMSGNEW
        LDA     #$1900
        DOSCALL

        ; read line to CONBUF
        LDX     #CONBUF
        LDY     #256
        LDA     #$0A00
        DOSCALL

        CPY     #0
        BEQ     +
        ACC8
        LDA     #0
        STA     CONBUF.W,Y
        ACC16
        LDX     #0
        JSR     COMMAND_TIME_PARSE.W
        BCS     @FAIL

@GOT    LDY     #0
        JSR     COMMANDNUMTMPBCD8TOBIN.W
        LDY     #1
        JSR     COMMANDNUMTMPBCD8TOBIN.W
        LDY     #2
        JSR     COMMANDNUMTMPBCD8TOBIN.W

        LDA     #$2D00
        LDX     #0
        LDY     #0
        AXY8
        LDA     NUMTMP.W
        LDX     NUMTMP+1.W
        LDY     NUMTMP+2.W
        AXY16
        DOSCALL
        BCS     @FAIL
+       AXY16
        RTS
@FAIL   LDA     #$1900
        LDX     #CMDTIMEMSGINVALID
        DOSCALL
        BRA     @LOOP

.ACCU 16
COMMAND_PAUSE:
        LDA     #$1900
        LDX     #COMMANDPAUSEMSG
        DOSCALL

        LDA     #$0800
        DOSCALL

        LDA     #$020D
        DOSCALL
        RTS

.ACCU 16
COMMAND_CHDIR:
        ACC8
        LDA     CONBUF.W,X
        BEQ     @SHOWCURDRIVE
        LDA     CONBUF+2.W,X
        BNE     @CHANGE
        LDA     CONBUF+1.W,X
        CMP     #':'
        BNE     @CHANGE
        LDA     CONBUF.W,X
        JSR     CMDUPPERCASE.W
        CMP     #'A'
        BCC     @CHANGE
        CMP     #'Z'+1
        BCS     @CHANGE
@SHOWOTHERDRIVE:
        STA     PATHBUF.W
        SEC
        SBC     #'A'-1
        ACC16
        AND     #$001F
        ORA     #$3100
        BRA     @SHOWPATH
@SHOWCURDRIVE:
        ACC16
        LDA     #$3E00
        DOSCALL
        ACC8
        CLC
        ADC     #$40
        STA     PATHBUF.W
        ACC16
        LDA     #$3100
@SHOWPATH:
        LDX     #PATHBUF+3.W
        DOSCALL
        BCS     @ERR
        LDA     #':'
        STA     PATHBUF+1.W
        LDA     #'\'
        STA     PATHBUF+2.W
        
        LDA     #$1900
        LDX     #PATHBUF
        DOSCALL
        
        LDA     #$020D
        DOSCALL

        RTS
@ERR:
        JSR     COMMAND_ERROR.W
        RTS
@CHANGE:
        ACC16
        TXA
        CLC
        ADC     #CONBUF.W
        TAX
        LDA     #$3000
        DOSCALL
        BCC     +
        JSR     COMMAND_ERROR.W
+       RTS

.ACCU 16
COMMAND_DIR:                            ; TODO: support /P (DIRFLAGS & 2)
        STZ     DIRFLAGS.W
        STZ     DIRTMP+4.W
        ACC8
-       JSR     @FLAG
        BCC     -
        STX     DIRTMP.W
@MAINLOOP:
        LDA     CONBUF.W,X
        BEQ     +
        JSR     COMMANDPARSESKIPSP.W
        LDA     CONBUF.W,X
        LDA     #'/'
        BEQ     @POSTFLAG
        INX
        BRA     @MAINLOOP
+       JMP     COMMAND_DIR_INT
@POSTFLAG:
        STZ     CONBUF.W,X
        JSR     @FLAGPOST
        BEQ     @MAINLOOP
@FLAG:
        JSR     COMMANDPARSESKIPSP.W
        LDA     CONBUF.W,X
        CMP     #'/'
        BNE     @FLAGNOT
        INX
@FLAGPOST:
        LDA     CONBUF.W,X
        INX
        JSR     CMDUPPERCASE.W
        CMP     #'W'
        BEQ     @FLAGWIDE
        CMP     #'P'
        BEQ     @FLAGPAUS
        CLC
        RTS
@FLAGNOT:
        SEC
        RTS
@FLAGWIDE:
        LDA     DIRFLAGS.W
        ORA     #1
        STA     DIRFLAGS.W
        CLC
        RTS
@FLAGPAUS
        LDA     DIRFLAGS.W
        ORA     #2
        STA     DIRFLAGS.W
        CLC
        RTS

COMMAND_DIR_INT:
        LDX     DIRTMP.W
        LDA     CONBUF.W,X
        BNE     COMMAND_DIR_SUPPLIED
COMMAND_DIR_EMPTY_PATH:
        ACC16
        STZ     DIRDRIVENUM.W
        LDA     #$3E00
        DOSCALL
        CLC
        ADC     #$40
        ACC8
        STA     PATHBUF.W
        LDA     #':'
        STA     PATHBUF+1.W
        LDA     #'\'
        STA     PATHBUF+2.W
        ACC16
        LDA     #$3100
        LDX     #PATHBUF+3
        DOSCALL
        ACC8
        LDX     #PATHBUF
        JSR     COMMAND_DIR_HEADER
        LDX     #COMMANDDIREMPTY
        JSR     COMMAND_DIR_LIST
        JSR     COMMAND_DIR_FOOTER
        RTS

COMMAND_DIR_INVALID:
        ACC16
        LDA     #DOS_ERR_INVALID_DRIVE
COMMAND_DIR_ERR:
        JSR     COMMAND_ERROR.W
        RTS

.ACCu 8
CMDNAMEHASWILDCARDS:
        PHX
        PHY
        LDX     #0
-       LDA     NAMEBUF.W,X
        BEQ     +
        CMP     #'*'
        BEQ     @FOUND
        CMP     #'?'
        BEQ     @FOUND
        INX
        BRA     -
+       PLY
        PLX
        CLC
        RTS
@FOUND  PLY
        PLX
        SEC
        RTS

COMMAND_DIR_SUPPLIED:
        ACC16
        STZ     DIRDRIVENUM.W
        LDA     #$3E00
        DOSCALL
        AND     #$FF
        STA     DIROLDDRIVE.W
        ACC8
        ; check drive
        LDA     CONBUF+1.W,X
        CMP     #':'
        BNE     +
        LDA     CONBUF.W,X
        INX
        INX
        JSR     CMDUPPERCASE.W
        CMP     #'A'
        BCC     COMMAND_DIR_INVALID
        CMP     #'Z'+1
        BCS     COMMAND_DIR_INVALID
        SEC
        SBC     #'A'-1
        ACC16
        ORA     #$0E00
        DOSCALL
        BCS     COMMAND_DIR_ERR
        ACC8
+
        ; scan to end of path
-       INX
        LDA     CONBUF.W,X
        BNE     -
        ; find last backslash
-       LDA     CONBUF.W,X
        CMP     #'\'
        BEQ     ++
        CPX     DIRTMP.W
        BCC     ++
        DEX
        BRA     -
++      ; X is now at last backslash, or before beginning of string
        LDY     #$FFFF
        PHX
        ; copy from after X to NAMEBUF
-       INX
        INY
        LDA     CONBUF.W,X
        JSR     CMDUPPERCASE.W
        STA     NAMEBUF.W,Y
        BEQ     +
        CPY     #15
        BCC     -
+       INY
        LDA     #0
        STA     NAMEBUF.W,Y
        PLX
        ; copy from before until X to end of PATHBUF
        LDY     #_sizeof_PATHBUF
-       DEY
        CPX     DIRTMP.W
        BCC     +
        LDA     CONBUF.W,X
        JSR     CMDUPPERCASE.W
        STA     PATHBUF.W,Y
        DEX
        BRA     -
+       LDA     #0
        STA     PATHBUF.W,Y
        INY
        STY     DIRTMP+2.W

        ; resolve file. is it a folder? if so, shift backwards
        LDA     NAMEBUF.W
        BEQ     +++
        JSR     CMDNAMEHASWILDCARDS.W
        BCS     +++
        ACC16
        LDA     DIRTMP+2.W
        CLC
        ADC     #PATHBUF
        TAX
        LDY     #FISBUF.W
        LDA     #$1100
        DOSCALL
        BCS     +++
        LDA     FISBUF.W
        AND     #$0040
        BEQ     +++
        ; scan X to end
        ACC8
        LDX     #0
-       INX
        LDA     NAMEBUF.W,X
        BNE     -
        ACC16
        TXA
        EOR     #$FFFF
        CLC
        ADC     #NAMEBUF.W
        TAX
        LDY     #NAMEBUF.W
        ACC8
-       LDA     $0000.W,Y
        STA     $0000.W,X
        DEC     DIRTMP+2.W
        INX
        INY
        CPX     #NAMEBUF.W
        BCC     -
        LDA     #'\'
        STA     NAMEBUF-1.W
        LDA     #0
        STA     NAMEBUF.W
+++     ACC16

        LDA     #PATHBUF
        CLC
        ADC     DIRTMP+2.W
        TAX
        ACC8
        JSR     COMMAND_BUILD_XPATH.W

        ACC16
        LDA     XPATHBUF.W
        AND     #$1F
        STA     DIRDRIVENUM.W

        LDX     #XPATHBUF
        JSR     COMMAND_DIR_HEADER
        LDA     #PATHBUF
        CLC
        ADC     DIRTMP+2.W
        TAX
        JSR     COMMAND_DIR_LIST
        JSR     COMMAND_DIR_FOOTER

        LDA     DIROLDDRIVE.W
        ORA     #$0E00
        DOSCALL

        RTS

COMMAND_DIR_HEADER:
        ACC8
        LDA     $0000.W,X
        STA     COMMANDDIRHEADER1_FMT.W
        ACC16
        AND     #$1F
        PHX
        JSR     CMDLOADFSMB.W
        PLX
        PHX

        LDA     #$1900
        LDX     #COMMANDDIRHEADER1
        DOSCALL

        ; volume label
        LDX     #14
-       LDA     FSMBBUF+$20.W,X
        STA     NAMEBUF.W,X
        DEX
        DEX
        BPL     -
        STZ     NAMEBUF+$10.W

        LDA     #$1900
        LDX     #NAMEBUF.W
        DOSCALL

        LDA     #$1900
        LDX     #COMMANDDIRHEADER2
        DOSCALL

        ; path
        LDA     1,S
        TAX
        LDA     #$1900
        DOSCALL

        LDA     #$1900
        LDX     #COMMANDDIRHEADER3
        DOSCALL

        STZ     DIRTOTALFILES.W
        
        PLX
COMMAND_DIR_CLC:
        CLC
COMMAND_DIR_RTS:
        RTS

COMMAND_DIR_LIST:
        ACC16
        LDA     #$1100
        LDY     #FISBUF.W
        DOSCALL
        BCS     @ERRFIRST
@FILELOOP:
        INC     DIRTOTALFILES.W
        JSR     COMMAND_DIR_PRINT_FIS
        
        LDA     #$1200
        LDY     #FISBUF.W
        DOSCALL
        BCC     @FILELOOP
@ERRNEXT:
        CMP     #DOS_ERR_NO_MORE_FILES
        BEQ     COMMAND_DIR_CLC                 ; no more files
        JSR     COMMAND_ERROR.W
        ;TODO: handle disk errors?
        BRA     COMMAND_DIR_RTS
@ERRFIRST:
        JSR     COMMAND_ERROR.W
        ;TODO: handle disk errors?
        BRA     COMMAND_DIR_RTS

COMMAND_DIR_PRINT_FIS:
        ACC8
        LDA     DIRFLAGS.W
        AND     #1
        BEQ     +
        JMP     COMMAND_DIR_PRINT_FIS_WIDE
+       BIT     FISBUF.W
        BVC     @FILENAME
        JMP     @DIRNAME
@FILENAME:
        ; 16 chars
        JSR     DOSFISCOPYPADFILENAME.W
        ACC16
        LDA     #$1900
        LDX     #NAMEBUF
        DOSCALL
        LDA     #$1900
        LDX     #DOSMSGDIRSPACE-4
        DOSCALL
@FILESIZE:
        ACC16
        LDA     #$1900
        LDX     #DOSMSGDIRSPACE-2
        DOSCALL
        LDA     FISBUF+$1A.W
        STA     WIDENUM1.W
        LDA     FISBUF+$1C.W
        STA     WIDENUM2.W
        JSR     UNPACKWIDEBCD.W
        ; 10 digits
        LDA     #$1900
        LDX     #CMDWIDEBCDBUFFER
        DOSCALL
        LDA     #$1900
        LDX     #DOSMSGDIRSPACE-2
        DOSCALL
@DATETIME:
        JSR     DOSFISUNPACKDATE.W
        JSR     UNPACK_DATE.W
        ACC16
        LDA     #$1900
        LDX     #CMDDATEMSGFMT
        DOSCALL
        LDA     #$1900
        LDX     #DOSMSGDIRSPACE-2
        DOSCALL
        JSR     DOSFISUNPACKTIME.W
        JSR     UNPACK_TIME.W
        ACC16
        LDA     #$1900
        LDX     #CMDTIMEMSGFMT
        DOSCALL
@END:
        ACC16
        LDA     #$020D
        DOSCALL
        RTS

@DIRNAME:
        ACC16
        LDA     #$0200|'['
        DOSCALL
        JSR     DOSFISCOPYCOMPACTFILENAME.W
        PHX
        LDA     #$1900
        LDX     #NAMEBUF.W
        DOSCALL
        LDA     #$0200|']'
        DOSCALL
        LDA     #DOSMSGDIRSPACE-17
        CLC
        ADC     1,S
        PLX
        TAX
        LDA     #$1900
        DOSCALL
        LDA     #$1900
        LDX     #DOSDIRMSGSUBDIR
        DOSCALL
        BRA     @DATETIME

COMMAND_DIR_PRINT_FIS_WIDE:
        BIT     FISBUF.W
        BVS     @DIRNAME
@FILENAME:
        ; 16 chars
        JSR     DOSFISCOPYPADFILENAME.W
        ACC16
        LDA     #$1900
        LDX     #NAMEBUF
        DOSCALL
        LDA     #$1900
        LDX     #DOSMSGDIRSPACE-2
        DOSCALL
        BRA     @WIDEEND
@DIRNAME:
        ACC16
        LDA     #$0200|'['
        DOSCALL
        JSR     DOSFISCOPYCOMPACTFILENAME.W
        PHX
        LDA     #$1900
        LDX     #NAMEBUF.W
        DOSCALL
        LDA     #$0200|']'
        DOSCALL
        LDA     #DOSMSGDIRSPACE-16
        CLC
        ADC     1,S
        PLX
        TAX
        LDA     #$1900
        DOSCALL
@WIDEEND:
        INC     DIRTMP+4.W
        LDA     DIRTMP+4.W
        CMP     #4
        BCC     +
        STZ     DIRTMP+4.W
        LDA     #$020D
        DOSCALL
+       RTS

DOSFISCOPYPADFILENAME:
        ACC8
        LDY     #0
        LDX     #0
-       LDA     FISBUF+2.W,Y
        CMP     #'.'
        BEQ     @DOT
@ST     STA     NAMEBUF.W,X
        INX
        INY
        CPY     #$0E
        BCC     -

        LDA     #' '
        STA     NAMEBUF.W,X
        INX
        LDA     #0
        STA     NAMEBUF.W,X
        ACC16
        RTS
.ACCu 8
@DOT:   LDA     #' '
        STA     NAMEBUF.W,X
        INX
        LDA     #'.'
        BRA     @ST

DOSFISCOPYCOMPACTFILENAME:
        ACC8
        LDY     #0
        LDX     #0
-       LDA     FISBUF+2.W,Y
        CMP     #' '
        BEQ     @SY
        CPY     #0
        BEQ     @ST
        CMP     #'.'
        BEQ     @DOT
@ST     STA     NAMEBUF.W,X
        INX
@SY     INY
        CPY     #$0E
        BCC     -

        LDA     #0
        STA     NAMEBUF.W,X
        ACC16
        RTS
.ACCu 8
@DOT:   CPY     #2
        BCS     +
        LDA     FISBUF+2.W
        CMP     #'.'
        BEQ     @ST
+       LDA     FISBUF+3.W,Y
        CMP     #' '
        BEQ     @SY
        LDA     #'.'
        BRA     @ST

DOSFISUNPACKDATE:
        ACC16

        LDA     FISBUF+$15.W
        XBA
        LSR     A
        LSR     A
        TAY
        
        LDA     FISBUF+$16.W
        XBA
        ASL     A
        ASL     A
        XBA
        AND     #$0F
        TAX
        
        LDA     FISBUF+$16.W
        XBA
        LSR     A
        AND     #$1F
        
        ACC8
        RTS

DOSFISUNPACKTIME:
        ACC16

        LDA     FISBUF+$19.W
        AND     #$7F
        TAY
        
        LDA     FISBUF+$18.W
        XBA
        ASL     A
        XBA
        AND     #$1F
        TAX
        
        LDA     FISBUF+$17.W
        XBA
        LSR     A
        LSR     A
        LSR     A
        LSR     A
        AND     #$1F
        
        ACC8
        RTS

COMMAND_DIR_FOOTER:
        ACC16

        LDA     DIRFLAGS.W
        AND     #1
        BEQ     +
        LDA     DIRTMP+4.W
        BEQ     +
        LDA     #$020D
        DOSCALL
+
        LDA     #$1900
        LDX     #COMMANDDIRFOOTER1
        DOSCALL

        ; total files
        LDA     DIRTOTALFILES.W
        STA     WIDENUM1.W
        STZ     WIDENUM2.W
        JSR     UNPACKWIDEBCD.W
        ; 10 digits
        LDA     #$1900
        LDX     #CMDWIDEBCDBUFFER
        DOSCALL

        LDA     #$1900
        LDX     #COMMANDDIRFOOTER2
        DOSCALL

        ; free space
        LDA     DIRDRIVENUM.W
        AND     #$001F
        ORA     #$3500
        DOSCALL
        STA     WIDENUM1.W
        STZ     WIDENUM2.W

-       ASL     WIDENUM1.W
        ROL     WIDENUM2.W
        DEX
        BNE     -

        JSR     UNPACKWIDEBCD.W
        ; 10 digits
        LDA     #$1900
        LDX     #CMDWIDEBCDBUFFER
        DOSCALL

        LDA     #$1900
        LDX     #COMMANDDIRFOOTER3
        DOSCALL

        RTS

COMMANDNUMTMPBCD8TOBIN:
        PHP
        ACC8
        LDA     NUMTMP.W,Y
        JSR     BCD8TOBIN.W
        STA     NUMTMP.W,Y
        PLP
        RTS

COMMANDNUMTMPBCD16TOBIN:
        PHP
        ACC16
        LDA     NUMTMP.W,Y
        JSR     BCD16TOBIN.W
        STA     NUMTMP.W,Y
        PLP
        RTS

.ACCU 8
COMMANDPARSEBCDNUM8P:
        LDA     CONBUF.W,X
        CMP     #'0'
        BCC     COMMANDPARSEBCDNUM8@ERR
        CMP     #'9'+1
        BCS     COMMANDPARSEBCDNUM8@ERR
        INX
        LDA     CONBUF.W,X
        CMP     #'0'
        BCC     @PART
        CMP     #'9'+1
        BCS     @PART
        DEX
        BRA     COMMANDPARSEBCDNUM8

@PART:
        DEX
        LDA     CONBUF.W,X
        INX
        AND     #$0F
        STA     NUMTMP.W,Y
        INY
        CLC
        RTS

.ACCU 8
COMMANDPARSEBCDNUM8:
        LDA     CONBUF.W,X
        CMP     #'0'
        BCC     @ERR
        CMP     #'9'+1
        BCS     @ERR
        AND     #$0F
        ASL     A
        ASL     A
        ASL     A
        ASL     A
        STA     NUMTMP.W,Y
        INX
        LDA     CONBUF.W,X
        CMP     #'0'
        BCC     @ERR
        CMP     #'9'+1
        BCS     @ERR
        AND     #$0F
        ORA     NUMTMP.W,Y
        STA     NUMTMP.W,Y
        INX
        INY
        CLC
        RTS
@ERR    SEC
        RTS

.ACCU 8
COMMANDPARSEBCDNUM16:
        JSR     COMMANDPARSEBCDNUM8.W
        BCS     @ERR
        JSR     COMMANDPARSEBCDNUM8.W
        BCS     @ERR
        CLC
        RTS
@ERR    SEC
        RTS

COMMAND_DATE_EXPECTSLASH:
        LDA     CONBUF.W,X
        CMP     #'/'
        BEQ     +
        CMP     #'-'
        BEQ     +
        SEC
        RTS
+       INX
        CLC
        RTS

COMMAND_TIME_EXPECTCOLON:
        LDA     CONBUF.W,X
        CMP     #':'
        BEQ     +
        CMP     #'.'
        BEQ     +
        SEC
        RTS
+       INX
        CLC
        RTS


UNPACK_DATE:
        ACC8
        PHY
        PHX
        JSR     BIN8TOBCD
        STA     NUMTMP.W

        PLX
        TXA
        JSR     BIN8TOBCD
        STA     NUMTMP+1.W

        PLY
        ACC16
        TYA
        CLC
        ADC     #1980
        JSR     BIN16TOBCD
        STA     NUMTMP+2.W

        ACC8
        LDA     NUMTMP+1.W
        LDX     #CMDDATEMSGFMT
        JSR     UNPACK_BCD8
        
        LDA     NUMTMP.W
        LDX     #CMDDATEMSGFMT.W+3
        JSR     UNPACK_BCD8

        ACC16
        LDA     NUMTMP+2.W
        LDX     #CMDDATEMSGFMT.W+6
        JSR     UNPACK_BCD16
        RTS

COMMAND_DATE_PARSE:
        ACC8
        LDY     #0
        JSR     COMMANDPARSEBCDNUM8P
        BCS     @ERR
        JSR     COMMAND_DATE_EXPECTSLASH
        BCS     @ERR
        JSR     COMMANDPARSEBCDNUM8P
        BCS     @ERR
        JSR     COMMAND_DATE_EXPECTSLASH
        BCS     @ERR
        PHX
        PHY
        JSR     COMMANDPARSEBCDNUM16
        BCS     @YEARFAIL
        PLY
        PLX
@ERR    ACC16
        RTS
.ACCU 8
@YEARFAIL:
        PLY
        PLX
        JSR     COMMANDPARSEBCDNUM8
        BCS     @ERR
        LDA     NUMTMP-1.W,Y
        STA     NUMTMP.W,Y
        CMP     #$80
        LDA     #$20
        BCC     +
        LDA     #$19
+       STA     NUMTMP-1.W,Y
        CLC
        RTS

UNPACK_TIME:
        ACC8
        PHY
        PHX
        JSR     BIN8TOBCD
        STA     NUMTMP.W

        PLX
        TXA
        JSR     BIN8TOBCD
        STA     NUMTMP+1.W

        PLY
        TYA
        JSR     BIN8TOBCD
        STA     NUMTMP+2.W

        LDA     NUMTMP.W
        CMP     #$12
        LDA     #'A'
        BCC     ++
        LDA     #'P'
        PHA
        SED
        LDA     NUMTMP.W
        CMP     #$13
        BCC     +
        SEC
        SBC     #$12
        STA     NUMTMP.W
+       CLD
        PLA
++      STA     CMDTIMEMSGFMT.W+9

        LDA     NUMTMP.W
        BNE     +
        LDA     #$12
+       LDX     #CMDTIMEMSGFMT
        JSR     UNPACK_BCD8
        
        LDA     NUMTMP+1.W
        LDX     #CMDTIMEMSGFMT.W+3
        JSR     UNPACK_BCD8
        
        LDA     NUMTMP+2.W
        LDX     #CMDTIMEMSGFMT.W+6
        JSR     UNPACK_BCD8
        RTS

COMMAND_TIME_PARSE:
        ACC8
        
        LDY     #0
        JSR     COMMANDPARSEBCDNUM8P
        BCS     @ERR
        JSR     COMMAND_TIME_EXPECTCOLON
        BCS     @ERR
        JSR     COMMANDPARSEBCDNUM8
        BCS     @ERR
        JSR     COMMAND_TIME_EXPECTCOLON
        BCS     @ERR
        JSR     COMMANDPARSEBCDNUM8
        BCS     @ERR
        JSR     COMMANDPARSESKIPSP

        LDA     CONBUF.W,X
        BEQ     @MIL
        CMP     #'A'
        BEQ     @AM
        CMP     #'a'
        BEQ     @AM
        CMP     #'P'
        BEQ     @PM
        CMP     #'p'
        BEQ     @PM
        BRA     @ERRC

        CLC
        ACC16
        RTS
@ERRC   SEC
@ERR    ACC16
        RTS

.ACCU 8
@MIL    LDA     NUMTMP.W
        CMP     #$24
        BEQ     @AM12
        BCS     @ERRC
        CLC
        ACC16
        RTS

.ACCU 8
@AM     INX
        LDA     CONBUF.W,X
        CMP     #'M'
        BEQ     +
        CMP     #'m'
        BEQ     +
        BRA     @ERRC
+       INX
        LDA     CONBUF.W,X
        BNE     @ERRC

        LDA     NUMTMP.W
        CMP     #$12
        BEQ     @AM12
        BCS     @ERRC
        BRA     +
@AM12   LDA     #0
+       STA     NUMTMP.W
        CLC
        ACC16
        RTS

.ACCU 8
@PM     INX
        LDA     CONBUF.W,X
        CMP     #'M'
        BEQ     +
        CMP     #'m'
        BEQ     +
        BRA     @ERRC
+       INX
        LDA     CONBUF.W,X
        BNE     @ERRC

        LDA     NUMTMP.W
        CMP     #$12
        BEQ     @PM12
        BCS     @ERRC
        BRA     +
@PM12   LDA     #0
+       SED
        CLC
        ADC     #$12
        CLD
        STA     NUMTMP.W
        CLC
        ACC16
        RTS

.ACCU 16
COMMAND_TYPE:
        ACC8
        JSR     CMDCHECKCOMMAND_ERROR_MANY

        LDA     CONBUF.W,X
        BNE     +
        JMP     COMMAND_ERROR_FEW
+       ACC16
        TXA
        CLC
        ADC     #CONBUF.W
        TAX
        LDA     #$0F01
        DOSCALL
        BCC     +
        JSR     COMMAND_ERROR
        RTS
+       
        PHD
        LDA     #FILEBUF.W
        TCD
@READLOOP
        LDY     #FILEBUFSIZE.W
        LDA     #$2100
        DOSCALL
        BCS     @ERRC

        CPY     #0
        BEQ     @FINISH
        STY     DIRTMP.W

        ACC8
        LDA     #0
        STA     FILEBUF.W,Y
        ACC16

        PHX
        LDX     #FILEBUF.W
        LDA     #$1900
        DOSCALL

        TXA
        SEC
        SBC     #FILEBUF.W
        PLX

        CMP     DIRTMP.W
        BCC     @FINISH

        LDA     DIRTMP.W
        CMP     #FILEBUFSIZE.W
        BEQ     @READLOOP
        
@FINISH
        PLD
        ; close file, ignore errors
        LDA     #$10FF
        DOSCALL
        RTS
@ERRC
        ; close file, ignore errors
        LDA     #$10FF
        DOSCALL
        LDA     #$020D
        DOSCALL
@ERR
        PLD
        JSR     COMMAND_ERROR
        RTS

COMMAND_ERASE:
        ACC8

        LDA     CONBUF.W,X
        BNE     +
        JMP     COMMAND_ERROR_FEW
+       ACC16
        TXA
        CLC
        ADC     #CONBUF.W
        TAX
        STX     DIRTMP.W
        STX     DIRTMP+2.W
        
-       LDA     $0000.W,X
        BEQ     +++
        CMP     #' '
        BEQ     ++
        CMP     #'?'
        BEQ     +
        CMP     #'*'
        BEQ     +
        INX
        BRA     -
+       JMP     COMMAND_ERASE_WILDCARDS
++      JMP     COMMAND_ERROR_MANY
+++
        LDX     DIRTMP.W
        LDY     #FISBUF.W
        LDA     #$1100
        DOSCALL
        BCS     +
        LDA     FISBUF.W
        AND     #$0040
        BEQ     +
        ACC8
        LDX     DIRTMP.W
-       INX
        LDA     $0000.W,X
        BNE     -
        LDA     #'\'
        STA     $0000.W,X        
        STZ     $0001.W,X
        INX
        STX     DIRTMP+2.W
+       
        ACC8
        LDX     DIRTMP.W
-       INX
        LDA     $0000.W,X
        BNE     -

        DEX
        LDA     $0000.W,X
        CMP     #'\'
        BEQ     COMMAND_ERASE_WILDCARDS

        ACC16
        LDX     DIRTMP.W
        LDA     #$1300
        DOSCALL
        BCC     @OK
@ERR    JSR     COMMAND_ERROR
@OK     RTS

COMMAND_ERASE_WILDCARDS:
        LDX     DIRTMP.W
        JSR     CMDPREBUILDWCPATH.W
        
        LDX     DIRTMP.W
        LDY     #FISBUF.W
        LDA     #$1100
        DOSCALL
        BCS     @ERR

        LDX     DIRTMP+2.W
        JSR     CMDBUILDWCPATHX.W
        
        LDY     WCPATH.W
        LDA     WCBUF.W,Y
        AND     #$FF
        BNE     +
        LDA     #$002A
        STA     WCBUF.W,Y
+
        LDX     #WCBUF.W
        LDA     #$1900
        DOSCALL

        LDX     #CMDDELWCMSGPROMPT.W
        LDA     #$1900
        DOSCALL

-       LDA     #$0700
        DOSCALL
        BMI     @SKIP
        JSR     CMDUPPERCASE16.W
        CMP     #$004E.W ;'N'
        BEQ     @SKIP
        CMP     #$0059.W ;'Y'
        BNE     -
+
        LDA     #$020D
        DOSCALL

---     ; only delete normal files (not dirs, hidden, system, readonly...)
        LDA     FISBUF.W
        AND     #$0FC0
        BNE     +

        JSR     CMDBUILDWCPATHFIS.W
        LDA     #$1300
        DOSCALL
        BCS     @ERR
+
        LDA     #$1200
        LDY     #FISBUF.W
        DOSCALL
        BCC     ---

        BRA     @OK
@ERR    JSR     COMMAND_ERROR
@OK     RTS
@SKIP   LDA     #$020D
        DOSCALL
        RTS

.INCLUDE "dos/consolef.asm"

COMMAND_RENAME:
        ACC8

        LDA     CONBUF.W,X
        BNE     +
--      JMP     COMMAND_ERROR_FEW
+       ACC16
        TXA
        CLC
        ADC     #CONBUF.W
        TAX
        STX     DIRTMP.W
        
        ACC8
        LDX     DIRTMP.W
-       INX
        LDA     $0000.W,X
        BEQ     --
        CMP     #' '
        BNE     -

        PHX
        STZ     $0000.W,X
        JSR     CMD_COPYPAR2
        PLX

        DEX
        LDA     $0000.W,X
        CMP     #'\'
        BEQ     +

        LDX     DIRTMP.W
-       LDA     $0000.W,X
        BEQ     ++
        CMP     #'?'
        BEQ     +
        CMP     #'*'
        BEQ     +
        INX
        BRA     -
+       JMP     COMMAND_RENAME_WILDCARDS
++
        ACC16
        LDX     DIRTMP.W
        LDY     #FISBUF.W
        LDA     #$1100
        DOSCALL
        BCS     @ERR

        JSR     COMMAND_RENAME_MKDESTFN.W
        LDX     DIRTMP.W
        LDA     #$1700
        DOSCALL
        BCC     @OK
@ERR    JSR     COMMAND_ERROR
@OK     RTS

COMMAND_RENAME_WILDCARDS:
        ACC16
        LDX     DIRTMP.W
        JSR     CMDPREBUILDWCPATH.W

        LDX     DIRTMP.W
        LDY     #FISBUF.W
        LDA     #$1100
        DOSCALL
        BCS     @ERR

---     ; only rename normal files (not dirs, hidden, system, readonly...)
        LDA     FISBUF.W
        AND     #$0FC0
        BNE     +

        JSR     CMDBUILDWCPATHFIS.W
        PHX
        JSR     COMMAND_RENAME_MKDESTFN.W
        PLX
        LDA     #$1700
        DOSCALL
        BCS     @ERR
+
        LDA     #$1200
        LDY     #FISBUF.W
        DOSCALL
        BCC     ---

        BRA     @OK
@ERR    JSR     COMMAND_ERROR
@OK     RTS

COMMAND_MKDIR:
        ACC8
        JSR     CMDCHECKCOMMAND_ERROR_MANY

        LDA     CONBUF.W,X
        BNE     +
        JMP     COMMAND_ERROR_FEW
+       ACC16
        TXA
        CLC
        ADC     #CONBUF.W
        TAX
        LDY     #$0000
        LDA     #$3600
        DOSCALL
        BCC     @OK
@ERR    JSR     COMMAND_ERROR
@OK     RTS

COMMAND_RMDIR:
        ACC8
        JSR     CMDCHECKCOMMAND_ERROR_MANY

        LDA     CONBUF.W,X
        BNE     +
        JMP     COMMAND_ERROR_FEW
+       ACC16
        TXA
        CLC
        ADC     #CONBUF.W
        TAX
        LDA     #$3300
        DOSCALL
        BCC     @OK
@ERR    CMP     #DOS_ERR_BAD_PARAMETER
        BEQ     @NORM
        JSR     COMMAND_ERROR
@OK     RTS
@NORM   LDA     #$1900
        LDX     #CMDRMDIRFAIL
        DOSCALL
        RTS

COMMAND_COPY:
        STZ     COPYTMP1.W
        STZ     COPYTMP2.W
        ACC8

        LDA     CONBUF.W,X
        BNE     +
--      JMP     COMMAND_ERROR_FEW
+       ACC16
        TXA
        CLC
        ADC     #CONBUF.W
        TAX
        STX     DIRTMP.W
        
        ACC8
        LDX     DIRTMP.W
-       INX
        LDA     $0000.W,X
        BEQ     --
        CMP     #' '
        BNE     -

        PHX
        STZ     $0000.W,X
        JSR     CMD_COPYPAR2

        ACC16
        LDX     XPATHBUF.W
        LDY     #FISBUF.W
        LDA     #$1100
        DOSCALL
        BCS     +
        LDA     FISBUF.W
        AND     #$0040
        BEQ     +
        ACC8
        LDX     #$FFFF
-       INX
        LDA     XPATHBUF.W,X
        BNE     -
        LDA     #'\'
        STA     XPATHBUF.W,X
        STZ     XPATHBUF+1.W,X
        ACC16
+
        LDX     #XPATHBUF.W
        JSR     CMDPREBUILDWC2PATH.W
        PLX

        ACC16
        LDX     DIRTMP.W
        LDY     #FISBUF.W
        LDA     #$1100
        DOSCALL
        BCS     +
        LDA     FISBUF.W
        AND     #$0040
        BEQ     +
        ACC8
        LDX     DIRTMP.W
-       INX
        LDA     $0000.W,X
        BNE     -
        LDA     #'\'
        STA     $0000.W,X        
        STZ     $0001.W,X
        INX
        STX     DIRTMP+2.W
+       
        ACC8
        LDX     DIRTMP.W
-       INX
        LDA     $0000.W,X
        BNE     -

        DEX
        LDA     $0000.W,X
        CMP     #'\'
        BEQ     +

        LDX     DIRTMP.W
-       LDA     $0000.W,X
        BEQ     ++
        CMP     #'?'
        BEQ     +
        CMP     #'*'
        BEQ     +
        INX
        BRA     -
+       JMP     COMMAND_COPY_WILDCARDS
++
        ACC16
        LDX     DIRTMP.W
        LDY     #FISBUF.W
        LDA     #$1100
        DOSCALL
        BCS     @ERR

        JSR     COMMAND_MOVE_CPDESTFN.W
        JSR     COMMAND_COPY_MERGENAMEBUF.W
        LDX     DIRTMP.W
        JSR     COMMAND_DO_COPYFILE.W
        BCC     @OK
@ERR    JSR     COMMAND_ERROR
@OK     JMP     COMMAND_COPY_END

COMMAND_COPY_WILDCARDS:
        ACC16
        INC     COPYTMP2.W
        LDX     DIRTMP.W
        JSR     CMDPREBUILDWCPATH.W

        LDX     DIRTMP.W
        LDY     #FISBUF.W
        LDA     #$1100
        BCS     @ERR

---     ; only COPY normal, readonly or system files
        LDA     FISBUF.W
        AND     #$0EC0
        BNE     @SKIP
        JSR     CMDBUILDWCPATHFIS.W
        PHX
        JSR     COMMAND_MOVE_CPDESTFN.W
        JSR     COMMAND_COPY_MERGENAMEBUF.W
        PLX
        JSR     COMMAND_DO_COPYFILE.W
        BCS     @ERR
@SKIP   LDA     #$1200
        LDX     DIRTMP.W
        LDY     #FISBUF.W
        DOSCALL
        BCC     ---

        BRA     @OK
@ERR    JSR     COMMAND_ERROR
@OK     

COMMAND_COPY_END:
        ACC16
        ; total files copied
        LDA     COPYTMP1.W
        STA     WIDENUM1.W
        STZ     WIDENUM2.W
        JSR     UNPACKWIDEBCD.W
        ; 10 digits
        LDA     #$1900
        LDX     #CMDWIDEBCDBUFFER
        DOSCALL

        LDA     #$1900
        LDX     #COMMANDCOPYOKMSG.W
        DOSCALL
        RTS

COMMAND_MOVE:
        STZ     COPYTMP1.W
        STZ     COPYTMP2.W
        ACC8

        LDA     CONBUF.W,X
        BNE     +
--      JMP     COMMAND_ERROR_FEW
+       ACC16
        TXA
        CLC
        ADC     #CONBUF.W
        TAX
        STX     DIRTMP.W
        
        ACC8
        LDX     DIRTMP.W
-       INX
        LDA     $0000.W,X
        BEQ     --
        CMP     #' '
        BNE     -

        PHX
        STZ     $0000.W,X
        JSR     CMD_COPYPAR2

        ACC16
        LDX     XPATHBUF.W
        LDY     #FISBUF.W
        LDA     #$1100
        DOSCALL
        BCS     +
        LDA     FISBUF.W
        AND     #$0040
        BEQ     +
        ACC8
        LDX     #$FFFF
-       INX
        LDA     XPATHBUF.W,X
        BNE     -
        LDA     #'\'
        STA     XPATHBUF.W,X
        STZ     XPATHBUF+1.W,X
        ACC16
+

        LDX     #XPATHBUF.W
        JSR     CMDPREBUILDWC2PATH.W
        PLX

        ACC16
        LDX     DIRTMP.W
        LDY     #FISBUF.W
        LDA     #$1100
        DOSCALL
        BCS     +
        LDA     FISBUF.W
        AND     #$0040
        BEQ     +
        ACC8
        LDX     DIRTMP.W
-       INX
        LDA     $0000.W,X
        BNE     -
        LDA     #'\'
        STA     $0000.W,X        
        STZ     $0001.W,X
        INX
        STX     DIRTMP+2.W
+       
        ACC8
        LDX     DIRTMP.W
-       INX
        LDA     $0000.W,X
        BNE     -

        DEX
        LDA     $0000.W,X
        CMP     #'\'
        BEQ     +

        LDX     DIRTMP.W
-       LDA     $0000.W,X
        BEQ     ++
        CMP     #'?'
        BEQ     +
        CMP     #'*'
        BEQ     +
        INX
        BRA     -
+       JMP     COMMAND_MOVE_WILDCARDS
++
        ACC16
        LDX     DIRTMP.W
        LDY     #FISBUF.W
        LDA     #$1100
        DOSCALL
        BCS     @ERR

        JSR     COMMAND_RENAME_MKDESTFN.W
        JSR     COMMAND_COPY_MERGENAMEBUF.W
        LDX     DIRTMP.W
        JSR     COMMAND_DO_MOVEFILE.W
        BCC     @OK
@ERR    JSR     COMMAND_ERROR
@OK     JMP     COMMAND_MOVE_END

COMMAND_MOVE_WILDCARDS:
        ACC16
        INC     COPYTMP2.W
        LDX     DIRTMP.W
        JSR     CMDPREBUILDWCPATH.W

        LDX     DIRTMP.W
        LDY     #FISBUF.W
        LDA     #$1100
        BCS     @ERR

---     ; only COPY normal, readonly or system files
        LDA     FISBUF.W
        AND     #$0EC0
        BNE     @SKIP
        JSR     CMDBUILDWCPATHFIS.W
        PHX
        JSR     COMMAND_RENAME_MKDESTFN.W
        JSR     COMMAND_COPY_MERGENAMEBUF.W
        PLX
        JSR     COMMAND_DO_MOVEFILE.W
        BCS     @ERR
@SKIP   LDA     #$1200
        LDX     DIRTMP.W
        LDY     #FISBUF.W
        DOSCALL
        BCC     ---

        BRA     @OK
@ERR    JSR     COMMAND_ERROR
@OK     

COMMAND_MOVE_END:
        ACC16
        ; total files copied
        LDA     COPYTMP1.W
        STA     WIDENUM1.W
        STZ     WIDENUM2.W
        JSR     UNPACKWIDEBCD.W
        ; 10 digits
        LDA     #$1900
        LDX     #CMDWIDEBCDBUFFER
        DOSCALL

        LDA     #$1900
        LDX     #COMMANDMOVEOKMSG.W
        DOSCALL
        RTS

COMMAND_VOL_P8:
        PHA
        LSR     A
        LSR     A
        LSR     A
        LSR     A
        AND     #$0F
        TAX
        LDA     CMDHEXDIGITS.W,X
        AND     #$FF
        ORA     #$0200
        DOSCALL
        PLA
        AND     #$0F
        TAX
        LDA     CMDHEXDIGITS.W,X
        AND     #$FF
        ORA     #$0200
        DOSCALL
        RTS

COMMAND_VOL_PRINTSN:
        LDA     FSMBBUF+$0A.W
        JSR     COMMAND_VOL_P8
        LDA     #$022F
        DOSCALL
        LDA     FSMBBUF+$0B.W
        JSR     COMMAND_VOL_P8
        RTS

COMMAND_VOL:
        LDA     #$3E00
        DOSCALL
        ACC8
        ORA     #$40
        STA     COMMANDDIRHEADER1_FMT.W
        ACC16
        AND     #$1F
        JSR     CMDLOADFSMB.W

        LDA     #$1900
        LDX     #COMMANDDIRHEADER1
        DOSCALL

        ; volume label
        LDX     #14
-       LDA     FSMBBUF+$20.W,X
        STA     NAMEBUF.W,X
        DEX
        DEX
        BPL     -
        STZ     NAMEBUF+$10.W

        LDA     #$1900
        LDX     #NAMEBUF.W
        DOSCALL

        LDA     #$1900
        LDX     #COMMANDVOLSN
        DOSCALL

        JSR     COMMAND_VOL_PRINTSN

        LDA     #$020D
        DOSCALL
        RTS

