; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS internal call vectors
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

DOSI_INTERNALTICK:
        AXY16
        LDA     DOSLD|DOSDATETICK.L
        AND     #$FF
        XBA
        EOR     DOSLD|DOSTMP2.L
        EOR     DOSLD|DOSTMP4.L
        EOR     DOSLD|DOSTMP7.L
        EOR     DOSLD|DOSTMP8.L
        ROR     A
        ROR     A
        ROR     A
        ADC     #0
        CLC
        ADC     DOSDATESECOND.W
        CLC
        RTL

; does A contain valid drive number? carry set if not
;       A = media ID
;       X = number of tracks
;       Y = number of sectors
DOSI_GETDISKINFO:
        AXY16
        CMP     #1
        BEQ     DOSI_GETDISKINFO_FLP1
        CMP     #2
        BEQ     DOSI_GETDISKINFO_FLP2
        SEC
        RTS
DOSI_GETDISKINFO_FLP2:
        LDX     #4
        BRA     DOSI_GETDISKINFO_FLP
DOSI_GETDISKINFO_FLP1:
        LDX     #0
DOSI_GETDISKINFO_FLP:
        ACC8
        LDA     IOBANK|FLP1STAT.L,X
        ACC16
        AND     #$001C
        TAY
        LDX     #160
        SEC
        SBC     #8
        LSR     A
        LSR     A
        CLC
        RTL

; Al = sector
; Ah = drive
; X = track
; Y = target address
; B = target bank
DOSI_READSECTOR:
        ENTERDOSRAM
        AXY16
        PEI     (DOSACTIVEDRIVE.B)
        ACC8
        XBA
        CMP     #0
        BEQ     +
        STA     DOSACTIVEDRIVE.B
+       XBA
        ACC16
        AND     #$FF
        STA     DOSLOADSECT.B
        STX     DOSLOADTRK.B
        LDA     5,S
        AND     #$FF
        STA     DOSIOBANK.B

        TYX
        JSR     DOSINTRAWLOADSECTOR.W
        
        PLA
        STA     DOSACTIVEDRIVE.B
        EXITDOSRAM
        RTL

; Al = sector
; Ah = drive
; X = track
; Y = source address
; B = source bank
DOSI_WRITESECTOR:
        ENTERDOSRAM
        AXY16
        PEI     (DOSACTIVEDRIVE.B)
        ACC8
        XBA
        CMP     #0
        BEQ     +
        STA     DOSACTIVEDRIVE.B
+       XBA
        ACC16
        AND     #$FF
        STA     DOSLOADSECT.B
        STX     DOSLOADTRK.B
        LDA     5,S
        AND     #$FF
        STA     DOSIOBANK.B

        TYX
        JSR     DOSINTRAWSTORESECTOR.W
        
        PLA
        STA     DOSACTIVEDRIVE.B
        EXITDOSRAM
        RTL

DOSICALLTABLE:
        JML     DOSBANKC|DOSI_INTERNALTICK
        JML     DOSBANKC|DOSI_GETDISKINFO
        JML     DOSBANKC|DOSI_WRITESECTOR
        JML     DOSBANKC|DOSI_READSECTOR
DOSICALLTABLE_END:
