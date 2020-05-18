; Ellipse Workstation 1100 (fictitious computer)
; ROM code (machine language monitor)
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

.BANK 1

.ORG $8000

; KEYCODETABLE, KEYB_APPLY_CAPS_TO_KEY in keytbls.asm

.DEFINE MONPAGE  $1200
.DEFINE MONBPAGE $800000|MONPAGE
.DEFINE OLDREGB  $00
.DEFINE OLDREGD  $02
.DEFINE OLDREGK  $04
.DEFINE OLDREGP  $06
.DEFINE OLDREGPC $08
.DEFINE MONADDRA $10
.DEFINE MONBANKA $12
.DEFINE MNREGD   $14
.DEFINE MNREGP   $16
.DEFINE MNREGB   $17
.DEFINE MNREGACC $18
.DEFINE MNREGX   $1A
.DEFINE MNREGY   $1C
.DEFINE MNREGS   $1E
.DEFINE MNLINELN $20
.DEFINE MNLINEPS $22
.DEFINE MNREGJML $25
.DEFINE MNREGPC  $26
.DEFINE MNREGK   $28
.DEFINE MNAXYSZ  $2A
.DEFINE MONTMP1  $30
.DEFINE MONTMP2  $32
.DEFINE MONTMP3  $34
.DEFINE MONTMP4  $36
.DEFINE MONBRKOL $38
.DEFINE MONNMIOL $3B
.DEFINE MONINNMI $3E
.DEFINE MONBLINK $40
.DEFINE MONADDR1 $50
.DEFINE MONBANK1 $52
.DEFINE MONADDR2 $54
.DEFINE MONBANK2 $56
.DEFINE MONNUM1  $58
.DEFINE MONNUM2  $5A
.DEFINE MONADDRM $5C
.DEFINE MONBANKM $5E
.DEFINE MONADDRE $60
.DEFINE MONBANKE $62
.DEFINE MNPRPLEN $64
.DEFINE MONSTART $66
.DEFINE MONSBANK $68
.DEFINE MONBREAK $69
.DEFINE MNBPFLAG $6A
.DEFINE MNBPADDR $6C
.DEFINE MNBPINST $6F
.DEFINE MONBUF   $80

MLMONITOR:                      ; enter with JSL
        PHP
        PHB
        PHD
        AXY16
        LDA     #MONPAGE
        PHA
        PLD
        ACC8
        LDA     #$80
        PHA
        PLB
        ; stack: D B P PC K
        LDA     3,S
        STA     OLDREGB.B
        LDA     4,S
        STA     OLDREGP.B
        LDA     7,S
        STA     OLDREGK.B
        ACC16
        LDA     1,S
        STA     OLDREGD.B
        LDA     5,S
        STA     OLDREGPC.B

        STZ     MONINNMI.B

        LDA     #MLMONBRK.W
        LDX     #MONPAGE|MONBRKOL.W
        LDY     #$0001.W
        JSL     ROM_SWAPBRK.L

        LDA     #MLMONNMI.W
        LDX     #MONPAGE|MONNMIOL.W
        LDY     #$0001.W
        JSL     ROM_SWAPNMI.L

        ACC8                    ; enable VSYNC NMI
        LDA     IOBANK|VPUCNTRL.L
        ORA     #$04
        STA     IOBANK|VPUCNTRL.L

        LDA     #$81
        STZ     MNREGP.B
        STA     MNREGK.B
        STA     MNREGB.B
        STA     MONSBANK.B
        ACC16

        STZ     MONSTART.B
        STZ     MONBLINK.B
        STZ     MNBPFLAG.B

        LDA     #$C000
        STA     MONSTART.B
        STA     MONADDRA.B
        STA     MNREGPC.B
        LDA     #$03FF
        STA     MNREGS.B
        XBA
        STZ     MNREGACC.B
        STZ     MNREGX.B
        STZ     MNREGY.B
        STZ     MNREGD.B
        STZ     MONBREAK.B
@LOOP:
        AXY16
        LDA     #$3F
        STA     MNPRPLEN.B
        LDA     #$0D
        JSL     TEXT_WRCHR.L
        LDA     #$3F
        JSL     TEXT_WRCHR.L
        JSR     MONITORPROMPT
        LDA     #0
        ACC8
        LDA     MONBUF.B
        BEQ     @LOOP
        AND     #$DF
        CMP     #$41
        BCC     @UNKCMD
        CMP     #$5B
        BCS     @UNKCMD
        SEC
        SBC     #$41
        ASL     A
        TAX
        JSR     (MONITORROUTINES,X)
        JMP     @LOOP

@UNKCMD:
        JSR     MONITORERROR 
        BRA     @LOOP

MONITORERROR:
        ACC8
        PHB
        LDA     #$01
        PHA
        PLB
        ACC16
        LDA     #MONITORMSGERROR
        JSL     TEXT_WRSTR.L
        PLB
        RTS

MONCODEBRK:
        AXY16
        LDA     #MONPAGE
        PHA
        PLD
        ACC8
        LDA     #$80
        STA     MONBREAK.B
        PHA
        PLB
        JSR     MONITORDUMPREG
        JMP     MLMONITOR@LOOP

MONITORDUMPREG_MSG_A:  
        .DB     13,"A=",0
MONITORDUMPREG_MSG_X:  
        .DB     "  X=",0
MONITORDUMPREG_MSG_Y:  
        .DB     "  Y=",0
MONITORDUMPREG_MSG_S:  
        .DB     "  S=",0
MONITORDUMPREG_MSG_P:  
        .DB     "  P=",0
MONITORDUMPREG_MSG_PC:  
        .DB     " PC=",0
MONITORDUMPREG_MSG_K:  
        .DB     "  K=",0
MONITORDUMPREG_MSG_B:  
        .DB     "  B=",0
MONITORDUMPREG_MSG_D:  
        .DB     "  D=",0
MONITORDUMPREG_MSG_CR_K:  
        .DB     13,"K=",0

MONITORREG:
        ACC8
        LDX     #1
        LDA     MONBUF,X
        BNE     +
        JMP     MONITORDUMPREG
+       AND     #$DF
        CMP     #'A'
        BEQ     MONITORREGSETA
        CMP     #'X'
        BEQ     MONITORREGSETX
        CMP     #'Y'
        BEQ     MONITORREGSETY
        CMP     #'S'
        BEQ     MONITORREGSETS
        CMP     #'C'
        BEQ     MONITORREGSETPC
        CMP     #'D'
        BEQ     MONITORREGSETD
        CMP     #'P'
        BEQ     MONITORREGSETP
        CMP     #'K'
        BEQ     MONITORREGSETK
        CMP     #'B'
        BEQ     MONITORREGSETB
        LDA     MONBUF,X
        CMP     #'1'
        BNE     +
        JMP     MONITORREGSET1
+       CMP     #'2'
        BNE     +
        JMP     MONITORREGSET2
+       JMP     MONITORERROR
        
MONITORREGSETA:
        LDY     #MNREGACC.W
        INX
        JSR     MONITORREAD16
        BCS     MONITORREGSET16
        JMP     MONITORERROR
        
MONITORREGSETX:
        LDY     #MNREGX.W
        INX
        JSR     MONITORREAD16
        BCS     MONITORREGSET16
        JMP     MONITORERROR
        
MONITORREGSETY:
        LDY     #MNREGY.W
        INX
        JSR     MONITORREAD16
        BCS     MONITORREGSET16
        JMP     MONITORERROR
        
MONITORREGSETS:
        LDY     #MNREGS.W
        INX
        JSR     MONITORREAD16
        BCS     MONITORREGSET16
        JMP     MONITORERROR
        
MONITORREGSETPC:
        LDY     #MNREGPC.W
        INX
        JSR     MONITORREAD16
        BCS     MONITORREGSET16
        JMP     MONITORERROR
        
MONITORREGSETD:
        LDY     #MNREGD.W
        INX
        JSR     MONITORREAD16
        BCS     MONITORREGSET16
        JMP     MONITORERROR
        
MONITORREGSETP:
        LDY     #MNREGP.W
        INX
        JSR     MONITORREAD8
        BCS     MONITORREGSET8
        JMP     MONITORERROR
        
MONITORREGSETK:
        LDY     #MNREGK.W
        INX
        JSR     MONITORREAD8
        BCS     MONITORREGSET8
        JMP     MONITORERROR
        
MONITORREGSETB:
        LDY     #MNREGB.W
        INX
        JSR     MONITORREAD8
        BCS     MONITORREGSET8
        JMP     MONITORERROR

MONITORREGSET8:
        ACC8
        LDA     MONNUM1.B
        STA     MONPAGE,Y
        LDA     MONBREAK.B
        BNE     +
        CPY     #MNREGK.B
        BNE     +
        STA     MONSBANK.B
+       RTS
        
MONITORREGSET16:
        ACC16
        LDA     MONNUM1.B
        STA     MONPAGE,Y
        LDA     MONBREAK.B
        BNE     +
        CPY     #MNREGPC.B
        BNE     +
        STA     MONSTART.B
+       RTS

MONITORREGSET1:
.ACCU 8
        INX
        LDA     MONBUF,X
        AND     #$DF
        CMP     #'A'
        BNE     +
        LDA     MNREGP.B
        ORA     #$20
        STA     MNREGP.B
        RTS
+       CMP     #'X'
        BNE     +
        LDA     MNREGP.B
        ORA     #$10
        STA     MNREGP.B
        RTS
+       JMP     MONITORERROR

MONITORREGSET2:
.ACCU 8
        INX
        LDA     MONBUF,X
        AND     #$DF
        CMP     #'A'
        BNE     +
        LDA     MNREGP.B
        AND     #$DF
        STA     MNREGP.B
        RTS
+       CMP     #'X'
        BNE     +
        LDA     MNREGP.B
        AND     #$EF
        STA     MNREGP.B
        RTS
+       JMP     MONITORERROR

MONITORDUMPREG:
        PHB
        ACC8
        LDA     #$01
        PHA
        PLB

        ACC16
        LDA     #MONITORDUMPREG_MSG_A.W
        JSL     TEXT_WRSTR.L
        LDA     MONBPAGE|MNREGACC.L
        JSL     WRITE_HEX_WORD.L
        
        LDA     #MONITORDUMPREG_MSG_X.W
        JSL     TEXT_WRSTR.L
        LDA     MONBPAGE|MNREGX.L
        JSL     WRITE_HEX_WORD.L
        
        LDA     #MONITORDUMPREG_MSG_Y.W
        JSL     TEXT_WRSTR.L
        LDA     MONBPAGE|MNREGY.L
        JSL     WRITE_HEX_WORD.L
        
        LDA     #MONITORDUMPREG_MSG_S.W
        JSL     TEXT_WRSTR.L
        LDA     MONBPAGE|MNREGS.L
        JSL     WRITE_HEX_WORD.L
        
        LDA     #MONITORDUMPREG_MSG_P.W
        JSL     TEXT_WRSTR.L
        LDA     MONBPAGE|MNREGP.L
        JSL     WRITE_HEX_BYTE.L
        
        LDA     #MONITORDUMPREG_MSG_PC.W
        JSL     TEXT_WRSTR.L
        LDA     MONBPAGE|MNREGPC.L
        JSL     WRITE_HEX_WORD.L
        
        LDA     #MONITORDUMPREG_MSG_K.W
        JSL     TEXT_WRSTR.L
        LDA     MONBPAGE|MNREGK.L
        JSL     WRITE_HEX_BYTE.L
        
        LDA     #MONITORDUMPREG_MSG_B.W
        JSL     TEXT_WRSTR.L
        LDA     MONBPAGE|MNREGB.L
        JSL     WRITE_HEX_BYTE.L
        
        LDA     #MONITORDUMPREG_MSG_D.W
        JSL     TEXT_WRSTR.L
        LDA     MONBPAGE|MNREGD.L
        JSL     WRITE_HEX_WORD.L

        PLB
        RTS

; A is ASCII code, outputs $00-$0F
; carry set if success
MONITORREADHEX:
.ACCU 8
        BEQ     ++
        CMP     #$30
        BCC     +
        CMP     #$3A
        BCS     +
        AND     #$0F
        SEC
        RTS
+       AND     #$DF
        CMP     #$41
        BCC     ++
        CMP     #$47
        BCS     ++
        AND     #$0F
        CLC
        ADC     #$09
        SEC
        RTS
++      CLC
        RTS

; X is index into buffer
; carry set if success
; output to MONNUM1
MONITORREAD8:
        JSR     MONITORSKIPSPACES
        ACC8
        LDA     MONBUF,X
        JSR     MONITORREADHEX
        BCC     @RET
        ASL     A
        ASL     A
        ASL     A
        ASL     A
        STA     MONNUM1.B
        INX
        LDA     MONBUF,X
        JSR     MONITORREADHEX
        BCC     @RET
        ORA     MONNUM1.B
        STA     MONNUM1.B
        INX
        SEC
@RET:
        RTS

; X is index into buffer
; carry set if success
; output to MONNUM1
MONITORREAD16:
.ACCU 8
        JSR     MONITORSKIPSPACES
        JSR     MONITORREAD8
        BCC     @RET
        LDA     MONNUM1.B
        STA     MONNUM1+1.B
        JSR     MONITORREAD8
        BCC     @RET
@RET:
        RTS

; same as above, but accepts less than 4 digits
MONITORREAD16LAZY:
.ACCU 8
        JSR     MONITORSKIPSPACES
        LDA     MONBUF.B+1,X
        BEQ     MONITORREAD16LAZY@1DIGIT
        CMP     #' '
        BEQ     MONITORREAD16LAZY@1DIGIT
        LDA     MONBUF.B+2,X
        BEQ     MONITORREAD16LAZY@2DIGIT
        CMP     #' '
        BEQ     MONITORREAD16LAZY@2DIGIT
        LDA     MONBUF.B+3,X
        BEQ     MONITORREAD16LAZY@3DIGIT
        CMP     #' '
        BEQ     MONITORREAD16LAZY@3DIGIT
        BRA     MONITORREAD16
@1DIGIT:
        LDA     MONBUF.B,X
        JSR     MONITORREADHEX
        BCC     @RTS
        STA     MONNUM1.B
        STZ     MONNUM1+1.B
        INX
        SEC
@RTS    RTS
@2DIGIT:
        JSR     MONITORREAD8
        BCC     @RTS
        STZ     MONNUM1+1.B
        INX
        SEC
        RTS
@3DIGIT:
        LDA     MONBUF.B,X
        JSR     MONITORREADHEX
        BCC     @RTS
        INX
        STA     MONNUM1+1.B
        JSR     MONITORREAD8
        BCC     @RTS
        SEC
        RTS

; X is index into buffer
; carry set if success
; output to MONADDR1 and maybe MONBANK1
MONITORREADADDR:
.ACCU 8
        JSR     MONITORSKIPSPACES
        LDA     MONBUF,X
        BEQ     @RETC
        LDA     MONBUF+1,X
        BEQ     @RETC
        CMP     #':'
        BEQ     @BANK1
        LDA     MONBUF+2,X
        BEQ     @RETC
        CMP     #':'
        BEQ     @BANK2
@ADDR   JSR     MONITORREAD16
        BCC     @RET
        ACC16
        LDA     MONNUM1.B
        STA     MONADDR1.B
        ACC8
        SEC
        RTS
@RETC   CLC
@RET    RTS
@BANK1  LDA     MONBUF,X
        CMP     #'K'
        BNE     +
        LDA     MNREGK.B
        STA     MONBANK1.B
        BRA     @ADDR
+       CMP     #'B'
        BEQ     @RETC
        LDA     MNREGB.B
        STA     MONBANK1.B
        BRA     @ADDR
@BANK2  JSR     MONITORREAD8
        BCC     @RET
        LDA     MONNUM1.B
        STA     MONBANK1.B
        INX
        BRA     @ADDR

MONITORSKIPSPACES:
        LDA     MONBUF,X
        CMP     #' '
        BNE     +
        INX
        BRA     MONITORSKIPSPACES
+       RTS

MONITORADDR:
        ACC8
        LDX     #1
        LDA     MONBUF,X
        BEQ     @SHOW
        JSR     MONITORREAD16
        BCC     @ERROR
        ACC16
        LDA     MONNUM1.B
        STA     MONSTART.B
        RTS
@ERROR: JMP     MONITORERROR
@SHOW:  
        ACC16
        LDA     #13
        JSL     TEXT_WRCHR.L
        LDA     MONSTART.B
        JSL     WRITE_HEX_WORD.L
        RTS

MONITORBANK:
        ACC8
        LDX     #1
        LDA     MONBUF,X
        BEQ     @SHOW
        AND     #$DF
        CMP     #'D'
        BEQ     @DATA
        CMP     #'K'
        BEQ     @CODE
@ERROR  JMP     MONITORERROR
@CODE:
        INX
        JSR     MONITORREAD8
        BCC     @ERROR
        LDA     MONNUM1.B
        STA     MNREGK.B
        RTS
@DATA:
        INX
        JSR     MONITORREAD8
        BCC     @ERROR
        LDA     MONNUM1.B
        STA     MNREGB.B
        RTS
@SHOW:
        ACC8
        PHB
        LDA     #$01
        PHA
        PLB

        ACC16
        LDA     #MONITORDUMPREG_MSG_CR_K.W
        JSL     TEXT_WRSTR.L
        LDA     MNREGK.L
        JSL     WRITE_HEX_BYTE.L
        
        LDA     #MONITORDUMPREG_MSG_B.W
        JSL     TEXT_WRSTR.L
        LDA     MNREGB.L
        JSL     WRITE_HEX_BYTE.L

        PLB
        RTS

MONITORMEM:
.ACCU 8
        LDX     #1
        LDA     MONBUF.B,X
        BEQ     @NOADDR
        LDA     MNREGB.B
        STA     MONBANK1.B
        JSR     MONITORREADADDR.B
        BCC     @ERROR
        LDA     MONBUF.B,X
        BEQ     @READ1BYTE
        JSR     MONITORREAD16LAZY.B
        BCS     @READMANY
@ERROR  JMP     MONITORERROR.W
@NOADDR:
        ACC16
        LDA     MONADDRM.B
        STA     MONADDR1.B
        LDA     MONBANKM.B
        STA     MONBANK1.B
        LDA     #$0100
        STA     MONNUM1.B
        BRA     @READMANY
@READ1BYTE:
.ACCu 8
        LDA     #13
        JSL     TEXT_WRCHR.L
        LDA     MONBANK1.B
        ACC16
        JSL     WRITE_HEX_BYTE.L
        LDA     #':'
        JSL     TEXT_WRCHR.L
        LDA     MONADDR1.B
        JSL     WRITE_HEX_WORD.L
        ACC8
        LDA     #9
        JSL     TEXT_WRCHR.L
        JSL     TEXT_WRCHR.L
        LDA     [$FF&MONADDR1.B]
        ACC16
        JSL     WRITE_HEX_BYTE.L
        LDA     MONADDR1.B
        STA     MONADDRE.B
        INC     A
        STA     MONADDRM.B
        LDA     MONBANK1.B
        STA     MONBANKM.B
        STA     MONADDRE.B
@RTS    RTS
@READMANY:
        ACC16
        LDA     MONADDR1.B
        STA     MONADDRE.B
        LDA     MONBANK1.B
        STA     MONBANKE.B
        LDX     MONNUM1.B
        BEQ     @RTS
        LDA     MONADDR1.B
        EOR     #$000F
        INC     A
        AND     #$000F
        STA     MONTMP2.B
        LDA     MONADDR1.B
        AND     #$FFF0
        STA     MONADDR1.B
@YLOOP:
        STX     MONNUM1.B
        ACC8
        LDA     #13
        JSL     TEXT_WRCHR.L
        LDA     MONBANK1.B
        JSL     WRITE_HEX_BYTE8.L
        LDA     #':'
        JSL     TEXT_WRCHR.L
        ACC16
        LDA     MONADDR1.B
        JSL     WRITE_HEX_WORD.L
        ACC8
        LDA     #9
        JSL     TEXT_WRCHR.L
        JSL     TEXT_WRCHR.L
        LDY     MONTMP2.B
        BEQ     @XLOOP
        LDA     #' '
@SPLOOP:
        JSL     TEXT_WRCHR.L
        JSL     TEXT_WRCHR.L
        JSL     TEXT_WRCHR.L
        DEY
        BNE     @SPLOOP
        LDY     MONTMP2.B
@XLOOP:
        LDA     [$FF&MONADDR1.B],Y
        JSL     WRITE_HEX_BYTE8.L
        LDA     #' '
        JSL     TEXT_WRCHR.L
        INY
        CPY     #$10
        BCS     @XLOOPEXIT
        CPY     MONNUM1.B
        BCS     @XLOOPEXITNOW
        BRA     @XLOOP
@XLOOPEXIT:
        ACC16
        STZ     MONTMP2.B
        LDA     MONADDR1.B
        CLC
        ADC     #$0010
        STA     MONADDR1.B
        LDA     MONNUM1.B
        SEC
        SBC     #$0010
        BEQ     @XLOOPEXITNOW
        TAX
        JMP     @YLOOP.W
@XLOOPEXITNOW:
        LDA     MONADDR1.B
        STA     MONADDRM.B
        LDA     MONBANK1.B
        STA     MONBANKM.B
        RTS

MONITORENTER:
.ACCU 8
        LDX     #1
        LDA     MONBUF.B,X
        BEQ     @NOADDR
        LDA     MNREGB.B
        STA     MONBANK1.B
        JSR     MONITORREADADDR.B
        BCS     @ENTERLOOP
@ERROR  JMP     MONITORERROR.W
@NOADDR:
        ACC16
        LDA     MONADDRE.B
        STA     MONADDR1.B
        LDA     MONBANKE.B
        STA     MONBANK1.B
        LDA     #$0100
        STA     MONNUM1.B
@ENTERLOOP:
        ACC8
        LDA     #13
        JSL     TEXT_WRCHR.L
        LDA     MONBANK1.B
        JSL     WRITE_HEX_BYTE8.L
        LDA     #':'
        JSL     TEXT_WRCHR.L
        ACC16
        LDA     MONADDR1.B
        JSL     WRITE_HEX_WORD.L
        ACC8
        LDA     #9
        JSL     TEXT_WRCHR.L
        JSL     TEXT_WRCHR.L
        ACC16
        LDA     #$30
        STA     MNPRPLEN.B
        JSR     MONITORPROMPT
        LDA     #0
        ACC8
        SEC
        LDA     MONBUF.B
        BEQ     @EXIT           ; success
        LDX     #0
        JSR     MONITORENTERVERIFY
        BCC     @SOFTERR        ; error
@ENTERBYTE:
        JSR     MONITORSKIPSPACES
        LDA     MONBUF.B,X
        BEQ     @ENTERLOOP
        JSR     MONITORREAD8
        BCC     @EXIT
        LDA     MONNUM1.B
        STA     [$FF&MONADDR1]
        INC     MONADDR1.B
        BRA     @ENTERBYTE
@SOFTERR:
        ACC16
        JSR     MONITORERROR.W
        BRA     @ENTERLOOP
@EXIT:
        ACC16
        LDA     MONADDR1.B
        STA     MONADDRE.B
        LDA     MONBANK1.B
        STA     MONBANKE.B
        BCS     +
        JMP     MONITORERROR.W
+       RTS

MONITORENTERVERIFY:
.ACCU 8
        PHX
@LOOP   JSR     MONITORSKIPSPACES
        LDA     MONBUF.B,X
        BEQ     @RETOK
        JSR     MONITORREADHEX
        BCC     @RET
        INX
        LDA     MONBUF.B,X
        JSR     MONITORREADHEX
        BCC     @RET
        INX
        BRA     @LOOP
@RETOK  SEC
@RET    PLX
        RTS

MONITORCOPY:
        ACC8
        LDA     MNREGB.B
        STA     MONBANK1.B
        STA     MONBANK2.B
        LDX     #1
        JSR     MONITORREADADDR.W
        BCC     @ERROR
        ACC16
        LDA     MONADDR1.B
        STA     MONADDR2.B
        ACC8
        LDA     MONBANK1.B
        STA     MONBANK2.B
        JSR     MONITORREADADDR.W
        BCC     @ERROR
        JSR     MONITORREAD16LAZY.W
        BCS     @OK
@ERROR  JMP     MONITORERROR.W
@OK     ACC16
        LDA     MONNUM1.B
        BEQ     @RET
        ACC8
        LDA     [$FF&MONADDR1]
        STA     [$FF&MONADDR2]
        ACC16
        INC     MONADDR1.B
        INC     MONADDR2.B
        DEC     MONNUM1.B
        BRA     @OK
@RET    RTS

MONITORCOMPARE:
        ACC8
        LDA     MNREGB.B
        STA     MONBANK1.B
        STA     MONBANK2.B
        LDX     #1
        JSR     MONITORREADADDR.W
        BCC     @ERROR
        ACC16
        LDA     MONADDR1.B
        STA     MONADDR2.B
        ACC8
        LDA     MONBANK1.B
        STA     MONBANK2.B
        JSR     MONITORREADADDR.W
        BCC     @ERROR
        JSR     MONITORREAD16LAZY.W
        BCS     @OK
@ERROR  JMP     MONITORERROR.W
@OK     ACC16
        LDA     MONNUM1.B
        BEQ     @RET
        ACC8
        LDA     [$FF&MONADDR1]
        CMP     [$FF&MONADDR2]
        BEQ     +

        ACC16
        LDA     #13
        JSL     TEXT_WRCHR.L
        LDA     MONBANK2.B
        JSL     WRITE_HEX_BYTE.L
        LDA     #':'
        JSL     TEXT_WRCHR.L
        LDA     MONADDR2.B
        JSL     WRITE_HEX_WORD.L

        LDX     #5
        LDA     #' '
-       JSL     TEXT_WRCHR.L
        DEX
        BNE     -

        ACC8
        LDA     [$FF&MONADDR2]
        JSL     WRITE_HEX_BYTE8.L

        LDX     #2
        LDA     #' '
-       JSL     TEXT_WRCHR.L
        DEX
        BNE     -

        LDA     [$FF&MONADDR1]
        JSL     WRITE_HEX_BYTE8.L
        ACC16

        LDX     #5
        LDA     #' '
-       JSL     TEXT_WRCHR.L
        DEX
        BNE     -
        
        LDA     MONBANK1.B
        JSL     WRITE_HEX_BYTE.L
        LDA     #':'
        JSL     TEXT_WRCHR.L
        LDA     MONADDR1.B
        JSL     WRITE_HEX_WORD.L

+       ACC16
        INC     MONADDR1.B
        INC     MONADDR2.B
        DEC     MONNUM1.B
        JMP     @OK
@RET    RTS

MONITORUNTIL:
        ACC8
        LDA     MNREGK.B
        STA     MONBANK1.B
        LDX     #1
        JSR     MONITORREADADDR.W
        BCS     +
@ERROR  JMP     MONITORERROR
+       LDA     MNBPFLAG.B
        BEQ     +
        LDA     MNBPINST.B
        STA     [MNBPADDR.B]
+       LDA     [MONADDR1.B]
        STA     MNBPINST.B
        ACC16
        LDA     MONADDR1.B
        STA     MNBPADDR.B
        ACC8
        LDA     MONBANK1.B
        STA     MNBPADDR+2.B
        LDA     #0
        STA     [MNBPADDR.B]
        BRA     MONITORGO@NOX
MONITORGO:
        ACC8
        LDX     #1
@NOX    LDA     MONBUF.B,X
        BNE     @STARTAT
        LDA     MONBREAK.B
        BNE     @RESUME
        ACC16
        LDA     MONSTART.B
        STA     MNREGPC.B
        ACC8
        LDA     MONSBANK.B
        STA     MNREGK.B
        BRA     @START
@STARTAT:
.ACCu 8
        JSR     MONITORREADADDR.W
        BCC     MONITORUNTIL@ERROR
        ACC16
        LDA     MONADDR1.B
        STA     MNREGPC.B
        ACC8
        LDA     MONADDR1+2.B
        STA     MNREGK.B
@START:
        ACC8
        LDA     #$FF
        STA     MONBREAK.B
        PHK
        PEA     @STARTEND-1
        ACC16
        TSC
        STA     MNREGS.B
        ACC8
@RESUME:
        LDA     #$5C
        STA     MNREGJML.B
        AXY16
        LDX     MNREGX.B
        LDY     MNREGY.B
        LDA     MNREGD.B
        TCD
        ACC8
        LDA     MONPAGE|MNREGB.W
        PHA
        PLB
        ACC16
        LDA     MONBPAGE|MNREGS.L
        TCS
        ACC8
        LDA     MONBPAGE|MNREGP.L
        PHA
        ACC16
        LDA     MONBPAGE|MNREGACC.L
        PLP
        JML     MONBPAGE|MNREGJML.L
@STARTEND:
        PHP
        PHB
        PHD
        AXY16
        PHA
        ACC8
        LDA     #$80
        PHA
        PLB
        STZ     MONPAGE|MONBREAK.W
        ACC16
        LDA     #MONPAGE
        TCD
        ACC8
        LDA     6,S
        STA     MNREGP.B
        LDA     5,S
        STA     MNREGB.B
        ACC16
        LDA     3,S
        STA     MNREGD.B
        LDA     1,S
        STA     MNREGACC.B
        PLA
        PLA
        PLA
        TSC
        STA     MNREGS.B
        STX     MNREGX.B
        STY     MNREGY.B
        JMP     MONITORDUMPREG

.DEFINE DISASMINSTRS 10
MONITORDISASM:
        ACC8
        LDA     MONBANKA.B
        STA     MONBANK1.B
        LDX     #1
        LDA     MONBUF.B,X
        BNE     @ADDR
        BRA     @START
@ADDR   JSR     MONITORREADADDR.W
        BCC     @ERROR
        ACC16
        LDA     MONADDR1.B
        STA     MONADDRA.B
        ACC8
        LDA     MONBANK1.B
        STA     MONBANKA.B
        BRA     @START
@ERROR  JMP     MONITORERROR.W
@START  LDA     MNREGP.B
        ASL     A
        ASL     A
        AND     #$C0
        STA     MNAXYSZ.B
        ACC16
        LDA     #0
        LDY     #DISASMINSTRS
@ILOOP  ACC16
        LDA     #13
        JSL     TEXT_WRCHR.L
        LDA     MONBANKA.B
        JSL     WRITE_HEX_BYTE.L
        LDA     #':'
        JSL     TEXT_WRCHR.L
        LDA     MONADDRA.B
        JSL     WRITE_HEX_WORD.L
        LDA     #9
        JSL     TEXT_WRCHR.L
        JSL     TEXT_WRCHR.L
        ACC8
        PHY
        JSR     MONITOR_AM_nextbyte.W
        TAX
        PHX
        JSL     WRITE_HEX_BYTE8.L
        LDA     #' '
        JSL     TEXT_WRCHR.L
        JSR     MONITORGETINSTRSIZE.W
        BEQ     +
        STA     MONTMP3.B
        LDY     #0
-       LDA     [MONADDRA.B],Y
        JSL     WRITE_HEX_BYTE8.L
        LDA     #' '
        JSL     TEXT_WRCHR.L
        INY
        CPY     MONTMP3.B
        BCC     -
+       LDX     #36
        JSL     TEXT_MVCURX.L
        PLX
        LDA     MONITORDISASMINSTR1.L,X
        JSL     TEXT_WRCHR.L
        LDA     MONITORDISASMINSTR2.L,X
        JSL     TEXT_WRCHR.L
        LDA     MONITORDISASMINSTR3.L,X
        JSL     TEXT_WRCHR.L
        LDA     #9
        JSL     TEXT_WRCHR.L
        CPX     #$C2
        BEQ     @REP
        CPX     #$E2
        BEQ     @SEP
@CONT   ACC16
        TXA
        ASL     A
        TAX
        ACC8
        JSR     (MONITORDISASMMODES.L,X)
        PLY
        DEY
        BEQ     +
        JMP     @ILOOP
+       RTS
@REP    LDA     [MONADDRA.B]
        EOR     #$FF
        ASL     A
        ASL     A
        AND     MNAXYSZ.B
        STA     MNAXYSZ.B
        BRA     @CONT
@SEP    LDA     [MONADDRA.B]
        ORA     MNAXYSZ.B
        AND     #$C0
        STA     MNAXYSZ.B
        BRA     @CONT

MONITORGETINSTRSIZE:
        LDA     MONITORDISASMBYTES.L,X
        CMP     #$FE
        BEQ     @X
        CMP     #$FF
        BEQ     @A
        DEC     A
        RTS
@X:
        LDA     #1
        BIT     MNAXYSZ.B
        BVS     +
        INC     A
+       RTS
@A:
        LDA     #1
        BIT     MNAXYSZ.B
        BMI     +
        INC     A
+       RTS

MONITORROUTINES:
        .DW     MONITORERROR                    ; A
        .DW     MONITORBANK                     ; B
        .DW     MONITORCOPY                     ; C
        .DW     MONITORDISASM                   ; D
        .DW     MONITORENTER                    ; E
        .DW     MONITORERROR                    ; F
        .DW     MONITORGO                       ; G
        .DW     MONITORERROR                    ; H
        .DW     MONITORERROR                    ; I
        .DW     MONITORERROR                    ; J
        .DW     MONITORERROR                    ; K
        .DW     MONITORERROR                    ; L
        .DW     MONITORMEM                      ; M
        .DW     MONITORERROR                    ; N
        .DW     MONITORCOMPARE                  ; O
        .DW     MONITORERROR                    ; P
        .DW     MONITORQUIT                     ; Q
        .DW     MONITORREG                      ; R
        .DW     MONITORERROR                    ; S
        .DW     MONITORERROR                    ; T
        .DW     MONITORUNTIL                    ; U
        .DW     MONITORERROR                    ; V
        .DW     MONITORERROR                    ; W
        .DW     MONITORADDR                     ; X
        .DW     MONITORERROR                    ; Y
        .DW     MONITORERROR                    ; Z

MONITORPROMPT:
        ACC16
        STZ     MNLINELN.B
        STZ     MNLINEPS.B
        STA     MONBLINK.B
@LOOP:
        JSL     KEYB_UPDKEYSI.L
        LDA     #28
        LDX     #26
        JSL     KEYB_GETKEY.L
        ACC16
        BEQ     @LOOP
        BCC     @LOOP
        CMP     #$0D
        BEQ     @CR
        CMP     #$08
        BEQ     @BKSP
        CMP     #$1E
        BEQ     @ARRLEFT
        CMP     #$1F
        BEQ     @ARRRIGHT
        CMP     #$7F
        BEQ     @LOOP
        CMP     #$20
        BCC     @LOOP
@NORMAL:
        LDX     MNLINELN.B
        CPX     MNPRPLEN.B
        BCS     @LOOP
        STA     MONBUF.B,X
        INC     MNLINEPS.B
        INX
        STX     MNLINELN.B
        JSL     TEXT_WRCHR
        BRA     @LOOP
@ARRLEFT:
        LDX     MNLINEPS.B
        BEQ     @LOOP
        DEC     MNLINEPS.B
        JSL     TEXT_WRCHR
        BRA     @LOOP
@ARRRIGHT:
        LDX     MNLINEPS.B
        CPX     MNLINELN.B
        BCS     @LOOP
        INC     MNLINEPS.B
        JSL     TEXT_WRCHR
        BRA     @LOOP
@BKSP:
        LDX     MNLINEPS.B
        BEQ     @LOOP
        STA     MONBUF.B,X
        DEX
        STX     MNLINEPS.B
        DEC     MNLINELN.B
        JSL     TEXT_WRCHR
        BRL     @LOOP
@CR:
        LDX     MNLINELN.B
        STZ     MONBUF.B,X
        INX
        STX     MNLINELN.B
        STZ     MONBLINK.B
        RTS

MONITORQUIT:
        AXY16

        LDX     #MONBRKOL.W
        LDY     #$0001.W
        JSL     ROM_UNSWAPBRK.L

        LDX     #MONNMIOL.W
        LDY     #$0001.W
        JSL     ROM_UNSWAPNMI.L

        ACC8
        LDA     #$01
        STA     IOBANK|EINTGNRC.L
        LDA     #$00
        STA     IOBANK|VPUCNTRL.L
        LDA     #$80
        PHA
        PLB
        LDA     OLDREGK.B
        PHA
        ACC16
        LDA     OLDREGPC.B
        PHA
        ACC8
        LDA     OLDREGP.B
        PHA
        LDA     OLDREGB.B
        PHA
        ACC16
        LDA     OLDREGD.B
        PHA
        PLD
        PLB
        PLP
        RTL

MLMONBRK:
        SETBD16 $80, MONPAGE
        LDA     15,S
        STX     MNREGPC.B
        LDA     12,S
        STA     MNREGACC.B
        LDA     10,S
        STA     MNREGX.B
        LDA     8,S
        STA     MNREGY.B
        LDA     5,S
        STA     MNREGD.B
        LDA     #0
        ACC8
        LDA     7,S
        STA     MNREGB.B
        LDA     14,S
        STA     MNREGP.B
        LDA     17,S
        STA     MNREGK.B
        AXY16
        TSC
        CLC
        ADC     #17
        STA     MNREGS.B
        TCS
        JMP     MONCODEBRK

MLMONNMI:
        SETB16  $01
        LDA     MONBPAGE|MONINNMI.L
        BNE     @NMIRET
        DEC     A
        STA     MONBPAGE|MONINNMI.L
        JSL     KEYB_INCTIMER
        SETB16  $80
        LDA     MONPAGE|MONBLINK.W
        BEQ     +
        JSL     TEXT_FLASHCUR
        ACC16
+       LDA     #0
        STA     MONBPAGE|MONINNMI.L
        BRA     +
@NMIRET SETB16  $80
+       JML     [MONPAGE|MONNMIOL.W]

MONITORMSGERROR:
        .DB     13,"=ERROR=",0

ALIGNPAGE

MONITORDISASMINSTR1:
        .DB     "BOCOTOAOPOAPTOAOBOOOTOAOCOITTOAO"
        .DB     "JAJABARAPARPBARABAAABARASADTBARA"
        .DB     "REWEMELEPELPJELEBEEEMELECEPTJELE"
        .DB     "RAPASARAPARRJARABAAASARASAPTJARA"
        .DB     "BSBSSSSSDBTPSSSSBSSSSSSSTSTTSSSS"
        .DB     "LLLLLLLLTLTPLLLLBLLLLLLLCLTTLLLL"
        .DB     "CCRCCCDCICDWCCDCBCCCPCDCCCPSJCDC"
        .DB     "CSSSCSISISNXCSISBSSSPSISSSPXJSIS"
MONITORDISASMINSTR2:
        .DB     "RRORSRSRHRSHSRSRPRRRRRSRLRNCRRSR"
        .DB     "SNSNINONLNOLINONMNNNINONENESINON"
        .DB     "TODOVOSOHOSHMOSOVOOOVOSOLOHCMOSO"
        .DB     "TDEDTDODLDOTMDODVDDDTDODEDLDMDOD"
        .DB     "RTRTTTTTEIXHTTTTCTTTTTTTYTXXTTTT"
        .DB     "DDDDDDDDADALDDDDCDDDDDDDLDSYDDDD"
        .DB     "PMEMPMEMNMEAPMEMNMMMEMEMLMHTMMEM"
        .DB     "PBEBPBNBNBOBPBNBEBBBEBNBEBLCSBNB"
MONITORDISASMINSTR3:
        .DB     "KAPABALAPALDBALALAAABALACACSBALA"
        .DB     "RDLDTDLDPDLDTDLDIDDDTDLDCDCCTDLD"
        .DB     "IRMRPRRRARRKPRRRCRRRNRRRIRYDLRRR"
        .DB     "SCRCZCRCACRLPCRCSCCCZCRCICYCPCRC"
        .DB     "AALAYAXAYTABYAXACAAAYAXAAASYZAZA"
        .DB     "YAXAYAXAYAXBYAXASAAAYAXAVAXXYAXA"
        .DB     "YPPPYPCPYPXIYPCPEPPPIPCPDPXPPPCP"
        .DB     "XCPCXCCCXCPAXCCCQCCCACCCDCXERCCC"
MONITORDISASMBYTES:                     ; $FE: 2 if XY=8b, 3 if XY=16b
                                        ; $FF: 2 if A =8b, 3 if A =16b
        .DB     2,2,2,2,2,2,2,2,1,$FF,1,1,3,3,3,4
        .DB     2,2,2,2,2,2,2,2,1,3,1,1,3,3,3,4
        .DB     3,2,4,2,2,2,2,2,1,$FF,1,1,3,3,3,4
        .DB     2,2,2,2,2,2,2,2,1,3,1,1,3,3,3,4
        .DB     1,2,2,2,3,2,2,2,1,$FF,1,1,3,3,3,4
        .DB     2,2,2,2,3,2,2,2,1,3,1,1,4,3,3,4
        .DB     1,2,3,2,2,2,2,2,1,$FF,1,1,3,3,3,4
        .DB     2,2,2,2,2,2,2,2,1,3,1,1,3,3,3,4
        .DB     2,2,3,2,2,2,2,2,1,$FF,1,1,3,3,3,4
        .DB     2,2,2,2,2,2,2,2,1,3,1,1,3,3,3,4
        .DB     $FE,2,$FE,2,2,2,2,2,1,$FF,1,1,3,3,3,4
        .DB     2,2,2,2,2,2,2,2,1,3,1,1,3,3,3,4
        .DB     $FE,2,2,2,2,2,2,2,1,$FF,1,1,3,3,3,4
        .DB     2,2,2,2,2,2,2,2,1,3,1,1,3,3,3,4
        .DB     $FE,2,2,2,2,2,2,2,1,$FF,1,1,3,3,3,4
        .DB     2,2,2,2,3,2,2,2,1,3,1,1,3,3,3,4
MONITORDISASMMODES:
        .DW     MONITOR_AM_imm.W
        .DW     MONITOR_AM_idpx.W
        .DW     MONITOR_AM_imm.W
        .DW     MONITOR_AM_sr.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_idpl.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_immA.W
        .DW     MONITOR_AM_acc.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abl.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_idpy.W
        .DW     MONITOR_AM_idp.W
        .DW     MONITOR_AM_idsy.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_idly.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_absy.W
        .DW     MONITOR_AM_acc.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_absx.W
        .DW     MONITOR_AM_absx.W
        .DW     MONITOR_AM_ablx.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_idpx.W
        .DW     MONITOR_AM_abl.W
        .DW     MONITOR_AM_sr.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_idpl.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_immA.W
        .DW     MONITOR_AM_acc.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abl.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_idpy.W
        .DW     MONITOR_AM_idp.W
        .DW     MONITOR_AM_idsy.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_idly.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_absy.W
        .DW     MONITOR_AM_acc.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_absx.W
        .DW     MONITOR_AM_absx.W
        .DW     MONITOR_AM_absx.W
        .DW     MONITOR_AM_ablx.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_idpx.W
        .DW     MONITOR_AM_imm.W
        .DW     MONITOR_AM_sr.W
        .DW     MONITOR_AM_bm.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_idpl.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_immA.W
        .DW     MONITOR_AM_acc.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abl.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_idpy.W
        .DW     MONITOR_AM_idp.W
        .DW     MONITOR_AM_idsy.W
        .DW     MONITOR_AM_bm.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_idly.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_absy.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_abl.W
        .DW     MONITOR_AM_absx.W
        .DW     MONITOR_AM_absx.W
        .DW     MONITOR_AM_ablx.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_idpx.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_sr.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_idpl.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_immA.W
        .DW     MONITOR_AM_acc.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_iabs.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abl.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_idpy.W
        .DW     MONITOR_AM_idp.W
        .DW     MONITOR_AM_idsy.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_idly.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_absy.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_iabx.W
        .DW     MONITOR_AM_absx.W
        .DW     MONITOR_AM_absx.W
        .DW     MONITOR_AM_ablx.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_idpx.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_sr.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_idpl.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_immA.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abl.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_idpy.W
        .DW     MONITOR_AM_idp.W
        .DW     MONITOR_AM_idsy.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_dpy.W
        .DW     MONITOR_AM_idly.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_absy.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_absx.W
        .DW     MONITOR_AM_absx.W
        .DW     MONITOR_AM_ablx.W
        .DW     MONITOR_AM_immX.W
        .DW     MONITOR_AM_idpx.W
        .DW     MONITOR_AM_immX.W
        .DW     MONITOR_AM_sr.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_idpl.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_immA.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abl.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_idpy.W
        .DW     MONITOR_AM_idp.W
        .DW     MONITOR_AM_idsy.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_dpy.W
        .DW     MONITOR_AM_idly.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_absy.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_absx.W
        .DW     MONITOR_AM_absx.W
        .DW     MONITOR_AM_absy.W
        .DW     MONITOR_AM_ablx.W
        .DW     MONITOR_AM_imm.W
        .DW     MONITOR_AM_idpx.W
        .DW     MONITOR_AM_imm.W
        .DW     MONITOR_AM_sr.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_idpl.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_immA.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abl.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_idpy.W
        .DW     MONITOR_AM_idp.W
        .DW     MONITOR_AM_idsy.W
        .DW     MONITOR_AM_idp.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_idly.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_absy.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_iabl.W
        .DW     MONITOR_AM_absx.W
        .DW     MONITOR_AM_absx.W
        .DW     MONITOR_AM_ablx.W
        .DW     MONITOR_AM_imm.W
        .DW     MONITOR_AM_idpx.W
        .DW     MONITOR_AM_imm.W
        .DW     MONITOR_AM_sr.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_idpl.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_immA.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_abl.W
        .DW     MONITOR_AM_dp.W
        .DW     MONITOR_AM_idpy.W
        .DW     MONITOR_AM_idp.W
        .DW     MONITOR_AM_idsy.W
        .DW     MONITOR_AM_abs.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_dpx.W
        .DW     MONITOR_AM_idly.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_absy.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_none.W
        .DW     MONITOR_AM_iabx.W
        .DW     MONITOR_AM_absx.W
        .DW     MONITOR_AM_absx.W
        .DW     MONITOR_AM_ablx.W

MONITOR_AM_nextbyte:
        LDA     [MONADDRA.B]
        ACC16
        INC     MONADDRA.B
        ACC8
        RTS

MONITOR_AM_none:
        RTS
MONITOR_AM_acc:
        LDA     #'A'
        JSL     TEXT_WRCHR.L
        RTS
MONITOR_AM_immX:
        BIT     MNAXYSZ.B
        BVC     MONITOR_AM_immw
        BRA     MONITOR_AM_imm
MONITOR_AM_immA:
        BIT     MNAXYSZ.B
        BPL     MONITOR_AM_immw
MONITOR_AM_imm:
        LDA     #'#'
        JSL     TEXT_WRCHR.L
MONITOR_AM_dp:
        LDA     #'$'
        JSL     TEXT_WRCHR.L
        JSR     MONITOR_AM_nextbyte.W
        JSL     WRITE_HEX_BYTE8.L
        RTS
MONITOR_AM_dpx:
        JSR     MONITOR_AM_dp.W
        LDA     #','
        JSL     TEXT_WRCHR.L
        LDA     #'X'
        JSL     TEXT_WRCHR.L
        RTS
MONITOR_AM_dpy:
        JSR     MONITOR_AM_dp.W
        LDA     #','
        JSL     TEXT_WRCHR.L
        LDA     #'Y'
        JSL     TEXT_WRCHR.L
        RTS
MONITOR_AM_sr:
        JSR     MONITOR_AM_dp.W
        LDA     #','
        JSL     TEXT_WRCHR.L
        LDA     #'S'
        JSL     TEXT_WRCHR.L
        RTS
MONITOR_AM_immw:
        LDA     #'#'
        JSL     TEXT_WRCHR.L
MONITOR_AM_abs:
        LDA     #'$'
        JSL     TEXT_WRCHR.L
        JSR     MONITOR_AM_nextbyte.W
        PHA
        JSR     MONITOR_AM_nextbyte.W
        JSL     WRITE_HEX_BYTE8.L
        PLA
        JSL     WRITE_HEX_BYTE8.L
        RTS
MONITOR_AM_absx:
        JSR     MONITOR_AM_abs.W
        LDA     #','
        JSL     TEXT_WRCHR.L
        LDA     #'X'
        JSL     TEXT_WRCHR.L
        RTS
MONITOR_AM_absy:
        JSR     MONITOR_AM_abs.W
        LDA     #','
        JSL     TEXT_WRCHR.L
        LDA     #'Y'
        JSL     TEXT_WRCHR.L
        RTS
MONITOR_AM_abl:
        LDA     #'$'
        JSL     TEXT_WRCHR.L
        JSR     MONITOR_AM_nextbyte.W
        PHA
        JSR     MONITOR_AM_nextbyte.W
        PHA
        JSR     MONITOR_AM_nextbyte.W
        JSL     WRITE_HEX_BYTE8.L
        PLA
        JSL     WRITE_HEX_BYTE8.L
        PLA
        JSL     WRITE_HEX_BYTE8.L
        RTS
MONITOR_AM_ablx:
        JSR     MONITOR_AM_abs.W
        LDA     #','
        JSL     TEXT_WRCHR.L
        LDA     #'X'
        JSL     TEXT_WRCHR.L
        RTS
MONITOR_AM_bm:
        JSR     MONITOR_AM_dp.W
        PHA
        JSR     MONITOR_AM_dp.W
        JSL     WRITE_HEX_BYTE.L
        LDA     #','
        JSL     TEXT_WRCHR.L
        PLA
        JSL     WRITE_HEX_BYTE.L
        RTS
MONITOR_AM_iabs:
        LDA     #'('
        JSL     TEXT_WRCHR.L
        JSR     MONITOR_AM_abs.W
        LDA     #')'
        JSL     TEXT_WRCHR.L
        RTS
MONITOR_AM_iabx:
        LDA     #'('
        JSL     TEXT_WRCHR.L
        JSR     MONITOR_AM_absx.W
        LDA     #')'
        JSL     TEXT_WRCHR.L
        RTS
MONITOR_AM_iabl:
        LDA     #'['
        JSL     TEXT_WRCHR.L
        JSR     MONITOR_AM_abs.W
        LDA     #']'
        JSL     TEXT_WRCHR.L
        RTS
MONITOR_AM_idp:
        LDA     #'('
        JSL     TEXT_WRCHR.L
        JSR     MONITOR_AM_dp.W
        LDA     #')'
        JSL     TEXT_WRCHR.L
        RTS
MONITOR_AM_idpl:
        LDA     #'['
        JSL     TEXT_WRCHR.L
        JSR     MONITOR_AM_dp.W
        LDA     #']'
        JSL     TEXT_WRCHR.L
        RTS
MONITOR_AM_idpx:
        LDA     #'('
        JSL     TEXT_WRCHR.L
        JSR     MONITOR_AM_dpx.W
        LDA     #')'
        JSL     TEXT_WRCHR.L
        RTS
MONITOR_AM_idpy:
        JSR     MONITOR_AM_idp.W
        LDA     #','
        JSL     TEXT_WRCHR.L
        LDA     #'Y'
        JSL     TEXT_WRCHR.L
        RTS
MONITOR_AM_idly:
        JSR     MONITOR_AM_idpl.W
        LDA     #','
        JSL     TEXT_WRCHR.L
        LDA     #'Y'
        JSL     TEXT_WRCHR.L
        RTS
MONITOR_AM_idsy:
        LDA     #'('
        JSL     TEXT_WRCHR.L
        JSR     MONITOR_AM_sr.W
        LDA     #')'
        JSL     TEXT_WRCHR.L
        LDA     #','
        JSL     TEXT_WRCHR.L
        LDA     #'Y'
        JSL     TEXT_WRCHR.L
        RTS
