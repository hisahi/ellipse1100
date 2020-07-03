; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS program (SYS.COM)
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

; does not work currently due to DOS file system bugs that can cause file
; system corruption

.INCLUDE "doscomhd.asm"

MAIN:
        ACC8
        LDA     $0080.W
        BEQ     BADPAR
        LDA     $0083.W
        BNE     BADPAR
        LDA     $0082.W
        CMP     #':'
        BNE     BADPAR
        LDA     $0081.W
        AND     #$DF
        CMP     #'A'
        BCC     BADPAR
        CMP     #'Z'+1
        BCS     BADPAR
        STA     DOS_SYS_DRV.W
        STA     CONSOLE_COM_DRV.W

        ACC16
        LDA     #$0F01
        LDX     #DOS_SYS
        DOSCALL
        BCS     READERROR
        STX     FILER1.W

        LDA     #$0F01
        LDX     #CONSOLE_COM
        DOSCALL
        BCC     READOPENOK
        STX     FILER2.W

        LDA     #$10FF
        LDX     FILER1.W
        DOSCALL

READERROR:
        LDA     #$1900
        LDX     #CANNOTOPENREAD
        DOSCALL
        LDA     #$0002
        DOSCALL

BADPAR:
        LDA     #$1900
        LDX     #BADPARMSG
        DOSCALL
        LDA     #$0002
        DOSCALL

FREEFILE2:
        LDA     #$1E00
        LDX     #CONSOLE_COM_DRV.W
        DOSCALL
        BCC     +
        JMP     WRITEERROR     
+       LDA     #$1300
        LDX     #CONSOLE_COM_DRV.W
        DOSCALL
        BCC     TRYFILE2
        JMP     WRITEERROR

READOPENOK:
TRYFILE2:
        LDA     #$1602
        LDY     #1
        LDX     #CONSOLE_COM_DRV.W
        DOSCALL
        BCC     +
        CMP     #DOS_ERR_ACCESS_DENIED
        BEQ     FREEFILE2
        BRA     WRITEERROR
+       STX     FILEW2.W
        BRA     TRYFILE1

FREEFILE1:
        LDA     #$1E00
        LDX     #DOS_SYS_DRV.W
        DOSCALL
        BCS     WRITEERROR2
        LDA     #$1300
        LDX     #DOS_SYS_DRV.W
        DOSCALL
        BCS     WRITEERROR2
        BRA     TRYFILE1

TRYFILE1:
        LDA     #$1602
        LDY     #7
        LDX     #DOS_SYS_DRV.W
        DOSCALL
        BCC     +
        CMP     #DOS_ERR_ACCESS_DENIED
        BEQ     FREEFILE1
        BRA     WRITEERROR2
+       STX     FILEW1.W

        LDA     #$8000
        TCD

WRITEFILE1:
        LDA     #$2100
        LDX     FILER1.W
        LDY     #$4000
        DOSCALL
        BCS     WRITEERROR1
        CPY     #0
        BEQ     WRITEFILE2
        
        LDA     #$2200
        LDX     FILEW1.W
        DOSCALL
        BCS     WRITEERROR1
        BRA     WRITEFILE1

WRITEERROR1:
        PHA
        LDA     #$10FF
        LDX     FILEW1.W
        DOSCALL
        PLA
WRITEERROR2:
        PHA
        LDA     #$10FF
        LDX     FILEW2.W
        DOSCALL
        PLA
WRITEERROR:
        PHA
        LDA     #$10FF
        LDX     FILER1.W
        DOSCALL
        LDA     #$10FF
        LDX     FILER2.W
        DOSCALL
        PLA
        CMP     #DOS_ERR_DRIVE_FULL.W
        BNE     +
        LDX     #CANNOTWRITESPACE
        BRA     ++
+       CMP     #DOS_ERR_DRIVE_NOT_READY.W
        BNE     +
        LDX     #CANNOTWRITEDRIVE
        BRA     ++
+       LDX     #CANNOTWRITE
++      LDA     #$1900
        DOSCALL
        LDA     #$0002
        DOSCALL

WRITEFILE2:
        LDA     #$2100
        LDX     FILER2.W
        LDY     #$4000
        DOSCALL
        BCS     WRITEERROR1
        CPY     #0
        BEQ     WRITEFILEOK
        
        LDA     #$2200
        LDX     FILEW2.W
        DOSCALL
        BCS     WRITEERROR1
        BRA     WRITEFILE2

WRITEFILEOK:
        LDA     #$10FF
        LDX     FILEW1.W
        DOSCALL
        LDA     #$10FF
        LDX     FILEW2.W
        DOSCALL
        LDA     #$10FF
        LDX     FILER2.W
        DOSCALL
        LDA     #$10FF
        LDX     FILER1.W
        DOSCALL
        LDA     #$1900
        LDX     #SYSOK
        DOSCALL
        LDA     #$0000
        DOSCALL

FILER1: .DW     0
FILER2: .DW     0
FILEW1: .DW     0
FILEW2: .DW     0
DOS_SYS_DRV:
        .DB     "@:"
DOS_SYS:
        .DB     "\DOS.SYS", 0
CONSOLE_COM_DRV:
        .DB     "@:"
CONSOLE_COM:
        .DB     "\CONSOLE.COM", 0
BADPARMSG:
        .DB     "Invalid drive specification", 13, 0
CANNOTOPENREAD:
        .DB     "Cannot open system files for reading.", 13
        .DB     "Make sure SYS is run from a bootable floppy drive.", 13, 0
CANNOTWRITE:
        .DB     "Failed to write system files onto destination drive", 13, 0
CANNOTWRITESPACE:
        .DB     "Not enough space for system files on destination drive", 13, 0
CANNOTWRITEDRIVE:
        .DB     "Destination drive is not ready", 13, 0
SYSOK:
        .DB     "System transferred", 13, 0


