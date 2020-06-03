; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS date/time functions
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

DOSMONTHDAYTABLE:
        .DB     31,28,31,30,31,30,31,31,30,31,30,31

DOSCMPDAYRAW:
        PHX
        BRA     DOSCMPDAY@INT

.ACCU 8
DOSCMPDAY:
        PHX
        LDX     DOSDATEMONTH.B
@INT
        PHA
        LDA     DOSLC|DOSMONTHDAYTABLE.L,X
        STA     DOSTMPD.B
; is leap year?
        CPX     #1
        BNE     +
        LDA     DOSDATEYEAR.B
        CMP     #2100-1980.B
        BEQ     +
        CMP     #2200-1980.B
        BEQ     +
        AND     #3
        BNE     +
        INC     DOSTMPD.B
+       PLA
        PLX
        INC     DOSTMPD.B
        CMP     DOSTMPD.B
        RTS

; assumes B=$80, D can be whatever
DOSUPDATETIMETICKSZERO:
.ACCU 8
        PHB
        LDA     #$80
        PHA
        PLB
        PHD
        PEA     DOSPAGE.W
        PLD
        
        LDA     DOSHALTCLOCK.W
        BEQ     +
-       LDA     DMA1STAT.L
        BMI     -
+
        INC     DOSDATESECOND.B
        LDA     DOSDATESECOND.B
        CMP     #60
        BCC     +
        STZ     DOSDATESECOND.B

        INC     DOSDATEMINUTE.B
        LDA     DOSDATEMINUTE.B
        CMP     #60
        BCC     +
        STZ     DOSDATEMINUTE.B

        INC     DOSDATEHOUR.B
        LDA     DOSDATEHOUR.B
        CMP     #24
        BCC     +
        STZ     DOSDATEHOUR.B

        INC     DOSDATEDAY.B
        LDA     DOSDATEDAY.B
        JSR     DOSCMPDAY.W
        BCC     +
        STZ     DOSDATEDAY.B

        INC     DOSDATEMONTH.B
        LDA     DOSDATEMONTH.B
        CMP     #12
        BCC     +
        STZ     DOSDATEMONTH.B

        INC     DOSDATEYEAR.B
+       PLD
        PLB
DOSTIMETICKSZERO:
        LDA     $007000.L
        AND     #1
        BEQ     +
        LDA     #50
        BRA     ++
+       LDA     #60
++      CLC
        ADC     DOSPAGE|DOSDATETICK.W
        STA     DOSPAGE|DOSDATETICK.W
        RTS

; $2A = get system date
DOSGETDATE:
        ENTERDOSRAM
        LDA     DOSDATEYEAR.B
        AND     #$FF
        TAY
        LDA     DOSDATEMONTH.B
        AND     #$FF
        INC     A
        TAX
        ; TODO: day of week
        LDA     DOSDATEDAY.B
        INC     A
        AND     #$FF
        EXITDOSRAM
        RTS

; $2B = set system date
DOSSETDATE:
        CMP     #0
        BEQ     @BADDATE
        CPX     #0
        BEQ     @BADDATE
        CPX     #13
        BCS     @BADDATE
        CPY     #256
        BCS     @BADDATE
        ENTERDOSRAM
        ACC8
        PHX
        PHY
        DEX
        JSR     DOSCMPDAYRAW.B
        BCS     @BADDAY
        AXY8
        DEC     A
        STA     DOSDATEDAY.B
        STX     DOSDATEMONTH.B
        STY     DOSDATEYEAR.B
        AXY16
        PLY
        PLX
        EXITDOSRAM
        CLC
        RTS
@BADDAY:
        AXY16
        PLY
        PLX
        EXITDOSRAM
@BADDATE:
        SEC
        RTS

; $2C = get system time
DOSGETTIME:
        ENTERDOSRAM
        LDA     #0
        ACC8
        LDA     DOSDATESECOND.B
        TAY
        LDA     DOSDATEMINUTE.B
        TAX
        LDA     DOSDATEHOUR.B
        ACC16
        EXITDOSRAM
        RTS

; $2D = set system time
DOSSETTIME:
        ENTERDOSRAM
        ACC8
        CMP     #24
        BCS     @BADTIME
        CPX     #60
        BCS     @BADTIME
        CPY     #60
        BCS     @BADTIME

        AXY8
        PHA
        PHX
        PHY

        STA     DOSDATEHOUR.B
        STX     DOSDATEMINUTE.B
        STY     DOSDATESECOND.B

        LDA     $007000.L
        AND     #1
        BEQ     +
        LDA     #50
        BRA     ++
+       LDA     #60
++      STA     DOSDATETICK.B

        PLY
        PLX
        PLA
        ACC16
        EXITDOSRAM
        RTS
@BADTIME:
        AXY16
        SEC
        RTS
