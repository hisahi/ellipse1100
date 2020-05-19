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
.DEFINE MNEMUL   $2C
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
        STA     MONBANKA.B
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
        ACC16
        PHB
        PEA     $0101
        PLB
        PLB
        LDA     #MONITORMSGBRK.W
        JSL     TEXT_WRSTR.L
        PLB
        ACC8
        LDA     MNBPFLAG.B
        BEQ     +
        STZ     MNBPFLAG.B
        LDA     MNBPINST.B
        STA     [MNBPADDR.B]
+       JSR     MONITORDUMPREG
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
        .DB     "  PC=",0
MONITORDUMPREG_MSG_K:  
        .DB     "  K=",0
MONITORDUMPREG_MSG_B:  
        .DB     "  B=",0
MONITORDUMPREG_MSG_D:  
        .DB     "  D=",0
MONITORDUMPREG_MSG_CR_K:  
        .DB     13,"K=",0
MONITORDUMPREG_BRK:
        .DB     "BRK",0

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
        
        LDA     MONBPAGE|MNEMUL.L
        BNE     +
        LDA     #' '
        JSL     TEXT_WRCHR.L
        BRA     ++
+       LDA     #'e'
        JSL     TEXT_WRCHR.L
++        
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
        
        LDA     #' '
        JSL     TEXT_WRCHR.L
        JSL     TEXT_WRCHR.L
        LDA     MONBPAGE|MONBREAK.L
        BEQ     +
        LDA     #MONITORDUMPREG_BRK.W
        JSL     TEXT_WRSTR.L
+
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
        BEQ     @EXITSAFE      ; success
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
@EXITSAFE:
        SEC
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
        LDA     #$FF
        STA     MNBPFLAG.B
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
        STZ     MNEMUL.B
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
        LDA     MONBPAGE|MNEMUL.L
        BNE     @RESUME_E
        ACC16
        LDA     MONBPAGE|MNREGACC.L
        PLP
        JML     MONBPAGE|MNREGJML.L
@RESUME_E:
        ACC16
        LDA     MONBPAGE|MNREGACC.L
        SEC
        XCE
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
        PHB
        PEA     $0101
        PLB
        PLB
        LDA     #MONITORMSGRTL.W
        JSL     TEXT_WRSTR.L
        PLB
        ACC8
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
        SEC
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

MONITORASM:
.ACCU 8
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
@START:
        LDA     MNREGP.B
        ASL     A
        ASL     A
        AND     #$C0
        STA     MNAXYSZ.B
@ENTERLOOP:
        ACC8
        LDA     #13
        JSL     TEXT_WRCHR.L
        LDA     MONBANKA.B
        JSL     WRITE_HEX_BYTE8.L
        LDA     #':'
        JSL     TEXT_WRCHR.L
        ACC16
        LDA     MONADDRA.B
        JSL     WRITE_HEX_WORD.L
        ACC8
        LDA     #9
        JSL     TEXT_WRCHR.L
        JSL     TEXT_WRCHR.L
        LDX     #36
        SEC
        JSL     TEXT_MVCURX.L
        ACC16
        LDA     #40
        STA     MNPRPLEN.B
        JSR     MONITORPROMPT
        LDA     #0
        ACC8
        SEC
        LDA     MONBUF.B
        BEQ     @EXIT           ; success
        LDX     #16
        SEC
        JSL     TEXT_MVCURX.L
        JSR     MONITORASMINSTRUCTION@GO
        BCC     @SOFTERR        ; error
        BRA     @ENTERLOOP
@SOFTERR:
        ACC16
        JSR     MONITORERROR.W
        BRA     @ENTERLOOP
@EXITSAFE:
        SEC
@EXIT:
        ACC16
        BCS     +
        JMP     MONITORERROR.W
+       RTS

MONITORASMINSTRUCTION:
@NOINSTR:
        SEC
        RTS
@ERROR:
        CLC
        RTS
@GO:
.ACCU 8
        LDX     #0
        JSR     MONITORSKIPSPACES
        LDA     MONBUF.B,X
        BEQ     @NOINSTR
        AND     #$DF
        STA     MONBUF.B,X
        LDA     MONBUF+1.B,X
        BEQ     @ERROR
        AND     #$DF
        STA     MONBUF+1.B,X
        LDA     MONBUF+2.B,X
        BEQ     @ERROR
        AND     #$DF
        STA     MONBUF+2.B,X
        
        LDA     MONBUF.B,X
        CMP     #4
        BEQ     @NOINSTR
        CMP     #14
        BNE     @NOTDOT
        LDA     MONBUF+1.B,X
        CMP     #'D'
        BNE     @ERROR
        LDA     MONBUF+2.B,X
        CMP     #'B'
        BEQ     @DB
        CMP     #'W'
        BNE     @ERROR
@DW:
        BRA     @ERROR
@DB:
        BRA     @ERROR
@NOTDOT:
        CMP     #'A'
        BCC     @ERROR
        CMP     #'Z'+1
        BCS     @ERROR
        SEC
        SBC     #'A'
        ASL     A
        PHX
        TXY
        TAX
        ACC16
        LDA     MONITORASMINSTR_LETTERS.L,X
        ACC8
        TAX
@SEARCHLOOP:
        LDA     MONITORASMINSTR_START.L,X 
        BEQ     @SEARCHNOTFOUND
        CMP     MONPAGE|MONBUF+1.W,Y
        BNE     @SEARCHNOTMATCH
        LDA     MONITORASMINSTR_START+1.L,X 
        CMP     MONPAGE|MONBUF+2.W,Y
        BNE     @SEARCHNOTMATCH
        ACC16
        LDA     MONITORASMINSTR_START+2.L,X
        STA     MONTMP4.B
        PLX
        ACC8
@FOUND  INX
        INX
        INX
        JSR     MONITORSKIPSPACES.W
        JMP     (MONPAGE|MONTMP4.W)
@SEARCHNOTMATCH:
        INX
        INX
        INX
        INX
        BRA     @SEARCHLOOP
@SEARCHNOTFOUND:
        PLX
        CLC
        RTS

MONITORROUTINES:
        .DW     MONITORASM                      ; A
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
        LDA     MONINNMI.B
        BEQ     +
        DEC     MONINNMI.B
        JSL     KEYB_INCTIMER.L
        LDA     MONBLINK.B
        BEQ     +
        JSL     TEXT_FLASHCUR.L
+       JSL     KEYB_UPDKEYSI.L
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

MONITORMSGBRK:
        .DB     13,"## BRK",0
MONITORMSGRTL:
        .DB     13,"## RTL",0
MONITORMSGERROR:
        .DB     13,"## ERROR ##",0

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
        .DW     MONITOR_AM_rel8.W
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
        .DW     MONITOR_AM_rel8.W
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
        .DW     MONITOR_AM_rel8.W
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
        .DW     MONITOR_AM_rel16.W
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
        .DW     MONITOR_AM_rel8.W
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
        .DW     MONITOR_AM_rel8.W
        .DW     MONITOR_AM_idpx.W
        .DW     MONITOR_AM_rel16.W
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
        .DW     MONITOR_AM_rel8.W
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
        .DW     MONITOR_AM_rel8.W
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
        .DW     MONITOR_AM_rel8.W
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
        .DW     MONITOR_AM_rel8.W
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
MONITOR_AM_rel8:
        LDA     #'$'
        JSL     TEXT_WRCHR.L
        JSR     MONITOR_AM_nextbyte.W
        STA     MONTMP1.B
        STZ     MONTMP1+1.B
        BPL     +
        DEC     MONTMP1+1.B
+       ACC16
        LDA     MONTMP1.B
        CLC
        ADC     MONADDRA.B
        JSL     WRITE_HEX_WORD.L
        ACC8
        RTS
MONITOR_AM_rel16:
        LDA     #'$'
        JSL     TEXT_WRCHR.L
        JSR     MONITOR_AM_nextbyte.W
        STA     MONTMP1.B
        JSR     MONITOR_AM_nextbyte.W
        STA     MONTMP1+1.B
        ACC16
        LDA     MONTMP1.B
        CLC
        ADC     MONADDRA.B
        JSL     WRITE_HEX_WORD.L
        ACC8
        RTS

MONITORASMINSTR_LETTERS:
        .DW MONITORASMINSTR_A-MONITORASMINSTR_START
        .DW MONITORASMINSTR_B-MONITORASMINSTR_START
        .DW MONITORASMINSTR_C-MONITORASMINSTR_START
        .DW MONITORASMINSTR_D-MONITORASMINSTR_START
        .DW MONITORASMINSTR_E-MONITORASMINSTR_START
        .DW MONITORASMINSTR_EMPTY-MONITORASMINSTR_START
        .DW MONITORASMINSTR_EMPTY-MONITORASMINSTR_START
        .DW MONITORASMINSTR_EMPTY-MONITORASMINSTR_START
        .DW MONITORASMINSTR_I-MONITORASMINSTR_START
        .DW MONITORASMINSTR_J-MONITORASMINSTR_START
        .DW MONITORASMINSTR_EMPTY-MONITORASMINSTR_START
        .DW MONITORASMINSTR_L-MONITORASMINSTR_START
        .DW MONITORASMINSTR_M-MONITORASMINSTR_START
        .DW MONITORASMINSTR_N-MONITORASMINSTR_START
        .DW MONITORASMINSTR_O-MONITORASMINSTR_START
        .DW MONITORASMINSTR_P-MONITORASMINSTR_START
        .DW MONITORASMINSTR_EMPTY-MONITORASMINSTR_START
        .DW MONITORASMINSTR_R-MONITORASMINSTR_START
        .DW MONITORASMINSTR_S-MONITORASMINSTR_START
        .DW MONITORASMINSTR_T-MONITORASMINSTR_START
        .DW MONITORASMINSTR_EMPTY-MONITORASMINSTR_START
        .DW MONITORASMINSTR_EMPTY-MONITORASMINSTR_START
        .DW MONITORASMINSTR_W-MONITORASMINSTR_START
        .DW MONITORASMINSTR_X-MONITORASMINSTR_START
        .DW MONITORASMINSTR_EMPTY-MONITORASMINSTR_START
        .DW MONITORASMINSTR_EMPTY-MONITORASMINSTR_START

MONITOR_INSTR_outbyte:
        PHA
        STA     [MONADDRA.B]
        JSL     WRITE_HEX_BYTE8.L
        LDA     #' '
        JSL     TEXT_WRCHR.L
        ACC16
        INC     MONADDRA.B
        ACC8
        PLA
        RTS

MONITOR_ASM_SKIPDOLLAR:
        LDA     MONBUF.B,X
        CMP     #'$'
        BNE     +
        INX
+       RTS

MONITOR_ASM_INSTR_STA:
        LDA     MONBUF.B,X
        CMP     #'#'
        BNE     +
        CLC
        RTS
+       LDA     #$80
        BRA     MONITOR_ASM_INSTR_ALU_READ.W
MONITOR_ASM_INSTR_ORA:
        LDA     #$00
        BRA     MONITOR_ASM_INSTR_ALU_READ.W
MONITOR_ASM_INSTR_AND:
        LDA     #$20
        BRA     MONITOR_ASM_INSTR_ALU_READ.W
MONITOR_ASM_INSTR_EOR:
        LDA     #$40
        BRA     MONITOR_ASM_INSTR_ALU_READ.W
MONITOR_ASM_INSTR_ADC:
        LDA     #$60
        BRA     MONITOR_ASM_INSTR_ALU_READ.W
MONITOR_ASM_INSTR_SBC:
        LDA     #$E0
        BRA     MONITOR_ASM_INSTR_ALU_READ.W
MONITOR_ASM_INSTR_CMP:
        LDA     #$C0
        BRA     MONITOR_ASM_INSTR_ALU_READ.W
MONITOR_ASM_INSTR_LDA:
        LDA     #$A0
        ;BRA     MONITOR_ASM_INSTR_ALU_READ.W
MONITOR_ASM_INSTR_ALU_READ:
        STA     MONTMP1.B
        LDA     MONBUF.B,X
        CMP     #'#'
        BEQ     @IMM
        CMP     #'['
        BEQ     @ILNG
        CMP     #'('
        BNE     +
        JMP     @IND
+       JSR     MONITOR_ASM_SKIPDOLLAR.W
        LDA     MONBUF.B+4,X
        JSR     MONITORREADHEX.W
        BCC     +
        JMP     @ABSL
+       LDA     MONBUF.B+2,X
        JSR     MONITORREADHEX.W
        BCC     @DP
        JMP     @ABS
@DP     JSR     MONITORREAD8.W
        BCC     @RTS
        JSR     MONITORSKIPSPACES.W
        LDA     MONBUF.B,X
        BNE     @DPC
        LDA     MONTMP1.B
        ORA     #$05
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
@OK     SEC
@RTS    RTS
@DPC    CMP     #','
        BNE     @ERR
        LDA     MONBUF.B+1,X
        AND     #$DF
        CMP     #'X'
        BNE     +
        LDA     #$15
        BRA     @DPCOK
+       CMP     #'S'
        BNE     @ERR
        LDA     #$03
@DPCOK  ORA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@ERR    CLC
        RTS
@IMM    INX
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        JSR     MONITORREAD16LAZY.W
        BCC     @RTS
        LDA     MONTMP1.B
        ORA     #$09
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        BIT     MNAXYSZ.B
        BMI     @A8
        LDA     MONNUM1+1.B
        JSR     MONITOR_INSTR_outbyte.W
@A8     SEC
        RTS
@ILNG   INX
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        JSR     MONITORREAD8.W
        BCC     @RTS
        LDA     MONBUF.B,X
        CMP     #']'
        BNE     @ERR
        INX
        LDA     MONBUF.B,X
        BNE     @ILNGI
        LDA     #$07
@ILOK   ORA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
@OK2    SEC
@RTS2   RTS
@ILNGI  CMP     #','
        BNE     @ERR
        LDA     MONBUF+1.B,X
        AND     #$DF
        CMP     #'Y'
        BNE     @ERR
        LDA     #$17
        BRA     @ILOK
@IND    INX
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        JSR     MONITORREAD8.W
        BCC     @RTS2
        LDA     MONBUF.B,X
        CMP     #','
        BEQ     @INDX
        CMP     #')'
        BNE     @ERR2
        LDA     MONBUF+1.B,X
        BNE     @INDY
        LDA     #$12
@INDOK  ORA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        BRA     @OK2
@INDX   LDA     MONBUF+1.B,X
        AND     #$DF
        CMP     #'S'
        BEQ     @INDS
        CMP     #'X'
        BNE     @ERR2
        LDA     MONBUF+2.B,X
        CMP     #')'
        BNE     @ERR2
        INX
        INX
        INX
        JSR     MONITORSKIPSPACES.W
        LDA     MONBUF.B,X
        BNE     @ERR2
        LDA     #$01
        BRA     @INDOK
@INDY   CMP     #','
        BNE     @ERR2
        LDA     MONBUF+2.B,X
        AND     #$DF
        CMP     #'Y'
        BNE     @ERR2
        LDA     #$11
        BRA     @INDOK
@INDS   LDA     MONBUF+2.B,X
        CMP     #')'
        BNE     @ERR2
        LDA     MONBUF+3.B,X
        CMP     #','
        BNE     @ERR2
        LDA     MONBUF+4.B,X
        AND     #$DF
        CMP     #'Y'
        BNE     @ERR2
        LDA     #$13
        BRA     @INDOK
@ERR2   CLC
@RTS3   RTS
@ABSL   JSR     MONITORREAD8.W
        BCC     @RTS3
        LDA     MONNUM1.B
        STA     MONNUM2.B
        JSR     MONITORREAD16.W
        BCC     @RTS3
        JSR     MONITORSKIPSPACES.W
        LDA     MONBUF.B,X
        BNE     @ABSLI
        LDA     #$0F
@ALOK   ORA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1+1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM2.B
        JSR     MONITOR_INSTR_outbyte.W
@OK3    SEC
        RTS
@ABSLI  CMP     #','
        BNE     @ERR2
        LDA     MONBUF+1.B,X
        AND     #$DF
        CMP     #'X'
        BNE     @ERR2
        LDA     #$1F
        BRA     @ALOK
@ABS    JSR     MONITORREAD16.W
        BCC     @RTS3
        JSR     MONITORSKIPSPACES.W
        LDA     MONBUF.B,X
        BNE     @ABSI
        LDA     #$0D
@ABOK   ORA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1+1.B
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@ABSI   CMP     #','
        BNE     @ERR2
        LDA     MONBUF+1.B,X
        AND     #$DF
        CMP     #'X'
        BNE     +
        LDA     #$1D
        BRA     @ABOK
+       CMP     #'Y'
        BNE     @ERR2
        LDA     #$19
        BRA     @ABOK

MONITOR_ASM_INSTR_DEC:
        LDA     MONBUF.B,X
        BEQ     @DEC_A
        AND     #$DF
        CMP     #'A'
        BNE     @DEC_NOT_A
        LDA     MONBUF.B+1,X
        BNE     @DEC_NOT_A
@DEC_A:
        LDA     #$3A
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@DEC_NOT_A:
        LDA     #$C0
        BRA     MONITOR_ASM_INSTR_RMW
MONITOR_ASM_INSTR_INC:
        LDA     MONBUF.B,X
        BEQ     @INC_A
        AND     #$DF
        CMP     #'A'
        BNE     @INC_NOT_A
        LDA     MONBUF.B+1,X
        BNE     @INC_NOT_A
@INC_A:
        LDA     #$1A
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@INC_NOT_A:
        LDA     #$E0
        BRA     MONITOR_ASM_INSTR_RMW
MONITOR_ASM_INSTR_ASL:
        LDA     #$00
        BRA     MONITOR_ASM_INSTR_RMW
MONITOR_ASM_INSTR_LSR:
        LDA     #$40
        BRA     MONITOR_ASM_INSTR_RMW
MONITOR_ASM_INSTR_ROL:
        LDA     #$20
        BRA     MONITOR_ASM_INSTR_RMW
MONITOR_ASM_INSTR_ROR:
        LDA     #$60
        ;BRA     MONITOR_ASM_INSTR_RMW
MONITOR_ASM_INSTR_RMW:
        STA     MONTMP1.B
        LDA     MONBUF.B,X
        BEQ     @YES_ACC
        AND     #$DF
        CMP     #'A'
        BNE     @NOT_ACC
        LDA     MONBUF+1.B,X
        BNE     @NOT_ACC
@YES_ACC:
        LDA     MONTMP1.B
        ORA     #$0A
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@NOT_ACC:
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        LDA     MONBUF.B+2,X
        JSR     MONITORREADHEX.W
        BCS     @ABS
@DP     JSR     MONITORREAD8.W
        BCC     @RTS
        JSR     MONITORSKIPSPACES.W
        LDA     MONBUF.B,X
        BNE     @DPI
        LDA     #$06
@DPOK   ORA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
@OK     SEC
@RTS    RTS
@DPI    CMP     #','
        BNE     @ERR
        LDA     MONBUF+1.B,X
        AND     #$DF
        CMP     #'X'
        BNE     @ERR
        LDA     #$16
        BRA     @DPOK
@ERR    CLC
        RTS
@ABS    JSR     MONITORREAD16.W
        BCC     @RTS
        JSR     MONITORSKIPSPACES.W
        LDA     MONBUF.B,X
        BNE     @ABSI
        LDA     #$0E
@ABOK   ORA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1+1.B
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@ABSI   CMP     #','
        BNE     @ERR
        LDA     MONBUF+1.B,X
        AND     #$DF
        CMP     #'X'
        BNE     @ERR
        LDA     #$1E
        BRA     @ABOK

MONITOR_ASM_INSTR_BPL:
        LDA     #$10
        BRA     MONITOR_ASM_INSTR_BRANCH
MONITOR_ASM_INSTR_BMI:
        LDA     #$30
        BRA     MONITOR_ASM_INSTR_BRANCH
MONITOR_ASM_INSTR_BVC:
        LDA     #$50
        BRA     MONITOR_ASM_INSTR_BRANCH
MONITOR_ASM_INSTR_BVS:
        LDA     #$70
        BRA     MONITOR_ASM_INSTR_BRANCH
MONITOR_ASM_INSTR_BCC:
        LDA     #$90
        BRA     MONITOR_ASM_INSTR_BRANCH
MONITOR_ASM_INSTR_BCS:
        LDA     #$B0
        BRA     MONITOR_ASM_INSTR_BRANCH
MONITOR_ASM_INSTR_BNE:
        LDA     #$D0
        BRA     MONITOR_ASM_INSTR_BRANCH
MONITOR_ASM_INSTR_BEQ:
        LDA     #$F0
        BRA     MONITOR_ASM_INSTR_BRANCH
MONITOR_ASM_INSTR_BRA:
        LDA     #$80
MONITOR_ASM_INSTR_BRANCH:
        STA     MONTMP1.B
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        JSR     MONITORREAD16.W
        BCC     @RTS
        ACC16
@DBG    LDA     MONNUM1.B
        SEC
        SBC     #2
        SEC
        SBC     MONADDRA.B
        BMI     @BMI
        CMP     #$0080
        BCS     @ERR
@BMIOK  ACC8
        PHA
        LDA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        PLA
        JSR     MONITOR_INSTR_outbyte.W
@OK     SEC
@RTS    RTS
.ACCU 16
@BMI    CMP     #$FF80
        BCS     @BMIOK
.ACCU 8
@ERR    CLC
        RTS

MONITOR_ASM_INSTR_JMP:
        LDA     MONBUF.B,X
        CMP     #'('
        BEQ     @IND
        CMP     #'['
        BEQ     @INDL
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        JSR     MONITORREAD16.W
        BCC     @RTS
        LDA     #$4C
@JMPOK  JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1+1.B
        JSR     MONITOR_INSTR_outbyte.W
@OK     SEC
@RTS    RTS
@ERR    CLC
        RTS
@IND    INX
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        JSR     MONITORREAD16.W
        BCC     @RTS
        LDA     MONBUF.B,X
        CMP     #','
        BEQ     @INDX
        CMP     #')'
        BNE     @ERR
        LDA     #$6C
        BRA     @JMPOK
@INDX   LDA     MONBUF+1.B,X
        AND     #$DF
        CMP     #'X'
        BNE     @ERR
        LDA     MONBUF+2.B,X 
        CMP     #')'
        BNE     @ERR
        LDA     #$7C
        BRA     @JMPOK
@INDL   INX
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        JSR     MONITORREAD16.W
        BCC     @RTS
        LDA     MONBUF.B,X
        CMP     #']'
        BNE     @ERR
        LDA     #$DC
        BRA     @JMPOK
MONITOR_ASM_INSTR_JML:
        LDA     MONBUF.B,X
        CMP     #'['
        BEQ     MONITOR_ASM_INSTR_JMP@INDL
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        JSR     MONITORREAD8.W
        BCC     @RTS
        LDA     MONNUM1.B
        STA     MONNUM2.B
        JSR     MONITORREAD16.W
        BCC     @RTS
        LDA     #$5C
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1+1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM2.B
        JSR     MONITOR_INSTR_outbyte.W
        SEC
@RTS    RTS

MONITOR_ASM_INSTR_JSR:
        LDA     MONBUF.B,X
        CMP     #'('
        BEQ     @IND
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        JSR     MONITORREAD16.W
        BCC     @RTS
        LDA     #$20
@JMPOK  JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1+1.B
        JSR     MONITOR_INSTR_outbyte.W
@OK     SEC
@RTS    RTS
@ERR    CLC
        RTS
@IND    INX
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        JSR     MONITORREAD16.W
        BCC     @RTS
        LDA     MONBUF.B,X
        CMP     #','
        BNE     @ERR
        LDA     MONBUF+1.B,X
        AND     #$DF
        CMP     #'X'
        BNE     @ERR
        LDA     MONBUF+2.B,X 
        CMP     #')'
        BNE     @ERR
        LDA     #$FC
        BRA     @JMPOK
MONITOR_ASM_INSTR_JSL:
        LDA     MONBUF.B,X
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        JSR     MONITORREAD8.W
        BCC     @RTS
        LDA     MONNUM1.B
        STA     MONNUM2.B
        JSR     MONITORREAD16.W
        BCC     @RTS
        LDA     #$22
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1+1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM2.B
        JSR     MONITOR_INSTR_outbyte.W
        SEC
@RTS    RTS

MONITOR_ASM_INSTR_REP:
        LDA     MONBUF.B,X
        CMP     #'#'
        BNE     @ERR
        INX
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        JSR     MONITORREAD8.W
        BCC     @ERR
        LDA     MONNUM1.B
        ASL     A
        ASL     A
        EOR     #$C0
        AND     MNAXYSZ.B
        STA     MNAXYSZ.B
        LDA     #$C2
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@ERR    CLC
        RTS

MONITOR_ASM_INSTR_BM_READ:
        LDA     MONBUF.B,X
        CMP     #'#'
        BNE     +
        INX
+       JSR     MONITOR_ASM_SKIPDOLLAR.W
        JMP     MONITORREAD8.W

MONITOR_ASM_INSTR_MVN:
        JSR     MONITOR_ASM_INSTR_BM_READ
        BCC     @ERR
        LDA     MONBUF.B,X
        CMP     #','
        BNE     @ERR
        INX
        JSR     MONITORSKIPSPACES.W
        LDA     MONNUM1.B
        STA     MONNUM2.B
        JSR     MONITOR_ASM_INSTR_BM_READ
        BCC     @ERR
        LDA     #$54
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM2.B
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@ERR    CLC
        RTS

MONITOR_ASM_INSTR_MVP:
        JSR     MONITOR_ASM_INSTR_BM_READ
        BCC     @ERR
        LDA     MONBUF.B,X
        CMP     #','
        BNE     @ERR
        JSR     MONITORSKIPSPACES.W
        LDA     MONNUM1.B
        STA     MONNUM2.B
        JSR     MONITOR_ASM_INSTR_BM_READ
        BCC     @ERR
        LDA     #$44
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM2.B
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@ERR    CLC
        RTS

MONITOR_ASM_INSTR_BRK:
        LDA     MONBUF.B,X
        BEQ     @ZEROCONSTANT
        JSR     MONITOR_ASM_INSTR_BM_READ
        BCC     @ERR
        LDA     #$00
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@ZEROCONSTANT:
        LDA     #$00
        JSR     MONITOR_INSTR_outbyte.W
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@ERR    CLC
        RTS

MONITOR_ASM_INSTR_COP:
        LDA     MONBUF.B,X
        BEQ     @ZEROCONSTANT
        JSR     MONITOR_ASM_INSTR_BM_READ
        BCC     @ERR
        LDA     #$02
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@ZEROCONSTANT:
        LDA     #$02
        JSR     MONITOR_INSTR_outbyte.W
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@ERR    CLC
        RTS

MONITOR_ASM_INSTR_SEP:
        LDA     MONBUF.B,X
        CMP     #'#'
        BNE     @ERR
        INX
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        JSR     MONITORREAD8.W
        BCC     @ERR
        LDA     MONNUM1.B
        ASL     A
        ASL     A
        AND     #$C0
        ORA     MNAXYSZ.B
        STA     MNAXYSZ.B
        LDA     #$E2
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@ERR    CLC
        RTS

MONITOR_ASM_INSTR_PEA:
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        JSR     MONITORREAD16.W
        BCC     @ERR
        LDA     #$F4
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1+1.B
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@ERR    CLC
        RTS

MONITOR_ASM_INSTR_PEI:
        LDA     MONBUF.B,X
        CMP     #'('
        BNE     @ERR
        INX
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        JSR     MONITORREAD8.W
        BCC     @ERR
        LDA     MONBUF.B,X
        CMP     #')'
        BNE     @ERR
        INX
        LDA     #$D4
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@ERR    CLC
        RTS

MONITOR_ASM_INSTR_PER:
        LDA     #$62
        BRA     MONITOR_ASM_INSTR_PER_BRL
MONITOR_ASM_INSTR_BRL:
        LDA     #$82
MONITOR_ASM_INSTR_PER_BRL:
        STA     MONTMP1.B
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        JSR     MONITORREAD16.W
        BCC     @ERR
        ACC16
        LDA     MONNUM1.B
        SEC
        SBC     #3
        SEC
        SBC     MONADDRA.B
        STA     MONNUM1.B
        ACC8
        LDA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1+1.B
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@ERR    CLC
        RTS

MONITOR_ASM_INSTR_TRB:
        LDA     #$10
        STA     MONTMP1.B
        LDA     MONBUF.B,X
        CMP     #'#'
        BEQ     MONITOR_ASM_INSTR_PER_BRL@ERR
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        LDA     MONBUF.B+2,X
        JSR     MONITORREADHEX.W
        BRA     MONITOR_ASM_INSTR_CPXY_REST
MONITOR_ASM_INSTR_TSB:
        LDA     #$00
        STA     MONTMP1.B
        LDA     MONBUF.B,X
        CMP     #'#'
        BEQ     MONITOR_ASM_INSTR_PER_BRL@ERR
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        LDA     MONBUF.B+2,X
        JSR     MONITORREADHEX.W
        BRA     MONITOR_ASM_INSTR_CPXY_REST
MONITOR_ASM_INSTR_CPX:
        LDA     #$E0
        STA     MONTMP1.B
        LDA     MONBUF.B,X
        CMP     #'#'
        BEQ     MONITOR_ASM_INSTR_CPY@IMM
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        LDA     MONBUF.B+2,X
        JSR     MONITORREADHEX.W
        BRA     MONITOR_ASM_INSTR_CPXY_REST
MONITOR_ASM_INSTR_CPY:
        LDA     #$C0
        STA     MONTMP1.B
        LDA     MONBUF.B,X
        CMP     #'#'
        BEQ     @IMM
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        LDA     MONBUF.B+2,X
        JSR     MONITORREADHEX.W
        BRA     MONITOR_ASM_INSTR_CPXY_REST
@IMM:
        JMP     MONITOR_ASM_INSTR_LDX@IMM
MONITOR_ASM_INSTR_CPXY_REST:
        BCS     @ABS
@DP     JSR     MONITORREAD8.W
        BCC     @RET
        LDA     MONTMP1.B
        ORA     #$04
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
@OK     SEC
@RET    RTS
@ABS    JSR     MONITORREAD16.W
        BCC     @RET
        LDA     MONTMP1.B
        ORA     #$0C
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1+1.B
        JSR     MONITOR_INSTR_outbyte.W
        BRA     @OK
MONITOR_ASM_INSTR_LDX:
        LDA     #$A2
        STA     MONTMP1.B
        LDA     MONBUF.B,X
        CMP     #'#'
        BEQ     @IMM
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        LDA     MONBUF.B+2,X
        JSR     MONITORREADHEX.W
        BCS     @ABS
@DP     JSR     MONITORREAD8.W
        BCC     @RET
        JSR     MONITORSKIPSPACES.W
        LDA     MONBUF.B,X
        BNE     @DPI
        LDA     #$04
@DPOK   ORA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
@OK     SEC
@RET    RTS
@DPI    CMP     #','
        BNE     @ERR
        LDA     MONBUF+1.B,X
        AND     #$DF
        CMP     #'Y'
        BNE     @ERR
        LDA     #$14
        BRA     @DPOK
@ERR    CLC
        RTS
@ABS    JSR     MONITORREAD16.W
        BCC     @RET
        JSR     MONITORSKIPSPACES.W
        LDA     MONBUF.B,X
        BNE     @ABSI
        LDA     #$0C
@ABOK   ORA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1+1.B
        JSR     MONITOR_INSTR_outbyte.W
        BRA     @OK
@ABSI   CMP     #','
        BNE     @ERR
        LDA     MONBUF+1.B,X
        AND     #$DF
        CMP     #'Y'
        BNE     @ERR
        LDA     #$1C
        BRA     @ABOK
@IMM    INX
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        JSR     MONITORREAD16LAZY.W
        BCC     @RTS
        LDA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        BIT     MNAXYSZ.B
        BVS     @X8
        LDA     MONNUM1+1.B
        JSR     MONITOR_INSTR_outbyte.W
@X8     SEC
@RTS    RTS
MONITOR_ASM_INSTR_BIT:
        LDA     #$20
        STA     MONTMP1.B
        LDA     MONBUF.B,X
        CMP     #'#'
        BNE     MONITOR_ASM_INSTR_LDY@NS
@IMM    LDA     #$80
        STA     MONTMP1.B
        BRL     MONITOR_ASM_INSTR_ALU_READ@IMM
MONITOR_ASM_INSTR_LDY:
        LDA     #$A0
        STA     MONTMP1.B
        LDA     MONBUF.B,X
        CMP     #'#'
        BEQ     MONITOR_ASM_INSTR_LDX@IMM
@NS     JSR     MONITOR_ASM_SKIPDOLLAR.W
        LDA     MONBUF.B+2,X
        JSR     MONITORREADHEX.W
        BCS     @ABS
@DP     JSR     MONITORREAD8.W
        BCC     @RET
        JSR     MONITORSKIPSPACES.W
        LDA     MONBUF.B,X
        BNE     @DPI
        LDA     #$04
@DPOK   ORA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
@OK     SEC
@RET    RTS
@DPI    CMP     #','
        BNE     @ERR
        LDA     MONBUF+1.B,X
        AND     #$DF
        CMP     #'X'
        BNE     @ERR
        LDA     #$14
        BRA     @DPOK
@ERR    CLC
        RTS
@ABS    JSR     MONITORREAD16.W
        BCC     @RET
        JSR     MONITORSKIPSPACES.W
        LDA     MONBUF.B,X
        BNE     @ABSI
        LDA     #$0C
@ABOK   ORA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1+1.B
        JSR     MONITOR_INSTR_outbyte.W
        BRA     @OK
@ABSI   CMP     #','
        BNE     @ERR
        LDA     MONBUF+1.B,X
        AND     #$DF
        CMP     #'X'
        BNE     @ERR
        LDA     #$1C
        BRA     @ABOK

MONITOR_ASM_INSTR_STX:
        LDA     #$86
        STA     MONTMP1.B
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        LDA     MONBUF.B+2,X
        JSR     MONITORREADHEX.W
        BCS     @ABS
@DP     JSR     MONITORREAD8.W
        BCC     @RET
        JSR     MONITORSKIPSPACES.W
        LDA     MONBUF.B,X
        BNE     @DPI
        LDA     #$04
@DPOK   ORA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
@OK     SEC
@RET    RTS
@DPI    CMP     #','
        BNE     @ERR
        LDA     MONBUF+1.B,X
        AND     #$DF
        CMP     #'Y'
        BNE     @ERR
        LDA     #$14
        BRA     @DPOK
@ERR    CLC
        RTS
@ABS    JSR     MONITORREAD16.W
        BCC     @RET
        JSR     MONITORSKIPSPACES.W
        LDA     MONBUF.B,X
        BNE     @ERR
        LDA     #$0C
        ORA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1+1.B
        JSR     MONITOR_INSTR_outbyte.W
        BRA     @OK
MONITOR_ASM_INSTR_STY:
        LDA     #$84
        STA     MONTMP1.B
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        LDA     MONBUF.B+2,X
        JSR     MONITORREADHEX.W
        BCS     @ABS
@DP     JSR     MONITORREAD8.W
        BCC     @RET
        JSR     MONITORSKIPSPACES.W
        LDA     MONBUF.B,X
        BNE     @DPI
        LDA     #$04
@DPOK   ORA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
@OK     SEC
@RET    RTS
@DPI    CMP     #','
        BNE     @ERR
        LDA     MONBUF+1.B,X
        AND     #$DF
        CMP     #'X'
        BNE     @ERR
        LDA     #$14
        BRA     @DPOK
@ERR    CLC
        RTS
@ABS    JSR     MONITORREAD16.W
        BCC     @RET
        JSR     MONITORSKIPSPACES.W
        LDA     MONBUF.B,X
        BNE     @ERR
        LDA     #$0C
        ORA     MONTMP1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1+1.B
        JSR     MONITOR_INSTR_outbyte.W
        BRA     @OK

MONITOR_ASM_INSTR_STZ:
        JSR     MONITOR_ASM_SKIPDOLLAR.W
        LDA     MONBUF.B+2,X
        JSR     MONITORREADHEX.W
        BCS     @ABS
@DP     JSR     MONITORREAD8.W
        BCC     @RET
        JSR     MONITORSKIPSPACES.W
        LDA     MONBUF.B,X
        BNE     @DPI
        LDA     #$64
@DPOK   JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
@OK     SEC
@RET    RTS
@DPI    CMP     #','
        BNE     @ERR
        LDA     MONBUF+1.B,X
        AND     #$DF
        CMP     #'X'
        BNE     @ERR
        LDA     #$74
        BRA     @DPOK
@ERR    CLC
        RTS
@ABS    JSR     MONITORREAD16.W
        BCC     @RET
        JSR     MONITORSKIPSPACES.W
        LDA     MONBUF.B,X
        BNE     @ABSI
        LDA     #$9C
@ABOK   JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1.B
        JSR     MONITOR_INSTR_outbyte.W
        LDA     MONNUM1+1.B
        JSR     MONITOR_INSTR_outbyte.W
        BRA     @OK
@ABSI   CMP     #','
        BNE     @ERR
        LDA     MONBUF+1.B,X
        AND     #$DF
        CMP     #'X'
        BNE     @ERR
        LDA     #$9E
        BRA     @ABOK

.MACRO MONITOR_SINGLE_BYTE_INSTR
        LDA     MONBUF.B,X
        BNE     @ERR
        LDA     #\1
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@ERR:   CLC
        RTS
.ENDM

MONITOR_ASM_INSTR_WDM:
        LDA     MONBUF.B,X
        BNE     @ERR
        LDA     #$42
        JSR     MONITOR_INSTR_outbyte.W
        JSR     MONITOR_INSTR_outbyte.W
        SEC
        RTS
@ERR:   CLC
        RTS

MONITOR_ASM_INSTR_DEX:
        MONITOR_SINGLE_BYTE_INSTR $CA
MONITOR_ASM_INSTR_DEY:
        MONITOR_SINGLE_BYTE_INSTR $88
MONITOR_ASM_INSTR_INX:
        MONITOR_SINGLE_BYTE_INSTR $E8
MONITOR_ASM_INSTR_INY:
        MONITOR_SINGLE_BYTE_INSTR $C8
MONITOR_ASM_INSTR_CLC:
        MONITOR_SINGLE_BYTE_INSTR $18
MONITOR_ASM_INSTR_CLD:
        MONITOR_SINGLE_BYTE_INSTR $D8
MONITOR_ASM_INSTR_CLI:
        MONITOR_SINGLE_BYTE_INSTR $58
MONITOR_ASM_INSTR_CLV:
        MONITOR_SINGLE_BYTE_INSTR $B8
MONITOR_ASM_INSTR_SEC:
        MONITOR_SINGLE_BYTE_INSTR $38
MONITOR_ASM_INSTR_SED:
        MONITOR_SINGLE_BYTE_INSTR $F8
MONITOR_ASM_INSTR_SEI:
        MONITOR_SINGLE_BYTE_INSTR $78
MONITOR_ASM_INSTR_PHA:
        MONITOR_SINGLE_BYTE_INSTR $48
MONITOR_ASM_INSTR_PHB:
        MONITOR_SINGLE_BYTE_INSTR $8B
MONITOR_ASM_INSTR_PHD:
        MONITOR_SINGLE_BYTE_INSTR $0B
MONITOR_ASM_INSTR_PHK:
        MONITOR_SINGLE_BYTE_INSTR $4B
MONITOR_ASM_INSTR_PHP:
        MONITOR_SINGLE_BYTE_INSTR $08
MONITOR_ASM_INSTR_PHX:
        MONITOR_SINGLE_BYTE_INSTR $DA
MONITOR_ASM_INSTR_PHY:
        MONITOR_SINGLE_BYTE_INSTR $5A
MONITOR_ASM_INSTR_PLA:
        MONITOR_SINGLE_BYTE_INSTR $68
MONITOR_ASM_INSTR_PLB:
        MONITOR_SINGLE_BYTE_INSTR $AB
MONITOR_ASM_INSTR_PLD:
        MONITOR_SINGLE_BYTE_INSTR $2B
MONITOR_ASM_INSTR_PLP:
        MONITOR_SINGLE_BYTE_INSTR $28
MONITOR_ASM_INSTR_PLX:
        MONITOR_SINGLE_BYTE_INSTR $FA
MONITOR_ASM_INSTR_PLY:
        MONITOR_SINGLE_BYTE_INSTR $7A
MONITOR_ASM_INSTR_TAX:
        MONITOR_SINGLE_BYTE_INSTR $AA
MONITOR_ASM_INSTR_TAY:
        MONITOR_SINGLE_BYTE_INSTR $A8
MONITOR_ASM_INSTR_TSX:
        MONITOR_SINGLE_BYTE_INSTR $BA
MONITOR_ASM_INSTR_TXA:
        MONITOR_SINGLE_BYTE_INSTR $8A
MONITOR_ASM_INSTR_TXS:
        MONITOR_SINGLE_BYTE_INSTR $9A
MONITOR_ASM_INSTR_TXY:
        MONITOR_SINGLE_BYTE_INSTR $9B
MONITOR_ASM_INSTR_TYA:
        MONITOR_SINGLE_BYTE_INSTR $98
MONITOR_ASM_INSTR_TYX:
        MONITOR_SINGLE_BYTE_INSTR $BB
MONITOR_ASM_INSTR_TCD:
        MONITOR_SINGLE_BYTE_INSTR $5B
MONITOR_ASM_INSTR_TCS:
        MONITOR_SINGLE_BYTE_INSTR $1B
MONITOR_ASM_INSTR_TDC:
        MONITOR_SINGLE_BYTE_INSTR $7B
MONITOR_ASM_INSTR_TSC:
        MONITOR_SINGLE_BYTE_INSTR $3B
MONITOR_ASM_INSTR_RTL:
        MONITOR_SINGLE_BYTE_INSTR $6B
MONITOR_ASM_INSTR_RTS:
        MONITOR_SINGLE_BYTE_INSTR $60
MONITOR_ASM_INSTR_RTI:
        MONITOR_SINGLE_BYTE_INSTR $40
MONITOR_ASM_INSTR_STP:
        MONITOR_SINGLE_BYTE_INSTR $DB
MONITOR_ASM_INSTR_WAI:
        MONITOR_SINGLE_BYTE_INSTR $CB
MONITOR_ASM_INSTR_XBA:
        MONITOR_SINGLE_BYTE_INSTR $EB
MONITOR_ASM_INSTR_XCE:
        MONITOR_SINGLE_BYTE_INSTR $FB
MONITOR_ASM_INSTR_NOP:
        MONITOR_SINGLE_BYTE_INSTR $EA

MONITORASMINSTR_START:
MONITORASMINSTR_A:
        .DB "DC"
        .DW MONITOR_ASM_INSTR_ADC
        .DB "ND"
        .DW MONITOR_ASM_INSTR_AND
        .DB "SL"
        .DW MONITOR_ASM_INSTR_ASL
MONITORASMINSTR_EMPTY:
        .DB 0
MONITORASMINSTR_B:
        .DB "CC"
        .DW MONITOR_ASM_INSTR_BCC
        .DB "CS"
        .DW MONITOR_ASM_INSTR_BCS
        .DB "EQ"
        .DW MONITOR_ASM_INSTR_BEQ
        .DB "IT"
        .DW MONITOR_ASM_INSTR_BIT
        .DB "MI"
        .DW MONITOR_ASM_INSTR_BMI
        .DB "NE"
        .DW MONITOR_ASM_INSTR_BNE
        .DB "PL"
        .DW MONITOR_ASM_INSTR_BPL
        .DB "RA"
        .DW MONITOR_ASM_INSTR_BRA
        .DB "RK"
        .DW MONITOR_ASM_INSTR_BRK
        .DB "RL"
        .DW MONITOR_ASM_INSTR_BRL
        .DB "VC"
        .DW MONITOR_ASM_INSTR_BVC
        .DB "VS"
        .DW MONITOR_ASM_INSTR_BVS
        .DB 0
MONITORASMINSTR_C:
        .DB "LC"
        .DW MONITOR_ASM_INSTR_CLC
        .DB "LD"
        .DW MONITOR_ASM_INSTR_CLD
        .DB "LI"
        .DW MONITOR_ASM_INSTR_CLI
        .DB "LV"
        .DW MONITOR_ASM_INSTR_CLV
        .DB "MP"
        .DW MONITOR_ASM_INSTR_CMP
        .DB "OP"
        .DW MONITOR_ASM_INSTR_COP
        .DB "PX"
        .DW MONITOR_ASM_INSTR_CPX
        .DB "PY"
        .DW MONITOR_ASM_INSTR_CPY
        .DB 0
MONITORASMINSTR_D:
        .DB "EC"
        .DW MONITOR_ASM_INSTR_DEC
        .DB "EX"
        .DW MONITOR_ASM_INSTR_DEX
        .DB "EY"
        .DW MONITOR_ASM_INSTR_DEY
        .DB 0
MONITORASMINSTR_E:
        .DB "OR"
        .DW MONITOR_ASM_INSTR_EOR
        .DB 0
MONITORASMINSTR_I:
        .DB "NC"
        .DW MONITOR_ASM_INSTR_INC
        .DB "NX"
        .DW MONITOR_ASM_INSTR_INX
        .DB "NY"
        .DW MONITOR_ASM_INSTR_INY
        .DB 0
MONITORASMINSTR_J:
        .DB "ML"
        .DW MONITOR_ASM_INSTR_JML
        .DB "MP"
        .DW MONITOR_ASM_INSTR_JMP
        .DB "SL"
        .DW MONITOR_ASM_INSTR_JSL
        .DB "SR"
        .DW MONITOR_ASM_INSTR_JSR
        .DB 0
MONITORASMINSTR_L:
        .DB "DA"
        .DW MONITOR_ASM_INSTR_LDA
        .DB "DX"
        .DW MONITOR_ASM_INSTR_LDX
        .DB "DY"
        .DW MONITOR_ASM_INSTR_LDY
        .DB "SR"
        .DW MONITOR_ASM_INSTR_LSR
        .DB 0
MONITORASMINSTR_M:
        .DB "VN"
        .DW MONITOR_ASM_INSTR_MVN
        .DB "VP"
        .DW MONITOR_ASM_INSTR_MVP
        .DB 0
MONITORASMINSTR_N:
        .DB "OP"
        .DW MONITOR_ASM_INSTR_NOP
        .DB 0
MONITORASMINSTR_O:
        .DB "RA"
        .DW MONITOR_ASM_INSTR_ORA
        .DB 0
MONITORASMINSTR_P:
        .DB "EA"
        .DW MONITOR_ASM_INSTR_PEA
        .DB "EI"
        .DW MONITOR_ASM_INSTR_PEI
        .DB "ER"
        .DW MONITOR_ASM_INSTR_PER
        .DB "HA"
        .DW MONITOR_ASM_INSTR_PHA
        .DB "HB"
        .DW MONITOR_ASM_INSTR_PHB
        .DB "HD"
        .DW MONITOR_ASM_INSTR_PHD
        .DB "HK"
        .DW MONITOR_ASM_INSTR_PHK
        .DB "HP"
        .DW MONITOR_ASM_INSTR_PHP
        .DB "HX"
        .DW MONITOR_ASM_INSTR_PHX
        .DB "HY"
        .DW MONITOR_ASM_INSTR_PHY
        .DB "LA"
        .DW MONITOR_ASM_INSTR_PLA
        .DB "LB"
        .DW MONITOR_ASM_INSTR_PLB
        .DB "LD"
        .DW MONITOR_ASM_INSTR_PLD
        .DB "LP"
        .DW MONITOR_ASM_INSTR_PLP
        .DB "LX"
        .DW MONITOR_ASM_INSTR_PLX
        .DB "LY"
        .DW MONITOR_ASM_INSTR_PLY
        .DB 0
MONITORASMINSTR_R:
        .DB "EP"
        .DW MONITOR_ASM_INSTR_REP
        .DB "OL"
        .DW MONITOR_ASM_INSTR_ROL
        .DB "OR"
        .DW MONITOR_ASM_INSTR_ROR
        .DB "TI"
        .DW MONITOR_ASM_INSTR_RTI
        .DB "TL"
        .DW MONITOR_ASM_INSTR_RTL
        .DB "TS"
        .DW MONITOR_ASM_INSTR_RTS
        .DB 0
MONITORASMINSTR_S:
        .DB "BC"
        .DW MONITOR_ASM_INSTR_SBC
        .DB "EC"
        .DW MONITOR_ASM_INSTR_SEC
        .DB "ED"
        .DW MONITOR_ASM_INSTR_SED
        .DB "EI"
        .DW MONITOR_ASM_INSTR_SEI
        .DB "EP"
        .DW MONITOR_ASM_INSTR_SEP
        .DB "TA"
        .DW MONITOR_ASM_INSTR_STA
        .DB "TP"
        .DW MONITOR_ASM_INSTR_STP
        .DB "TX"
        .DW MONITOR_ASM_INSTR_STX
        .DB "TY"
        .DW MONITOR_ASM_INSTR_STY
        .DB "TZ"
        .DW MONITOR_ASM_INSTR_STZ
        .DB 0
MONITORASMINSTR_T:
        .DB "AX"
        .DW MONITOR_ASM_INSTR_TAX
        .DB "AY"
        .DW MONITOR_ASM_INSTR_TAY
        .DB "CD"
        .DW MONITOR_ASM_INSTR_TCD
        .DB "CS"
        .DW MONITOR_ASM_INSTR_TCS
        .DB "DC"
        .DW MONITOR_ASM_INSTR_TDC
        .DB "RB"
        .DW MONITOR_ASM_INSTR_TRB
        .DB "SB"
        .DW MONITOR_ASM_INSTR_TSB
        .DB "SC"
        .DW MONITOR_ASM_INSTR_TSC
        .DB "SX"
        .DW MONITOR_ASM_INSTR_TSX
        .DB "XA"
        .DW MONITOR_ASM_INSTR_TXA
        .DB "XS"
        .DW MONITOR_ASM_INSTR_TXS
        .DB "XY"
        .DW MONITOR_ASM_INSTR_TXY
        .DB "YA"
        .DW MONITOR_ASM_INSTR_TYA
        .DB "YX"
        .DW MONITOR_ASM_INSTR_TYX
        .DB 0
MONITORASMINSTR_W:
        .DB "AI"
        .DW MONITOR_ASM_INSTR_WAI
        .DB "DM"
        .DW MONITOR_ASM_INSTR_WDM
        .DB 0
MONITORASMINSTR_X:
        .DB "BA"
        .DW MONITOR_ASM_INSTR_XBA
        .DB "CE"
        .DW MONITOR_ASM_INSTR_XCE
        .DB 0

MLMONBRK:
        CLI
        BNE     MLMONBRKE
        SETBD16 $80, MONPAGE
        LDA     11,S
        SEC
        SBC     #2
        STA     MNREGPC.B
        LDA     8,S
        STA     MNREGACC.B
        LDA     6,S
        STA     MNREGX.B
        LDA     4,S
        STA     MNREGY.B
        LDA     1,S
        STA     MNREGD.B
        LDA     #0
        ACC8
        LDA     3,S
        STA     MNREGB.B
        LDA     10,S
        STA     MNREGP.B
        LDA     13,S
        STA     MNREGK.B
        AXY16
        TSC
        CLC
        ADC     #13
        STA     MNREGS.B
        TCS
        LDA     #0
        STA     MNEMUL.B
        JMP     MONCODEBRK

MLMONBRKE:
        SETBD16 $80, MONPAGE
        LDA     15,S
        SEC
        SBC     #2
        STA     MNREGPC.B
        LDA     8,S
        STA     MNREGACC.B
        LDA     6,S
        STA     MNREGX.B
        LDA     4,S
        STA     MNREGY.B
        LDA     1,S
        STA     MNREGD.B
        LDA     #0
        ACC8
        LDA     3,S
        STA     MNREGB.B
        LDA     14,S
        STA     MNREGP.B
        STZ     MNREGK.B
        AXY16
        TSC
        CLC
        ADC     #17
        STA     MNREGS.B
        TCS
        LDA     #1
        STA     MNEMUL.B
        JMP     MONCODEBRK

MLMONNMI:
        ; increment NMI counter
        SETB16  $80
        INC     MONPAGE|MONINNMI.W
        JML     [MONPAGE|MONNMIOL.W]
