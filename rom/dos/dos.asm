; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS code (top-level)
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

.INCLUDE "e1100.asm"

.MEMORYMAP
SLOTSIZE $10000
DEFAULTSLOT 0
SLOT 0 $0000
.ENDME

.ROMBANKMAP
BANKSTOTAL 1
BANKSIZE $10000
BANKS 1
.ENDRO

; DOS uses DMA1

.MACRO SETBANK8
        ACC8
        LDA     #\1
        PHA
        PLB
.ENDM

.MACRO SETBANK16
        PEA     (\1 | (\1 << 8))
        PLB
        PLB
.ENDM

.DEFINE DOSMAXDRIVES    2
.DEFINE OPENFILES       32
; must be power of two
.DEFINE NUMFILECACHES   4
.DEFINE CONMODENORMAL   0
.DEFINE CONMODEQUIET    1
.DEFINE CONMODERAW      2
.DEFINE MAXPATH         128     ; also need to adjust DOSCURPATHTOX

.DEFINE DOSBANKD        $800000
.DEFINE DOSBANKC        $810000
.DEFINE DOSICALLVEC     $1A     ; in $81
.DEFINE DOSPAGE         $4400
.DEFINE DOSLD           (DOSBANKD|DOSPAGE)
.DEFINE DOSLC           DOSBANKC
.DEFINE DOSTMP1         $00     ; used in file resolving, ctable load, math,
                                ;       file handle code
.DEFINE DOSTMP2         $02     ; used for path resolving,
                                ;       file handle code
.DEFINE DOSTMP3         $04     ; used for file & path resolving,
                                ;       file handle code
.DEFINE DOSTMP4         $06     ; used for path resolving, file handle code
.DEFINE DOSTMP5         $08     ; used in wildcards, paths, file execution
.DEFINE DOSTMP6         $0A     ; used in wildcard file matching, file exec,
                                ;       chunk allocation
.DEFINE DOSTMP7         $0C     ; used in wildcard file matching, file exec,
                                ;       chunk freeing
.DEFINE DOSTMP8         $0E     ; used in wildcard file matching, file exec,
                                ;       & file handle code
.DEFINE DOSTMPX1        $10     ; used for file r/w (total read/written)
                                ;          file seek (new value low)
.DEFINE DOSTMPX2        $12     ; used for file r/w (destination)
                                ;          file seek (new value high)
.DEFINE DOSTMPX3        $14     ; used for file r/w (internal handle)
                                ;          file seek (internal handle)
.DEFINE DOSTMPX4        $16     ; used for file r/w (bank)
.DEFINE DOSTMPX5        $18     ; used for file r/w (read/written on this iter)
.DEFINE DOSTMPD         $1A     ; used by date/time increment routine (NMI)
.DEFINE DOSFILEDEVICE   $1E
.DEFINE DOSACTIVEDRIVE  $20
.DEFINE DOSACTIVEDIR    $22
.DEFINE DOSBUSY         $24
.DEFINE DOSLOADTRK      $30
.DEFINE DOSLOADSECT     $32
.DEFINE DOSCTABLEINRAM  $34
.DEFINE DOSOLDNMI       $36
.DEFINE DOSINNMI        $39
.DEFINE DOSCTBLCACHSECT $3A
.DEFINE DOSNEXTFILEDIR  $3C
.DEFINE DOSNEXTFILEOFF  $3E
.DEFINE DOSCACHEDDIRCH  $40
.DEFINE DOSLASTEXITCODE $42
.DEFINE DOSIOBANK       $44
.DEFINE DOSUPDATEPATH   $45
.DEFINE DOSSTDINCONMODE $46
.DEFINE DOSFILESTRTERM  $48
.DEFINE DOSACTIVEHANDLE $4A
.DEFINE DOSOLDIRQ       $4C
.DEFINE DOSPROGBANK     $4F
.DEFINE DOSLASTFCACHE   $50
.DEFINE DOSFSMBDIRTY    $52
.DEFINE DOSADIRDIRTY    $54
.DEFINE DOSCTABLEDIRTY  $56
.DEFINE DOSPREVDIRCHUNK $58
.DEFINE DOSDATEYEAR     $E9
.DEFINE DOSDATEMONTH    $EA
.DEFINE DOSDATEDAY      $EB
.DEFINE DOSDATEHOUR     $EC
.DEFINE DOSDATEMINUTE   $ED
.DEFINE DOSDATESECOND   $EE
.DEFINE DOSDATETICK     $EF
.DEFINE DOSREALDRIVE    $F0
.DEFINE DOSDRIVEDIRS    $F2
.DEFINE DOSFLASHCURSOR  $4500
.DEFINE DOSKEYBBUF      $4600
.DEFINE DOSKEYBBUFL     $4610
.DEFINE DOSKEYBBUFR     $4612
.DEFINE DOSFREEBANKS    $4680
.DEFINE DOSSTRINGCACHE  $4700
.DEFINE DOSPATHSTR      $4800
.DEFINE DOSFILETABLE    $4A00
.DEFINE DOSPATHSTRSIZE  DOSFILETABLE-DOSPATHSTR
.DEFINE DOSUNUSEDAREA   $5000
.DEFINE DOSENVTABLE     $5400
.DEFINE FSMBCACHE       $5800
.DEFINE AUXSECTCACHE    $5A00
.DEFINE DIRCHUNKCACHE   $5C00
.DEFINE CTABLECACHE     $6000
.DEFINE FILECACHES      $7000

.INCLUDE "dos/errors.asm"

.MACRO DOS_RETURN_ERROR
        AXY16
        LDA     #\1
        SEC
        RTS
.ENDM

.MACRO ENTERDOSRAM
        PHB
        PHD
        ACC16
        PHA
        SETBANK16       $80
        LDA     #DOSPAGE
        TCD
        PLA
.ENDM

.MACRO EXITDOSRAM
        PLD
        PLB
.ENDM

.BANK 0 .SLOT 0

.ORGA $000000           ; DOS
        .DB     "DOS."
.ACCU 16
.INDEX 16
        .INCLUDE    "dos/start.asm"
.ACCU 16
.INDEX 16
        .INCLUDE    "dos/call.asm"
.ACCU 16
.INDEX 16
        .INCLUDE    "dos/fs.asm"
.ACCU 16
.INDEX 16
        .INCLUDE    "dos/fscalls.asm"
.ACCU 16
.INDEX 16
        .INCLUDE    "dos/iocalls.asm"
.ACCU 16
.INDEX 16
        .INCLUDE    "dos/mem.asm"
.ACCU 16
.INDEX 16
        .INCLUDE    "dos/fileio.asm"
.ACCU 16
.INDEX 16
        .INCLUDE    "dos/conio.asm"
.ACCU 16
.INDEX 16
        .INCLUDE    "dos/exec.asm"
.ACCU 16
.INDEX 16
        .INCLUDE    "dos/time.asm"
