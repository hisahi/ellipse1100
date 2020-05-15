/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
Emulator debug console header file

Copyright (c) 2020 Sampo Hippeläinen (hisahi)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#ifndef _E1100_EMUTERM_H
#define _E1100_EMUTERM_H

#include <stdlib.h>

extern int f1wp, f2wp;
extern char drive0fn[MAX_PATH_NAME + 1];
extern char drive1fn[MAX_PATH_NAME + 1];

extern void save_floppy_media(int drivenum);
extern int file_is_readonly(const char* fn);
extern void emu_term_do_line(const char* buf, size_t buflen);

#endif /* _E1100_EMUTERM_H */
