/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
Floppy drive header

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

#ifndef _E1100_FLOPPY_H
#define _E1100_FLOPPY_H

#include "mem.h"
#include <stdio.h>

#define _FLOPPY_SIDES 2
#define _FLOPPY_TRACKS 80
#define _FLOPPY_SECTOR_SIZE 512
#define _FLOPPY_SD_SECTORS 12
#define _FLOPPY_HD_SECTORS 16
#define _FLOPPY_UD_SECTORS 20

#define _FLOPPY_SD_SIZE (_FLOPPY_SIDES * _FLOPPY_TRACKS * _FLOPPY_SECTOR_SIZE \
                         * _FLOPPY_SD_SECTORS)
#define _FLOPPY_HD_SIZE (_FLOPPY_SIDES * _FLOPPY_TRACKS * _FLOPPY_SECTOR_SIZE \
                         * _FLOPPY_HD_SECTORS)
#define _FLOPPY_UD_SIZE (_FLOPPY_SIDES * _FLOPPY_TRACKS * _FLOPPY_SECTOR_SIZE \
                         * _FLOPPY_UD_SECTORS)

#define _DRIVE_TRACK_SEEK_TIME_MS 6
#define _DRIVE_HEAD_SETTLE_TIME_MS 2
#define _DRIVE_RPM 300

#define _ABS(x) ((x < 0) ? (-x) : (x))

typedef enum floppy_size {
    FLOPPY_NONE, FLOPPY_SD, FLOPPY_HD, FLOPPY_UD,
    FLOPPY_SD_WP, FLOPPY_HD_WP, FLOPPY_UD_WP
} floppy_size;

typedef enum floppy_drive_status {
    FLOPPY_STATUS_READY,
    FLOPPY_STATUS_SEEK,
    FLOPPY_STATUS_SEEK_READ,
    FLOPPY_STATUS_SEEK_WRITE,
    FLOPPY_STATUS_READING,
    FLOPPY_STATUS_WRITING,
    FLOPPY_STATUS_ERROR,
    FLOPPY_STATUS_DISK_WRITE
} floppy_drive_status;

#define FLOPPY_ERROR_NONE 0
#define FLOPPY_ERROR_BUSY 1
#define FLOPPY_ERROR_NO_DISK 2
#define FLOPPY_ERROR_FAIL_SEEK 3
#define FLOPPY_ERROR_FAIL_READ 4
#define FLOPPY_ERROR_FAIL_WRITE 5

typedef struct floppy_drive {
    unsigned char* disk;
    unsigned char* buffer;
    unsigned int track;
    unsigned int sector;
    unsigned int target_track;
    unsigned int target_sector;
    unsigned int sector_offset;
    unsigned int disk_offset;
    int seek_time;
    floppy_drive_status status;
    floppy_size media;
    unsigned char side;
    unsigned char error;
    unsigned char doirq;
    BYTE irq;
} floppy_drive;

inline int floppy_is_write_protected(floppy_drive* drive)
{
    switch (drive->media)
    {
    case FLOPPY_NONE: 
    case FLOPPY_SD:
    case FLOPPY_HD:
    case FLOPPY_UD: return 0;
    case FLOPPY_SD_WP:
    case FLOPPY_HD_WP:
    case FLOPPY_UD_WP: return 1;
    }

    return 0;
}

inline int floppy_sector_count(floppy_drive* drive)
{
    switch (drive->media)
    {
    case FLOPPY_NONE: break;
    case FLOPPY_SD:
    case FLOPPY_SD_WP: return _FLOPPY_SD_SECTORS;
    case FLOPPY_HD:
    case FLOPPY_HD_WP: return _FLOPPY_HD_SECTORS;
    case FLOPPY_UD:
    case FLOPPY_UD_WP: return _FLOPPY_UD_SECTORS;
    }

    return 0;
}

inline size_t floppy_disk_size(floppy_drive* drive)
{
    switch (drive->media)
    {
    case FLOPPY_NONE: return 0;
    case FLOPPY_SD:
    case FLOPPY_SD_WP: return _FLOPPY_SD_SIZE;
    case FLOPPY_HD:
    case FLOPPY_HD_WP: return _FLOPPY_HD_SIZE;
    case FLOPPY_UD:
    case FLOPPY_UD_WP: return _FLOPPY_UD_SIZE;
    }

    return 0;
}

inline int floppy_seek_time_to_track(int current, int target)
{
    if (current == target) return 0;
    return _ABS(current - target) * _DRIVE_TRACK_SEEK_TIME_MS
                                  + _DRIVE_HEAD_SETTLE_TIME_MS;
}

inline int floppy_seek_time_to_sector(int current, int target, int count)
{
    if (target < current) target += count;
    int rawtime = (target - current) * (1000 / (_DRIVE_RPM / 60));
    return (rawtime + (count - 1)) / count;
}

inline int floppy_sector_rw_time(int count)
{
    return floppy_seek_time_to_sector(0, 1, count);
}

void floppy_init(void);
void floppy_free(void);
void floppy_tick(int deltaMs);
void floppy_reset(void);
// 0 if success, <>0 if failure. FILE must be opened in read mode
int floppy_mount(int drivenum, FILE* file, int wp);
void floppy_unmount(int drivenum);
int floppy_has_media(int drivenum);
// 0 if success, <>0 if failure. FILE must be opened in write mode
int floppy_save_disk(int drivenum, FILE* file);
BYTE floppy_read(int drivenum, int port);
void floppy_write(int drivenum, int port, BYTE data);

#endif /* _E1100_FLOPPY_H */
