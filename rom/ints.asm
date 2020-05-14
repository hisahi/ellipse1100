; Ellipse Workstation 1100 (fictitious computer)
; ROM code (interrupt handlers)
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

INTH_RET:
        AXY16
        PLA
        RTI

INTH_NMI:                       ; NMI native handler, jump to SW handler
        AXY16
        CLD
        PHA                     ; load interrupt device number
        PHK                     ; make sure RTI goes to INTH_RET
        PEA     INTH_RET
        PHP
        LDA     $700002
        AND     #$FF.W
        JML     SWRAMNMI-1      ; jump to trampoline
INTH_IRQ:                       ; IRQ native handler, jump to SW handler
        AXY16
        CLD
        PHA                     ; load interrupt device number
        PHK                     ; make sure RTI goes to INTH_RET
        PEA     INTH_RET
        PHP
        LDA     $700002
        AND     #$FF.W
        JML     SWRAMIRQ-1      ; jump to trampoline

INTH_COP:                       ; COP native handler, ignore
INTH_E_COP:                     ; COP emulation handler, ignore
INTH_BRK:                       ; BRK native handler, ignore
INTH_E_BRK:                     ; BRK emulation handler, ignore
INTH_ABORT:                     ; ABORT native handler, ignore
INTH_E_ABORT:                   ; ABORT emulation handler, ignore
        RTI

INTH_E_NMI:                     ; NMI emulation handler
        CLD
        CLC
        XCE                     ; jump to native after disabling E
        PHK
        PEA     INTH_E_NMI_RET
        PHP
        JMP     INTH_NMI
INTH_E_NMI_RET:
        SEC
        XCE
        RTI

INTH_E_IRQ:                     ; IRQ emulation handler
        CLD
        CLC
        XCE                     ; jump to native after disabling E
        PHK
        PEA     INTH_E_NMI_RET
        PHP
        JMP     INTH_IRQ
