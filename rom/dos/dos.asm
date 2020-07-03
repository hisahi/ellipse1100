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

; DOS uses DMA1 (unless FIXTEXT happens to be)

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

; DOS main memory area $80:4000 - $80:43FF
.DEFINE DOSBANKD        $800000
.DEFINE DOSBANKC        $810000
.DEFINE DOSICALLVEC     $1A     ; in $81
.DEFINE DOSPAGE         $4000
.DEFINE DOSLD           (DOSBANKD|DOSPAGE)
.DEFINE DOSLC           DOSBANKC
.DEFINE DOSTMP1         $00     ; used in file resolving, ctable load, math,
                                ;       file handle code, mem allocation (cnt)
.DEFINE DOSTMP2         $02     ; used for path resolving,
                                ;       file handle code, mem allocation
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
.DEFINE DOSTMP9         $1C     ; used for path resolving
.DEFINE DOSFILEDEVICE   $1E
.DEFINE DOSACTIVEDRIVE  $20
.DEFINE DOSACTIVEDIR    $22
.DEFINE DOSBUSY         $24
.DEFINE DOSOLDTEXTDMA1  $26
.DEFINE DOSCTABLEINRAM  $28
.DEFINE DOSLOADTRK      $30
.DEFINE DOSLOADSECT     $32
.DEFINE DOSFILESTRTERM  $34
.DEFINE DOSOLDNMI       $36
.DEFINE DOSINNMI        $39
.DEFINE DOSNEXTFILEDRV  $3A
.DEFINE DOSNEXTFILEDIR  $3C
.DEFINE DOSNEXTFILEOFF  $3E
.DEFINE DOSCACHEDDIRCH  $40
.DEFINE DOSLASTEXITCODE $42
.DEFINE DOSIOBANK       $44
.DEFINE DOSUPDATEPATH   $45
.DEFINE DOSSTDINCONMODE $46
.DEFINE DOSNEXTDIRCHUNK $48
.DEFINE DOSACTIVEHANDLE $4A
.DEFINE DOSOLDIRQ       $4C
.DEFINE DOSPROGBANK     $4F
.DEFINE DOSLASTFCACHE   $50
.DEFINE DOSFSMBDIRTY    $52
.DEFINE DOSADIRDIRTY    $54
.DEFINE DOSCTABLEDIRTY  $56
.DEFINE DOSPREVDIRCHUNK $58
.DEFINE DOSCACHEDDRIVE  $5A
.DEFINE DOSCTBLCACHSECT $5C
.DEFINE DOSIRQCOUNTER   $5E
.DEFINE DOSKEYBWAIT     $5F
.DEFINE DOSSKIPRO       $60
.DEFINE DOSDATEYEAR     $E9
.DEFINE DOSDATEMONTH    $EA
.DEFINE DOSDATEDAY      $EB
.DEFINE DOSDATEHOUR     $EC
.DEFINE DOSDATEMINUTE   $ED
.DEFINE DOSDATESECOND   $EE
.DEFINE DOSDATETICK     $EF
.DEFINE DOSREALDRIVE    $F0
.DEFINE DOSDRIVEDIRS    $F2
.DEFINE DOSFLASHCURSOR  $4100
.DEFINE DOSHALTCLOCKDMA $4102
.DEFINE DOSFILEDTCACHE  $4104
.DEFINE DOSDTETMECACHE  $4109
.DEFINE DOSHALTCLOCKUPD $4110
.DEFINE DOSSTRBUF2      $4180
.DEFINE DOSKEYBBUF      $4200
.DEFINE DOSKEYBBUFL     $4210
.DEFINE DOSKEYBBUFR     $4212
.DEFINE DOSMOVEFNBUF    $4220
.DEFINE DOSFREEBANKS    $4280

; DOS high memory area $80:8000 - $80:BFFF
.DEFINE DOSINBUF        $8700
.DEFINE DOSINBUFSTAR    $8700
.DEFINE DOSPATHSTR      $8800
.DEFINE DOSFILETABLE    $8A00
.DEFINE DOSPATHSTRSIZE  DOSFILETABLE-DOSPATHSTR
.DEFINE DOSSTRINGCACHE  $9000
.DEFINE DOSPATHBUF      $9100
.DEFINE DOSFILETABLESZ  DOSSTRINGCACHE-DOSFILETABLE
.DEFINE DOSENVTABLE     $9400
.DEFINE FSMBCACHE       $9800
.DEFINE AUXSECTCACHE    $9A00
.DEFINE DIRCHUNKCACHE   $9C00
.DEFINE CTABLECACHE     $A000
.DEFINE FILECACHES      $B000

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

.DEFINE TEXTALLOWDMA1 $80101C

.MACRO RESERVEDMA1
        PHP
        ACC8
        PHA
-       LDA     DMA1STAT.L
        BMI     -
        LDA     TEXTALLOWDMA1.L
        STA     DOSOLDTEXTDMA1.B
        LDA     #$FF
        STA     TEXTALLOWDMA1.L
        PLA
        PLP
.ENDM

.MACRO FREEDMA1
        PHA
        LDA     DOSOLDTEXTDMA1.B
        STA     TEXTALLOWDMA1.L
        PLA
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
.ACCU 16
.INDEX 16
        .INCLUDE    "dos/icall.asm"
