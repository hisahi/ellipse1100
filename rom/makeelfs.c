/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
ELFS file system preparation (used for DOS and SublimOS floppies)

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

/* Compile with: cc -o makeelfs makeelfs.c */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <unistd.h> /* required for chdir, otherwise implement it yourself */

typedef struct add_file
{
    char srcfn[16];
    char fn[16];
    unsigned attr;
    unsigned year;
    unsigned month;
    unsigned day;
    unsigned hour;
    unsigned minute;
    unsigned second;
} ADD_FILE;

int print_help(void)
{
    fprintf(stderr, "makeelfs -- prepares an ELFS file system to floppy image\n"
                    "\n"
                    "USAGE: makeelfs <image> <fs>\n"
                    "\n"
                    "    image       The floppy image to prepare to.\n"
                    "    fs          A .fs text file describing how the\n"
                    "                file system should be prepared.\n");
    return 0;
}

int is_leap_year(int year)
{
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
}

int days_month_table[12] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
int days_per_month(int month, int year)
{
    return days_month_table[month] + (month == 1 && is_leap_year(year));
}

int fail_perror(const char* str)
{
    perror(str);
    return -1;
}

void warn_puts(const char* str)
{
    fprintf(stderr, "warning: %s\n", str);
}

int fail_puts(const char* str)
{
    fprintf(stderr, "error: %s\n", str);
    return -1;
}

ADD_FILE* add_files;
int add_files_cnt = 0;
int add_files_sz = 0;
int media_id = -1;
unsigned sectorcount = 0;
unsigned chunkcount = 0;
unsigned sectorspertrack = 0;
unsigned sectorsperctable = 0;
unsigned long curdir = 0;
unsigned long curdirchunk = 0;
char label[16] = {' '};

int read_fs_file(const char* fsfn)
{
    char line[512] = {'\0'};
    char tmp[32];
    FILE* fsfile;

    if (!(add_files = malloc(sizeof(ADD_FILE) * (add_files_sz = 16))))
        return fail_puts("cannot allocate memory for file buffer");
    if (!(fsfile = fopen(fsfn, "r")))
        return fail_perror("cannot open .fs file");
    
    while (fgets(line, 512, fsfile))
    {
        line[strcspn(line, "\r\n")] = '\0';
        if (!*line) continue;
        sscanf(line, "%31s", tmp);

        if (0 == strcmp(tmp, "media"))
        {
            if (sscanf(line, "media %31s", tmp) < 1)
                return fail_puts("invalid media command");

            if (0 == strcmp(tmp, "floppysd"))
                media_id = 1, sectorspertrack = 12, sectorcount = 80 * 12 * 2;
            else if (0 == strcmp(tmp, "floppyhd"))
                media_id = 2, sectorspertrack = 16, sectorcount = 80 * 16 * 2;
            else if (0 == strcmp(tmp, "floppyud"))
                media_id = 3, sectorspertrack = 20, sectorcount = 80 * 20 * 2;
            else
                return fail_puts("unrecognized media format");
        }
        else if (0 == strcmp(tmp, "label"))
        {
            char* src = line + 6, * dst = label;
            if (sscanf(line, "label ") < 0)
                return fail_puts("invalid label command");
            
            while (*src && dst < label + 16)
                *dst++ = *src++;
            while (dst < label + 16)
                *dst++ = ' ';

            if (*src && dst >= label + 16)
                warn_puts("label too long, truncated at 16 chars");
        }
        else if (0 == strcmp(tmp, "dir"))
        {
            char fn[15] = {'\0'};
            ADD_FILE* af;
            char* dot;
            char* fnend;
            int dyear, dmonth, dday, dhour, dminute, dsecond, attr, i;
            if (sscanf(line, "dir %4s %14s %d-%d-%d %d:%d:%d", tmp, fn,
                    &dyear, &dmonth, &dday, &dhour, &dminute, &dsecond) < 8)
                return fail_puts("invalid dir command");
            
            if (dyear < 1980 || dyear > 1980 + 511)
                return fail_puts("invalid date supplied for 'dir'");
            if (dmonth < 1 || dmonth > 12)
                return fail_puts("invalid date supplied for 'dir'");
            if (dday < 1 || dday > days_per_month(dmonth - 1, dyear + 1980))
                return fail_puts("invalid date supplied for 'dir'");
            if (dhour < 0 || dhour > 23)
                return fail_puts("invalid date supplied for 'dir'");
            if (dminute < 0 || dminute > 59)
                return fail_puts("invalid date supplied for 'dir'");
            if (dsecond < 0 || dsecond > 59)
                return fail_puts("invalid date supplied for 'dir'");
            
            attr = 1 << 14;
            if (strchr(tmp, 'S'))
                attr |= 1;
            if (strchr(tmp, 'H'))
                attr |= 2;
            if (strchr(tmp, 'R'))
                attr |= 4;

            dyear -= 1980;

            if (add_files_cnt == add_files_sz)
            {
                if (!(add_files = realloc(add_files, 
                            sizeof(ADD_FILE) * (add_files_sz *= 2))))
                    return fail_puts("cannot allocate memory for file buffer");
            }

            af = &add_files[add_files_cnt++];

            strcpy(af->srcfn, fn);
            strcpy(af->fn, "          .   ");
            dot = fn;
            fnend = fn + strlen(fn);
            while (*dot && *dot != '.')
                ++dot;
            if (dot - fn > 10)
                return fail_puts("file name can be at most 10 characters long");
            if (fnend - dot > 4)
                return fail_puts("extension can be at most 3 characters long");
            memcpy(af->fn, fn, dot - fn);
            if (*dot)
                memcpy(af->fn + 11, dot + 1, fnend - dot - 1);

            for (i = 0; i < 16; ++i)
                af->fn[i] = toupper(af->fn[i]);

            af->attr = attr;
            af->year = dyear;
            af->month = dmonth;
            af->day = dday;
            af->hour = dhour;
            af->minute = dminute;
            af->second = dsecond;
        }
        else if (0 == strcmp(tmp, "file"))
        {
            char fn[15] = {'\0'};
            ADD_FILE* af;
            char* dot;
            char* fnend;
            int dyear, dmonth, dday, dhour, dminute, dsecond, attr, i;
            if (sscanf(line, "file %4s %14s %d-%d-%d %d:%d:%d", tmp, fn,
                    &dyear, &dmonth, &dday, &dhour, &dminute, &dsecond) < 8)
                return fail_puts("invalid file command");
            
            if (dyear < 1980 || dyear > 1980 + 511)
                return fail_puts("invalid date supplied for 'file'");
            if (dmonth < 1 || dmonth > 12)
                return fail_puts("invalid date supplied for 'file'");
            if (dday < 1 || dday > days_per_month(dmonth - 1, dyear + 1980))
                return fail_puts("invalid date supplied for 'file'");
            if (dhour < 0 || dhour > 23)
                return fail_puts("invalid date supplied for 'file'");
            if (dminute < 0 || dminute > 59)
                return fail_puts("invalid date supplied for 'file'");
            if (dsecond < 0 || dsecond > 59)
                return fail_puts("invalid date supplied for 'file'");
            
            attr = 0;
            if (strchr(tmp, 'S'))
                attr |= 1;
            if (strchr(tmp, 'H'))
                attr |= 2;
            if (strchr(tmp, 'R'))
                attr |= 4;

            dyear -= 1980;

            if (add_files_cnt == add_files_sz)
            {
                if (!(add_files = realloc(add_files, 
                            sizeof(ADD_FILE) * (add_files_sz *= 2))))
                    return fail_puts("cannot allocate memory for file buffer");
            }

            af = &add_files[add_files_cnt++];

            strcpy(af->srcfn, fn);
            strcpy(af->fn, "          .   ");
            dot = fn;
            fnend = fn + strlen(fn);
            while (*dot && *dot != '.')
                ++dot;
            if (dot - fn > 10)
                return fail_puts("file name can be at most 10 characters long");
            if (fnend - dot > 4)
                return fail_puts("extension can be at most 3 characters long");
            memcpy(af->fn, fn, dot - fn);
            if (*dot)
                memcpy(af->fn + 11, dot + 1, fnend - dot - 1);

            for (i = 0; i < 16; ++i)
                af->fn[i] = toupper(af->fn[i]);

            af->attr = attr;
            af->year = dyear;
            af->month = dmonth;
            af->day = dday;
            af->hour = dhour;
            af->minute = dminute;
            af->second = dsecond;
        }
    }

    fclose(fsfile);
    
    if (media_id == -1)
        return fail_puts("no 'media' specified");

    return 0;
}

int write_elfs_fsmb(FILE* floppy)
{
    char buf[4] = { '\0' };
    unsigned total_sz, free_space, first_data_sector;
    int i;

    sectorsperctable = (sectorcount + 511) / 512;
    sectorsperctable = (sectorsperctable + 1) & ~1; /* round up to even */
    chunkcount = sectorcount >> 1;
    --chunkcount;                           /* boot block / FSMB uses 2 sec */
    chunkcount -= sectorsperctable >> 1;

    fseek(floppy, 512, SEEK_SET);           /* sector 1 */
    fputs("ELFS", floppy);                  /* ELFS volume identifier */
    fwrite("\0\0\0\0", 1, 4, floppy);       /* volume attributes */
    buf[0] = media_id & 0xFF;
    buf[1] = (media_id >> 8) & 0xFF;
    fwrite(buf, 1, 2, floppy);              /* media ID */
    for (i = 0; i < 2; ++i) buf[i] = rand() & 255;
    fwrite(buf, 1, 2, floppy);              /* serial */
    fseek(floppy, 4, SEEK_CUR);             /* padding */
    fwrite("\012\0", 1, 2, floppy);         /* log2(bytes per chunk) = 10 */
    buf[0] = (chunkcount - 1) & 0xFF;
    buf[1] = (chunkcount >> 8) & 0xFF;
    fwrite(buf, 1, 2, floppy);              /* maximum chunk */
    buf[0] = (sectorspertrack >> 1) & 0xFF;
    buf[1] = (sectorspertrack >> 9) & 0xFF;
    fwrite(buf, 1, 2, floppy);              /* chunks per track */
    buf[0] = sectorsperctable & 0xFF;
    buf[1] = (sectorsperctable >> 8) & 0xFF;
    fwrite(buf, 1, 2, floppy);              /* sectors per chunk table */
    fwrite("\002\0", 1, 2, floppy);         /* bytes per chunk num = 2 */
    fseek(floppy, 6, SEEK_CUR);             /* padding */
    fwrite(label, 1, 16, floppy);           /* label */

    /* 1 sector for FIS, 1 sector for FSMB */
    total_sz = (sectorcount - sectorsperctable - 2) * 512;
    buf[0] = total_sz & 0xFF;
    buf[1] = (total_sz >> 8) & 0xFF;
    buf[2] = (total_sz >> 16) & 0xFF;
    buf[3] = (total_sz >> 24) & 0xFF;
    fwrite(buf, 1, 4, floppy);              /* total space */
    
    free_space = total_sz;
    buf[0] = free_space & 0xFF;
    buf[1] = (free_space >> 8) & 0xFF;
    buf[2] = (free_space >> 16) & 0xFF;
    buf[3] = (free_space >> 24) & 0xFF;
    fwrite(buf, 1, 4, floppy);              /* free space */

    first_data_sector = 2 + sectorsperctable;
    buf[0] = first_data_sector & 0xFF;
    buf[1] = (first_data_sector >> 8) & 0xFF;
    buf[2] = (first_data_sector >> 16) & 0xFF;
    buf[3] = (first_data_sector >> 24) & 0xFF;
    fwrite(buf, 1, 4, floppy);              /* first data sector */

    return ferror(floppy) ? -1 : 0;
}

int write_elfs_ctable(FILE* floppy)
{
    unsigned i;
    unsigned total_chunks = sectorsperctable * 256;
    fseek(floppy, 1024, SEEK_SET);          /* sector 2 */

    fwrite("\377\377", 1, 2, floppy);       /* invalid sector */
    for (i = 1; i < chunkcount; ++i)
        fwrite("\0\0", 1, 2, floppy);       /* free sector */
    for (i = chunkcount; i < total_chunks; ++i)
        fwrite("\377\377", 1, 2, floppy);   /* invalid sector */

    return ferror(floppy) ? -1 : 0;
}

int get_next_chunk(FILE* floppy, unsigned* chunk, unsigned* fileindx)
{
    unsigned base = sectorsperctable * 512;
    unsigned char buf[2];
    unsigned oldpos;

    /* seek to chunk table */
    if (*chunk >= chunkcount)
        return 0xFFFE; /* bad chunk */

    oldpos = ftell(floppy);
    fseek(floppy, 1024 + *chunk * 2, SEEK_SET);
    fread(buf, 1, 2, floppy);
    if (ferror(floppy))
        return -1;

    *chunk = buf[0] | (buf[1] << 8);
    *fileindx = base + *chunk * 1024;
    fseek(floppy, oldpos, SEEK_SET);
    return 0;
}

int get_next_free_chunk(FILE* floppy, unsigned* chunk, unsigned* fileindx)
{
    unsigned i;
    unsigned base = sectorsperctable * 512;
    unsigned nextfreechunk = 0;
    unsigned oldpos = 0;
    unsigned char buf[4];

    oldpos = ftell(floppy);

    /* seek to chunk table */
    fseek(floppy, 1024 + 2, SEEK_SET);
    for (i = 1; i < chunkcount; ++i)
    {
        fread(buf, 1, 2, floppy);
        if (buf[0] == 0 && buf[1] == 0)
        {
            /* this chunk is free */
            nextfreechunk = i;
            break;
        }
    }
    
    if (nextfreechunk == 0)                 /* no free space */
        return -1;

    if (*chunk != 0)                        /* link with previous */
    {
        /* seek to previous chunk */
        fseek(floppy, 1024 + *chunk * 2, SEEK_SET);
        buf[0] = nextfreechunk & 0xFF;
        buf[1] = (nextfreechunk >> 8) & 0xFF;
        fwrite(buf, 1, 2, floppy);
    }
    /* seek to new chunk */
    fseek(floppy, 1024 + nextfreechunk * 2, SEEK_SET);
    fwrite("\377\377", 1, 2, floppy);       /* end of chain for now */

    /* reduce free space by 1 KB */
    fseek(floppy, 0x234, SEEK_SET);
    fread(buf, 1, 4, floppy);
    if (buf[1] < 4)
    {
        if (buf[2] == 0)
            --buf[3];
        --buf[2];
    }
    buf[1] -= 4;
    fseek(floppy, 0x234, SEEK_SET);
    fwrite(buf, 1, 4, floppy);

    *chunk = nextfreechunk;
    *fileindx = base + *chunk * 1024;
    fseek(floppy, oldpos, SEEK_SET);
    return ferror(floppy);
}

int directory_find_file(FILE* floppy, const char* fn, unsigned* result,
                        unsigned* attr, unsigned* fchunk)
{
    char buf[32];
    unsigned oldpos;
    unsigned newpos;
    unsigned i;
    unsigned chunk;

    *result = 0;
    *attr = 0;
    *fchunk = 0;
    oldpos = ftell(floppy);
    newpos = curdir;
    chunk = curdirchunk;

    while (!*result && chunk != 0xFFFF)
    {
        if (fseek(floppy, newpos, SEEK_SET))
            return -1;
        
        for (i = 0; i < 32; ++i)
        {
            if (fread(buf, 1, 32, floppy) < 32)
                return -1;
            if (!strncmp(buf + 2, fn, 14))
            {
                *result = ftell(floppy) - 32;
                *attr = buf[0] | (buf[1] << 8);
                *fchunk = buf[30] | (buf[31] << 8);
                break;
            }
        }

        if (get_next_chunk(floppy, &chunk, &newpos))
            return -1;
    }

    fseek(floppy, oldpos, SEEK_SET);
    return ferror(floppy);
}

int go_up_directory(FILE* floppy)
{
    unsigned result;
    unsigned attr;
    unsigned fchunk;
    unsigned base = sectorsperctable * 512;

    if (directory_find_file(floppy, "..        .   ", &result, &attr, &fchunk))
        return -1;
    if (!result)
        return 0;
    curdirchunk = fchunk;
    curdir = base * 1024 + curdirchunk;
    fseek(floppy, curdir, SEEK_SET);
    return ferror(floppy) || find_free_dir_slot(floppy);
}

int find_free_dir_slot(FILE* floppy)
{
    unsigned pos;
    char buf[32];
    for (;;)
    {
        pos = ftell(floppy);
        if (pos != curdir && !(pos & ~1023)) /* end of this chunk */
        {
            unsigned chunk, fileindx;

            chunk = curdirchunk;
            /* end of chunk */
            if (get_next_chunk(floppy, &chunk, &fileindx))
                return fail_perror("cannot get next chunk");
            if (chunk == 0xFFFF)
            {
                if (get_next_free_chunk(floppy, &chunk, &fileindx))
                    return fail_puts("disk is full");
                fseek(floppy, fileindx, SEEK_SET);
                if (initialize_directory_chunk(chunk, floppy))
                    return fail_puts("directory init error");
                return;
            }
            fseek(floppy, fileindx, SEEK_SET);
        }
        
        
        if (fread(buf, 1, 32, floppy) < 32)
            return fail_perror("cannot read file entry");
        if (buf[0] & 128)
            return;
    }
}

int directory_add_file_raw(FILE* floppy, ADD_FILE file,
                    unsigned start, unsigned long size)
{
    unsigned pos;
    unsigned findx;
    unsigned attr;
    unsigned fchunk;
    char buf[5];

    pos = ftell(floppy);
    if (pos != curdir && !(pos & ~1023)) /* end of this chunk */
    {
        unsigned chunk, fileindx;

        chunk = curdirchunk;
        /* end of chunk */
        if (get_next_free_chunk(floppy, &chunk, &fileindx))
            return fail_puts("disk is full");
        fseek(floppy, fileindx, SEEK_SET);
        if (initialize_directory_chunk(chunk, floppy))
            return fail_puts("directory init error");
    }

    if (directory_find_file(floppy, file.fn, &findx, &attr, &fchunk))
        return fail_puts("file find error");
    if (findx)
        return fail_puts("file name already taken");

    buf[0] = (file.attr >> 8) & 0xFF;
    buf[1] = file.attr & 0xFF;
    fwrite(buf, 1, 2, floppy);              /* attributes */
    fwrite(file.fn, 1, 14, floppy);         /* file name 10 '.' extension 3 */
    fwrite("\0\0\0\0\0", 1, 5, floppy);     /* padding */

    buf[0] = 0xFF & (file.year >> 6);
    buf[1] = 0xFF & ((file.year << 2) | (file.month >> 2));
    buf[2] = 0xFF & ((file.month << 6) | (file.day << 1) | (file.hour >> 4));
    buf[3] = 0xFF & ((file.hour << 4) | (file.minute >> 1));
    buf[4] = 0xFF & ((file.minute << 7) | file.second);
    
    fwrite(buf, 1, 5, floppy);              /* date */
    
    buf[0] = size & 0xFF;
    buf[1] = (size >> 8) & 0xFF;
    buf[2] = (size >> 16) & 0xFF;
    buf[3] = (size >> 24) & 0xFF;
    fwrite(buf, 1, 4, floppy);              /* file size */
    
    buf[0] = start & 0xFF;
    buf[1] = (start >> 8) & 0xFF;
    fwrite(buf, 1, 2, floppy);              /* starting chunk */

    return ferror(floppy);
}

int directory_add_file(FILE* floppy, ADD_FILE file)
{
    FILE* srcfile;
    char buf[1024];
    unsigned dirpos;
    unsigned read;
    unsigned attr;
    unsigned long total = 0;
    unsigned chunk = 0;
    unsigned first_chunk = 0xFFFF;
    unsigned fileindx;

    if (file.attr & (1 << 14))
    {
        unsigned base = sectorsperctable * 512;
        /* subdirectory */
        printf("[%s] subdirectory\n", file.srcfn);
        if (!strcmp(file.srcfn, "."))
            return;
        if (chdir(file.srcfn))
            return fail_perror("cannot go to 'dir' directory");
        if (!strcmp(file.srcfn, ".."))
            return go_up_directory(floppy);
        if (directory_find_file(floppy, file.fn, &fileindx, &attr, &chunk))
            return fail_perror("file find error");
        if (chunk)
        {
            if (!(attr & (1 << 14)))
                return fail_puts("not a subdirectory");
            curdirchunk = chunk;
            curdir = base + chunk * 1024;
            fseek(floppy, curdir, SEEK_SET);
            return ferror(floppy) || find_free_dir_slot(floppy);
        }
        chunk = first_chunk;
        if (get_next_free_chunk(floppy, &chunk, &fileindx))
            return fail_puts("disk is full");
        if (directory_add_file_raw(floppy, file, chunk, total))
            return -1;
        if (fseek(floppy, base + chunk * 1024, SEEK_SET))
            return fail_perror("seek error");
        return initialize_directory(chunk, curdirchunk, floppy);
    }

    if (!(srcfile = fopen(file.srcfn, "rb")))
        return fail_perror("cannot open 'file'");

    dirpos = ftell(floppy);
    while ((read = fread(buf, 1, 1024, srcfile)) > 0)
    {
        if (get_next_free_chunk(floppy, &chunk, &fileindx))
            return fail_puts("disk is full");
        if (first_chunk == 0xFFFF)
            first_chunk = chunk;
        fseek(floppy, fileindx, SEEK_SET);
        fwrite(buf, 1, read, floppy);
        total += read;
    }

    fclose(srcfile);
    if (ferror(floppy))
        return -1;
    
    printf("%s: %lu B\n", file.srcfn, total);
    fseek(floppy, dirpos, SEEK_SET);
    return directory_add_file_raw(floppy, file, first_chunk, total);
}

int initialize_directory_chunk(unsigned chunk, FILE* floppy)
{
    unsigned i;
    unsigned oldpos;
    
    oldpos = ftell(floppy);
    for (i = 0; i < 512; ++i)
        fwrite("\377\377", 1, 2, floppy);   /* blank slot */

    if (!ferror(floppy))
        fseek(floppy, oldpos, SEEK_SET);
    return ferror(floppy) ? -1 : 0;
}

int initialize_directory(unsigned chunk, unsigned root_chunk, FILE* floppy)
{
    ADD_FILE af;
    time_t timer;
    struct tm* tinfo;
    
    if (initialize_directory_chunk(chunk, floppy))
        return -1;
    curdir = ftell(floppy);

    time(&timer);
    tinfo = localtime(&timer);

    strcpy(af.fn, ".         .   ");
    af.attr = 1 << 14;
    af.year = tinfo->tm_year - 80;
    af.month = tinfo->tm_mon + 1;
    af.day = tinfo->tm_mday;
    af.hour = tinfo->tm_hour;
    af.minute = tinfo->tm_min;
    af.second = tinfo->tm_sec % 60;
    
    if (directory_add_file_raw(floppy, af, chunk, 0))
        return -1;
    strcpy(af.fn, "..        .   ");
    if (root_chunk && directory_add_file_raw(floppy, af, root_chunk, 0))
        return -1;
    return ferror(floppy) ? -1 : 0;
}

int write_elfs_files(FILE* floppy)
{
    /* write root directory */
    unsigned chunk = 0;
    unsigned fileindx;
    unsigned i;
    unsigned numfiles = 0;

    if (get_next_free_chunk(floppy, &chunk, &fileindx))
        return fail_puts("disk is full");
    fseek(floppy, fileindx, SEEK_SET);

    if (initialize_directory(chunk, 0, floppy))
        return fail_perror("cannot initialize directory");
    curdirchunk = chunk;

    for (i = 0; i < add_files_cnt; ++i)
        if (directory_add_file(floppy, add_files[i]))
            return -1;

    return 0;
}

int prepare_elfs(const char* ffn, const char* fsfn)
{
    int ret;
    FILE* floppy;
    if (!(floppy = fopen(ffn, "rb+")))
        return fail_perror("cannot open floppy");

    srand(time(NULL));
    if (ret = read_fs_file(fsfn))
    {
        fclose(floppy);
        return EXIT_FAILURE;
    }
    if (ret = write_elfs_fsmb(floppy))
    {
        fail_perror("cannot write FSMB");
        fclose(floppy);
        return EXIT_FAILURE;
    }
    if (ret = write_elfs_ctable(floppy))
    {
        fail_perror("cannot write chunk table");
        fclose(floppy);
        return EXIT_FAILURE;
    }
    if (ret = write_elfs_files(floppy))
    {
        fclose(floppy);
        return EXIT_FAILURE;
    }

    fclose(floppy);
    return EXIT_SUCCESS;
}

int main(int argc, char** argv)
{
    int fdfilei = 0;
    int fsfilei = 0;
    int i;

    for (i = 1; i < argc; ++i)
    {
        if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help"))
            return print_help();
        else if (!strcmp(argv[i], "--"))
            break;
        else if (!fdfilei)
            fdfilei = i;
        else if (!fsfilei)
            fsfilei = i;
    }
    if (!fdfilei)
        fdfilei = i;
    if (!fsfilei)
        fsfilei = i + 1;
    if (fdfilei >= argc || fsfilei >= argc)
        return print_help();

    return prepare_elfs(argv[fdfilei], argv[fsfilei]);
}
