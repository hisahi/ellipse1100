; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS file system (ELFS) external functions
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

; $0E = set active drive
DOSSETDRIVE:
        DOSMEMENTER
        PHX
        PHY
        PHA
        JSR     DOSPAGEINDIR.W
        PLA
        AND     #$1F
        BEQ     @BAD
        CMP     #DOSMAXDRIVES+1
        BCS     @BAD
        CMP     DOSREALDRIVE.B
        BEQ     +
        STA     DOSACTIVEDRIVE.B
        JSR     DOSPAGEINACTIVEDRIVE.W
        BCS     @FAIL
        JSR     DOSPAGEOUTDRIVE.W
+       PLY
        PLX
        DOSMEMEXIT
        CLC
        RTS
@BAD    LDA     #DOS_ERR_INVALID_DRIVE
@FAIL   PLY
        PLX
        DOSMEMEXIT
        SEC
        RTS

; $3E = get active drive
DOSGETDRIVE:
        DOSMEMENTER
        LDA     DOSREALDRIVE.B
        DOSMEMEXIT
        CLC
        RTS

DOSPACKFIS:
.REPEAT 8 INDEX OFF
        LDA     DOSBANKD|DOSSTRINGCACHE+OFF*2.L,X
        STA     $0030+OFF*2,Y
.ENDR
        PHY
        PHX
        LDA     DOSLD|DOSNEXTFILEOFF.L
        TAX
-       LDA     DOSBANKD|DIRCHUNKCACHE.L,X
        STA     $0000.W,Y
        INX
        INX
        INY
        INY
        TXA
        AND     #$1F
        BNE     -
        PLX
        PLY
        LDA     DOSLD|DOSNEXTFILEDRV.L
        STA     $0020.W,Y
        LDA     DOSLD|DOSNEXTFILEDIR.L
        STA     $0022.W,Y
        LDA     DOSLD|DOSNEXTFILEOFF.L
        STA     $0024.W,Y
@DONE:
        RTS

; $11 = find first matching file
; B:X=xpathname   B:Y=address to FIB (file index block)
DOSFINDFIRST:
        PHX
        PHY
        JSR     DOSCOPYBXSTRBUFUC.W
        ENTERDOSRAM
        ACC8
        LDA     #$80
        STA     DOSIOBANK.B
        ACC16
        JSR     DOSPAGEINDIR.W
        LDX     #0
        JSR     DOSEXTRACTRESOLVEPATH.W
        BCS     @ERRM
        PHX
        JSR     DOSPAGEINACTIVEDRIVE.W
        BCS     @ERRMX
        LDA     DOSACTIVEDRIVE.B
        STA     DOSNEXTFILEDRV.B
        LDA     DOSACTIVEDIR.B
        STA     DOSNEXTFILEDIR.B
        STZ     DOSNEXTFILEOFF.B
        PLX
        PHX
        JSR     DOSRESOLVENEXTFILE.W
        BCS     @ERRMX
        JSR     DOSWIPEBUFFERLEFTOVER.W
        PLX
        EXITDOSRAM
        PLY
        JSR     DOSPACKFIS.W
        PLX
        CLC
        RTS
@ERRMX  PLX
@ERRM   EXITDOSRAM
@ERR    PLY
        PLX
        SEC
        RTS

DOSUNPACKFIS:
.REPEAT 8 INDEX OFF
        LDA     $0030+OFF*2,Y
        STA     DOSBANKD|DOSSTRINGCACHE+OFF*2.L
.ENDR
        LDA     #0
        STA     DOSBANKD|DOSSTRINGCACHE+16.L
        LDA     $0020.W,Y
        AND     #$1F
        STA     DOSLD|DOSNEXTFILEDRV.L
        LDA     $0022.W,Y
        STA     DOSLD|DOSNEXTFILEDIR.L
        LDA     $0024.W,Y
        CLC
        ADC     #$0020
        STA     DOSLD|DOSNEXTFILEOFF.L
        RTS

; $12 = find next matching file
DOSFINDNEXT:
        PHX
        PHY
        JSR     DOSUNPACKFIS.W
        ENTERDOSRAM
        ACC8
        LDA     #$80
        STA     DOSIOBANK.B
        ACC16
        PHX
        LDX     #0
        JSR     DOSRESOLVENEXTFILE.W
        PLX
        BCS     @ERRM
        JSR     DOSWIPEBUFFERLEFTOVER.W
        EXITDOSRAM
        PLY
        JSR     DOSPACKFIS.W
        PLX
        CLC
        RTS
@ERRM   CMP     #DOS_ERR_FILE_NOT_FOUND
        BNE     +
        LDA     #DOS_ERR_NO_MORE_FILES
+       EXITDOSRAM
@ERR    PLY
        PLX
        SEC
        RTS

; $0F = open file
DOSOPENFILE:

DOSLOOKUPHANDLE:
        CPX     #16
        BCS     @BADHANDLE
        PHA
        PHB
        ; stack: (user code) JSL24($810000) JSR16(callx) JSR16(LOOKUPANDVERIFY)
        ;               A16 B8
        ACC8
        LDA     10,S    ; current program bank
        PHA
        ACC16
        PLB
        LDA     $0000,X
        TAX
        PLB
        PLA
        JMP     DOSVERIFYHANDLE
@BADHANDLE
        LDA     #DOS_ERR_BAD_FILE_HANDLE
        SEC
        RTS

; $10 = close file
DOSCLOSEFILE:
        PHA
        PHX
        PHY
        JSR     DOSLOOKUPHANDLE.W
        BCS     ++
        ENTERDOSRAM
        JSR     DOSVERIFYHANDLE.W
        BCS     +
        JSR     DOSCLOSEHANDLE.W
+       EXITDOSRAM
++      PLY
        PLX
        PLA
        RTS

; $0D = flush all open files
DOSFLUSHFILES:
        PHA
        PHX
        PHY
        ENTERDOSRAM
        JSR     DOSFLUSHALLFILES.W
        EXITDOSRAM
        PLY
        PLX
        PLA
        RTS

; $16 = create/truncate file
DOSCREATEFILE:

; $13 = delete files
DOSDELETEFILE:

; $17 = rename file
DOSRENAMEFILE:

; $37 = move file entry
DOSMOVEENT:

; $33 = create directory
DOSMKDIR:

; $36 = delete (empty) directory
DOSRMDIR:

; $32 = update file entry
DOSUPDDIRENT:

; $18 = get drive info
DOSGETDRIVEINFO:

; $1E = set file attributes
DOSSETATTRS:

; $1F = get file attributes
DOSGETATTRS:

; $21 = read from file
DOSFILEREAD:
        PHX
        JSR     DOSLOOKUPHANDLE.W
        BCS     +++
        ACC8
        PHB
        PLA
        ACC16
        AND     #$00FF
        ORA     #$8000
        STA     DOSLD|DOSTMPX4.L
        TDC
        STA     DOSLD|DOSTMPX2.L
        ENTERDOSRAM
        JSR     DOSVERIFYHANDLE.W
        BCS     ++
        ; TODO: check if can read
        STX     DOSTMPX3.B
        STZ     DOSTMPX1.B
-       LDX     DOSTMPX3.B
        PHY
        JSR     DOSFILEREMBYTES.W
        STA     DOSTMPX5.B
        CPY     DOSTMPX5.B
        BCS     @READX5
        STY     DOSTMPX5.B
@READX5
        LDA     DOSTMPX5.B
        BEQ     @ENDLOOP
        JSR     DOSFILEREADCYCLE.W
        BCC     @ENDLOOP
        PHA
        LDA     DOSTMPX1.B
        BEQ     @ERR
        PLA
@ENDLOOP:
        LDA     DOSTMPX1.B
        CLC
        ADC     DOSTMPX5.B
        STA     DOSTMPX1.B
        PLA
        SEC
        SBC     DOSTMPX5.B
        TAY
        BEQ     +
        BRL     -
+       LDY     DOSTMPX1.B
        CLC
++      EXITDOSRAM
+++     PLX
        RTS
@ERR    PLA
        EXITDOSRAM
        SEC
        PLX
        RTS

; $22 = write to file
DOSFILEWRITE:
        PHX
        JSR     DOSLOOKUPHANDLE.W
        BCS     +++
        ACC8
        PHB
        PLA
        ACC16
        AND     #$00FF
        ORA     #$8000
        STA     DOSLD|DOSTMPX4.L
        TDC
        STA     DOSLD|DOSTMPX2.L
        ENTERDOSRAM
        JSR     DOSVERIFYHANDLE.W
        BCS     ++
        ; TODO: check if can write
        STX     DOSTMPX3.B
        STZ     DOSTMPX1.B
-       LDX     DOSTMPX3.B
        PHY
        JSR     DOSFILEREMBYTESWRITE.W
        STA     DOSTMPX5.B
        CPY     DOSTMPX5.B
        BCS     @READX5
        STY     DOSTMPX5.B
@READX5
        LDA     DOSTMPX5.B
        BEQ     @ENDLOOP
        JSR     DOSFILEWRITECYCLE.W
        BCC     @ENDLOOP
        PHA
        LDA     DOSTMPX1.B
        BEQ     @ERR
        PLA
@ENDLOOP:
        LDA     DOSTMPX1.B
        CLC
        ADC     DOSTMPX5.B
        STA     DOSTMPX1.B
        PLA
        SEC
        SBC     DOSTMPX5.B
        TAY
        BEQ     +
        BRL     -
+       LDY     DOSTMPX1.B
        CLC
++      EXITDOSRAM
+++     PLX
        RTS
@ERR    PLA
        EXITDOSRAM
        SEC
        PLX
        RTS

; $23 = get file size
DOSFILEGETSIZE:
        PHX
        JSR     DOSLOOKUPHANDLE.W
        BCS     +++
        ENTERDOSRAM
        JSR     DOSVERIFYHANDLE.W
        BCS     ++
        JSR     DOSFILEDOGETSIZE.w
++      EXITDOSRAM
+++     PLX
        RTS

; $24 = seek file
DOSFILESEEK:
        PHX
        JSR     DOSLOOKUPHANDLE.W
        BCS     +++
        ENTERDOSRAM
        JSR     DOSVERIFYHANDLE.W
        BCS     ++
        JSR     DOSFILEDOSEEK.w
++      EXITDOSRAM
+++     PLX
        RTS

; $25 = truncate file at pointer
DOSFILETRUNC:
        PHX
        JSR     DOSLOOKUPHANDLE.W
        BCS     +++
        ENTERDOSRAM
        JSR     DOSVERIFYHANDLE.W
        BCS     ++
        JSR     DOSFILEDOTRUNC.w
++      EXITDOSRAM
+++     PLX
        RTS

; $30 = set current directory
DOSSETDIR:
        PHX
        PHY
        JSR     DOSCOPYBXSTRBUFUC.W
        ENTERDOSRAM
        ACC8
        LDA     DOSREALDRIVE.B
        STA     DOSTMPX1.B
        LDA     #$80
        STA     DOSIOBANK.B
        LDA     #$FF
        STA     DOSUPDATEPATH.B
        JSR     DOSSHIFTINPATH.W
@DBG1
        ACC16
        JSR     DOSPAGEINDIR.W
        LDX     #0
        JSR     DOSRESOLVEPATH.W
        BCS     @ERRM
        JSR     DOSPAGEOUTDIR.W
        JSR     DOSSHIFTOUTPATH.W
@DBG2
        LDA     DOSTMPX1.B
        STA     DOSACTIVEDRIVE.B
        STA     DOSREALDRIVE.B
        STZ     DOSUPDATEPATH.B
        EXITDOSRAM
        PLY
        PLX
        CLC
        RTS
@ERRM   PHA
        LDA     DOSTMPX1.B
        STA     DOSACTIVEDRIVE.B
        STZ     DOSUPDATEPATH.B
        PLA
        EXITDOSRAM
@ERR    PLY
        PLX
        SEC
        RTS

; $31 = get current directory
DOSGETDIR:
        PHA
        LDA     DOSLD|DOSACTIVEDRIVE.L
        STA     DOSLD|DOSTMP1.L
        PLA
        AND     #$FF
        BEQ     +
        CMP     #DOSMAXDRIVES+1
        BCS     @INVALIDDRIVE
        STA     DOSLD|DOSACTIVEDRIVE.L
+       PHX
        PHY
        TXY
        ENTERDOSRAM
        JSR     DOSCURPATHTOX.W
        EXITDOSRAM
        DEY
        ACC8
-       INX
        INY
        LDA     $800000,X
        STA     $0000,Y
        BNE     -
+       ACC16
        LDA     DOSLD|DOSTMP1.L
        STA     DOSLD|DOSACTIVEDRIVE.L
        PLY
        PLX
        CLC
        RTS
@INVALIDDRIVE:
        PLA
        LDA     #DOS_ERR_INVALID_DRIVE
        SEC
        RTS

; $35 = get free space
DOSGETFREESPACE:
        PHY
        ENTERDOSRAM
        AND     #$FF
        BEQ     +
        STA     DOSACTIVEDRIVE.B
+       JSR     DOSCOUNTFREESECTORS.W
        BCS     ++
        LDX     FSMBCACHE+$10.W
++      EXITDOSRAM
        PLY
        RTS
