; Ellipse Workstation 1100 (fictitious computer)
; Ellipse DOS error codes
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

.DEFINE DOS_ERR_NO_ERR            $00.W
.DEFINE DOS_ERR_UNK_FUNCTION      $01.W
.DEFINE DOS_ERR_BAD_FILE_HANDLE   $02.W
.DEFINE DOS_ERR_FILE_NOT_FOUND    $03.W
.DEFINE DOS_ERR_VOLUME_NOT_FOUND  $04.W
.DEFINE DOS_ERR_BAD_PATH          $05.W
.DEFINE DOS_ERR_DRIVE_NOT_READY   $06.W
.DEFINE DOS_ERR_NO_MORE_HANDLES   $07.W
.DEFINE DOS_ERR_ACCESS_DENIED     $08.W
.DEFINE DOS_ERR_OUT_OF_MEMORY     $09.W
.DEFINE DOS_ERR_DRIVE_FULL        $0A.W
.DEFINE DOS_ERR_FILE_OPEN         $0B.W
.DEFINE DOS_ERR_FILE_NOT_EXEC     $0C.W
.DEFINE DOS_ERR_NO_MORE_FILES     $0D.W
.DEFINE DOS_ERR_BAD_PARAMETER     $0E.W
.DEFINE DOS_ERR_PATH_NOT_FOUND    $0F.W
.DEFINE DOS_ERR_DOS_BUSY          $10.W
.DEFINE DOS_ERR_INVALID_DRIVE     $11.W
.DEFINE DOS_ERR_IO_ERROR          $12.W
.DEFINE DOS_ERR_READ_ERROR        $13.W
.DEFINE DOS_ERR_WRITE_ERROR       $14.W
.DEFINE DOS_ERR_EXEC_TOO_LARGE    $15.W
.DEFINE DOS_ERR_CANNOT_SEEK       $16.W
.DEFINE DOS_ERR_CREATE_ERROR      $17.W
