; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS sample executable (HELLO.COM)
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
        ACC8                    ; 8-bit A
        LDA     $0080.W         ; do we have stuff on the command line?
        BNE     @NAME           ; if so, go to @NAME (length > 0)
@WORLD:
        ACC16                   ; 16-bit accumulator
        LDA     #$0900          ; Ah=$09 => print until '$'
        LDX     #MSG            ; print from MSG
        DOSCALL
        LDA     #$0000          ; Ah=$00 => terminate (exit code Al=$00)
        DOSCALL
@NAME:
        ACC16                   ; 16-bit accumulator
        LDA     #$0900          ; Ah=$09 => print until '$'
        LDX     #MSG1           ; print from MSG1
        DOSCALL
        LDA     #$1900          ; Ah=$19 => print until $00
        LDX     #$0081          ; from the command line
        DOSCALL
        LDA     #$0900          ; Ah=$09 => print until '$'
        LDX     #MSG2           ; print from MSG2
        DOSCALL
        LDA     #$0000          ; Ah=$00 => terminate (exit code Al=$00)
        DOSCALL

MSG:
        .DB     "Hello, World!", 13, "$"
MSG1:
        .DB     "Hello, $"
MSG2:
        .DB     "!", 13, "$"
