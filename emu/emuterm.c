/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
Emulator debug console

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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cpu.h"
#include "emulator.h"
#include "emuterm.h"
#include "mem.h"
#include "io.h"
#include "e1100.h"
#include "vpu.h"
#include "backend.h"
#include "floppy.h"

int emu_dump_memory(void)
{
    FILE* fp;
    if (fp = fopen("e1100.dmp", "wb"))
    {
        fseek(fp, 0x000000, SEEK_SET);
        (void)fwrite(mem_ptr_rom(), 1, _ROM_SIZE, fp);
        fseek(fp, 0x400000, SEEK_SET);
        (void)fwrite(mem_ptr_vram(), 1, _ROM_SIZE, fp);
        fseek(fp, 0x700000, SEEK_SET);
        for (int i = 0; i < 128; ++i)
            fputc(io_read(i), fp);
        fseek(fp, 0x800000, SEEK_SET);
        (void)fwrite(mem_ptr_ram(), 1, _ROM_SIZE, fp);
        fclose(fp);
        return 0;
    }
    else
    {
        perror("e1100.dmp");
        return 1;
    }
}

int emu_dump_screen(void)
{
    size_t sz;
    const char* buf;
    if (!(buf = vpu_get_screen(&sz)))
    {
        fprintf(stderr, "No screen to dump\n");
        return 1;
    }

    FILE* fp;
    if (fp = fopen("e1100scr.dmp", "wb"))
    {
        (void)fwrite(buf, 1, sz, fp);
        return 0;
    }
    else
    {
        perror("e1100scr.dmp");
        return 1;
    }
}

// strncpy until space
size_t strncpy_sp(char* dst, const char* src, size_t size)
{
    size_t i;
    for (i = 0; i < size - 1; ++i)
    {
        if (src[i] == '\0' || src[i] == ' ')
            break;
        dst[i] = src[i];
    }
    if (i < size)
        dst[i] = '\0';
    return i;
}

static unsigned long long last_total_cycles = 0;
static int last_cmd_i = 0;
static char tok0[64];
void emu_term_do_line(const char* buf, size_t buflen)
{
    size_t tok0len = strncpy_sp(tok0, buf, buflen);

    if (buflen <= 1)
    {
        if (last_cmd_i)
        {
            e1100_step_instruction();
            emulator_dump_state();
        }
        return;
    }

    if (!strcmp(tok0, "r")) // run
    {
        printf("running from %04x\n", regs.PC);
        emu_unpause();
    }
    else if (!strcmp(tok0, "q")) // quit
        emu_close_quit();
    else if (!strcmp(tok0, "p")) // pause
        emu_pause_debug();
    else if (!strcmp(tok0, "s")) // state
        emulator_dump_state();
    else if (!strcmp(tok0, "mm")) // complete memory dump
    {
        if (!emu_dump_memory())
            printf("dumped memory to e1100.dmp\n");
    }
    else if (!strcmp(tok0, "ms")) // complete screen buffer dump
    {
        if (!emu_dump_screen())
            printf("dumped screen to e1100scr.dmp\n");
    }
    else if (!strcmp(tok0, "i")) // instruction
    {
        emu_pause();
        last_cmd_i = 1;
        e1100_step_instruction();
        emulator_dump_state();
    }
    else if (!strcmp(tok0, "f") || !strcmp(tok0, "f1")) // floppy 1 mount
    {
        if (buflen > tok0len + 1)
        {
            FILE* fp = fopen(buf + tok0len + 1, "rb");
            if (fp)
            {
                if (floppy_has_media(0) && !f1wp) save_floppy_media(0);
                f1wp = file_is_readonly(drive0fn);
                strncpy(drive0fn, buf + tok0len + 1, MAX_PATH_NAME + 1);
                if (!floppy_mount(0, fp, f1wp))
                    printf("Mounted floppy to drive I\n");
                else
                    printf("Could not mount floppy drive I\n"
                           "(wrong size? must be 960, 1280 or 1600 KB)\n");
            }
            else
                perror("failed to open f1 file");
        }
        else
        {
            if (floppy_has_media(0) && !f1wp) save_floppy_media(0);
            floppy_unmount(0);
            memset(drive0fn, 0, MAX_PATH_NAME + 1);
            printf("Unmounted drive I\n");
        }
    }
    else if (!strcmp(tok0, "f2")) // floppy 2 mount
    {
        if (buflen > tok0len + 1)
        {
            FILE* fp = fopen(buf + tok0len + 1, "rb");
            if (fp)
            {
                if (floppy_has_media(1) && !f2wp) save_floppy_media(1);
                f2wp = file_is_readonly(drive1fn);
                strncpy(drive1fn, buf + tok0len + 1, MAX_PATH_NAME + 1);
                if (!floppy_mount(1, fp, f2wp))
                    printf("Mounted floppy to drive I\n");
                else
                    printf("Could not mount floppy drive I\n"
                           "(wrong size? must be 960, 1280 or 1600 KB)\n");
            }
            else
                perror("failed to open f2 file");
        }
        else
        {
            if (floppy_has_media(1) && !f2wp) save_floppy_media(1);
            floppy_unmount(1);
            memset(drive1fn, 0, MAX_PATH_NAME + 1);
            printf("Unmounted drive I\n");
        }
    }
    else if (!strcmp(tok0, "b")) // breakpoint
    {
        unsigned int tmp;
        int r = buflen > tok0len + 1
                    ? sscanf(buf + tok0len + 1, "%04x", &tmp) : EOF;
        if (breakpoint_enabled = r > 0)
        {
            breakpoint_addr = tmp;
            printf("Will break at PC=%04x\n", breakpoint_addr);
        }
        else if (r == EOF)
        {
            printf("Break disabled\n");
        }
    }
    else if (!strcmp(tok0, "x1")) // screen size x1
    {
        int w, h;
        vpu_get_resolution(&w, &h);
        emu_set_window_size(w, h);
    }
    else if (!strcmp(tok0, "x2")) // screen size x2
    {
        int w, h;
        vpu_get_resolution(&w, &h);
        emu_set_window_size(w * 2, h * 2);
    }
    else if (!strcmp(tok0, "cc")) // cycle counter
    {
        printf("        Cycles: %40llu\n"
               " since last cc: %40llu\n"
               "avg per second: %40llu\n"
               " total runtime: %40llu ms\n",
               total_cycles, total_cycles - last_total_cycles,
               (total_cycles * 1000) / total_ms, total_ms);
        
        last_total_cycles = total_cycles;
    }
    else if (!strcmp(tok0, "z")) // reset
    {
        e1100_reset();
        printf("CPU RESET\n");
    }
    else if (!strcmp(tok0, "dma")) // dma
    {
        for (int i = 0; i < 65540; ++i)
            dma_cycle();
        printf("fast-forwarded DMA\n");
    }
    else if (!strcmp(tok0, "wake")) // wake
    {
        cpuWai = 0;
        printf("CPU wake ok\n");
    }
    else if (!strcmp(tok0, "seek")) // seek
    {
        floppy_tick(10000);
        floppy_tick(10000);
        printf("floppy seek ok\n");
    }
    else if (!strcmp(tok0, "?") || !strcmp(tok0, "h")) // help
    {
        printf("?       help\n");
        printf("q       quit emulator\n");
        printf("r       continue running\n");
        printf("p       pause\n");
        printf("z       reset\n");
        printf("s       dump state\n");
        printf("mm      dump complete memory to file\n");
        printf("ms      dump complete raw screenbuffer to file\n");
        printf("i       step instruction\n");
        printf("b       set breakpoint PC address (16-bit)\n");
        printf("dma     instantly finish DMA\n");
        printf("wake    wake from WAI\n");
        printf("seek    insta-seek floppy drives\n");
        printf("f       mount floppy I or unmount\n");
        printf("f1      mount floppy I or unmount\n");
        printf("f2      mount floppy II or unmount\n");
        printf("x1      set window size to x1 resolution\n");
        printf("x2      set window size to x2 resolution\n");
        printf("cc      cycle counter\n");
    }
    else
        printf("Unknown command - type ? for help\n");

    fflush(stdout);
}
