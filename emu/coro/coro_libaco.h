/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
Coroutine header for libaco

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

#include "libaco/aco.h"
#include "../emulator.h"

typedef aco_t* coroutine;

// void coro_init(void)
#define coro_init() { \
            aco_thread_init(NULL); \
            main_coro = aco_create(NULL, NULL, 0, NULL, NULL); \
            share_stack = aco_share_stack_new(0); \
        }

// void coro_quit(void)
#define coro_quit() { \
            aco_share_stack_destroy(share_stack); \
            aco_destroy(main_coro); \
        }

// void coro_create(coroutine* coro, void (*func)(void))
#define coro_create(coro,func) { \
            if (!(*coro = aco_create(main_coro, share_stack, 512, func, 0))) \
                emu_fail("Failed to create coroutine"); \
        }

// void coro_destroy(coroutine* coro)
#define coro_destroy(co) aco_destroy(*co)

// void coro_resume(coroutine* coro)
#define coro_resume(co) aco_resume(*co)

// void coro_yield(void)
#define coro_yield() aco_yield()

extern coroutine main_coro;
extern aco_share_stack_t* share_stack;
