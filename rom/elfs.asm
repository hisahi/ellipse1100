; Ellipse Workstation 1100 (fictitious computer)
; Header for EGFS (Ellipse Grid File System) and Ellipse partition mat
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

.DEFINE PART_RAW $01 EXPORT
.DEFINE PART_ELFS $02 EXPORT
.DEFINE PART_DOSINT $03 EXPORT

.MACRO ELLIPSEPART ARGS PTYPE, PFLAGS, FIRSTTRK, FIRSTSCT, LASTTRK, LASTSCT
        .DB PTYPE
        .DB PFLAGS
        .DW FIRSTTRK
        .DW LASTTRK
        .DB FIRSTSCT
        .DB LASTSCT
.ENDM

.MACRO ELLIPSEPARTBLANK
        ELLIPSEPART     0, $00, 0, 0, 0, 0
.ENDM

.MACRO DDW
        .DW     $FFFF&(DDW)
        .DW     $FFFF&(DDW>>16)
.ENDM
