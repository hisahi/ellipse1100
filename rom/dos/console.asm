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

.DEFINE FILEBUF $F800
.DEFINE FILEBUFSIZE $0400
.DEFINE FILETMP $FC00
.DEFINE FISBUF $FC20
.DEFINE CONBUF $FD00
.DEFINE XPATHBUF $FE00
.DEFINE PATHBUF $FE80
.DEFINE NAMEBUF $FF00
.DEFINE EXECBUF $FF80
.DEFINE _sizeof_PATHBUF (NAMEBUF-PATHBUF)

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
        JSR     COMMAND_VER
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

        ; A: - Z:
        LDA     CONBUF+1.W
        CMP     #':'
        BNE     ++
        LDA     CONBUF+2.W
        BNE     ++
        LDA     CONBUF.W
        CMP     #'A'
        BCC     ++
        CMP     #'Z'+1
        BCC     @SWITCHDRIVE
+       CMP     #'a'
        BCC     ++
        CMP     #'z'+1
        BCC     @SWITCHDRIVE
++   
        LDA     CONBUF.W
        CMP     #'A'
        BCC     +
        CMP     #'Z'+1
        BCC     @CMDALPHA
+       CMP     #'a'
        BCC     +
        CMP     #'z'+1
        BCC     @CMDALPHA
+       
        LDA     CONBUF.W
        CMP     #'\'
        BEQ     @CMDBS

        JSR     COMMAND_UNKNOWN
        
@NOCMD  ACC16
        JMP     CMDLOOP

@SWITCHDRIVE
        JSR     CMDUPPERCASE.W
        JSR     CMDSWITCHDRIVE.W
        ACC16
        JMP     CMDLOOP

@CMDBS
        JSR     CMDVALIDPATHFN.W
        BCS     +
        JSR     CMDSEEKRUN.W
+       BRA     @CMDOK

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
        JSR     CMDVALIDPATHFN.W
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
        LDA     CONBUF.W,X
        CMP     #' '
        BNE     +
        INX
+       STX     EXECTMP.W
        ACC16
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

; same as above, but allows paths and pushes to PATHBUF
CMDVALIDPATHFN:
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
        CMP     #':'
        BEQ     @COLON
        CMP     #'\'
        BEQ     @BS
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
@COLON  CPX     #1
        BNE     @ENDFN
.ACCU 8
@VALIDCH
        LDA     CONBUF.W,X
        JSR     CMDUPPERCASE.W
        STA     PATHBUF.W,Y
        INX
        INY
        BRA     @LOOP
@ENDFN  LDA     EXECTMP+2.W
        BEQ     @ENDEXT
@ENDFNZ
        LDA     #0
        STA     PATHBUF.W,Y
        LDA     CONBUF.W,X
        CMP     #' '
        BNE     +
        INX
+       STX     EXECTMP.W
        ACC16
        CLC
        RTS
.ACCU 8
@BS     STZ     EXECTMP+2.W             ; got ext?
        BRA     @VALIDCH
.ACCU 8
@ENDEXT
        CPY     #11
        BCS     @INVALID
        LDA     #'.'
        STA     PATHBUF.W,Y
        INY
        LDA     #'*'
        STA     PATHBUF.W,Y
        INY
        BRA     @ENDFNZ
.ACCU 8
@EXT    LDA     EXECTMP+2.W
        BNE     @ENDFNZ
        INC     EXECTMP+2.W
        LDA     CONBUF.W,X
        STA     PATHBUF.W,Y
        INX
        INY
        JMP     @LOOP

.ACCu 8
CMDSWITCHDRIVE:
        SEC
        SBC     #'@'
        ACC16
        AND     #$1F
        ORA     #$0E00
        DOSCALL
        BCC     +
        JSR     COMMAND_ERROR
+       LDA     #$020D
        DOSCALL
        RTS

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

; input value in WIDENUM1,WIDENUM2. will be modified!
; output in CMDWIDEBCDBUFFER
UNPACKWIDEBCD:
        ACC16
        PHX
        PHY
        CLD

        LDA     #$3030
        STA     CMDWIDEBCDBUFFER.W
        STA     CMDWIDEBCDBUFFER+2.W
        STA     CMDWIDEBCDBUFFER+4.W
        STA     CMDWIDEBCDBUFFER+6.W
        STA     CMDWIDEBCDBUFFER+8.W

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
        INC     CMDWIDEBCDBUFFER.W,X
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
        STA     CMDWIDEBCDBUFFER.W,X
        ACC16
@RETURN:
        ; remove leading zeroes
        ACC8
        LDX     #0
-       CPX     #9
        BCS     +
        LDA     CMDWIDEBCDBUFFER.W,X
        CMP     #'0'
        BNE     +
        LDA     #' '
        STA     CMDWIDEBCDBUFFER.W,X
        INX
        BRA     -

+       PLY
        PLX
        ACC16
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
        ACC16
        TAX
        LDA     COMMANDERRORMSGTABLEDISK.W,X
        AND     #$FF
        STA     ERRTMP.W
        BEQ     +

        PHX
        LDA     $804020.L       ; DOSACTIVEDRIVE
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

        LDA     #$020D
        DOSCALL
        RTS

COMMAND_ERROR_FEW:
        ACC16
        LDA     #$1900
        LDX     #CMDPARFEWERR.W
        DOSCALL

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
        LDA     #$1100
        LDX     #PATHBUF.W
        LDY     #FISBUF.W
@DBG
        DOSCALL
        BCS     @ERR
        BRA     @CHECKFILE

@NEXTFILE
        LDA     #$1200
        LDY     #FISBUF.W
        DOSCALL
        BCS     @ERR

@CHECKFILE
        BIT     FISBUF-$01.W            ; directory?
        BVS     +
        LDA     FISBUF+$0C.W
        CMP     #$432E                  ; '.C'
        BNE     +
        LDA     FISBUF+$0E.W
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
        LDY     #NAMEBUF.W
CMDFISCOPYFN_INT:
        ACC8
        LDX     #0
@LOOP
        CPX     #$0E
        BCS     @EXIT
        LDA     FISBUF+$02.W,X
        CMP     #' '
        BEQ     @PAD
        STA     $0000.W,Y
        INY
@PAD    INX
        BRA     @LOOP
@EXIT
        LDA     #0
        STA     $0000.W,Y
        ACC16
        RTS

CMDFISCOPYPATHFN:
        LDY     #PATHBUF.W
        JSR     CMDMVYENDOFPATH
        BRA     CMDFISCOPYFN_INT

CMDMVYENDOFPATH:
        ACC8
        DEY
-       INY
        LDA     $0000.W,Y
        BNE     -
-       DEY
        LDA     $0000.W,Y
        CMP     #'\'
        BEQ     @BS
        CPY     #PATHBUF.W+1
        BCS     -
        LDA     $0001.W,Y
        CMP     #':'
        BNE     +
        INY
@BS     INY
+       RTS

.ACCU 16
CMDFISEXECCOM:
        JSR     CMDFISCOPYPATHFN.W

        LDA     EXECTMP.W
        CLC
        ADC     #CONBUF.W
        STA     EXECBUF.W
        
        STZ     EXECBUF+2.W

        LDA     #$3800
        LDX     #PATHBUF.W
        LDY     #EXECBUF.W
        DOSCALL

        BCS     @ERR
        CLC
        RTS
@ERR    JSR     COMMAND_ERROR.W
        SEC
        RTS

COMMAND_BUILD_XPATH:
        ACC8
        LDA     NAMEBUF.W  
        PHA
        LDA     #0
        STA     NAMEBUF.W
        ; does new path start with drive specified? copy it over, else
        ; use current drive
        LDA     $0000.W,X
        BEQ     @STDDRIVE
        JSR     CMDUPPERCASE.W
        CMP     #'A'
        BCC     @STDDRIVE
        CMP     #'Z'+1
        BCS     @STDDRIVE
        LDA     $0001.W,X
        CMP     #':'
        BNE     @STDDRIVE
        STA     XPATHBUF+1.W
        LDA     $0000.W,X
        STA     XPATHBUF.W
        INX
        INX
        BRA     @DRIVEOK
@STDDRIVE:
        ACC16
        LDA     #$3E00
        DOSCALL
        CLC
        ADC     #$40
        ACC8
        STA     XPATHBUF.W
        LDA     #':'
        STA     XPATHBUF+1.W
@DRIVEOK:
        LDY     #2
        LDA     $0000.W,X
        CMP     #'\'
        BEQ     @COPYPATH
        LDA     #'\'
        STA     XPATHBUF.W,Y
        INY
        PHX
        ACC16

        TYA
        CLC
        ADC     #XPATHBUF.W
        TAX
        LDA     #$3100
        DOSCALL
        PLX
        ACC8

-       LDA     XPATHBUF.W,Y
        BEQ     @COPYBS
        INY
        BRA     -
@COPYBS
        LDA     #'\'
        STA     XPATHBUF.W,Y
@COPYPATH
        LDA     $0000.W,X
        STA     XPATHBUF.W,Y
        BEQ     +
        INX
        INY
        BNE     @COPYPATH
+       PLA
        STA     NAMEBUF.W
        RTS

.INCLUDE "dos/consolec.asm"

.ACCU 8
COMMANDPARSESKIPSP:
        DEX
-       INX
        LDA     CONBUF.W,X
        CMP     #' '
        BEQ     -
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
DIRFLAGS:
        .DW     0
DIRTOTALFILES:
        .DW     0
DIRTMP:
        .DW     0, 0
DIRDRIVENUM:
        .DW     0
DIROLDDRIVE:
        .DW     0
WIDENUM1:
        .DW     0
WIDENUM2:
        .DW     0

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
POWERSOF10:
.MACRO PO10
        .DW     (10^\1)&$FFFF
        .DW     ((10^\1)>>16)&$FFFF
.ENDM
.REPEAT 10 INDEX N
        PO10    9-N
.ENDR

CONSOLEMESSAGE:
        .DB     13, "Ellipse DOS Console v1.00", 13
        .DB     "(C) Ellipse Data Electronics, 1985-1986.", 13, 13, 0
CMDPARFEWERR:
        .DB     "Not enough parameters", 13, 0
CMDPARMANYERR:
        .DB     "Too many parameters", 13, 0
CMDDATEMSG:
        .DB     "Current system date: "
CMDDATEMSGFMT:
        .DB     "$$/$$/$$$$", 0
CMDDATEMSGNEW:
        .DB     "     Enter new date: ", 0
CMDDATEMSGINVALID:
        .DB     "Invalid date", 13, 0
CMDTIMEMSG:
        .DB     "Current system time: "
CMDTIMEMSGFMT:
        .DB     "$$:$$:$$ $M", 0
CMDTIMEMSGNEW:
        .DB     "     Enter new time: ", 0
CMDTIMEMSGINVALID:
        .DB     "Invalid time", 13, 0
CMDUNKNOWN:
        .DB     "Command or file not found", 13, 0
CMDRMDIRFAIL:
        .DB     "Cannot create file", 13, 0
CMDMSGECHO:
        .DB     "ECHO is ", 0
CMDMSGECHOTOFF:
        .DB     "OFF.", 0
CMDMSGECHOTON:
        .DB     "ON.", 0
COMMANDPAUSEMSG:
        .DB     "Press any key to continue...", 0
COMMANDDIRHEADER1:
        .DB     13, " Volume of drive "
COMMANDDIRHEADER1_FMT:
        .DB     "$: is <", 0
COMMANDDIRHEADER2:
        .DB     ">", 13, " Directory of  ", 0
COMMANDDIRHEADER3:
        .DB     13, 13, 0
COMMANDDIRFOOTER1:
        .DB     13, "   ", 0
COMMANDDIRFOOTER2:
        .DB     " file(s)    ", 0
COMMANDDIRFOOTER3
        .DB     " byte(s) free", 13
COMMANDDIREMPTY:
        .DB     0
DOSDIRMSGSUBDIR:
        .DB     "<DIR>          ", 0
DOSMSGDIRSPACE_END:
        .DB     "                                "
DOSMSGDIRSPACE:
        .DB     0
CMDWIDEBCDBUFFER:
        .DB     "$$$$$$$$$$", 0

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
COMMANDMSGERROR_17:
        .DB     "Cannot create file", 0

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
        .DW     COMMANDMSGERROR_17

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
        .DB     0
COMMANDTABLE_B:
        .DB     0
COMMANDTABLE_C:
        .DB     "D", 0
        .DW     COMMAND_CHDIR
        .DB     "HDIR", 0
        .DW     COMMAND_CHDIR
        .DB     "LS", 0
        .DW     COMMAND_CLS
        .DB     0
COMMANDTABLE_D:
        .DB     "ATE", 0
        .DW     COMMAND_DATE
        .DB     "IR", 0
        .DW     COMMAND_DIR
        .DB     0
COMMANDTABLE_E:
        .DB     "CHO", 0
        .DW     COMMAND_ECHO
        .DB     "XIT", 0
        .DW     COMMAND_EXIT
        .DB     0
COMMANDTABLE_F:
        .DB     0
COMMANDTABLE_G:
        .DB     0
COMMANDTABLE_H:
        .DB     0
COMMANDTABLE_I:
        .DB     0
COMMANDTABLE_J:
        .DB     0
COMMANDTABLE_K:
        .DB     0
COMMANDTABLE_L:
        .DB     0
COMMANDTABLE_M:
        .DB     0
COMMANDTABLE_N:
        .DB     0
COMMANDTABLE_O:
        .DB     0
COMMANDTABLE_P:
        .DB     "AUSE", 0
        .DW     COMMAND_PAUSE
        .DB     0
COMMANDTABLE_Q:
        .DB     0
COMMANDTABLE_R:
        .DB     0
COMMANDTABLE_S:
        .DB     0
COMMANDTABLE_T:
        .DB     "IME", 0
        .DW     COMMAND_TIME
        .DB     "YPE", 0
        .DW     COMMAND_TYPE
        .DB     0
COMMANDTABLE_U:
        .DB     0
COMMANDTABLE_V:
        .DB     "ER", 0
        .DW     COMMAND_VER
        .DB     0
COMMANDTABLE_W:
        .DB     0
COMMANDTABLE_X:
        .DB     0
COMMANDTABLE_Y:
        .DB     0
COMMANDTABLE_Z:
        .DB     0
