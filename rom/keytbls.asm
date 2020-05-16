; Ellipse Workstation 1100 (fictitious computer)
; ROM code (keyboard code tables)
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

.org $F900

; matrix code to ASCII key code conversion
; one row of 8 bytes is one column of matrix, starting from bit 0 to 7
; special codes: $80 CTRL $81 LShift $82 LAlt $83 Caps $84 Aux1
;                         $91 RShift $92 RAlt          $94 Aux2
;                $00 unconnected

KEYCODETABLE:
        .DB     $10, $60, $09, $80, $81, $83, $28, $2F
        .DB     $11, $31, $71, $61, $94, $82, $37, $39
        .DB     $12, $32, $77, $73, $7A, $20, $34, $36
        .DB     $13, $33, $65, $64, $78, $00, $31, $33
        .DB     $14, $34, $72, $66, $63, $00, $30, $00
        .DB     $15, $35, $74, $67, $76, $00, $00, $00
        .DB     $16, $36, $79, $68, $62, $00, $00, $00
        .DB     $17, $37, $75, $6A, $6E, $00, $00, $00
        .DB     $18, $38, $69, $6B, $6D, $00, $29, $2A
        .DB     $19, $39, $6F, $6C, $2C, $00, $38, $2D
        .DB     $1A, $30, $70, $3B, $2E, $00, $35, $2B
        .DB     $00, $2D, $5B, $27, $2F, $92, $32, $0D
        .DB     $00, $3D, $5D, $84, $00, $00, $00, $00
        .DB     $00, $7E, $00, $0D, $91, $00, $00, $00
        .DB     $00, $08, $00, $00, $1E, $00, $00, $00
        .DB     $00, $7F, $0E, $1C, $1F, $1D, $00, $00
; if shift held
KEYCODETABLE_SHIFT:
        .DB     $10, $7E, $09, $80, $81, $83, $28, $2F
        .DB     $11, $21, $51, $41, $94, $82, $37, $39
        .DB     $12, $40, $57, $53, $5A, $20, $34, $36
        .DB     $13, $23, $45, $44, $58, $00, $31, $33
        .DB     $14, $24, $52, $46, $43, $00, $30, $00
        .DB     $15, $25, $54, $47, $56, $00, $00, $00
        .DB     $16, $5E, $59, $48, $42, $00, $00, $00
        .DB     $17, $26, $55, $4A, $4E, $00, $00, $00
        .DB     $18, $2A, $49, $4B, $4D, $00, $29, $2A
        .DB     $19, $28, $4F, $4C, $3C, $00, $38, $2D
        .DB     $1A, $29, $50, $3A, $3E, $00, $35, $2B
        .DB     $00, $5F, $7B, $22, $3F, $92, $32, $0D
        .DB     $00, $2B, $7D, $84, $00, $00, $00, $00
        .DB     $00, $7C, $00, $0D, $91, $00, $00, $00
        .DB     $00, $08, $00, $00, $1E, $00, $00, $00
        .DB     $00, $7F, $0E, $1C, $1F, $1D, $00, $00
; if caps should apply to char code
KEYB_APPLY_CAPS_TO_KEY:
        .DB     0,0,0,0,0,0,0,0
        .DB     0,0,1,1,0,0,0,0
        .DB     0,0,1,1,1,0,0,0
        .DB     0,0,1,1,1,0,0,0
        .DB     0,0,1,1,1,0,0,0
        .DB     0,0,1,1,1,0,0,0
        .DB     0,0,1,1,1,0,0,0
        .DB     0,0,1,1,1,0,0,0
        .DB     0,0,1,1,1,0,0,0
        .DB     0,0,1,1,0,0,0,0
        .DB     0,0,1,0,0,0,0,0
        .DB     0,0,1,0,0,0,0,0
        .DB     0,0,0,0,0,0,0,0
        .DB     0,0,0,0,0,0,0,0
        .DB     0,0,0,0,0,0,0,0
        .DB     0,0,0,0,0,0,0,0
