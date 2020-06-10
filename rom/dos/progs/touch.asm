; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS command: TOUCH.COM (create file, or just update date)
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
        LDA     $0080.W
        BNE     @FILE
@NOTPARS: 
        ACC16
        LDA     #$1900
        LDX     #MSGNOTPARS
        DOSCALL
        LDA     #$0002
        DOSCALL
@FILE:
        ACC16
        LDA     #$0F03
        LDX     #$0081
        DOSCALL
        BCS     @FILEERR
        ; auto-close on quit
        LDA     #$0000
        DOSCALL
@FILEERR:
        CMP     #DOS_ERR_FILE_NOT_FOUND.W
        BEQ     @CREATE
        CMP     #DOS_ERR_PATH_NOT_FOUND.W
        BEQ     @ERRPATH
        CMP     #DOS_ERR_DRIVE_NOT_READY.W
        BEQ     @ERRDRV
@ERR:
        LDA     #$1900
        LDX     #MSGFAIL
        DOSCALL
        LDA     #$0002
        DOSCALL
@ERRPATH:
        LDA     #$1900
        LDX     #MSGBADPATH
        DOSCALL
        LDA     #$0002
        DOSCALL
@ERRDRV:
        LDA     #$1900
        LDX     #MSGDRVNOTREADY
        DOSCALL
        LDA     #$0002
        DOSCALL
@CREATE:
        LDA     #$1603
        LDX     #$0081
        LDY     #$0000
        DOSCALL
        BCS     @FILEERR
        ; auto-close on quit
        LDA     #$0000
        DOSCALL

MSGNOTPARS:
        .DB     "Not enough parameters", 13, 0
MSGFAIL:
        .DB     "TOUCH failed", 13, 0
MSGBADPATH:
        .DB     "Invalid path", 13, 0
MSGDRVNOTREADY:
        .DB     "Drive not ready", 13, 0
