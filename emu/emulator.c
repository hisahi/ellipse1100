/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
Main emulator

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

#include "backend.h"
#include "cpu.h"
#include "mem.h"
#include "vpu.h"
#include "e1100.h"
#include "io.h"
#include "floppy.h"
#include "emuterm.h"

int open_terminal = 0;
int paused = 0;
int breakpoint_enabled = 0;
unsigned int breakpoint_bank = 0;
unsigned int breakpoint_addr = 0;
int f1wp = 0, f2wp = 0;
int f1mount = 0, f2mount = 0;
int doubleres = 0;
int startpal = 0;
char drive0fn[MAX_PATH_NAME + 1];
char drive1fn[MAX_PATH_NAME + 1];
unsigned long long total_cycles = 0;
unsigned long long total_ms = 0;

void emu_pause(void)
{
    paused = 1;
}

void emu_unpause(void)
{
    paused = 0;
    emu_get_tick_ns();
}

void emu_pause_debug(void)
{
    emu_pause();
    emulator_dump_state();
}

void load_rom(void)
{
    FILE* fp;
    if (fp = fopen("ellipse.rom", "rb"))
    {
        (void)fread(mem_ptr_rom(), 1, _ROM_SIZE, fp);
        fclose(fp);
    }
    else
    {
        perror("ellipse.rom");
        exit(EXIT_FAILURE);
    }
}

void save_floppy_media(int drivenum)
{
    FILE* fp = fopen(drivenum == 1 ? drive1fn : drive0fn, "rb");
    if (fp)
    {
        if (!floppy_save_disk(drivenum, fp))
            perror("failed to save floppy file");
    }
    else
        perror("failed to save floppy file");
}

int file_is_readonly(const char* fn)
{
    FILE* fp;
    if (fp = fopen(fn, "ab"))
        fclose(fp);
    return !fp;
}

void emu_fail(const char * reason)
{
    fprintf(stderr, "emu_fail: %s", reason);
    abort();
}

void emulator_dump_state(void)
{
    printf("=========== 65C816 CPU STATE ===========\n");
    printf("     A:%04x  X:%04x  Y:%04x  S:%04x\n",
                        regs.A, regs.X, regs.Y, regs.S);
    printf("     D:%04x    B:%02x    K:%02x  PC:%04x\n",
                        regs.D, regs.B, regs.K, regs.PC);
    printf("     P:%c%c%c%c%c%c%c%c/%c\n",
                        (regs.P & P_N) ? 'N' : '-',
                        (regs.P & P_V) ? 'V' : '-',
                        (regs.P & P_M) ? 'M' : '-',
                        (regs.P & P_X) ? 'X' : '-',
                        (regs.P & P_D) ? 'D' : '-',
                        (regs.P & P_I) ? 'I' : '-',
                        (regs.P & P_Z) ? 'Z' : '-',
                        (regs.P & P_C) ? 'C' : '-',
                        regs.E         ? 'E' : '-');
    printf("========================================\n");
    printf("    ");
    emulator_disasm_instr(regs.PC);
    printf("========================================\n");
    fflush(stdout);
}

int emulator_main()
{
    unsigned long long NS_PER_FRAME = NS_PER_MS * 10;
    unsigned long long tick = 0, acc = 0;
    unsigned long cyc_tot = 0, cyc_part = 0, i;
    unsigned long acc_ms;
    const char* cmdline;
    size_t cmdlinelen;
    
    coro_init();
    emu_init("E1100em (F11 releases, F12 pauses)");
    e1100_init(startpal ? VS_PAL : VS_NTSC);
    load_rom();
    emu_get_tick_ns();

    if (doubleres)
    {
        int w, h;
        vpu_get_resolution(&w, &h);
        emu_set_window_size(w * 2, h * 2);
        emu_center_window();
    }

    if (open_terminal)
        emu_pause_debug();
    else
        puts("E1100em - press F12 to open debug terminal\n");

    if (f1mount)
    {
        FILE* fp = fopen(drive0fn, "rb");
        if (fp)
        {
            f1wp = file_is_readonly(drive0fn);
            if (!floppy_mount(0, fp, f1wp))
                printf("Mounted floppy to drive I\n");
            else
                printf("Could not mount floppy drive I\n"
                        "(wrong size? must be 960, 1280 or 1600 KB)\n");
        }
        else
            perror("failed to open -f1 file");
    }

    if (f2mount)
    {
        FILE* fp = fopen(drive1fn, "rb");
        if (fp)
        {
            f2wp = file_is_readonly(drive1fn);
            if (!floppy_mount(0, fp, f2wp))
                printf("Mounted floppy to drive II\n");
            else
                printf("Could not mount floppy drive II\n"
                        "(wrong size? must be 960, 1280 or 1600 KB)\n");
        }
        else
            perror("failed to open -f2 file");
    }

    while (emu_running())
    {
        if (emu_term_hasline(&cmdline, &cmdlinelen))
            emu_term_do_line(cmdline, cmdlinelen);

        tick = emu_get_tick_ns();
        acc = (acc + tick) % (100 * NS_PER_MS);
        cyc_tot = 0;

        acc_ms = acc / NS_PER_MS;
        acc %= NS_PER_MS;
        total_ms += acc_ms;

        if (!paused)
        {
            for (i = 0; i < acc_ms; ++i)
            {
                cyc_tot += CYC_PER_MS;
                cyc_part += CYC_PART_PER_MS;
                cyc_tot += cyc_part / 1000;
                cyc_part %= 1000;
            }

            floppy_tick(acc_ms);

            total_cycles += e1100_run(cyc_tot
#ifdef SLOWDOWN
                        / SLOWDOWN
#endif
                        );
        }

        emu_delay_ms(3);
    }

    if (floppy_has_media(0) && !f1wp) save_floppy_media(0);
    if (floppy_has_media(1) && !f2wp) save_floppy_media(1);

    e1100_free();
    emu_free();
    return EXIT_SUCCESS;
}

int emulator_help(void)
{
    // TODO
    return EXIT_SUCCESS;
}

int main(int argc, char** argv)
{
    for (int i = 1; i < argc; ++i)
    {
        if (!strcmp(argv[i], "-g"))
        {
            open_terminal = 1;
        }
        else if (!strcmp(argv[i], "-f") || !strcmp(argv[i], "-f1"))
        {
            if (++i < argc)
            {
                strncpy(drive0fn, argv[i], MAX_PATH_NAME + 1);
                ++f1mount;
            }
        }
        else if (!strcmp(argv[i], "-f2"))
        {
            if (++i < argc)
            {
                strncpy(drive1fn, argv[i], MAX_PATH_NAME + 1);
                ++f2mount;
            }
        }
        else if (!strcmp(argv[i], "-2"))
        {
            ++doubleres;
        }
        else if (!strcmp(argv[i], "-p"))
        {
            ++startpal;
        }
        else if (!strcmp(argv[i], "-h"))
        {
            return emulator_help();
        }
        else if (!strcmp(argv[i], "--"))
        {
            break;
        }
    }
    return emulator_main();
}
