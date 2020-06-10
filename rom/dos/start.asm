; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS initialization
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

DOSSTART:
        SEI
        LDA     #MESSAGE_DOSSTART.w
        JSL     TEXT_WRSTR.L
        BRA     @REST
.ORG DOSICALLVEC
        JSR     $0000
        JMP     DOSCALLEXIT
.ORG $0040
        .DW     1
        .DW     1
        .DW     1
@REST:
        ACC8
        LDA     #$4C                            ; JMP abs
        STA     DOSBANKC.L

        SETBANK8        $80

        ACC16
        LDA     #DOSCALLENTRY
        STA     DOSBANKC+1.L

        LDA     #DOSPAGE
        TCD

; also clears DOSUPDATEPATH
        LDA     #$0080
        STA     DOSIOBANK.B
        STZ     DOSBUSY.B
        
        STZ     DOSCTBLCACHSECT.B
        STZ     DOSHALTCLOCKDMA.W
        STZ     DOSHALTCLOCKUPD.W
        STZ     DOSCACHEDDIRCH.B
        STZ     DOSKEYBBUFL.B
        STZ     DOSKEYBBUFR.B
        STZ     DOSLASTFCACHE.B
        STZ     DOSFSMBDIRTY.B
        STZ     DOSADIRDIRTY.B
        STZ     DOSCTABLEDIRTY.B
        STZ     DOSDATEYEAR.B
        STZ     DOSDATEMONTH.B  ;+     DOSDATEDAY.B
        STZ     DOSDATEHOUR.B   ;+  DOSDATEMINUTE.B
        STZ     DOSDATESECOND.B ;+    DOSDATETICK.B
        STZ     DOSOLDTEXTDMA1.B
        
        LDA     #$0001
        STA     DOSFLASHCURSOR.W
        LDX     #0
-       STA     DOSDRIVEDIRS.B,X
        INX
        INX
        CPX     #14
        BCC     -
        STA     DOSACTIVEDIR.W

        LDA     #$01
        STA     DOSACTIVEDRIVE.B
        STA     DOSREALDRIVE.B
        JSR     DOSLOADFSMB.W
        JSR     DOSVERIFYVOLUME.W
        BCS     DOS_FATAL_UNSUPFS
        JSR     DOSLOADCTABLE.W
        JSR     DOSINITMISCBUFFERS.W

        LDA     #DOSNMIHANDLER.W
        LDX     #DOSPAGE|DOSOLDNMI.W
        LDY     #$0081.W
        JSL     ROM_SWAPNMI.L

        LDA     #DOSIRQHANDLER.W
        LDX     #DOSPAGE|DOSOLDIRQ.W
        LDY     #$0081.W
        JSL     ROM_SWAPIRQ.L

        ; enable keyboard interrupt & NMI V-SYNC
        LDA     #$01
        STA     IOBANK|EINTGNRC.L
        LDA     #$06
        STA     IOBANK|VPUCNTRL.L

        LDA     #$FF
        STA     DOSOLDTEXTDMA1.B
        FREEDMA1

        LDA     #$1234
        STA     $801234.L

        CLI

DOS_CONSOLE:
        SETBANK16       $81
        LDX     #DOS_EXECNAME
        LDY     #DOS_EXECSTRUCT
        LDA     #$3800
        DOSCALL
        BCC     DOS_CONSOLE
DOS_CONSOLE_FAIL:
        LDA     #MESSAGE_CANNOTSTART.w
        JSL     TEXT_WRSTR.L
        STP

DOS_FATAL_UNSUPFS:
        SETBANK8        $81
        LDA     #MESSAGE_UNSUPFS.w
        JSL     TEXT_WRSTR.L
        STP

MESSAGE_DOSSTART:
        .DB     "Starting Ellipse DOS...",13,0
MESSAGE_UNSUPFS:
        .DB     "Unsupported file system",13,0
MESSAGE_CANNOTSTART:
        .DB     "Cannot find "
DOS_EXECNAME:
        .DB     "CONSOLE.COM"
DOS_EMPTYSTR:
        .DB     0
DOS_EXECSTRUCT:
        .DW     DOS_EMPTYSTR
        .DW     DOSENVTABLE
        .DB     $80

DOSNMIHANDLER:
        ; set "got NMI" to nonzero
        SETB8   $80
        DEC     DOSPAGE|DOSDATETICK.W
        LDA     #$FF
        STA     DOSPAGE|DOSINNMI.W
        LDA     DOSPAGE|DOSDATETICK.W
        BMI     +
        JSR     DOSUPDATETIMETICKSZERO.W
+       AXY16
        JML     [DOSPAGE|DOSOLDNMI.W]

DOSIRQHANDLER:
        SETB8   $80
        SEI
        
        BIT     DOSPAGE|DOSKEYBWAIT.W
        BMI     @INCCOUNTER
        ; keyboard update routine
        JSL     KEYB_UPDKEYSI.L
        LDA     #28
        LDX     #26
        JSL     KEYB_GETKEY.L
        AND     #$FF
        BCC     ++
        ACC8
        BEQ     ++
        PHA
        LDA     DOSPAGE|DOSKEYBBUFR.W
        INC     A
        AND     #$0F
        CMP     DOSPAGE|DOSKEYBBUFL.W
        BEQ     +
        STA     DOSPAGE|DOSKEYBBUFR.W
        DEC     A
        AND     #$0F
        TAX
        PLA
        STA     DOSPAGE|DOSKEYBBUF.W,X
++      JML     [DOSPAGE|DOSOLDIRQ.W]
+       PLA
        JML     [DOSPAGE|DOSOLDIRQ.W]

@INCCOUNTER:
        LDA     #$FF
        TSB     DOSPAGE|DOSIRQCOUNTER.W
        JML     [DOSPAGE|DOSOLDIRQ.W]

.ACCU 16
DOSGETVER:              ; $3F = get Ellipse DOS version
        LDA     #$0100
        RTS
