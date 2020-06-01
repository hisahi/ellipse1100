; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS command interpreter (CONSOLE.COM)
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

DATETIMEQUERY:
        ; first boot?
        LDA     $801234.L
        CMP     #$1234
        BNE     @ALREADYSET
        
        LDA     #$0000
        STA     $801234.L

        ; ask user for date & time
        JSR     COMMAND_DATE.W
        JSR     COMMAND_TIME.W

@ALREADYSET:

BEGINNINGMSG:
        LDX     #CONSOLEMESSAGE
        LDA     #$1900
        DOSCALL

CMDLOOP:
        LDA     ECHOON.W
        AND     #$FF
        BEQ     +
        JSR     CMDPROMPT
+
        LDX     #CONBUF
        LDY     #256
        LDA     #$0A00
        DOSCALL

        ACC8
        ; replace last CR with nul
        TYX
        STZ     CONBUF.W,X
@CMDDBG:
        LDA     CONBUF.W
        BEQ     @NOCMD

        CMP     #'A'
        BCC     +
        CMP     #'Z'+1
        BCC     @CMDALPHA
+       CMP     #'a'
        BCC     +
        CMP     #'z'+1
        BCC     @CMDALPHA
+       
        ; special characters?
        JSR     COMMAND_UNKNOWN
        
@NOCMD  ACC16
        JMP     CMDLOOP

.ACCU 8
@CMDALPHA
        AND     #$DF
        SEC
        SBC     #'A'
        ASL     A
        ACC16
        AND     #$FF
        TAX
        LDA     COMMANDTABLELETTERS.W,X
        TAX
        LDY     #1
        JSR     CMDFINDRUN.W
        BCC     @CMDOK
        JSR     CMDVALIDFN.W
        BCS     +
        JSR     CMDSEEKRUN.W
        BCC     @CMDOK
+       JSR     COMMAND_UNKNOWN.W
@CMDOK:
        AXY16
        LDA     ECHOON.W
        BEQ     +
        LDA     #$020D
        DOSCALL
+       JMP     CMDLOOP.W

.ACCU 16
CMDPROMPT:
; print path
        LDA     #$3E00
        DOSCALL
        CLC
        ADC     #$0240
        DOSCALL
        
        LDA     #$0200 | ':'
        DOSCALL
        LDA     #$0200 | '\'
        DOSCALL

        LDA     #$3100
        LDX     #PATHBUF
        DOSCALL
        
        LDA     #$1900
        LDX     #PATHBUF
        DOSCALL

        LDA     #$0200 | '>'
        DOSCALL

        RTS

; copy command buffer "file name" to fn buffer
; carry clear if OK, carry set if invalid
CMDVALIDFN:
        ACC16
        LDA     #0
        ACC8
        LDX     #0
        LDY     #0
        STZ     EXECTMP+2.W             ; got ext?
@LOOP   CPY     #15
        BCS     @INVALID
        LDA     CONBUF.W,X
        BEQ     @ENDFN
        CMP     #' '
        BEQ     @ENDFN
        CMP     #'/'
        BEQ     @ENDFN
        CMP     #'\'
        BEQ     @ENDFN
        CMP     #'.'
        BEQ     @EXT
        PHX
        TAX
        LDA     COMMANDFNVALIDCHARS.W,X
        PLX
        CMP     #0
        BNE     @VALIDCH
@INVALID
        SEC
        ACC16
        RTS
.ACCU 8
@VALIDCH
        LDA     CONBUF.W,X
        JSR     CMDUPPERCASE.W
        STA     NAMEBUF.W,Y
        INX
        INY
        BRA     @LOOP
@ENDFN  LDA     EXECTMP+2.W
        BEQ     @ENDEXT
@ENDFNZ
        LDA     #0
        STA     NAMEBUF.W,Y
        STX     EXECTMP.W
        LDA     CONBUF.W,X
        CMP     #' '
        BNE     +
        INX
+       ACC16
        CLC
        RTS
.ACCU 8
@ENDEXT
        CPY     #11
        BCS     @INVALID
        LDA     #'.'
        STA     NAMEBUF.W,Y
        INY
        LDA     #'*'
        STA     NAMEBUF.W,Y
        INY
        BRA     @ENDFNZ
.ACCU 8
@EXT    LDA     EXECTMP+2.W
        BNE     @ENDFNZ
        INC     EXECTMP+2.W
        LDA     CONBUF.W,X
        STA     NAMEBUF.W,Y
        INX
        INY
        BRA     @LOOP

.ACCU 8
BIN8TOBCD:
        STZ     BCDTMP2.W
BIN8TOBCDOFF:
        PHP
        AXY16
        PHX
        AXY8
        CLC
        ADC     BCDTMP2.W
        PHA
        AND     #$0F
        CMP     #$0A
        BCC     +
        CLC
        ADC     #6
+       STA     BCDTMP.W
        PLA
        LSR     A
        LSR     A
        LSR     A
        LSR     A
        AND     #$0F
        TAX
        LDA     BCDTABLEH.W,X
        STA     BCDTMP2.W
        LDA     BCDTABLEL.W,X
        CLC
        SED
        ADC     BCDTMP.W
        STA     BCDTMP.W
        CLD
        LDA     BCDTMP2.W
        ADC     #0
        STA     BCDTMP2.W
        AXY16
        PLX
        PLP
        LDA     BCDTMP.W
        RTS

.ACCU 16
BIN16TOBCD:
        STZ     BCDTMP2.W
BIN16TOBCDOFF:
        STZ     BCDTMP.W
        PHP
        AXY16
        PHX
        PHA
        ACC8
        JSR     BIN8TOBCDOFF
        LDA     BCDTMP2.W
        STA     BCDTMP+1.W
        ACC16
        SED

        LDA     1,S
        AND     #$0F00
        XBA
        ASL     A
        TAX
        LDA     BCDTABLE100.W,X
        CLC
        ADC     BCDTMP.W
        STA     BCDTMP.w

        LDA     1,S
        AND     #$F000
        XBA
        LSR     A
        LSR     A
        LSR     A
        TAX
        LDA     BCDTABLE1000H.W,X
        STA     BCDTMP2.W

        LDA     BCDTABLE1000.W,X
        CLC
        ADC     BCDTMP.W
        XBA
        STA     BCDTMP.W

        LDA     BCDTMP2.W
        ADC     #0
        STA     BCDTMP2.W

        PLA
        PLX
        LDA     BCDTMP.W
        PLP
        RTS

.ACCU 8
BCD8TOBIN:
        STA     BCDTMP+1.W
        AND     #$F0
        LSR     A
        STA     BCDTMP.W
        LSR     A
        LSR     A
        CLC
        ADC     BCDTMP.W
        STA     BCDTMP.W
        LDA     BCDTMP+1.W
        AND     #$0F
        CLC
        ADC     BCDTMP.W
        RTS

.ACCU 16
BCD16TOBIN:
        ACC8
        JSR     BCD8TOBIN.W     ; BCD high
        XBA
        JSR     BCD8TOBIN.W     ; BCD low
        STA     BCDTMP.W        ; store BCD low
        STZ     BCDTMP+1.W
        ACC16
        XBA
        AND     #$FF            ; BCD high zero-extended to 16b
        ; A = A * 100
        ASL     A
        ASL     A
        STA     BCDTMP2.W
        ASL     A
        ASL     A
        ASL     A
        STA     BCDTMP3.W
        ASL     A
        CLC
        ADC     BCDTMP2.W
        CLC
        ADC     BCDTMP3.W
        CLC
        ADC     BCDTMP.W
        RTS

.ACCU 8
UNPACK_BCD8:
        PHA
        AND     #$0F
        ORA     #$30
        STA     $0001.W,X

        LDA     1,S
        LSR     A
        LSR     A
        LSR     A
        LSR     A
        AND     #$0F
        ORA     #$30
        STA     $0000.W,X

        PLA
        RTS

.ACCU 16
UNPACK_BCD16:
        ACC8
        JSR     UNPACK_BCD8
        XBA
        INX
        INX
        JSR     UNPACK_BCD8
        DEX
        DEX
        XBA
        ACC16
        RTS

COMMAND_UNKNOWN:
        ACC16
        LDA     #$1900
        LDX     #CMDUNKNOWN
        DOSCALL
        RTS

; print standard error message
; C=1 if disk error
COMMAND_ERROR:
        TAX
        LDA     COMMANDERRORMSGTABLEDISK.W,X
        AND     #$FF
        STA     ERRTMP.W
        BEQ     +

        PHX
        LDA     #$3E00
        DOSCALL
        CLC
        ADC     #$0040
        ACC8
        STA     COMMANDMSGERROR_DRIVE_FMT.W
        ACC16

        LDA     #$1900
        LDX     #COMMANDMSGERROR_DRIVE.W
        DOSCALL
        PLX
+       TXA
        ASL     A
        TAX
        LDA     COMMANDERRORMSGTABLE.W,X
        TAX
        LDA     #$1900
        DOSCALL
        LSR     ERRTMP.W
        RTS

.ACCU 8
CMDUPPERCASE:
        CMP     #'a'
        BCC     +
        CMP     #'z'+1
        BCS     +
        AND     #$DF
+       RTS

CMDFINDRUN:
        PHY
        ACC8
        LDA     $0000.W,X
        BEQ     @NOTFOUND

-       LDA     $0000.W,X
        BEQ     @ENDMATCH
        LDA     CONBUF.W,Y
        JSR     CMDUPPERCASE
        CMP     $0000.W,X
        BNE     @NOMATCH

        INX
        INY
        BRA     -

@ENDMATCH:
        LDA     CONBUF.W,Y
        BEQ     @YESMATCH
        CMP     #'0'
        BCC     @YESMATCH
@NOMATCH:
-       INX
        LDA     $0000.W,X
        BNE     -
        INX
        INX
        INX
        PLY
        BRA     CMDFINDRUN
@YESMATCH:
        INX
        ACC16
        LDA     $0000.W,X
        STA     @CMDJMP+1.W
        TYX
        ACC8
        LDA     CONBUF.W,X
        CMP     #' '
        BNE     +
        INX
+       ACC16
        PLY
@CMDJMP:
        JSR     $0000.W
        CLC
        RTS
@NOTFOUND:
        PLY
        SEC
        RTS

CMDSEEKRUN:
        ACC16
        LDA     #$1107
        LDX     #NAMEBUF.W
        LDY     #FISBUF.W
        DOSCALL
        BCS     @ERR
        BRA     @CHECKFILE

@NEXTFILE
        LDA     #$1200
        LDY     #FISBUF.W
        DOSCALL
        BCS     @ERR

@CHECKFILE
        LDA     FISBUF+$0C.W
        CMP     #$432E                  ; '.C'
        BNE     +
        CMP     #$4D4F                  ; 'OM'
        BNE     +
        JMP     CMDFISEXECCOM
+
@NOTEXEC
        BRA     @NEXTFILE

        RTS
@ERR    CMP     #DOS_ERR_FILE_NOT_FOUND
        BEQ     +
        CMP     #DOS_ERR_NO_MORE_FILES
        BEQ     +
        JSR     COMMAND_ERROR.W
+       SEC
        RTS

CMDFISCOPYFN:
        ACC8
        LDX     #0
        LDY     #0
@LOOP
        CPX     #$0D
        BCS     @EXIT
        BRA     @LOOP
        LDA     FISBUF+$02.W
        CMP     #' '
        BEQ     @PAD
        STA     NAMEBUF.W,Y
        INY
@PAD    INX
        BRA     @LOOP
@EXIT
        ACC16
        RTS

.ACCU 16
CMDFISEXECCOM:
        JSR     CMDFISCOPYFN.W

        LDA     EXECTMP.W
        CLC
        ADC     #CONBUF.W
        STA     EXECBUF.W
        
        STZ     EXECBUF+2.W

        LDA     #$3800
        LDX     #NAMEBUF.W
        LDY     #EXECBUF.W
        DOSCALL

        BCS     @ERR
        CLC
        RTS
@ERR    JSR     COMMAND_ERROR.W
        SEC
        RTS

.ACCU 16
COMMAND_EXIT:
        LDA     #$0000
        DOSCALL

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

        ACC8
        JSR     BIN8TOBCD
        STA     NUMTMP.W

        TXA
        JSR     BIN8TOBCD
        STA     NUMTMP+1.W

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

        LDX     #CMDDATEMSG
        LDA     #$1900
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

        ACC8
        JSR     BIN8TOBCD
        STA     NUMTMP.W

        TXA
        JSR     BIN8TOBCD
        STA     NUMTMP+1.W

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

        ACC16

        LDX     #CMDTIMEMSG
        LDA     #$1900
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

COMMANDPARSESKIPSP:
        DEX
-       INX
        LDA     CONBUF.W,X
        CMP     #' '
        BEQ     -
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

BCDTMP:
        .DW     0
BCDTMP2:
        .DW     0
BCDTMP3:
        .DW     0
NUMTMP:
        .DB     0, 0, 0, 0, 0, 0
EXECTMP:
        .DW     0
        .DB     0
ERRTMP:
        .DW     0
ECHOON:
        .DB     1

BCDTABLEL:
        .DB     $00, $16, $32, $48, $64, $80, $96, $12
        .DB     $28, $44, $60, $76, $92, $08, $24, $40
BCDTABLEH:
        .DB     0, 0, 0, 0, 0, 0, 0, 1
        .DB     1, 1, 1, 1, 1, 2, 2, 2
BCDTABLE100:
        .DW     $0000, $0256, $0512, $0768, $1024, $1280, $1536, $1792
        .DW     $2048, $2304, $2560, $2816, $3072, $3328, $3584, $3840
BCDTABLE1000:
        .DW     $0000, $4096, $8192, $2288, $6384, $0480, $4576, $8672
        .DW     $2768, $6864, $0960, $5056, $9152, $3248, $7344, $1440
BCDTABLE1000H:
        .DW     0, 0, 0, 1, 1, 2, 2, 2
        .DW     3, 3, 4, 4, 4, 5, 5, 6

CONSOLEMESSAGE:
        .DB     13, "Ellipse DOS Console v1.00", 13
        .DB     "(C) Ellipse Data Electronics, 1985-1986.", 13, 13, 0
CMDDATEMSG:
        .DB     "Current system date: "
CMDDATEMSGFMT:
        .DB     "$$/$$/$$$$", 13, 0
CMDDATEMSGNEW:
        .DB     "     Enter new date: ", 0
CMDDATEMSGINVALID:
        .DB     "Invalid date", 13, 0
CMDTIMEMSG:
        .DB     "Current system time: "
CMDTIMEMSGFMT:
        .DB     "$$:$$:$$ $M", 13, 0
CMDTIMEMSGNEW:
        .DB     "     Enter new time: ", 0
CMDTIMEMSGINVALID:
        .DB     "Invalid time", 13, 0
CMDUNKNOWN:
        .DB     "Command or file not found", 13, 0
CMDMSGECHO:
        .DB     "ECHO is ", 0
CMDMSGECHOTOFF:
        .DB     "OFF.", 0
CMDMSGECHOTON:
        .DB     "ON."

COMMANDMSGERROR_DRIVE:
        .DB     "Drive "
COMMANDMSGERROR_DRIVE_FMT:
        .DB     "$: ", 0
COMMANDMSGERROR_00:
        .DB     0
COMMANDMSGERROR_01:
        .DB     "Invalid function", 0
COMMANDMSGERROR_02:
        .DB     "Invalid handle", 0
COMMANDMSGERROR_03:
        .DB     "File or directory not found", 0
COMMANDMSGERROR_04:
        .DB     "Volume not found", 0
COMMANDMSGERROR_05:
        .DB     "Invalid path", 0
COMMANDMSGERROR_06:
        .DB     "Drive not ready", 0
COMMANDMSGERROR_07:
        .DB     "Too many files open", 0
COMMANDMSGERROR_08:
        .DB     "Access denied", 0
COMMANDMSGERROR_09:
        .DB     "Out of memory", 0
COMMANDMSGERROR_0A:
        .DB     "Drive is full", 0
COMMANDMSGERROR_0B:
        .DB     "File is already open", 0
COMMANDMSGERROR_0C:
        .DB     "Cannot run program", 0
COMMANDMSGERROR_0E:
        .DB     "Invalid function parameter", 0
COMMANDMSGERROR_11:
        .DB     "No such drive", 0
COMMANDMSGERROR_12:
        .DB     "General I/O failure", 0
COMMANDMSGERROR_13:
        .DB     "Read error", 0
COMMANDMSGERROR_14:
        .DB     "Write error", 0
COMMANDMSGERROR_15:
        .DB     "Executable cannot fit into memory", 0
COMMANDMSGERROR_16:
        .DB     "Seek error", 0

COMMANDERRORMSGTABLE:
        .DW     COMMANDMSGERROR_00
        .DW     COMMANDMSGERROR_01
        .DW     COMMANDMSGERROR_02
        .DW     COMMANDMSGERROR_03
        .DW     COMMANDMSGERROR_04
        .DW     COMMANDMSGERROR_05
        .DW     COMMANDMSGERROR_06
        .DW     COMMANDMSGERROR_07
        .DW     COMMANDMSGERROR_08
        .DW     COMMANDMSGERROR_09
        .DW     COMMANDMSGERROR_0A
        .DW     COMMANDMSGERROR_0B
        .DW     COMMANDMSGERROR_0C
        .DW     COMMANDMSGERROR_00
        .DW     COMMANDMSGERROR_0E
        .DW     COMMANDMSGERROR_03
        .DW     COMMANDMSGERROR_00
        .DW     COMMANDMSGERROR_11
        .DW     COMMANDMSGERROR_12
        .DW     COMMANDMSGERROR_13
        .DW     COMMANDMSGERROR_14
        .DW     COMMANDMSGERROR_15
        .DW     COMMANDMSGERROR_16

COMMANDERRORMSGTABLEDISK:
        .DB     0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0
        .DB     0,0,1,1,1,0,1

COMMANDTABLELETTERS:
        .DW     COMMANDTABLE_A
        .DW     COMMANDTABLE_B
        .DW     COMMANDTABLE_C
        .DW     COMMANDTABLE_D
        .DW     COMMANDTABLE_E
        .DW     COMMANDTABLE_F
        .DW     COMMANDTABLE_G
        .DW     COMMANDTABLE_H
        .DW     COMMANDTABLE_I
        .DW     COMMANDTABLE_J
        .DW     COMMANDTABLE_K
        .DW     COMMANDTABLE_L
        .DW     COMMANDTABLE_M
        .DW     COMMANDTABLE_N
        .DW     COMMANDTABLE_O
        .DW     COMMANDTABLE_P
        .DW     COMMANDTABLE_Q
        .DW     COMMANDTABLE_R
        .DW     COMMANDTABLE_S
        .DW     COMMANDTABLE_T
        .DW     COMMANDTABLE_U
        .DW     COMMANDTABLE_V
        .DW     COMMANDTABLE_W
        .DW     COMMANDTABLE_X
        .DW     COMMANDTABLE_Y
        .DW     COMMANDTABLE_Z

COMMANDFNVALIDCHARS:
        .DB     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .DB     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .DB     0,1,0,1,1,1,1,1,1,1,0,0,0,1,0,0
        .DB     1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,0
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

COMMANDTABLE_A:
COMMANDTABLE_B:
COMMANDTABLE_C:
        .DB     0
COMMANDTABLE_D:
        .DB     "ATE", 0
        .DW     COMMAND_DATE
        .DB     0
COMMANDTABLE_E:
        .DB     "CHO", 0
        .DW     COMMAND_ECHO
        .DB     "XIT", 0
        .DW     COMMAND_EXIT
        .DB     0
COMMANDTABLE_F:
COMMANDTABLE_G:
COMMANDTABLE_H:
COMMANDTABLE_I:
COMMANDTABLE_J:
COMMANDTABLE_K:
COMMANDTABLE_L:
COMMANDTABLE_M:
COMMANDTABLE_N:
COMMANDTABLE_O:
COMMANDTABLE_P:
COMMANDTABLE_Q:
COMMANDTABLE_R:
COMMANDTABLE_S:
        .DB     0
COMMANDTABLE_T:
        .DB     "IME", 0
        .DW     COMMAND_TIME
        .DB     0
COMMANDTABLE_U:
COMMANDTABLE_V:
COMMANDTABLE_W:
COMMANDTABLE_X:
COMMANDTABLE_Y:
COMMANDTABLE_Z:
        .DB     0

CONBUF:
.REPEAT 256
        .DB     0
.ENDR

PATHBUF:
.REPEAT 128
        .DB     0
.ENDR

NAMEBUF:
.REPEAT 16
        .DB     0
.ENDR

FISBUF:
.REPEAT 64
        .DB     0
.ENDR

EXECBUF:
.REPEAT 16
        .DB     0
.ENDR
