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

DOSPAGEINDIRAPI:
        JSR     DOSPAGEINDIR.W
        PHA
        PHX
        PHY
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        JSR     DOSPAGEINACTIVEDRIVE.W
        LDA     DOSACTIVEDIR.B
        JSR     DOSPAGEINACTIVEDIR.W
        PLY
        PLX
        PLA
        RTS

; $0E = set active drive
DOSSETDRIVE:
        ENTERDOSRAM
        PHX
        PHY
        PHA
        JSR     DOSPAGEINDIRAPI.W
        PLA
        AND     #$1F
        BEQ     @BAD
        CMP     #DOSMAXDRIVES+1
        BCS     @BAD
        CMP     DOSREALDRIVE.B
        BEQ     +
        STZ     DOSCACHEDDRIVE.B
        STA     DOSACTIVEDRIVE.B
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        JSR     DOSPAGEINACTIVEDRIVE.W
        BCS     @FAIL
        JSR     DOSPAGEOUTDRIVE.W
+       PLY
        PLX
        EXITDOSRAM
        CLC
        RTS
@BAD    LDA     #DOS_ERR_INVALID_DRIVE
@FAIL   PLY
        PLX
        EXITDOSRAM
        SEC
        JMP     DOSMAYBEENDDIRWRITE.W

; $3E = get active drive
DOSGETDRIVE:
        ENTERDOSRAM
        LDA     DOSREALDRIVE.B
        EXITDOSRAM
        CLC
        RTS

DOSPACKFIS:
.REPEAT 8 INDEX OFF
        LDA     DOSBANKD|DOSSTRINGCACHE+OFF*2.L,X
        STA     $0030+OFF*2,Y
.ENDR
DOSPACKFISPART:
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
        LDA     DOSLD|DOSNEXTDIRCHUNK.L
        STA     $0026.W,Y
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
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        JSR     DOSPAGEINDIRAPI.W
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
        LDX     DOSNEXTFILEDIR.B
        JSR     DOSNEXTCHUNK.W
        BCS     @ERRMX
        STX     DOSNEXTDIRCHUNK.B
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
        JMP     DOSMAYBEENDDIRWRITE.W
@ERRMX  PLX
@ERRM   EXITDOSRAM
@ERR    PLY
        PLX
        SEC
        JMP     DOSMAYBEENDDIRWRITE.W

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
        LDA     $0026.W,Y
        STA     DOSLD|DOSNEXTDIRCHUNK.L
        RTS

; $12 = find next matching file
DOSFINDNEXT:
        PHX
        PHY
        JSR     DOSUNPACKFIS.W
        ENTERDOSRAM
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        PHX
        LDX     #0
        JSR     DOSRESOLVENEXTFILE.W
        PLX
        BCS     @ERRM
        EXITDOSRAM
        PLY
        JSR     DOSPACKFISPART.W
        PLX
        CLC
        JMP     DOSMAYBEENDDIRWRITE.W
@ERRM   CMP     #DOS_ERR_FILE_NOT_FOUND
        BNE     +
        LDA     #DOS_ERR_NO_MORE_FILES
+       EXITDOSRAM
@ERR    PLY
        PLX
        SEC
        JMP     DOSMAYBEENDDIRWRITE.W

DOSFINDOPENHANDLESLOT:
        PHB
        PHA
        PLB
        ACC16
        LDX     #0
-       LDA     $0020.W,X
        BEQ     +
        INX
        INX
        CPX     #$0020
        BCC     -
        LDA     #DOS_ERR_NO_MORE_HANDLES
        ACC16
        PLB
        PLB
        SEC
        RTS
+       TXA
        ACC16
        LSR     A
        PLB
        PLB
        CLC
        RTS

.ACCU 16
DOSOPENFILEALT:
        PHX
        PHY
        AND     #$FF
        STA     DOSLD|DOSTMPX3.L
        JSR     DOSCOPYBXSTRBUFUC.W
        LDA     15,S                     ; old program bank
        BRA     DOSOPENFILE@GO

; $0F = open file
DOSOPENFILE:
        PHX
        PHY
        AND     #$FF
        STA     DOSLD|DOSTMPX3.L
        JSR     DOSCOPYBXSTRBUFUC.W
        LDA     9,S                     ; old program bank
@GO     AND     #$FF
        STA     DOSLD|DOSTMPX1.L
        JSR     DOSFINDOPENHANDLESLOT.W
        BCS     @ERR
        STA     DOSLD|DOSTMPX2.L
        ENTERDOSRAM
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        JSR     DOSPAGEINDIRAPI.W
        LDX     #0
        JSR     DOSEXTRACTRESOLVEPATH.W
        BCS     @ERRM
        PHX
        JSR     DOSPAGEINACTIVEDRIVE.W
        PLX
        BCS     @ERRM
        JSR     DOSRESOLVEFILE.W
        BCS     @ERRM
        LDX     DOSTMPX3.B                      ; mode
        LDY     DOSTMPX1.B                      ; job ID
        CPX     #0
        BEQ     @INVALIDMODE
        CPX     #4
        BCS     @INVALIDMODE
        JSR     DOSOPENHANDLE.W
        BCS     @ERRM
        
        ; file handle is open. place into local table
        PHA
        LDA     DOSTMPX2.B
        ASL     A
        TAX
        PLA
        PHB
        LDY     DOSTMPX1.B
        PHY
        PLB
        STA     $0020.W,X
        PLB
        PLB

        EXITDOSRAM
        PLY
        PLX
        LDA     DOSLD|DOSTMPX2.L
        TAX
        LDA     #$0000
        CLC
        JMP     DOSMAYBEENDDIRWRITE.W
@INVALIDMODE
        LDA     #DOS_ERR_BAD_PARAMETER.W
@ERRM   EXITDOSRAM
@ERR    PLY
        PLX
        SEC
        JMP     DOSMAYBEENDDIRWRITE.W

; must be called with old program bank in A
DOSLOOKUPHANDLE:
        CPX     #16
        BCS     @BADHANDLE
        PHA
        PHB
        ACC8
        PHA
        ACC16
        PLB
        TXA
        ASL     A
        TAX
        LDA     $0020.W,X
        TAX
        PLB
        PLA
        JMP     DOSVERIFYHANDLE
@BADHANDLE
        LDA     #DOS_ERR_BAD_FILE_HANDLE
        SEC
        RTS

DOSTRASHHANDLE:
        CPX     #16
        BCS     @BADHANDLE
        PHA
        PHB
        ; stack: (user code) JSL24($810000) JSR16(callx) JSR16(TRASHHANDLE)
        ;               A16 B8
        ACC8
        PHA
        ACC16
        PLB
        TXA
        ASL     A
        TAX
        STZ     $0020.W,X
        PLB
        PLA
@BADHANDLE
        RTS

; $10 = close file
DOSCLOSEFILE:
        PHA
        PHX
        PHY
        ; stack: JSL24(K8 PC16) JSR16 A16 X16 Y16
        LDA     11,S
        JSR     DOSLOOKUPHANDLE.W       ; also verifies
        BCS     ++
        ENTERDOSRAM
        LDA     8,S                     ; orig A
        AND     #$FF
        BNE     @IGNOREERRORS
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        JSR     DOSCLOSEHANDLE.W
        BCS     @ERR
        JSR     DOSWRITEBACK.W
        BCS     @ERR
        ; original X
        LDA     6,S
        TAX
        LDA     11,S
        JSR     DOSTRASHHANDLE.W
        CLC
@ERR
+       EXITDOSRAM
++      PLY
        PLX
        PLA
        JMP     DOSMAYBEENDDIRWRITE.W
        
@IGNOREERRORS:
        JSR     DOSCLOSEHANDLE.W
        JSR     DOSWRITEBACK.W
        ; original X
        LDA     6,S
        TAX
        LDA     14,S                    ; orig bank
        JSR     DOSTRASHHANDLE.W
        CLC
        EXITDOSRAM
        PLY
        PLX
        PLA
        RTS

; $0D = flush all disk buffers (except files)
DOSFLUSHBUFFERS:
        PHA
        PHX
        PHY
        ENTERDOSRAM
        JSR     DOSWRITEBACK.W
        EXITDOSRAM
        PLY
        PLX
        PLA
        JMP     DOSMAYBEENDDIRWRITE.W

; flush all open files
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
        JMP     DOSMAYBEENDDIRWRITE.W

; $16 = create/truncate file
DOSCREATEFILE:
        PHX
        PHA
        ORA     #$02
        JSR     DOSOPENFILEALT.W
        BCS     @CHECKERR
        PLA
        PLX
        PHX
        PHA
        ; stack: JSL24(K8 PC16) JSR16 X16 A16
        LDA     9,S
        JSR     DOSLOOKUPHANDLE.W                       ; also verifies
        BCC     +
        PLX
        BRA     +++
+       PLA
        ENTERDOSRAM
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        JSR     DOSFILEDOTRUNC.w
++      EXITDOSRAM
+++     PLX
        JMP     DOSMAYBEENDDIRWRITE.W
@CHECKERR:
        CMP     #DOS_ERR_FILE_NOT_FOUND.W
        BEQ     @CREATE
        PLX
        PLX
        SEC
        JMP     DOSMAYBEENDDIRWRITE.W
@CREATE:
        PLA
        PLX
        PHX
        PHY
        PHA
        JSR     DOSCOPYBXSTRBUFUC.W
        LDA     3,S
        TAY
        ENTERDOSRAM
        PHY
        JSR     DOSPAGEINDIRAPI.W
        LDX     #0
        JSR     DOSEXTRACTRESOLVEPATH.W
        BCS     @ERRM
        PHX
        JSR     DOSPAGEINACTIVEDRIVE.W
        PLX
        BCS     @ERRM
        PLY
        JSR     DOSDOCREATEFILE.W
        EXITDOSRAM
        PLA
        PLY
        PLX
        JMP     DOSOPENFILE.W
@ERRM   PLY
        EXITDOSRAM
        PLY
        PLY
        PLX
        SEC
        JMP     DOSMAYBEENDDIRWRITE.W

; $13 = delete files
DOSDELETEFILE:
        PHX
        PHY
        JSR     DOSCOPYBXSTRBUFUC.W
        ENTERDOSRAM
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        JSR     DOSPAGEINDIRAPI.W
        LDX     #0
        JSR     DOSEXTRACTRESOLVEPATH.W
        BCS     @ERRM
        PHX
        JSR     DOSPAGEINACTIVEDRIVE.W
        PLX
        BCS     @ERRM
        JSR     DOSRESOLVEFILE.W
        BCS     @ERRM
        JSR     DOSDODELETEFILE.W
        BCS     @ERRM
        EXITDOSRAM
        PLY
        PLX
        CLC
        JMP     DOSMAYBEENDDIRWRITE.W
@ERRM   EXITDOSRAM
@ERR    PLY
        PLX
        SEC
        JMP     DOSMAYBEENDDIRWRITE.W

; $17 = rename file
DOSRENAMEFILE:
        PHX
        PHY
        JSR     DOSCOPYBXSTRBUFUC.W
        ENTERDOSRAM
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        JSR     DOSPAGEINDIRAPI.W
        LDX     #0
        JSR     DOSEXTRACTRESOLVEPATH.W
        BCS     @ERRM
        PHX
        JSR     DOSPAGEINACTIVEDRIVE.W
        PLX
        BCS     @ERRM
        JSR     DOSRESOLVEFILE.W
        BCS     @ERRM
        LDA     4,S ; old Y
        TAX
        EXITDOSRAM
        JSR     DOSCOPYBXSTRBUFUC.W
        ENTERDOSRAM
        JSR     DOSDORENAMEFILE.W
        BCS     @ERRM
        EXITDOSRAM
        PLY
        PLX
        CLC
        JMP     DOSMAYBEENDDIRWRITE.W
@ERRM   EXITDOSRAM
@ERR    PLY
        PLX
        SEC
        JMP     DOSMAYBEENDDIRWRITE.W

; $37 = move file entry
DOSMOVEENT:
        PHX
        PHY
        JSR     DOSCOPYBXSTRBUFUC.W
        ENTERDOSRAM
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        JSR     DOSPAGEINDIRAPI.W
        LDX     #0
        JSR     DOSEXTRACTRESOLVEPATH.W
        BCS     @ERRM
        PHX
        JSR     DOSPAGEINACTIVEDRIVE.W
        PLX
        BCS     @ERRM
        JSR     DOSRESOLVEFILE.W
        BCS     @ERRM
        JSR     DOSSTOREFILEENTFORMOVE.W
        EXITDOSRAM
        LDA     1,S ; old Y
        TAX
        JSR     DOSCOPYBXSTRBUFUC.W
        ENTERDOSRAM
        JSR     DOSPAGEINDIRAPI.W
        LDX     #0
        JSR     DOSRESOLVEPATH.W
        BCS     @ERRM
        LDA     DOSACTIVEDRIVE.B
        CMP     DOSTMPX1.B
        BNE     @ERRND
        LDA     DOSACTIVEDIR.B
        CMP     DOSTMPX2.B
        BEQ     @NOMOVE
        JSR     DOSMOVELOADFNSTRBUF.W
        LDX     #0
        JSR     DOSRESOLVEFILE.W
        BCS     +
        JSR     DOSDODELETEFILE.W
        BCS     @ERRM
        BRA     ++
+       CMP     #DOS_ERR_FILE_NOT_FOUND.W
        BNE     @ERRM
++      JSR     DOSDOMOVEENT.W
        BCS     @ERRM
@NOMOVE:
        EXITDOSRAM
        PLY
        PLX
        CLC
        JMP     DOSMAYBEENDDIRWRITE.W
@ERRND  LDA     #DOS_ERR_BAD_PARAMETER
@ERRM   EXITDOSRAM
@ERR    PLY
        PLX
        SEC
        JMP     DOSMAYBEENDDIRWRITE.W

; $33 = create directory
DOSMKDIR:
        PHX
        PHY
        PHA
        JSR     DOSCOPYBXSTRBUFUC.W
        LDA     3,S
        TAY
        ENTERDOSRAM
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        PHY
        JSR     DOSPAGEINDIRAPI.W
        LDX     #0
        JSR     DOSEXTRACTRESOLVEPATH.W
        BCS     @ERRM
        PHX
        JSR     DOSPAGEINACTIVEDRIVE.W
        PLX
        PHX
        JSR     DOSRESOLVEFILE.W
        PLX
        BCC     @ERREX
        CMP     #DOS_ERR_FILE_NOT_FOUND
        BNE     @ERRM
        PLY
        JSR     DOSCREATEDIRECTORY.W
        EXITDOSRAM
        PLA
        PLY
        PLX
        CLC
        JMP     DOSMAYBEENDDIRWRITE.W
@ERRM   PLY
        EXITDOSRAM
        PLY
        PLY
        PLX
        SEC
        JMP     DOSMAYBEENDDIRWRITE.W
; already exists
@ERREX  PLY
        EXITDOSRAM
        PLY
        PLY
        PLX
        SEC
        LDA     #DOS_ERR_CREATE_ERROR.W
        JMP     DOSMAYBEENDDIRWRITE.W

; $36 = delete (empty) directory
DOSRMDIR:
        PHX
        PHY
        JSR     DOSCOPYBXSTRBUFUC.W
        ENTERDOSRAM
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        JSR     DOSPAGEINDIRAPI.W
        LDX     #0
        JSR     DOSEXTRACTRESOLVEPATH.W
        BCS     @ERRM
        PHX
        JSR     DOSPAGEINACTIVEDRIVE.W
        PLX
        BCS     @ERRM
        JSR     DOSRESOLVEFILE.W
        BCS     @ERRM
        JSR     DOSREMOVEDIRECTORY.W
        BCS     @ERRM
        EXITDOSRAM
        PLY
        PLX
        CLC
        JMP     DOSMAYBEENDDIRWRITE.W
@ERRM   EXITDOSRAM
@ERR    PLY
        PLX
        SEC
        JMP     DOSMAYBEENDDIRWRITE.W

; $18 = get drive info
DOSGETDRIVEINFO:
        PHX
        PHY
        ENTERDOSRAM
        AND     #$FF
        STA     DOSACTIVEDRIVE.B
        JSR     DOSPAGEINACTIVEDRIVE.W
        JSR     DOSGETACTIVEDRIVEINFO.W
        EXITDOSRAM
        PLY
        PLX
        RTS

; $1E = set file attributes
DOSSETATTRS:
        STA     DOSTMPX1.B
        PHX
        PHY
        JSR     DOSCOPYBXSTRBUFUC.W
        ENTERDOSRAM
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        JSR     DOSPAGEINDIRAPI.W
        LDX     #0
        JSR     DOSEXTRACTRESOLVEPATH.W
        BCS     @ERRM
        PHX
        JSR     DOSPAGEINACTIVEDRIVE.W
        PLX
        BCS     @ERRM
        JSR     DOSRESOLVEFILE.W
        BCS     @ERRM
        LDX     DOSNEXTFILEOFF.B
        LDA     DOSTMPX1.B
        ACC8
        STA     DIRCHUNKCACHE+$01.W,X
        ACC16
        EXITDOSRAM
        PLY
        PLX
        CLC
        JMP     DOSMAYBEENDDIRWRITE.W
@ERRM   EXITDOSRAM
@ERR    PLY
        PLX
        SEC
        JMP     DOSMAYBEENDDIRWRITE.W

; $1F = get file attributes
DOSGETATTRS:
        PHX
        PHY
        JSR     DOSCOPYBXSTRBUFUC.W
        ENTERDOSRAM
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        JSR     DOSPAGEINDIRAPI.W
        LDX     #0
        JSR     DOSEXTRACTRESOLVEPATH.W
        BCS     @ERRM
        PHX
        JSR     DOSPAGEINACTIVEDRIVE.W
        PLX
        BCS     @ERRM
        JSR     DOSRESOLVEFILE.W
        BCS     @ERRM
        LDX     DOSNEXTFILEOFF.B
        LDA     DIRCHUNKCACHE+$01.W,X
        AND     #$FF
        EXITDOSRAM
        PLY
        PLX
        CLC
        JMP     DOSMAYBEENDDIRWRITE.W
@ERRM   EXITDOSRAM
@ERR    PLY
        PLX
        SEC
        JMP     DOSMAYBEENDDIRWRITE.W

; $21 = read from file
DOSFILEREAD:
        PHX
        PHA
        ; stack: JSL24(K8 PC16) JSR16 X16 A16
        LDA     9,S
        JSR     DOSLOOKUPHANDLE.W       ; also verifies
        BCC     +
        PLX
        BRA     +++
+       PLA
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
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        STX     DOSTMPX3.B
        STZ     DOSTMPX1.B
        JSR     DOSFILECANREAD.W
        BCS     @ERRC
-       LDX     DOSTMPX3.B
        PHY
        JSR     DOSFILEREMBYTES.W
        STA     DOSTMPX5.B
        CPY     DOSTMPX5.B
        BCS     @READX5
        STY     DOSTMPX5.B
@READX5
        LDA     DOSTMPX5.B
        BEQ     @FILEEOF
        JSR     DOSFILEREADCYCLE.W
        BCC     @ENDLOOP
        PHA
        LDA     DOSTMPX1.B
        BEQ     @ERRY
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
@FILEEOF
        PLY
+       LDY     DOSTMPX1.B
        CLC
++      EXITDOSRAM
+++     PLX
        JMP     DOSMAYBEENDDIRWRITE.W
@ERRY   PLY
@ERR    PLA
@ERRC   EXITDOSRAM
        SEC
        PLX
        JMP     DOSMAYBEENDDIRWRITE.W

; $22 = write to file
DOSFILEWRITE:
        PHX
        PHA
        ; stack: JSL24(K8 PC16) JSR16 X16 A16
        LDA     9,S
        JSR     DOSLOOKUPHANDLE.W       ; also verifies
        BCC     +
        PLX
        BRA     +++
+       PLA
        ACC8
        PHB
        PLA
        ACC16
        AND     #$00FF
        XBA
        ORA     #$0080
        STA     DOSLD|DOSTMPX4.L
        TDC
        STA     DOSLD|DOSTMPX2.L
        ENTERDOSRAM
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        STX     DOSTMPX3.B
        STZ     DOSTMPX1.B
        JSR     DOSFILECANWRITE.W
        BCS     @ERRC
-       LDX     DOSTMPX3.B
        PHY
        JSR     DOSFILEREMBYTESWRITE.W
        STA     DOSTMPX5.B
        CPY     DOSTMPX5.B
        BCS     @READX5
        STY     DOSTMPX5.B
@READX5
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
        JMP     DOSMAYBEENDDIRWRITE.W
@ERR    PLA
@ERRC   EXITDOSRAM
        SEC
        PLX
        JMP     DOSMAYBEENDDIRWRITE.W

; $23 = get file size
DOSFILEGETSIZE:
        PHX
        PHA
        ; stack: JSL24(K8 PC16) JSR16 X16 A16
        LDA     9,S
        JSR     DOSLOOKUPHANDLE.W                       ; also verifies
        BCC     +
        PLX
        BRA     +++
+       PLA
        ENTERDOSRAM
        PHA
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        PLA
        JSR     DOSFILEDOGETSIZE.w
++      EXITDOSRAM
+++     PLX
        JMP     DOSMAYBEENDDIRWRITE.W

; $24 = seek file
DOSFILESEEK:
        PHX
        PHA
        ; stack: JSL24(K8 PC16) JSR16 X16 A16
        LDA     9,S
        JSR     DOSLOOKUPHANDLE.W                       ; also verifies
        BCC     +
        PLX
        BRA     +++
+       PLA
        ENTERDOSRAM
        PHA
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        PLA
        JSR     DOSFILEDOSEEK.w
++      EXITDOSRAM
+++     PLX
        JMP     DOSMAYBEENDDIRWRITE.W

; $25 = truncate file at pointer
DOSFILETRUNC:
        PHX
        PHA
        ; stack: JSL24(K8 PC16) JSR16 X16 A16
        LDA     9,S
        JSR     DOSLOOKUPHANDLE.W                       ; also verifies
        BCC     +
        PLX
        BRA     +++
+       PLA
        ENTERDOSRAM
        PHA
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        PLA
        JSR     DOSFILEDOTRUNC.w
++      EXITDOSRAM
+++     PLX
        JMP     DOSMAYBEENDDIRWRITE.W

; $30 = set current directory
DOSSETDIR:
        PHX
        PHY
        JSR     DOSCOPYBXSTRBUFUC.W
        ENTERDOSRAM
        ACC8
        LDA     DOSREALDRIVE.B
        STA     DOSTMPX1.B
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        LDA     #$FF
        STA     DOSUPDATEPATH.B
        JSR     DOSSHIFTINPATH.W

        ACC16
        JSR     DOSPAGEINDIRAPI.W
        LDX     #0
        JSR     DOSRESOLVEPATH.W
        BCS     @ERRM
        JSR     DOSPAGEOUTDIR.W
        JSR     DOSSHIFTOUTPATH.W

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
        JMP     DOSMAYBEENDDIRWRITE.W

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
        PHA
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        PLA
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
        JMP     DOSMAYBEENDDIRWRITE.W

; $3C = read drive FSMB
DOSREADFSMB:
        ENTERDOSRAM
        PHA
        ACC8
        LDA     #(DOSBANKD>>16)
        STA     DOSIOBANK.B
        ACC16
        PLA
        AND     #$FF
        BEQ     +
        STA     DOSACTIVEDRIVE.B
+       STX     DOSTMP1.B
        LDA     3,S
        AND     #$FF
        STA     DOSTMP2.B
        PHX
        PHY
        JSR     DOSPAGEINACTIVEDRIVE.W
        BCS     +
        LDX     #$0200
        TXY
-       DEX
        DEX
        LDA     FSMBCACHE.W,X
        DEY
        DEY
        STA     [DOSTMP1.B],Y
        BPL     -
        CLC
+       PLY
        PLX
        EXITDOSRAM
        RTS

