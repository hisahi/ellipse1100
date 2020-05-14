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

int open_terminal = 0;
int paused = 0;
int breakpoint_enabled = 0;
unsigned int breakpoint_addr = 0;
int f1wp = 0, f2wp = 0;
int f1mount = 0, f2mount = 0;
char drive0fn[MAX_PATH_NAME + 1];
char drive1fn[MAX_PATH_NAME + 1];

void emu_pause(void)
{
    paused = 1;
}

void emu_unpause(void)
{
    paused = 0;
    emu_get_tick_ns();
}

void emu_puts(const char * str)
{
    puts(str);
    fflush(stdout);
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
    }
    else
        printf("Unknown command - type ? for help\n");

    fflush(stdout);
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
    emu_init("E1100em (F11 to release mouse)");
    e1100_init(VS_NTSC);
    load_rom();
    emu_get_tick_ns();

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
        acc += tick;
        cyc_tot = 0;

        acc_ms = acc / NS_PER_MS;
        acc %= NS_PER_MS;

        for (i = 0; i < acc_ms; ++i)
        {
            cyc_tot += CYC_PER_MS;
            cyc_part += CYC_PART_PER_MS;
            cyc_tot += cyc_part / 1000;
            cyc_part %= 1000;
        }

        if (!paused)
        {
            floppy_tick(acc_ms);

            for (i = cyc_tot; !paused && i > 8; i -= 8)
            {
                e1100_tick(); e1100_tick(); e1100_tick(); e1100_tick();
                e1100_tick(); e1100_tick(); e1100_tick(); e1100_tick();
            }

            for (; !paused && i; --i)
                e1100_tick();
        }

        emu_delay_ms(5);
    }

    e1100_free();
    emu_free();
    return EXIT_SUCCESS;
}

int emulator_help(void)
{

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
