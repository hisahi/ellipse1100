/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
ROM checksum recalculator, needed to build ROM

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

/* Compile with: cc -o e1100cs e1100cs.c */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int print_help(void)
{
    fprintf(stderr, "e1100cs -- recomputes checksum for Ellipse ROM image\n"
                    "\n"
                    "USAGE: e1100cs <file>\n"
                    "\n"
                    "    file        The ROM file to recompute the checksum\n"
                    "                for. 16-bit, stored at the very end.\n");
    return EXIT_SUCCESS;
}

int fail_perror(const char* str)
{
    perror(str);
    return EXIT_FAILURE;
}

int fail_puts(const char* str)
{
    fprintf(stderr, "%s", str);
    return EXIT_FAILURE;
}

int recompute_checksum(const char* fn)
{
    char buf[17] = {'\0'};
    unsigned char page[256];
    unsigned sum = 0;
    size_t fsz, remaining, reading, i;

    FILE* file = fopen(fn, "rb+");
    if (!file)
        return fail_perror("cannot open file");

    if (fseek(file, 0, SEEK_END))
        return fail_perror("failed to seek file");
    fsz = ftell(file);

    if (fsz < 65536 || fsz > (16 * 65536) || 0 != (fsz & (fsz - 1)))
        return fail_puts("cannot compute checksum: not a valid ROM image\n");
    rewind(file);
    if (fread(buf, 1, 16, file) < 16)
        return fail_perror("failed to read file");
    if (strcmp(buf, "(C) ELLIPSE DATA"))
        return fail_puts("cannot compute checksum: not a valid ROM image\n");
    
    rewind(file);
    remaining = fsz - 2;
    while (remaining > 0)
    {
        reading = remaining;
        if (reading > sizeof(page)) reading = sizeof(page);

        if (fread(page, 1, reading, file) < reading)
            return fail_perror("failed to read file");
        
        for (i = 0; i < reading; i += 2)
            sum = 0xFFFFU & (sum + (page[i] | (page[i + 1] << 8)));
        remaining -= reading;
    }

    if (fseek(file, fsz - 2, SEEK_SET))
        return fail_perror("failed to seek file");
    
    sum = 0xFFFFU & (~sum + 1);
    buf[0] = sum & 0xFF;
    buf[1] = (sum >> 8) & 0xFF;
    if (fwrite(buf, 1, 2, file) < 2)
        return fail_perror("failed to write file");

    printf("checksum= $%04X\n", sum);
    fclose(file);
    return EXIT_SUCCESS;
}

int main(int argc, char** argv)
{
    int romfilei = 0;
    int i;

    for (i = 1; i < argc; ++i)
    {
        if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help"))
        {
            return print_help();
        }
        else if (!strcmp(argv[i], "--"))
        {
            break;
        }
        else if (!romfilei)
            romfilei = i;
    }
    if (!romfilei)
        romfilei = i;
    if (romfilei >= argc)
        return print_help();

    return recompute_checksum(argv[romfilei]);
}
