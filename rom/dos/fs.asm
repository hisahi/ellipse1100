; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS file system (ELFS) internal functions
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

.ACCU 16
.INDEX 16

; assumes B=$80 D=DOSPAGE
; X=where to load to
DOSINTRAWLOADSECTOR:
        RESERVEDMA1
.ACCU 16
        TXA
        STA     DMA1DST.L
        LDA     #$0200
        STA     DMA1CNT.L
        LDA     #0
        ACC8
        LDA     DOSIOBANK.B
        ACC16
        ORA     #$7000
        STA     DMA1BNKS.L
        LDA     DOSACTIVEDRIVE.B
        DEC     A
        CMP     #DOSMAXDRIVES
        BCS     DOSRTSINVALIDDRIVE
        ASL     A
        TAX
        JSR     (DOSINTRAWLOADSECTORDRIVES.W,X)
        FREEDMA1
        RTS

; assumes B=$80 D=DOSPAGE
; X=where to load to
DOSINTRAWSTORESECTOR:
        RESERVEDMA1
.ACCU 16
        TXA
        STA     DMA1SRC.L
        LDA     #$0200
        STA     DMA1CNT.L
        LDA     #0
        ACC8
        LDA     DOSIOBANK.B
        ACC16
        ORA     #$7000
        STA     DMA1BNKS.L
        LDA     DOSACTIVEDRIVE.B
        DEC     A
        CMP     #DOSMAXDRIVES
        BCS     DOSRTSINVALIDDRIVE
        ASL     A
        TAX
        JSR     (DOSINTRAWSTORESECTORDRIVES.W,X)
        FREEDMA1
        RTS

DOSRTSINVALIDDRIVE:
        DOS_RETURN_ERROR     DOS_ERR_INVALID_DRIVE

DOSERRORCODES_FLOPPY:
        .DB     0
        .DB     DOS_ERR_IO_ERROR
        .DB     DOS_ERR_DRIVE_NOT_READY
        .DB     DOS_ERR_IO_ERROR
        .DB     DOS_ERR_READ_ERROR
        .DB     DOS_ERR_WRITE_ERROR

DOSINTRAWLOADSECTOR_FLOPPY:
        PHB
        SETBANK16       $70
        TXA
        ASL     A
        TAX
        CLC
        ADC     #FLP1DATA.W
        STA     DMA1SRC.W
        ACC8
        LDA     DOSLD|DOSLOADTRK.L
        CMP     #80
        BCC     +
        CLC
        ADC     #48
+       STA     FLP1TRCK.W,X
        LDA     DOSLD|DOSLOADSECT.L
        STA     FLP1SECT.W,X
        LDA     #$41
        STA     FLP1STAT.W,X

-       BIT     FLP1STAT.W,X
        BVS     @ERROR
        BPL     -

        LDA     #$94
        STA     DMA1CTRL.W

-       BIT     FLP1STAT.W,X
        BVS     @ERROR
        BIT     DMA1STAT.W
        BMI     -

        ACC16
        PLB
        CLC
        RTS
@ERROR  STZ     DMA1CTRL.W
        LDA     FLP1DATA.W,X
        ACC16
        AND     #$FF
        TAX
        LDA     DOSLC|DOSERRORCODES_FLOPPY.L,X
        AND     #$FF
        SEC
        PLB
        RTS

DOSINTRAWSTORESECTOR_FLOPPY:
        PHB
        SETBANK16       $70
        TXA
        ASL     A
        TAX
        CLC
        ADC     #FLP1STAT.W
        STA     DMA1DST.W
        ACC8
        LDA     DOSLD|DOSLOADTRK.L
        CMP     #80
        BCC     +
        CLC
        ADC     #48
+       STA     FLP1TRCK.W,X
        LDA     DOSLD|DOSLOADSECT.L
        STA     FLP1SECT.W,X
        LDA     #$42
        STA     FLP1STAT.W,X

-       BIT     FLP1STAT.W,X
        BVS     DOSINTRAWLOADSECTOR_FLOPPY@ERROR
        BPL     -

        LDA     #$98
        STA     DMA1CTRL.W

-       BIT     FLP1STAT.W,X
        BVS     DOSINTRAWLOADSECTOR_FLOPPY@ERROR
        BIT     DMA1STAT.W
        BMI     -

        ACC16
        PLB
        CLC
        RTS

DOSINTRAWLOADSECTORDRIVES:
        .DW     DOSINTRAWLOADSECTOR_FLOPPY
        .DW     DOSINTRAWLOADSECTOR_FLOPPY

DOSINTRAWSTORESECTORDRIVES:
        .DW     DOSINTRAWSTORESECTOR_FLOPPY
        .DW     DOSINTRAWSTORESECTOR_FLOPPY

DOSINTRAWCTABLEINRAM:
        .DB     1
        .DB     1

DOSVERIFYVOLUME:
        PHB
        SETBANK16       $80

        LDA     FSMBCACHE.W
        CMP     #$4C45
        BNE     @FAIL
        
        LDA     FSMBCACHE+2.W
        CMP     #$5346
        BNE     @FAIL
        
        LDA     FSMBCACHE+$10.W
        CMP     #$000A
        BNE     @FAIL
        
        LDA     FSMBCACHE+$16.W
        BEQ     @FAIL
        LDA     FSMBCACHE+$08.W
        CMP     #1
        BCC     +
        CMP     #3
        BCS     +
        LDA     FSMBCACHE+$16.W
        CMP     #$0010
        BCS     @FAIL
+

        LDA     FSMBCACHE+$38.W
        AND     #1
        BNE     @FAIL

        LDA     FSMBCACHE+$18.W
        CMP     #2
        BNE     @FAIL

        LDA     FSMBCACHE+$12.W
        XBA
        AND     #$FF
        INC     A
        CMP     FSMBCACHE+$16.W
        BCS     @FAIL
        
        LDA     FSMBCACHE+$14.W
        BEQ     @FAIL

        PLB
        CLC
        RTS
@FAIL   PLB
        SEC
        RTS

; assumes B=$80 D=DOSPAGE
; rewrite FSMB
DOSWRITEFSMB:
        STZ     DOSFSMBDIRTY.B
        STZ     DOSLOADTRK.B
        LDA     #1
        STA     DOSLOADSECT.B
        LDX     #FSMBCACHE.W
        JMP     DOSINTRAWSTORESECTOR.W
+       RTS

; assumes B=$80 D=DOSPAGE
; load FSMB
DOSLOADFSMB:
        STZ     DOSLOADTRK.B
        LDA     #1
        STA     DOSLOADSECT.B
        LDA     DOSACTIVEDRIVE.B
        STA     DOSCACHEDDRIVE.B
        LDX     #FSMBCACHE.W
        JMP     DOSINTRAWLOADSECTOR.W

DOSLOADCTABLE_OK:
        CLC
        RTS
; assumes B=$80 D=DOSPAGE
; load CTABLE (if on floppy)
DOSLOADCTABLE:
        ACC8
        LDX     DOSACTIVEDRIVE.B
        LDA     DOSLC|DOSINTRAWCTABLEINRAM.L,X
        STA     DOSCTABLEINRAM.B
        ACC16
        BEQ     DOSLOADCTABLE_OK

        LDA     #CTABLECACHE.W
        STA     DOSTMP1.B
        
        ; on standard floppies, we will never go past track 0 on loading CTABLE
        STZ     DOSLOADTRK.B
        LDA     #2
        STA     DOSLOADSECT.B

        LDY     FSMBCACHE+$16.W
-       LDX     DOSTMP1.B
        JSR     DOSINTRAWLOADSECTOR.W

        LDA     DOSTMP1.B
        CLC
        ADC     #$0200
        STA     DOSTMP1.B

        INC     DOSLOADSECT.B
        DEY
        BNE     -

        STZ     DOSCTABLEDIRTY.B

        CLC
        RTS
@ERR:   SEC
        RTS

DOSSTORECTABLE_OK:
        CLC
        RTS
; assumes B=$80 D=DOSPAGE
; store CTABLE (if on floppy)
DOSSTORECTABLE:
        ACC8
        LDX     DOSACTIVEDRIVE.B
        LDA     DOSLC|DOSINTRAWCTABLEINRAM.L,X
        STA     DOSCTABLEINRAM.B
        ACC16
        BEQ     DOSSTORECTABLE_OK

        LDA     #CTABLECACHE.W
        STA     DOSTMP1.B
        
        ; on standard floppies, we will never go past track 0 on loading CTABLE
        STZ     DOSLOADTRK.B
        LDA     #2
        STA     DOSLOADSECT.B

        LDY     FSMBCACHE+$16.W
-       LDX     DOSTMP1.B
        JSR     DOSINTRAWSTORESECTOR.W

        LDA     DOSTMP1.B
        CLC
        ADC     #$0200
        STA     DOSTMP1.B

        INC     DOSLOADSECT.B
        DEY
        BNE     -

        STZ     DOSCTABLEDIRTY.B

        CLC
        RTS
@ERR:   SEC
        RTS

; converts chunk number in Y to sect/track
DOSCONVCHUNK:
; chunk Y to sector X
        TYA
        DEC     A
        ASL     A
        CLC
        ADC     FSMBCACHE+$38.W
        TAX
; converts sector number in X to DOSLOADTRK and DOSLOADSECT
DOSCONVSECTOR:
; load "sectors per track" = "chunks per track" << 1
        LDA     FSMBCACHE+$14.W
        ASL     A
; long division; X/A = Q=DOSLOADTRK.B, R=X
;                             (track), (sector)
        STZ     DOSLOADTRK.B
        LDY     #0
-       INY
        ASL     A
        BCC     -
        ROR     A       
        STA     DOSTMP1.B
-       TXA
        SEC
        SBC     DOSTMP1.B
        BCC     +
        TAX
+       ROL     DOSLOADTRK.B
        LSR     DOSTMP1.B
        DEY
        BNE     -
; store sector result
        STX     DOSLOADSECT.B
        RTS

; assumes B=$80 D=DOSPAGE
; X=where to read to
; Y=chunk number
DOSLOADCHUNK:
        PHX
        JSR     DOSCONVCHUNK.W
        LDA     1,S
        TAX
        JSR     DOSINTRAWLOADSECTOR
        BCS     +
        INC     DOSLOADSECT.B
        PLA
        CLC
        ADC     #$0200
        TAX
        JMP     DOSINTRAWLOADSECTOR
+       PLX
        RTS

; assumes B=$80 D=DOSPAGE
; X=where to read to
; Y=chunk number
DOSSTORECHUNK:
        PHX
        JSR     DOSCONVCHUNK.W
        LDA     1,S
        TAX
        JSR     DOSINTRAWSTORESECTOR
        BCS     +
        INC     DOSLOADSECT.B
        PLA
        CLC
        ADC     #$0200
        TAX
        JMP     DOSINTRAWSTORESECTOR
+       PLX
        RTS

.MACRO DOSMEMENTER
        PHB
        PHD
        PHA
        SETBANK16       $80
        LDA     #DOSPAGE
        TCD
        PLA
.ENDM

.MACRO DOSMEMEXIT
        PLD
        PLB
.ENDM

; assumes B=$80 D=DOSPAGE
; load actual current drive/disk
; destroys A
DOSPAGEINDIR:
        PHX
        LDA     DOSREALDRIVE.B
        STA     DOSACTIVEDRIVE.B
        DEC     A
        ASL     A
        TAX
        LDA     DOSDRIVEDIRS.B,X
        STA     DOSACTIVEDIR.B
        PLX
        RTS

; assumes B=$80 D=DOSPAGE
; save actual current drive back
; destroys A
DOSPAGEOUTDRIVE:
        LDA     DOSACTIVEDRIVE.B
        STA     DOSREALDRIVE.B
        RTS

; assumes B=$80 D=DOSPAGE
; save actual current dir back
; destroys A
DOSPAGEOUTDIR:
        PHX
        LDA     DOSACTIVEDRIVE.B
        DEC     A
        ASL     A
        TAX
        LDA     DOSACTIVEDIR.B
        STA     DOSDRIVEDIRS.B,X
        LDA     DOSREALDRIVE.B
        STA     DOSACTIVEDRIVE.B
        PLX
        RTS

; cache in new part of ctable
; A=chunk table index to load (sector-2)
DOSCTABLEPARTLOAD:
        STA     DOSTMP1.B
        LDA     DOSCTABLEINRAM.B
        BNE     +
        JSR     DOSCTABLEPARTWRITEBACK.W
        STZ     DOSCTABLEDIRTY.B
        PHX
        PHY
        LDA     DOSTMP1.B
        INC     A
        INC     A
        STA     DOSCTBLCACHSECT.B
        JSR     DOSCONVSECTOR.W
        LDX     #CTABLECACHE.W
        JSR     DOSINTRAWLOADSECTOR.W
        PLY
        PLX
+       RTS

; write back partial ctable
DOSCTABLEPARTWRITEBACK:
        LDA     DOSCTABLEINRAM.B
        BNE     +
        LDA     DOSCTABLEDIRTY.B
        BEQ     +
        STZ     DOSCTABLEDIRTY.B
        PHX
        PHY
        LDX     DOSCTBLCACHSECT.B
        JSR     DOSCONVSECTOR.W
        LDX     #CTABLECACHE.W
        JSR     DOSINTRAWSTORESECTOR.W
        ; TODO: handle failure, which usually means bad sector or disk removed
        PLY
        PLX
+       RTS

; write back full ctable
DOSCTABLEWRITEBACKRAW:
        LDA     DOSCTABLEINRAM.B
        BEQ     DOSCTABLEPARTWRITEBACK
        LDA     DOSCTABLEDIRTY.B
        BEQ     +
        STZ     DOSCTABLEDIRTY.B
        PHX
        PHY
        JSR     DOSSTORECTABLE.W
        PLY
        PLX
+       RTS

; write back full ctable
DOSCTABLEWRITEBACK:
        LDA     DOSCTABLEINRAM.B
        BEQ     DOSCTABLEPARTWRITEBACK
        LDA     DOSCTABLEDIRTY.B
        BEQ     +
        STZ     DOSCTABLEDIRTY.B
        JSR     DOSSTARTDIRWRITE.B
        JSR     DOSDIRWRITEBACKRAW.W
        JSR     DOSENDDIRWRITE.B
+       RTS

; assumes B=$80 D=DOSPAGE
DOSDIRWRITEBACK:
        LDA     DOSADIRDIRTY.B
        BEQ     +
        JSR     DOSSTARTDIRWRITE.B
        JSR     DOSDIRWRITEBACKRAW.W
        JSR     DOSENDDIRWRITE.B
+       RTS

; assumes B=$80 D=DOSPAGE
DOSWRITEBACK:
        LDA     DOSFSMBDIRTY.B
        ORA     DOSCTABLEDIRTY.B
        ORA     DOSADIRDIRTY.B
        BEQ     +
        JSR     DOSSTARTDIRWRITE.B
        JSR     DOSCTABLEWRITEBACKRAW.W
        JSR     DOSDIRWRITEBACKRAW.W
        JSR     DOSENDDIRWRITE.B
+       RTS

; assumes B=$80 D=DOSPAGE
; X is current chunk
; returns next chunk in X or $FFFF if end of chain
; C=1 if error, C=0 if success
DOSNEXTCHUNK:
        LDA     DOSCTABLEINRAM.B
        BEQ     @LOADCTABLE
        TXA
        ASL     A
        TAX
        LDA     CTABLECACHE.W,X
        TAX
        CLC
        RTS
@LOADCTABLE:
        TXA
        XBA
        AND     #$FF
        INC     A
        INC     A
        CMP     DOSCTBLCACHSECT.B
        BEQ     +
        JSR     DOSCTABLEPARTWRITEBACK.W
        STA     DOSCTBLCACHSECT.B
        PHX
        PHY
        TAX
        JSR     DOSCONVSECTOR.W
        LDX     #CTABLECACHE.W
        JSR     DOSINTRAWLOADSECTOR.W
        BCS     @FAIL
        PLY
        PLX
+       TXA
        ASL     A
        AND     #$01FF
        TAX
        LDA     CTABLECACHE.W,X
        CLC
        RTS
@FAIL   STZ     DOSCTBLCACHSECT.B
        PLY
        PLX
        RTS

; write back cached directory
DOSDIRWRITEBACKRAW:
        LDA     DOSADIRDIRTY.B
        BEQ     +
        STZ     DOSADIRDIRTY.B
        PHX
        LDX     #DIRCHUNKCACHE.W
        PHY
        LDY     DOSCACHEDDIRCH.B
        JSR     DOSSTORECHUNK.W
        ; TODO: handle failure, which usually means bad sector or disk removed
        PLY
        PLX
+       RTS

; assumes B=$80 D=DOSPAGE
; makes sure DOSACTIVEDRIVE is the currently active drive
; C=1 if error, C=0 if success
DOSPAGEINACTIVEDRIVE:
        LDA     DOSACTIVEDRIVE.B
        CMP     DOSCACHEDDRIVE.B
        BNE     @DO
        CLC
        RTS
@DO     PHA
        LDA     DOSCACHEDDRIVE.B
        STA     DOSACTIVEDRIVE.B

        JSR     DOSFLUSHALLFILES.W
        BCS     @FAIL
        JSR     DOSWRITEBACK.W
        BCS     @FAIL
        ; since we write back the directory above, we can
        ; invalidate dir chunk cache
        STZ     DOSCACHEDDIRCH.B
        ; same with ctable cache
        STZ     DOSCTBLCACHSECT.B
        STZ     DOSCTABLEDIRTY.B

        PLA
        STA     DOSACTIVEDRIVE.B

@POST
        JSR     DOSLOADFSMB.W
        BCS     @FAIL2
        JSR     DOSVERIFYVOLUME.W
        BCS     @FAIL2
        JSR     DOSLOADCTABLE.W
        BCS     @FAIL2

@ALLOK
        ; get current directory of new drive
        LDA     DOSACTIVEDRIVE.B
        DEC     A
        ASL     A
        TAX
        LDA     DOSDRIVEDIRS.B,X
        STA     DOSACTIVEDIR.B

        CLC
        RTS

@FAIL   STA     1,S
        PLA
        SEC
        RTS

@FAIL2  SEC
        RTS

; assumes B=$80 D=DOSPAGE
; makes sure DIRCHUNKCACHE contains the chunk in A
; C=1 if error, C=0 if success
DOSPAGEINACTIVEDIR:
        CMP     DOSCACHEDDIRCH.B
        BEQ     +
        ACC16
        PHA
        JSR     DOSDIRWRITEBACK.W
        ACC16
        PLA
        ;BCS     @FAIL2
        STA     DOSCACHEDDIRCH.B
        PHX
        LDX     #DIRCHUNKCACHE.W
        PHY
        LDY     DOSCACHEDDIRCH.B
@LOAD   JSR     DOSLOADCHUNK.W
        BCS     @FAIL
        PLY
        PLX
+       CLC
        RTS
@FAIL   PLY
        PLX
@FAIL2  STZ     DOSCACHEDDIRCH.B
+       SEC
        RTS

; compare filename between DOSSTRINGCACHE,X (null-terminated; no *?) and 
;                          DIRCHUNKCACHE,Y
; result: BEQ/BNE
DOSCMPFILENAME:
        ACC8
@NEXTCHAR:
        TYA
        AND     #$1F
        CMP     #$0C
        BEQ     @YMUSTBEDOT
        CMP     #$10
        BCS     @XMUSTBEOVER2
        LDA     DIRCHUNKCACHE.W,Y
        CMP     #' '
        BEQ     @SKIPY
        CMP     DOSSTRINGCACHE.W,X
        BNE     @COMPDIFF
        INX
@SKIPY  INY
        BRA     @NEXTCHAR
@YMUSTBEDOT:
        LDA     DIRCHUNKCACHE.W,Y
        CMP     #'.'
        BNE     @COMPDIFF
        LDA     DIRCHUNKCACHE+1.W,Y
        CMP     #' '
        BEQ     @XMUSTBEOVER
@XMUSTBEDOT:
        LDA     DOSSTRINGCACHE,X
        CMP     #'.'
        BNE     @COMPDIFF
        INX
        INY
        BRA     @NEXTCHAR
@XMUSTBEOVER:
        LDA     DOSSTRINGCACHE,X
        BNE     @COMPDIFF
        BRA     @COMPOK
@XMUSTBEOVER2:
        LDA     DOSSTRINGCACHE,X
        BNE     @COMPDIFF
@COMPOK:
        ACC16
        LDA     #0
        RTS
@COMPDIFF:
        ACC16
        LDA     #$FFFF
        RTS

; compare filename between DOSSTRINGCACHE,X (null-terminated; *? ok) and 
;                          DIRCHUNKCACHE,Y
; result: BEQ/BNE
DOSCMPFILENAMEWC:
        ACC8
        LDA     DOSSTRINGCACHE.W,X
        BEQ     @COMPOK
@NEXTCHAR:
        TYA
        AND     #$1F
        CMP     #$0C
        BEQ     @YMUSTBEDOT
        CMP     #$10
        BCS     @XMUSTBEOVER2
        LDA     DIRCHUNKCACHE.W,Y
        CMP     #' '
        BEQ     @SKIPY
        CMP     DOSSTRINGCACHE.W,X
        BNE     @NOMATCH
@FINE   INX
@SKIPY  INY
        BRA     @NEXTCHAR
@YMUSTBEDOT:
        LDA     DIRCHUNKCACHE.W,Y
        CMP     #'.'
        BNE     @COMPDIFF
        LDA     DIRCHUNKCACHE+1.W,Y
        CMP     #' '
        BEQ     @XMUSTBEOVER
@XMUSTBEDOT:
        LDA     DOSSTRINGCACHE,X
        CMP     #'.'
        BNE     @COMPDIFF
        INX
        INY
        BRA     @NEXTCHAR
@XMUSTBEOVER:
        LDA     DOSSTRINGCACHE,X
        BNE     @COMPDIFF
        BRA     @COMPOK
@XMUSTBEOVER2:
        LDA     DOSSTRINGCACHE,X
        BNE     @COMPDIFF
@COMPOK:
        ACC16
        LDA     #0
        RTS
.ACCU 8
@XM:
        LDA     DIRCHUNKCACHE.W,Y
        BEQ     @COMPDIFF
        CMP     #' '
        BEQ     @COMPDIFF
        BNE     @FINE
@XS:
        BRA     DOSCMPFILENAMESTAR
@NOMATCH:
        LDA     DOSSTRINGCACHE.W,X
        CMP     #'?'
        BEQ     @XM
        CMP     #'*'
        BEQ     @XS
@COMPDIFF:
        ACC16
        LDA     #$FFFF
        RTS

.ACCU 8
DOSCMPFILENAMESTAR:
        ; match from end first
        PHX
        PHY
        ACC16
        TYA
        AND     #$E0
        ORA     #$0F
        TAY
        ACC8
-       INX
        LDA     DOSSTRINGCACHE.W,X
        BNE     -
        DEX
-       TYA
        AND     #$1F
        CMP     #2
        BCS     +
        LDA     DOSSTRINGCACHE.W,X
        BNE     @NOTMATCHLAST
        BRA     @MATCHOKLAST
+       LDA     DIRCHUNKCACHE.W,Y
        CMP     #' '
        BEQ     +
        CMP     DOSSTRINGCACHE.W,X
        BNE     @CHECKNOTSTAR
        DEX
+       DEY
        BRA     -
        PLY
        PLX
@CHECKNOTSTAR:
        LDA     DOSSTRINGCACHE.W,X
        CMP     #'*'
        BNE     @NOTMATCHLAST
        BRA     @FOUNDSTAREND
@NOTMATCHLAST:
        PLY
        PLX
@NOTMATCH:
        ACC16
        LDA     #$FFFF
        RTS
@MATCHOKLAST:
        PLY
        PLX
@MATCHOK:
        ACC16
        LDA     #$0000
        RTS
.ACCU 8
@FOUNDSTAREND:
        STX     DOSTMP5.B               ; final asterisk
        STY     DOSTMP6.B               ; end of matchable area
        PLY                             ; beginning of matchable area
        STY     DOSTMP8.B
        PLX                             ; after first asterisk
        DEX
@STARSEGLOOP:
        INX
        STX     DOSTMP7.B
@STARSEGLOOPNOINX:
        CPX     DOSTMP5.B
        BEQ     @MATCHOK
        BCS     @NOTMATCH
        ; pj = X, tj = Y, pi = T7, ti = T8, pe = T5, te = T6
@STARLOOP:
        LDA     DOSSTRINGCACHE.W,X
        CMP     #'*'
        BEQ     @STAREND
        CMP     DIRCHUNKCACHE.W,Y
        BNE     @STARINCY
        CPY     DOSTMP6.B
        BCS     @NOTMATCH
        INX
        INY
        BRA     @STARLOOP
@STAREND:
        STY     DOSTMP8.B
        LDX     DOSTMP7.B
        BRA     @STARSEGLOOP
@STARINCY:
        INC     DOSTMP8.B
        LDY     DOSTMP8.B
        LDX     DOSTMP7.B
        BRA     @STARSEGLOOPNOINX

.ACCU 16
; assumes B=$80 D=DOSPAGE
; path is checked from DOSSTRINGCACHE and may not contain wildcards
; if file found (C=0), result in DOSNEXTFILEDRV, *DIR, OFF
; else (C=1), A contains error code
; $0E = set active drive
DOSRESOLVEPATHFILE:
        JSR     DOSEXTRACTRESOLVEPATH
        BCC     DOSRESOLVEFILE
        RTS
; assumes B=$80 D=DOSPAGE
; name is checked from DOSSTRINGCACHE and may not contain wildcards or
;                               path separators (\)
; X is offset to that cache
; if file found (C=0), result in DOSNEXTFILEDRV, *DIR, OFF
; else (C=1), A contains error code
DOSRESOLVEFILE:
        STZ     DOSPREVDIRCHUNK.B
        JSR     DOSPAGEINACTIVEDRIVE.W
        LDA     DOSACTIVEDIR.B
        JSR     DOSPAGEINACTIVEDIR.W
        BCS     @ERR
        STX     DOSTMP3.B
@LDY    LDY     #0
-       STY     DOSTMP1.B
        ACC8
        LDA     DIRCHUNKCACHE.W,Y
        ACC16
        BMI     +                       ; free/deleted file slot
        INY
        INY
        JSR     DOSCMPFILENAME
        BEQ     @FOUND
+       LDX     DOSTMP3.B
        LDA     DOSTMP1.B
        CLC
        ADC     #$0020
        TAY
        CPY     #$0400                  ; end of directory chunk
        BCC     -
        BRA     @NCH
@FOUND  LDA     DOSTMP1.B
        AND     #$FFE0
        STA     DOSNEXTFILEOFF.B
        LDA     DOSACTIVEDRIVE.B
        STA     DOSNEXTFILEDRV.B
        LDA     DOSCACHEDDIRCH.B
        STA     DOSNEXTFILEDIR.B
        CLC
        RTS
@NOTF   LDA     #DOS_ERR_FILE_NOT_FOUND
@ERR    SEC
        RTS
@NCH    LDX     DOSCACHEDDIRCH.B
        STX     DOSPREVDIRCHUNK.B
        JSR     DOSNEXTCHUNK.W
        BCS     @ERR
        CPX     #$FFFF
        BEQ     @NOTF
        JSR     DOSDIRWRITEBACK.W
        STX     DOSCACHEDDIRCH.B
        TXY
        LDX     #DIRCHUNKCACHE.W
        JSR     DOSLOADCHUNK.W
        BCS     @ERR
        LDX     DOSTMP3.B
        BRL     @LDY

.ACCU 8
; switch drive according to letter at DOSSTRINGCACHE
DOSPATHSWITCHDRIVE:
        LDA     DOSSTRINGCACHE.W
        AND     #$DF
        CMP     #'A'
        BCC     @INVALIDPATH
        CMP     #'Z'+1
        BCS     @INVALIDPATH
        SEC
        SBC     #'A'-1
        CMP     #DOSMAXDRIVES+1
        BCS     @INVALIDPATH
        ACC16
        AND     #$001F
        STA     DOSACTIVEDRIVE.B

        PHX
        PHY
        JSR     DOSPAGEINACTIVEDRIVE.W
        PLY
        PLX
        RTS
@INVALIDPATH:
        ACC16
        LDA     #DOS_ERR_BAD_PATH
        ACC8
        SEC
        RTS
@FAIL   PLY
        PLX
        SEC
        RTS

DOSEXTRACTRESOLVEPATH:
        LDX     #0
        STX     DOSTMP3.B
        DEX
        ACC8
-       INX
        LDA     DOSSTRINGCACHE.W,X
        BNE     -
        CPX     #2
        BCC     +
        LDA     DOSSTRINGCACHE+1.W
        CMP     #':'
        BNE     +
        JSR     DOSPATHSWITCHDRIVE
        BCS     @RTS
        ACC16
        LDA     #2
        STA     DOSTMP3.B
        ACC8
+
; find last backslash
-       DEX
        BMI     @CLC                            ; no backslash
        LDA     DOSSTRINGCACHE.W,X
        CMP     #'\'
        BNE     -
        CPX     #0
        BEQ     @BS0
@OK     STZ     DOSSTRINGCACHE.W,X
        ACC16
        INX
        STX     DOSTMP4.B
        LDX     DOSTMP3.B
        JSR     DOSRESOLVEPATH_INT
        ACC8
        PHA
        LDX     DOSTMP4.B
        LDA     #'\'
        STA     DOSSTRINGCACHE-1.W,X
        PLA
        ACC16
        RTS
.ACCU 8
@CLC    LDX     #0
        LDA     DOSSTRINGCACHE.W
        BEQ     +
        LDA     DOSSTRINGCACHE+1.W
        CMP     #':'
        BNE     +
        LDX     #2
+       ACC16
        CLC
@RTS    RTS
.ACCU 8
@BS0    JSR     DOSGOTOROOT.W
        BCC     @OK
@BS0E   ACC16
        RTS

; copy current drive path to DOSPATHBUF
DOSSHIFTINPATH:
        ACC8
        JSR     DOSCURPATHTOX.W
        LDY     #DOSPATHBUF.W
        BRA     DOSCOPYPATHXY.W
        
; copy current drive path to DOSPATHBUF
DOSSHIFTOUTPATH:
        ACC8
        JSR     DOSCURPATHTOX.W
        TXY
        LDX     #DOSPATHBUF.W
        JMP     DOSCOPYPATHXY.W

; copy path from X to Y
; uses A, X, Y, DOSTMP8
DOSCOPYPATHXY:
        LDA     $0000.W,X
        STA     $0000.W,Y
        STA     DOSTMP8.B
        LDA     DOSTMP8.B
-       BEQ     +
        INX
        INY
        LDA     $0000.W,X
        STA     $0000.W,Y
        DEC     DOSTMP8.B
        BRA     -
+       LDA     #0
        STA     $0001.W,Y
        ACC16
        RTS

; stores length of null-terminated buffer starting at DOSTMP2.B to
;                                                     DOSTMP8.B
DOSBUFPATHSTRLEN:
        PHX
        ACC16
        STZ     DOSTMP8.B
        LDX     DOSTMP2.B
-       ACC8
        LDA     DOSSTRINGCACHE.W,X
        BEQ     +
        INX
        ACC16
        INC     DOSTMP8.B
        BRA     -
+       PLX
        ACC8
        RTS

; assumes B=$80 D=DOSPAGE
DOSMAYBEAPPENDPATH:
        ACC8
        LDA     DOSUPDATEPATH.B
        BNE     DOSAPPENDPATH
        ACC16
        CLC
        RTS
@EMPT   ACC16
        PLA
        CLC
        RTS
.ACCU 8
DOSAPPENDPATH:
        ACC16
        LDX     #DOSPATHBUF.W
        LDA     $0000.W,X
        AND     #$FF
        PHX
        CLC
        ADC     1,S
        INC     A
        PLX
        TAY
        ; X = beginning of path string buffer
        ; Y = next character
        ACC8
        PHX
        LDX     DOSTMP2.B
        LDA     DOSSTRINGCACHE.W,X
        BEQ     DOSMAYBEAPPENDPATH@EMPT
        CMP     #'.'
        BNE     ++
        LDA     DOSSTRINGCACHE+1.W,X
        BEQ     DOSMAYBEAPPENDPATH@EMPT
        CMP     #'.'
        BNE     ++
        LDA     DOSSTRINGCACHE+2.W,X
        BNE     ++
        JMP     @REVERSE
++      PLX
        ; no initial backslash for string
        LDA     $0000.W,X
        BEQ     @COPYREST
@BACKSLASH:
        LDA     $0000.W,X
        CMP     #$7F
        BCS     @PATHTOOLONG
        LDA     #$5C
        STA     $0000.W,Y
        INC     $0000.W,X
        INY
@COPYREST:
        JSR     DOSBUFPATHSTRLEN.W
        LDA     $0000.W,X
        ACC16
        AND     #$FF
        CLC
        ADC     DOSTMP8.B
        CMP     #$7E
        BCS     @PATHTOOLONG
        ACC8
        STA     $0000.W,X
        LDX     DOSTMP2.B
        DEX
        DEY
-       INX
        INY
        LDA     DOSSTRINGCACHE.W,X
        STA     $0000.W,Y
        BNE     -
        CLC
        RTS
@PATHTOOLONG:
        ACC16
        LDA     #DOS_ERR_BAD_PATH.W
        SEC
        RTS

@REVERSE:
        PLX
.ACCU 8
        ; X = beginning of path string buffer
        ; Y = next character
        DEY
-       LDA     $0000.W,Y
        CMP     #$5C
        BEQ     +
        LDA     #0
        STA     $0000.W,Y
        DEY
        DEC     $0000.W,X
        BNE     -
+       LDA     #0
        STA     $0000.W,Y
        CLC
        RTS

; go to root directory
DOSGOTOROOT:
        ACC16
        LDA     #1
        STA     DOSACTIVEDIR.B
        ACC8
        LDA     DOSUPDATEPATH.B
        BEQ     +
        PHX
        STZ     DOSPATHBUF.W
        PLX
+       ACC8
        CLC
        RTS

; assumes B=$80 D=DOSPAGE
; path is checked from DOSSTRINGCACHE and may not contain wildcards
; X is offset to that cache
; if path found (C=0), ACTIVEDIR set to that path
; else (C=1), A contains error code
DOSRESOLVEPATH:
        ACC8
        LDA     DOSSTRINGCACHE.W
        BEQ     ++
        LDA     DOSSTRINGCACHE+1.W
        CMP     #':'
        BNE     ++
        JSR     DOSPATHSWITCHDRIVE
        PHP
        CPX     #2
        BCC     +
        LDX     #2
+       PLP
        BCC     ++
        RTS
++
DOSRESOLVEPATH_INT:
        ACC8
        LDA     DOSSTRINGCACHE.W,X
        BEQ     @NOPATH
        CMP     #'\'
        BNE     @LOOP
        JSR     DOSGOTOROOT.W
        INX
@LOOP:  ; find next backslash and replace it with '\0'
        STX     DOSTMP2.B
        STZ     DOSTMP9.B
        LDA     DOSSTRINGCACHE.W,X
        BEQ     @NOPATH
        CMP     #'\'
        BEQ     @BADPATH
-       INX
        LDA     DOSSTRINGCACHE.W,X
        BEQ     ++
        CMP     #'\'
        BNE     -
+       LDA     DOSSTRINGCACHE.W,X
        STA     DOSTMP9.B
        LDA     #0
        STA     DOSSTRINGCACHE.W,X
++      PHX
        LDX     DOSTMP2.B                       ; original X value
        ACC16
        JSR     DOSRESOLVEFILE.W
        BCS     @FILERESVFAILED
        JSR     DOSMAYBEAPPENDPATH.W
        BCS     @FILERESVFAILED
        PLX
        ACC8
        LDA     DOSTMP9.B
        STA     DOSSTRINGCACHE.W,X
        BEQ     +
        INX
+       STX     DOSTMP2.B                       ; next address
; check if file is directory and move into it if so
        ACC16
        LDA     DOSNEXTFILEOFF.B
        CLC
        ADC     #DIRCHUNKCACHE.W
        STA     DOSTMP5.B
        ACC8
        LDY     #0
        LDA     (DOSTMP5.B),Y
        AND     #$40
        BEQ     @NOTFOLDER                      ; not folder???
        ACC16
        LDY     #$1E
        LDA     (DOSTMP5.B),Y
        STA     DOSACTIVEDIR.B
        ACC8
        LDX     DOSTMP2.B
        BRA     @LOOP

@NOPATH ACC16
        CLC
        RTS
@BADPATH:
        ACC16
        LDA     #DOS_ERR_BAD_PATH
        SEC
        RTS
@FILERESVFAILED:
        ACC8
        PLX
        PHA
        LDA     #'\'
        STA     DOSSTRINGCACHE.W,X
        PLA
        ACC16
        CMP     #DOS_ERR_FILE_NOT_FOUND
        BNE     +
        LDA     #DOS_ERR_PATH_NOT_FOUND
+       SEC
        RTS
@NOTFOLDER:
        ACC16
        LDA     #DOS_ERR_PATH_NOT_FOUND
        SEC
        RTS

; assumes B=$80 D=DOSPAGE
; path is checked from DOSSTRINGCACHE and may contain wildcards, but not
;                               path separators (\)
; X is offset to that cache
; DOSNEXTFILEDRV is drive
; DOSNEXTFILEDIR is directory (chunk)
; DOSNEXTFILEOFF is offset into chunk
; else (C=1), A contains error code
DOSRESOLVENEXTFILE:
        STX     DOSTMP3.B
        STZ     DOSPREVDIRCHUNK.B
        LDA     DOSNEXTFILEDRV.B
        STA     DOSACTIVEDRIVE.B
        JSR     DOSPAGEINACTIVEDRIVE.W
        LDA     DOSNEXTFILEDIR.B
        JSR     DOSPAGEINACTIVEDIR.W
        BCS     @ERR
        LDY     DOSNEXTFILEOFF.B
        CPY     #$0400.W
        BCS     @NCH
-       STY     DOSTMP1.B
        ACC8
        LDA     DIRCHUNKCACHE.W,Y
        ACC16
        BMI     +                       ; free/deleted file slot
        INY
        INY
        JSR     DOSCMPFILENAMEWC
        BEQ     @FOUND
+       LDX     DOSTMP3.B
        LDA     DOSTMP1.B
        CLC
        ADC     #$0020
        TAY
        CPY     #$0400.W                ; end of directory chunk
        BCC     -
        BRA     @NCH
@FOUND  LDA     DOSTMP1.B
        AND     #$FFE0
        STA     DOSNEXTFILEOFF.B
        LDA     DOSACTIVEDRIVE.B
        STA     DOSNEXTFILEDRV.B
        LDA     DOSCACHEDDIRCH.B
        STA     DOSNEXTFILEDIR.B
        CLC
        RTS
@NOTF   LDA     #DOS_ERR_FILE_NOT_FOUND
@ERR    SEC
        RTS
@NCH    LDX     DOSCACHEDDIRCH.B
        STX     DOSPREVDIRCHUNK.B
        JSR     DOSNEXTCHUNK.W
        BCS     @ERR
        CPX     #$FFFF
        BEQ     @NOTF
        JSR     DOSDIRWRITEBACK.W
        STX     DOSCACHEDDIRCH.B
        TXY
        LDX     #DIRCHUNKCACHE.W
        JSR     DOSLOADCHUNK.W
        BCS     @ERR
        LDX     DOSTMP3.B
        LDY     #2
        BRL     -

; assumes B=$80 D=DOSPAGE
; starting a write operation on chunk table or directory entries
DOSSTARTDIRWRITE:
        PHP
        ACC16
        LDA     FSMBCACHE+6.W
        ORA     #$8000
        STA     FSMBCACHE+6.W
        JSR     DOSWRITEFSMB.W
        PLP
        RTS

; assumes B=$80 D=DOSPAGE
; finishing a write operation on chunk table or directory entries
DOSENDDIRWRITE:
        PHP
        ACC16
        LDA     FSMBCACHE+6.W
        ORA     #$8000
        STA     FSMBCACHE+6.W
        JSR     DOSWRITEFSMB.W
        PLP
        RTS

; X = pointer to current path in bank $80 for currently selected drive
DOSCURPATHTOX:
        ACC16
        LDA     DOSACTIVEDRIVE.B
        AND     #$FF
        DEC     A
        ; A = A << 7
        XBA
        LSR     A
        CLC
        ADC     #DOSPATHSTR.W
        TAX
        ACC8
        RTS

DOSNEXTFREEHANDLESLOT:
        LDX     #0
        LDY     #OPENFILES
        ACC8
-       LDA     DOSFILETABLE.W,X
        BMI     @FOUND
        ACC16
        TXA
        CLC
        ADC     #$0030
        TAX
        DEY
        BNE     -
        LDA     #DOS_ERR_NO_MORE_FILES
        SEC
        RTS
@FOUND  CLC
        RTS

DOSALLOWEDTOOPENFILE:
        LDA     DOSTMP1.B
        CMP     #1
        BEQ     +
        LDX     DOSNEXTFILEOFF.B
        LDA     DIRCHUNKCACHE.W,X
        AND     #$0100
        BNE     @ERR                    ; cannot open read-only files with W
+       LDA     DIRCHUNKCACHE.W,X
        AND     #$0040
        BNE     @ERR                    ; cannot open subdir as file
        LDX     #0
        LDY     #OPENFILES
        ACC8
-       LDA     DOSFILETABLE.W,X
        BPL     @SKIP
        LDA     DOSTMP1.B
        ACC16
        LDA     DOSFILETABLE+$10.W,X
        CMP     DOSNEXTFILEDIR
        BNE     @SKIP
        LDA     DOSFILETABLE+$12.W,X
        CMP     DOSNEXTFILEOFF
        BNE     @SKIP
        LDA     DOSFILETABLE+$20.W,X
        AND     #$1F
        CMP     DOSNEXTFILEDRV
        BNE     @SKIP
        LDA     DOSTMP1.B
        CMP     #1
        BNE     @ERR
        LDA     DOSFILETABLE+$24.W,X
        AND     #$FF
        CMP     #1
        BEQ     @SKIP
@ERR    LDA     #DOS_ERR_ACCESS_DENIED.W
        SEC
        RTS
@SKIP   ACC16
        TXA
        CLC
        ADC     #$0030
        TAX
        DEY
        BNE     -
        CLC
        RTS

; flush all open file handle caches
; directory entries are NOT updated
; assumes B=$80 D=DOSPAGE
DOSFLUSHALLFILES:
        LDX     #DOSFILETABLE.W
        LDY     #OPENFILES
-       ACC8
        LDA     $0000.W,X
        BMI     @SKIP
        LDA     $0024.W,X
        AND     #$FF
        CMP     #1
        BEQ     @SKIP
        LDA     $0021.W,X
        BPL     @SKIP
        ACC16
        PHX
        PHY
        JSR     DOSFLUSHFILE.W
        PLY
        PLX
@SKIP   ACC16
        TXA
        CLC
        ADC     #$0030
        TAX
        DEY
        BNE     -
        CLC
        RTS

.MACRO CONVERTFILECACHEPOINTER
.ACCU 16
        AND     #$FF
        XBA
        ASL     A
        ASL     A
        CLC
        ADC     #FILECACHES
.ENDM

; pages in file to cache
; assumes B=$80 D=DOSPAGE
; X=handle
; C=1 in case of error
DOSPAGEINFILE:
        ACC8
        LDA     $0024.W,X
        AND     #$01
        BEQ     @NOCACHE
        LDA     $0021.W,X
        BPL     @RET
        LDA     DOSLASTFCACHE.B
        STA     DOSTMP8.B
        ; evict file if the cache is already used
        JSR     DOSEVICTFILE.W
        ; load chunk
        PHX
        LDY     $0018.W,X
        LDA     DOSTMP8.B
        ACC16
        AND     #$FF
        CONVERTFILECACHEPOINTER
        TAX
        JSR     DOSLOADCHUNK.W
        BCS     @ERR
        PLX
        ACC8
        LDA     DOSTMP8.B
        STA     $0021.W,X
@RET    CMP     DOSLASTFCACHE.B
        BNE     +
        LDA     DOSLASTFCACHE.B
        INC     A
        ACC16
        AND     #NUMFILECACHES-1
        STA     DOSLASTFCACHE.B
+       CLC
        RTS
@NOCACHE:
        ACC16
        CLC
        RTS
@ERR    PLX
        SEC
        RTS

; makes sure cache slot at DOSTMP8.B is unused
; assumes B=$80 D=DOSPAGE
DOSEVICTFILE:
        LDX     #DOSFILETABLE.W
        LDY     #OPENFILES
        ACC8
-       LDA     $0000.W,X
        BMI     @SKIP
        LDA     $0021.W,X
        CMP     DOSTMP8.B
        BNE     @SKIP
        ACC16
        BRA     DOSFLUSHFILE.W
@SKIP   ACC16
        TXA
        CLC
        ADC     #$0030
        TAX
        DEY
        BNE     -
        CLC
        RTS
; flushes file cache
; assumes B=$80 D=DOSPAGE
; X=handle
DOSFLUSHFILE:
        LDA     $0000.W,X
        AND     #$0080
        BNE     @RET
        LDA     $0024.W,X
        AND     #$00FF
        CMP     #1
        BEQ     @RET
        ACC8
        LDA     $0021.W,X
        BPL     @RET
        PHX
        LDY     $0018.W,X
        LDA     $0021.W,X
        ACC16
        CONVERTFILECACHEPOINTER
        TAX
        JSR     DOSSTORECHUNK.W
        PLX
        ACC8
        LDA     #$FF
        STA     $0021.W,X
@RET    ACC16
        CLC
        RTS

; validate file name at string buffer offset X
; cache clear if OK, cache set with error if not
DOSVALIDATEFILENAME:
        ACC8
        PHX
        DEX
-       INX
        LDA     DOSSTRINGCACHE.W,X
        BEQ     +
        TAX
        LDA     DOSBANKC|DOSFNVALIDCHARS.L,X
        BEQ     @ERR
+       PLX
        ACC16
        CLC
        RTS
@ERR    PLX
        ACC16
        LDA     #DOS_ERR_CREATE_ERROR
        SEC
        RTS

DOSFNVALIDCHARS:
        .DB     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .DB     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .DB     0,1,0,1,1,1,1,1,1,1,0,0,0,1,0,0
        .DB     1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,0
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        .DB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

; opens file handle
; assumes B=$80 D=DOSPAGE
; either DOSFILEDEVICE (=/= 0) contains device number, or
;       DOSNEXTFILEDRV is drive
;       DOSNEXTFILEDIR is directory (chunk)
;       DOSNEXTFILEOFF is offset into chunk
; X=mode (1=read, 2=write, 3=read/write)
; Y=job ID
; if success (C=0), A contains new file handle to place in local table
; else (C=1), A contains error code
DOSOPENHANDLE:
.ACCU 16
        STX     DOSTMP1.B
        STY     DOSTMP4.B
        LDA     DOSFILEDEVICE.B
        BEQ     +
        JMP     DOSOPENHANDLEDEV
+       JSR     DOSALLOWEDTOOPENFILE
        BCS     @ERR
        JSR     DOSNEXTFREEHANDLESLOT
        BCS     @ERR
; import file handle from directory entry

        LDA     DOSNEXTFILEOFF.W
        CLC
        ADC     #DIRCHUNKCACHE
        STA     DOSTMP2.B

        LDY     #0
        LDA     (DOSTMP2.B),Y
        AND     #$C0
        BNE     @SUBDIR         ; cannot open subdirs or deleted files

        LDY     #30
        TXA
        CLC
        ADC     #DOSFILETABLE.W
        STA     DOSTMP3.B

-       LDA     (DOSTMP2.B),Y
        STA     (DOSTMP3.B),Y
        DEY
        DEY
        BPL     -

; reset other values
; directory chunk
        LDA     DOSNEXTFILEDIR.B
        STA     DOSFILETABLE+$10.W,X
; directory offset
        LDA     DOSNEXTFILEOFF.B
        STA     DOSFILETABLE+$12.W,X
; current offset
        STZ     DOSFILETABLE+$14.W,X
        STZ     DOSFILETABLE+$16.W,X
; current chunk
        LDA     DOSFILETABLE+$1E.W,X
        STA     DOSFILETABLE+$18.W,X
; drive number; $FF for current file cache for no cache
        LDA     DOSNEXTFILEDRV.B
        AND     #$001F
        ORA     #$FF00
        STA     DOSFILETABLE+$20.W,X
; job ID
        LDA     DOSTMP4.B
        STA     DOSFILETABLE+$22.W,X
; file mode
        LDA     DOSTMP1.B
        STA     DOSFILETABLE+$24.W,X
; last chunk
        LDA     DOSFILETABLE+$1E.W,X
        PHX
        TAX
-       STX     DOSTMP4.B
        JSR     DOSNEXTCHUNK.W
        BCS     @ERRF
        CPX     #$FFFF
        BNE     -
        PLX
        LDA     DOSTMP4.B
        STA     DOSFILETABLE+$2E.W,X

        LDA     DOSTMP3.B
        CLC
        RTS
@ERRF   PLX
        PHA
        LDA     #$FFFF
        STA     DOSFILETABLE+$2E.W,X
        PLA
@ERR    SEC
        RTS
@SUBDIR
        lDA     #DOS_ERR_ACCESS_DENIED.W
        SEC
        RTS

; return file handle for device according to DOSFILEDEVICE
DOSOPENHANDLEDEV:
        STP;TODO

; check if file handle is valid
; SEC and A set if handle invalid
; else all registers preserved except P
; assumes B=$80 D=DOSPAGE
; X=handle itself
DOSVERIFYHANDLE:
        CPX     #$0000
        BEQ     @INVALID
        CPX     #$0001                  ; console device
        BNE     @INVALID
        CPX     #DOSFILETABLE.W
        BCC     @INVALID
        CPX     #DOSFILETABLE.W+$0030*OPENFILES.W
        BCS     @INVALID
        CLC
        RTS
@INVALID:
        LDA     #DOS_ERR_BAD_FILE_HANDLE
        SEC
        RTS

DOSPACKDATE:
        RESERVEDMA1

        ACC16
        LDA     #$8080
        STA     DMA1BNKS.L
        LDA     #6
        STA     DMA1CNT.L
        LDA     #DOSDTETMECACHE
        STA     DMA1SRC.L
        LDA     #DOSDATEYEAR
        STA     DMA1DST.L

        ACC8
        LDA     #$90
        STA     DOSHALTCLOCK.W
        STA     DMA1CTRL.L
        
-       LDA     DMA1STAT.L
        BMI     -

        FREEDMA1

        ACC8
        STZ     DOSHALTCLOCK.W

        ; DOSDTETMECACHE: year, month, day, hour, minute, second
        ACC16
        STZ     DOSFILEDTCACHE.W
        STZ     DOSFILEDTCACHE+1.W
        STZ     DOSFILEDTCACHE+3.W
        
        LDA     DOSDTETMECACHE.W                ; year
        AND     #$FF
        ASL     A
        ASL     A
        XBA
        TSB     DOSFILEDTCACHE.W
        
        LDA     DOSDTETMECACHE+1.W              ; month
        AND     #$FF
        XBA
        LSR     A
        LSR     A
        XBA
        TSB     DOSFILEDTCACHE+1.W
        
        LDA     DOSDTETMECACHE+2.W              ; day
        AND     #$FF
        ASL     A
        XBA
        TSB     DOSFILEDTCACHE+2.W
        
        LDA     DOSDTETMECACHE+3.W              ; hour
        AND     #$FF
        ASL     A
        ASL     A
        ASL     A
        ASL     A
        XBA
        TSB     DOSFILEDTCACHE+2.W
        
        LDA     DOSDTETMECACHE+4.W              ; minute
        AND     #$FF
        XBA
        LSR     A
        XBA
        TSB     DOSFILEDTCACHE+3.W
        
        LDA     DOSDTETMECACHE+4.W              ; second
        AND     #$FF
        TSB     DOSFILEDTCACHE+4.W

        LDY     #$15
        LDA     DOSFILEDTCACHE.W
        STA     (DOSTMP2.B),Y
        LDA     DOSFILEDTCACHE+1.W
        LDY     #$16
        STA     (DOSTMP2.B),Y
        LDA     DOSFILEDTCACHE+3.W
        LDY     #$18
        STA     (DOSTMP2.B),Y

        ACC16
        RTS

; closes file handle and updates directory entry
; local file table must be updated afterwards to replace handle with 0
; assumes B=$80 D=DOSPAGE
; X=handle itself
; should call DOSWRITEBACK afterwards!
DOSCLOSEHANDLE:
.ACCU 16
        CPX     #DOSFILETABLE
        BCC     @NOCLOSE
        CPX     #DOSFILETABLE+$0030*OPENFILES
        BCS     @NOCLOSE
        JSR     DOSFLUSHFILE.W
        BCS     @CLOSEERR0
        PHX

; maybe update directory entry
        LDA     $0024.W,X
        AND     #2
        BEQ     ++

        LDA     DOSFILETABLE+$20.W,X
        AND     #$FF
        STA     DOSACTIVEDRIVE.B
        JSR     DOSPAGEINACTIVEDRIVE.W
        BCS     @CLOSEERR0

        LDA     $0010.W,X
        JSR     DOSPAGEINACTIVEDIR.W
        BCS     @CLOSEERR0
        LDA     #$FFFF
        STA     DOSADIRDIRTY.B

        LDA     $0012.W,X
        CLC
        ADC     #DIRCHUNKCACHE
        STA     DOSTMP2.B

        LDY     #$1A
        LDA     $001A.W,X
        STA     (DOSTMP2.B),Y
        
        LDY     #$1C
        LDA     $001C.W,X
        STA     (DOSTMP2.B),Y

        LDY     #$1E
        LDA     $001E.W,X
        STA     (DOSTMP2.B),Y

        JSR     DOSPACKDATE.W

; clear out file entry in global table
        LDA     1,S
        TAX
++      LDY     #$18
        LDA     #$00FF          ; FF 00 FF 00 ...
-       STA     $0000,X
        INX
        INX
        DEY
        BNE     -
        PLX
@NOCLOSE:
        RTS

@CLOSEERR0:
        LDX     #0
        SEC
        RTS
@CLOSEERR1:
        LDX     #1
        SEC
        RTS

; (pages in file and) hands current cache address in A
; assumes B=$80 D=DOSPAGE
; X = file handle
; C=1 if error
DOSFILEHANDLECONVADDR:
.ACCU 16
        JSR     DOSPAGEINFILE.W
        BCS     +
        LDA     $0021.W,X
        CONVERTFILECACHEPOINTER
+       RTS

; number of bytes remaining in current chunk for paged-in file
; assumes B=$80 D=DOSPAGE
; X=handle itself
; return value in A
DOSFILEREMBYTES:
        LDA     $0016.W,X
        CMP     $001E.W,X
        BNE     +
        LDA     $0014.W,X
        EOR     $001C.W,X
        AND     #$FC00
        BEQ     DOSFILEREMBYTESWRITE@LAST
DOSFILEREMBYTESWRITE:
+       LDA     $0014.W,X
        AND     #$03FF
        EOR     #$03FF
        RTS
@LAST   LDA     $001C.W,X
        SEC
        SBC     $0014.W,X
        RTS

; return if file is EOF
; assumes B=$80 D=DOSPAGE
; X=handle itself
; A =$0000 if file not at EOF
; A<>$0000 if file at EOF
DOSFILEEOF:
        LDA     $0016.W,X
        BMI     ++
        CMP     $001E.W,X
        BCC     ++
        BEQ     +
        LDA     #$FFFF
        RTS
+       LDA     $0014.W,X
        CMP     $001C.W,X
        BCC     ++
        LDA     #$FFFF
        RTS
++      LDA     #0
        RTS

; seek file handle to next chunk
; assumes B=$80 D=DOSPAGE
; X=handle itself
; C=0 A<>$0000 if next chunk loaded
; C=0 A =$0000 if no more remaining
; C=1 if error
DOSFILENEXTCHUNKREAD:
        JSR     DOSFLUSHFILE.W
        PHX
        LDA     $0018.W,X
        TAX
        JSR     DOSNEXTCHUNK.W
        BCS     @ERR
        CPX     #$FFFF
        BEQ     @ZERO
        TXA
        PLX
        STA     $0018.W,X
        JMP     DOSPAGEINFILENEXTCHUNK.W
@ZERO   PLX
        CLC
        LDA     #0
        RTS
@ERR    PLX
        SEC
        RTS


; free chunk
;       X=chunk to free
; assumes B=$80 D=DOSPAGE
; returns               C=0     
;                       C=1     A=error
DOSFREECHUNK:
        LDA     #$0000
; link chunk to previous chunk
;       A=next  X=previous
; assumes B=$80 D=DOSPAGE
; returns               C=0     
;                       C=1     A=error
DOSLINKCHUNK:
        STA     DOSTMP6.B
        LDA     DOSCTABLEINRAM.B
        BNE     DOSLINKCHUNKRAM

        TXA
        XBA
        AND     #$FF
        JSR     DOSCTABLEPARTLOAD.W
        
        TAX
        ASL     A
        TAX
        LDA     #$FFFF
        STA     DOSCTABLEDIRTY.B
        LDA     DOSTMP6.B
        STA     CTABLECACHE.W,X

        RTS
DOSLINKCHUNKRAM:
        LDA     #$FFFF
        STA     DOSCTABLEDIRTY.B
        LDA     DOSTMP6.B
        STA     CTABLECACHE.W,X
        CLC
        RTS

; free chunks in chain starting from chunk X
; assumes B=$80 D=DOSPAGE
; returns               C=0
;                       C=1     A  =error
DOSFREEMANYCHUNKS:
        PHX
        JSR     DOSNEXTCHUNK.W
        BCS     @ERRX
        STX     DOSTMP7.B
        PLX
        ; set chunk to be free
        JSR     DOSFREECHUNK.W
        BCS     @ERR
        LDX     DOSTMP7.B
        CPX     #$FFFF
        BNE     DOSFREEMANYCHUNKS
        PLX
        CLC
        RTS
@ERRX   PLX
@ERR    SEC
        RTS

; A=number of free sectors
; assumes B=$80 D=DOSPAGE
DOSCOUNTFREESECTORS:
        ; TODO: cache result
        ACC16
        STZ     DOSTMP7.B
        JSR     DOSPAGEINACTIVEDRIVE.W
        BCS     @ERR
        LDA     DOSCTABLEINRAM.B
        BNE     DOSCOUNTFREESECTORS@RAM
@TRYALLCTABLESECS:
        STZ     DOSTMP6.B
--      LDA     DOSTMP6.B
        JSR     DOSCTABLEPARTLOAD.W
        BCS     +
-       LDA     CTABLECACHE.W,X
        BNE     +
        INC     DOSTMP7.B
+       INX
        INX
        CPX     #$0200
        BCC     -
        LDA     DOSTMP6.B
        INC     A
        STA     DOSTMP6.B
        CMP     FSMBCACHE+$16.W
        BCC     --
        CLC
+       LDA     DOSTMP7.B
@ERR    RTS

@RAM    LDA     FSMBCACHE+$12.W
        ASL     A
        INC     A
        STA     DOSTMP8.W
        LDX     #0
@LOOP   LDA     CTABLECACHE.W,X
        BNE     +
        INC     DOSTMP7.B
+       INX
        INX
        CPX     DOSTMP8.W
        BCC     @LOOP
        LDA     DOSTMP7.B
        CLC
        RTS

; allocates chunk for new files
; assumes B=$80 D=DOSPAGE
; returns               C=0     A&X=new chunk
;                       C=1     A  =error
DOSALLOCATENEWFILECHUNK:
        ACC16
        LDA     DOSCTABLEINRAM.B
        BNE     DOSALLOCATENEWFILECHUNKRAM

        ; go over currently cached CTABLE first to find space
        LDX     #0
-       LDA     CTABLECACHE.W,X
        BEQ     @FOUND
        TXA
        CLC
        ADC     #$08
        TAX
        CMP     #$0200
        BCC     -
        BRA     DOSALLOCATECHUNK
@FOUND:
        LDA     #$FFFF
        STA     DOSCTABLEDIRTY.B
        STA     CTABLECACHE.W,X
        TXA
        LSR     A
        PHA
        LDA     DOSCTBLCACHSECT.B
        XBA
        AND     #$FF00
        INC     A
        INC     A
        CLC
        ADC     1,S
        PLX
        TAX
        CLC
        RTS

DOSALLOCATENEWFILECHUNKRAM:
DOSALLOCATECHUNKRAM:
        LDA     FSMBCACHE+$12.W
        ASL     A
        INC     A
        STA     DOSTMP6.W
        LDX     #0
@LOOP   LDA     CTABLECACHE.W,X
        BEQ     @FOUND
        INX
        CPX     DOSTMP6.W
        BCC     @LOOP
        LDA     #DOS_ERR_DRIVE_FULL.W
        SEC
        RTS
@FOUND:
        LDA     #$FFFF
        STA     DOSCTABLEDIRTY.B
        STA     CTABLECACHE.W,X
        TXA
        CLC
        RTS

; allocate chunk for anything else
; assumes B=$80 D=DOSPAGE
; returns               C=0     A=new chunk
;                       C=1     A=error
DOSALLOCATECHUNK:
        LDA     DOSCTABLEINRAM.B
        BNE     DOSALLOCATECHUNKRAM

        ; go over currently cached CTABLE first to find space
        LDX     #0
-       LDA     CTABLECACHE.W,X
        BEQ     DOSALLOCATENEWFILECHUNK@FOUND
        INX
        INX
        CPX     #$0200
        BCC     -
@TRYALLCTABLESECS:
        STZ     DOSTMP6.B
--      LDA     DOSTMP6.B
        JSR     DOSCTABLEPARTLOAD.W
        BCS     +
-       LDA     CTABLECACHE.W,X
        BEQ     DOSALLOCATENEWFILECHUNK@FOUND
        INX
        INX
        CPX     #$0200
        BCC     -
        LDA     DOSTMP6.B
        INC     A
        STA     DOSTMP6.B
        CMP     FSMBCACHE+$16.W
        BCC     --
        LDA     #DOS_ERR_DRIVE_FULL.W
        SEC
+       RTS

; seek file handle to next chunk, or allocate new chunk
; assumes B=$80 D=DOSPAGE
; X=handle itself
; C=0 if next chunk available
; C=1 if error
DOSFILENEXTCHUNKWRITE:
        LDA     $0020.W,X
        AND     #$FF
        STA     DOSACTIVEDRIVE.B
        JSR     DOSPAGEINACTIVEDRIVE.W
        BCS     @ERRX
        JSR     DOSFLUSHFILE.W
        PHX
        LDA     $0018.W,X
        TAX
        JSR     DOSNEXTCHUNK.W
        BCS     @ERR
        CPX     #$FFFF
        BEQ     @APPEND
        TXA
        PLX
        STA     $0018.W,X
        JMP     DOSPAGEINFILENEXTCHUNK.W
@ERR    PLX
        SEC
@ERRX   RTS
@APPEND
        JSR     DOSALLOCATECHUNK.W
        BCS     @ERR
        PHX
        PHA
        LDA     $0018.W,X
        TAX
        PLA
        STA     $0018.W,X
        JSR     DOSLINKCHUNK.W
; fill with zeros
        PLX
        PHX
        JSR     DOSPAGEINFILENEXTCHUNK.W
        BCS     +
        PLX
        PHX
        PHY
        JSR     DOSFILEHANDLECONVADDR.W
        TAX
        LDY     #512
-       STZ     $0000.W,X
        INX
        INX
        DEY
        BNE     -
        PLY
+       PLX
        RTS

; allocate new chunks for file if necessary
DOSEXTENDFILE:
        LDA     $0020.W,X
        AND     #$FF
        STA     DOSACTIVEDRIVE.B
        JSR     DOSPAGEINACTIVEDRIVE.W
        BCS     @ERRX
        LDA     $0016.W,X
        CMP     $001C.W,X
        BCC     @NO
        BNE     @YES
        LDA     $0014.W,X
        CMP     $001A.W,X
        BCC     @NO
        EOR     $001A.W,X
        AND     #$FC00
        BNE     @YES
@NO     CLC
        RTS
@YES    PHX
        JSR     DOSFILENEXTCHUNKWRITE.W
        BCS     @ERR
        PLX
        LDA     $001A.W,X
        CLC
        ADC     #$0400
        STA     $001A.W,X
        LDA     $001C.W,X
        ADC     #0
        STA     $001C.W,X
        BRA     DOSEXTENDFILE
@ERR    PLX
@ERRX   RTS

; go to next chunk, or if none, allocate new chunk for active directory
DOSEXTENDDIR:
        LDX     DOSCACHEDDIRCH.B
        STX     DOSPREVDIRCHUNK.B
        JSR     DOSNEXTCHUNK.W
        BCS     @ERR
        CPX     #$FFFF
        BEQ     @ALLOC
        JSR     DOSDIRWRITEBACK.W
        STX     DOSCACHEDDIRCH.B
        LDX     #DIRCHUNKCACHE.W
        JSR     DOSLOADCHUNK.W
        BCS     @ERR
        CLC
@ERR    RTS
@ALLOC  JSR     DOSALLOCATECHUNK.W
        BCS     @ERR
        JSR     DOSDIRWRITEBACK.W
        STA     DOSCACHEDDIRCH.B
        LDA     #$FFFF
        STA     DOSADIRDIRTY.B
        LDX     #0
-       STA     DIRCHUNKCACHE.W,X
        STA     DIRCHUNKCACHE+2.W,X
        STA     DIRCHUNKCACHE+4.W,X
        STA     DIRCHUNKCACHE+6.W,X
        STA     DIRCHUNKCACHE+8.W,X
        STA     DIRCHUNKCACHE+10.W,X
        STA     DIRCHUNKCACHE+12.W,X
        STA     DIRCHUNKCACHE+14.W,X
        PHA
        TXA
        CLC
        ADC     #$0010
        TAX
        PLA
        CPX     #$0400
        BCC     -
        RTS

; find next free position in current active drive and dir
; C=0 if found, NEXTFILEDRV/DIR/OFF contains pointer
; C=1 if error
DOSALLOCDIRSLOT:
        ACC16
        STA     DOSACTIVEDRIVE.B
        JSR     DOSPAGEINACTIVEDRIVE.W
        BCS     @ERR
        LDA     DOSACTIVEDIR.B
        JSR     DOSPAGEINACTIVEDIR.W
        BCS     @ERR
--      LDX     #$0000
-       ACC8
        LDA     DIRCHUNKCACHE.W,X
        ACC16
        BMI     +
        TXA
        CLC
        ADC     #$0020
        TAX
        CMP     #$0400
        BCC     -
        ; load next chunk
        JSR     DOSEXTENDDIR.W
        BCC     --
@ERR    RTS
+       STX     DOSNEXTFILEOFF.B
        LDA     DOSCACHEDDIRCH.B
        STA     DOSNEXTFILEDIR.B
        LDA     DOSACTIVEDRIVE.B
        STA     DOSNEXTFILEDRV.B
        CLC
        RTS

DOSPAGEINFILENEXTCHUNK:
        ACC8
        ; load chunk
        LDA     $0024.W,X
        AND     #1
        BEQ     +
        PHX
        LDY     $0018.W,X
        LDA     DOSTMP8.B
        ACC16
        CONVERTFILECACHEPOINTER
        TAX
        JSR     DOSLOADCHUNK.W
        BCS     @ERR
        PLX
        ACC8
        LDA     $0018.W,X
        CMP     DOSLASTFCACHE.B
        BNE     +
        LDA     DOSLASTFCACHE.B
        INC     A
        ACC16
        AND     #NUMFILECACHES-1
        STA     DOSLASTFCACHE.B
+       ACC16
        ORA     #$0001
        CLC
        RTS
@ERR    PLX
        SEC
        RTS

; used for Ah=$21
; assumes B=$80 D=DOSPAGE
; reads 0 <= DOSTMPX5 < $0400 from handle at DOSTMPX3 into memory at DOSTMPX2
;                       banks at DOSTMPX4
; C=0 if read
; C=1 if error
DOSFILEREADCYCLE:
        BIT     $0016.W,X
        BMI     @NEGOFFSET
        CMP     DOSTMPX5.B
        BEQ     @ZERO
        LDX     DOSTMPX3.B
        JSR     DOSPAGEINFILE.W
        BCS     +
        RESERVEDMA1
.ACCU 16
        LDX     DOSTMPX3.B
        LDA     DOSTMPX2.B
        STA     DMA1DST.L
        LDA     $0014.W,X
        STA     DOSTMP2.B
        AND     #$03FF
        STA     DOSTMP1.B
        JSR     DOSFILEHANDLECONVADDR.W
        CLC
        ADC     DOSTMP1.B
        STA     DMA1SRC.L
        LDA     DOSTMPX5.B
        STA     DMA1CNT.L
        LDA     DOSTMPX4.B
        STA     DMA1BNKS.L
-       LDA     DMA1STAT.L
        BMI     -
        LDA     DMA1DST.L
        STA     DOSTMPX2.B
        FREEDMA1
        LDA     DOSTMPX5.B
        CLC
        ADC     $0014.W,X
        STA     $0014.W,X
        LDA     $0016.W,X
        ADC     #0
        STA     $0016.W,X
; did we reach end of chunk?
        EOR     DOSTMP2.B
        AND     #$0400
        BNE     @NEXTCH
+       RTS
@NEGOFFSET:
        LDA     #DOS_ERR_READ_ERROR
        SEC
        RTS
@ZERO   CLC
        RTS
@NEXTCH:
        LDX     DOSTMPX3.B
        JSR     DOSFILENEXTCHUNKREAD.W
        RTS

; used for Ah=$22
; assumes B=$80 D=DOSPAGE
; writes 0 <= DOSTMPX5 < $0400 to handle at DOSTMPX3 from memory at DOSTMPX2
;                       banks at DOSTMPX4
; C=0 if written
; C=1 if error
DOSFILEWRITECYCLE:
        BIT     $0016.W,X
        BMI     @NEGOFFSET
        LDX     DOSTMPX3.B
        JSR     DOSEXTENDFILE.W
        LDX     DOSTMPX3.B
        CMP     DOSTMPX5.B
        BEQ     @ZERO
        RESERVEDMA1
.ACCU 16
        LDA     DOSTMPX2.B
        STA     DMA1SRC.L
        LDA     $0014.W,X
        STA     DOSTMP2.B
        AND     #$03FF
        STA     DOSTMP1.B
        JSR     DOSFILEHANDLECONVADDR.W
        CLC
        ADC     DOSTMP1.B
        STA     DMA1DST.L
        LDA     DOSTMPX5.B
        STA     DMA1CNT.L
        LDA     DOSTMPX4.B
        STA     DMA1BNKS.L
-       BIT     DMA1STAT.W
        BMI     -
        LDA     DMA1DST.L
        STA     DOSTMPX2.B
        FREEDMA1
        BRA     @WRITEOK
@NEGOFFSET:
        LDA     #DOS_ERR_WRITE_ERROR
        SEC
        RTS
@ZERO   CLC
        RTS
@WRITEOK:
        LDA     DOSTMPX5.B
        CLC
        ADC     $0014.W,X
        STA     $0014.W,X
        LDA     $0016.W,X
        ADC     #0
        STA     $0016.W,X
; update file size if it went past the pointer
        LDA     $0016.W,X
        CMP     $001E.W,X
        BCC     ++
        BNE     +
        LDA     $0014.W,X
        CMP     $001C.W,X
        BCC     ++
+       LDA     $0014.W,X
        STA     $001C.W,X
        LDA     $0016.W,X
        STA     $001E.W,X
; did we reach end of chunk?
++      EOR     DOSTMP2.B
        AND     #$0400
        BNE     @NEXTCH
        RTS
@NEXTCH:
        LDX     DOSTMPX3.B
        JSR     DOSFILENEXTCHUNKWRITE.W
        RTS

; do file seeking
; assumes B=$80 D=DOSPAGE
DOSFILEDOSEEK:
        CPX     #DOSFILETABLE
        BCC     @NOSEEK
        STX     DOSTMPX3.B
        PHA
        TDC
        STA     DOSTMPX1.B
        STY     DOSTMPX2.B
        LDA     1,S
        AND     #$FF
        BEQ     @SET
        DEC     A
        BEQ     @CUR
        DEC     A
        BEQ     @END
        PLA
        LDA     #DOS_ERR_BAD_PARAMETER
        SEC
        RTS
@NOSEEK LDA     #DOS_ERR_CANNOT_SEEK
        SEC
        RTS
@CUR    LDX     DOSTMPX3.B
        LDA     DOSTMPX1.B
        CLC
        ADC     $0014.W,X
        STA     $0014.W,X
        LDA     DOSTMPX2.B
        ADC     $0016.W,X
        STA     $0016.W,X
        BRA     @RETURN

@END    LDX     DOSTMPX3.B
        LDA     DOSTMPX1.B
        CLC
        ADC     $001A.W,X
        STA     $0014.W,X
        LDA     DOSTMPX2.B
        ADC     $001C.W,X
        STA     $0016.W,X
        BRA     @RETURN

@SET    LDX     DOSTMPX3.B
        LDA     DOSTMPX1.B
        STA     $0014.W,X
        LDA     DOSTMPX2.B
        STA     $0016.W,X

@RETURN:
        LDY     $0016.W,X
        LDA     $0014.W,X
        TAX
        PLA
        CLC
        RTS

; get file size in Y,A
; X=handle
; assumes B=$80 D=DOSPAGE
DOSFILEDOGETSIZE:
        LDY     $001C.W,X
        LDA     $001A.W,X
        RTS

; truncate file at pointer
; X=handle
; assumes B=$80 D=DOSPAGE
DOSFILEDOTRUNC:
        ; do not allow truncate if only read access
        LDA     $0024.W,X
        AND     #2
        BEQ     @ACC

        LDA     $0020.W,X
        AND     #$FF
        STA     DOSACTIVEDRIVE.B
        JSR     DOSPAGEINACTIVEDRIVE.W
        BCS     @ERR

        ; get next chunk of current chunk
        PHX
        LDA     $0018.W,X
        TAX
        JSR     DOSNEXTCHUNK.W
        BCS     @ERRX
        STX     DOSTMPX1.B

        ; mark current chunk as last
        LDA     1,S
        TAX
        LDA     $0018.W,X
        TAX
        LDA     #$FFFF
        JSR     DOSLINKCHUNK.W
        BCS     @ERRX

        ; free remaining chunks
        LDX     DOSTMPX1.B
        JSR     DOSFREEMANYCHUNKS.W
        BCS     @ERRX

        PLX

        ; copy file pointer to file size
        LDA     $0014.W,X
        STA     $001A.w,X
        LDA     $0016.W,X
        STA     $001C.w,X

        CLC
        RTS

@ACC    LDA     #DOS_ERR_ACCESS_DENIED
        SEC
        RTS
@ERRX   PLX
@ERR    SEC
        RTS
