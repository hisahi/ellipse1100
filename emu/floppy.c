/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
Floppy drive implementation

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
#include <string.h>

#include "mem.h"
#include "floppy.h"
#include "io.h"

BYTE floppy1_media[_FLOPPY_UD_SIZE];
BYTE floppy2_media[_FLOPPY_UD_SIZE];
BYTE floppy1_buffer[_FLOPPY_UD_SIZE];
BYTE floppy2_buffer[_FLOPPY_UD_SIZE];

floppy_drive drive1 = { .status = FLOPPY_STATUS_READY, .media = FLOPPY_NONE,
                        .disk = floppy1_media, .buffer = floppy1_buffer,
                        .error = FLOPPY_ERROR_NONE, .doirq = 0, .irq = 0x10 };
floppy_drive drive2 = { .status = FLOPPY_STATUS_READY, .media = FLOPPY_NONE,
                        .disk = floppy2_media, .buffer = floppy2_buffer,
                        .error = FLOPPY_ERROR_NONE, .doirq = 0, .irq = 0x11 };

void floppy_init(void)
{
    floppy_reset();
}

void floppy_free(void)
{
}

static inline void floppy_irq(floppy_drive* drive)
{
    if (drive->doirq)
        io_raise_irq(drive->irq);
}

static inline void floppy_clear_error(floppy_drive* drive)
{
    if (drive->status == FLOPPY_STATUS_ERROR)
    {
        drive->status = FLOPPY_STATUS_READY;
        drive->error = FLOPPY_ERROR_NONE;
    }
}

static inline void floppy_error(floppy_drive* drive, BYTE e)
{
    drive->status = FLOPPY_STATUS_ERROR;
    drive->error = e;
    floppy_irq(drive);
}

// 0 if success, <>0 if failure
int floppy_mount(int drivenum, FILE* file, int wp)
{
    size_t fsize;
    switch (drivenum)
    {
    case 0:
        if (drive1.status != FLOPPY_STATUS_READY)
            floppy_error(&drive1, FLOPPY_ERROR_NO_DISK);
        memset(floppy2_media, 0, sizeof(floppy1_media));
        floppy_irq(&drive1);
        fsize = fread(floppy1_media, 1, _FLOPPY_UD_SIZE, file);
        if (fsize < 1)
        {
            drive1.media = FLOPPY_NONE;
            memset(floppy1_media, 0, sizeof(floppy1_media));
            return 1;
        }
        else if (fsize <= _FLOPPY_SD_SIZE)
            drive1.media = wp ? FLOPPY_SD_WP : FLOPPY_SD;
        else if (fsize <= _FLOPPY_HD_SIZE)
            drive1.media = wp ? FLOPPY_HD_WP : FLOPPY_HD;
        else if (fsize <= _FLOPPY_UD_SIZE)
            drive1.media = wp ? FLOPPY_UD_WP : FLOPPY_UD;
        return 0;
    case 1:
        if (drive2.status != FLOPPY_STATUS_READY)
            floppy_error(&drive2, FLOPPY_ERROR_NO_DISK);
        memset(floppy2_media, 0, sizeof(floppy2_media));
        floppy_irq(&drive2);
        fsize = fread(floppy2_media, 1, _FLOPPY_UD_SIZE, file);
        if (fsize < 1)
        {
            drive2.media = FLOPPY_NONE;
            memset(floppy2_media, 0, sizeof(floppy2_media));
            return 1;
        }
        else if (fsize <= _FLOPPY_SD_SIZE)
            drive2.media = wp ? FLOPPY_SD_WP : FLOPPY_SD;
        else if (fsize <= _FLOPPY_HD_SIZE)
            drive2.media = wp ? FLOPPY_HD_WP : FLOPPY_HD;
        else if (fsize <= _FLOPPY_UD_SIZE)
            drive2.media = wp ? FLOPPY_UD_WP : FLOPPY_UD;
        return 0;
    }

    return -1;
}

int floppy_save_disk(int drivenum, FILE* file)
{
    floppy_drive* drive;
    size_t sz;
    switch (drivenum)
    {
    case 0: drive = &drive1; break;
    case 1: drive = &drive2; break;
    default: return 1;
    }

    if (floppy_is_write_protected(drive))
        return 0;
    sz = floppy_disk_size(drive);

    return fwrite(drive->disk, 1, sz, file) < sz;
}

void floppy_unmount(int drivenum)
{
    switch (drivenum)
    {
    case 0:
        drive1.media = FLOPPY_NONE;
        if (drive1.status != FLOPPY_STATUS_READY)
            floppy_error(&drive1, FLOPPY_ERROR_NO_DISK);
        else
            floppy_irq(&drive1);
        memset(floppy1_media, 0, sizeof(floppy1_media));
        break;
    case 1:
        drive2.media = FLOPPY_NONE;
        if (drive2.status != FLOPPY_STATUS_READY)
            floppy_error(&drive2, FLOPPY_ERROR_NO_DISK);
        else
            floppy_irq(&drive2);
        memset(floppy2_media, 0, sizeof(floppy2_media));
        break;
    }
}

static inline BYTE floppy_status(floppy_drive* drive)
{
    BYTE s;
    if (drive->status == FLOPPY_STATUS_READING
            || drive->status == FLOPPY_STATUS_WRITING)
        s |= 0x80;
    else if (drive->status == FLOPPY_STATUS_ERROR)
        s |= 0x40;
    
    switch (drive->media)
    {
    case FLOPPY_NONE: break;
    case FLOPPY_SD: s |= 0x0C; break;
    case FLOPPY_HD: s |= 0x10; break;
    case FLOPPY_UD: s |= 0x14; break;
    case FLOPPY_SD_WP: s |= 0x0E; break;
    case FLOPPY_HD_WP: s |= 0x12; break;
    case FLOPPY_UD_WP: s |= 0x16; break;
    }

    s |= drive->doirq << 5;
    return s;
}

static inline void floppy_read_sector(floppy_drive* drive)
{
    memcpy(drive->buffer,
           drive->disk + drive->disk_offset, _FLOPPY_SECTOR_SIZE);
    drive->target_sector = (drive->target_sector + 1)
                            % floppy_sector_count(drive);
    drive->sector = drive->target_sector;
    drive->sector_offset = 0;
}

static inline void floppy_write_sector(floppy_drive* drive)
{
    memcpy(drive->disk + drive->disk_offset,
           drive->buffer, _FLOPPY_SECTOR_SIZE);
    drive->status = FLOPPY_STATUS_DISK_WRITE;
    drive->seek_time = floppy_sector_rw_time(floppy_sector_count(drive));
}

static void floppy_seek_done(floppy_drive* drive)
{
#if _FLOPPY_DEBUG
    printf("Floppy has finished seeking (off = %d)\n", drive->disk_offset);
#endif
    switch (drive->status)
    {
    case FLOPPY_STATUS_DISK_WRITE:
        drive->target_sector = (drive->target_sector + 1)
                                % floppy_sector_count(drive);
    case FLOPPY_STATUS_SEEK:
        drive->status = FLOPPY_STATUS_READY;
        floppy_irq(drive);
        break;
    case FLOPPY_STATUS_SEEK_READ:
        floppy_read_sector(drive);
        drive->status = FLOPPY_STATUS_READING;
        floppy_irq(drive);
        break;
    case FLOPPY_STATUS_SEEK_WRITE:
        drive->status = FLOPPY_STATUS_WRITING;
        floppy_irq(drive);
        break;
    }
    drive->sector = drive->target_sector;
    drive->track = drive->target_track;
}

static void floppy_seek(floppy_drive* drive, int write)
{
#if _FLOPPY_DEBUG
    puts("Seeking floppy drive");
#endif
    unsigned target_track = 127 & drive->target_track;
    drive->side = drive->target_track >> 7;
    
    if (drive->status == FLOPPY_STATUS_SEEK
        || drive->status == FLOPPY_STATUS_SEEK_READ
        || drive->status == FLOPPY_STATUS_SEEK_WRITE
        || drive->status == FLOPPY_STATUS_DISK_WRITE)
    {
        floppy_error(drive, FLOPPY_ERROR_BUSY);
        return;
    }
    if (drive->media == FLOPPY_NONE)
    {
        floppy_error(drive, FLOPPY_ERROR_NO_DISK);
        return;
    }
    if (write && floppy_is_write_protected(drive))
    {
        floppy_error(drive, FLOPPY_ERROR_FAIL_WRITE);
        return;
    }

    if (target_track >= _FLOPPY_TRACKS)
    {
        floppy_error(drive, FLOPPY_ERROR_FAIL_SEEK);
        return;
    }
    if (drive->target_sector >= floppy_sector_count(drive))
    {
        floppy_error(drive, FLOPPY_ERROR_FAIL_SEEK);
        return;
    }

    drive->disk_offset = ((drive->side * _FLOPPY_TRACKS + target_track)
                        * floppy_sector_count(drive) + drive->target_sector)
                        * _FLOPPY_SECTOR_SIZE;
    drive->seek_time = floppy_seek_time_to_track(target_track,
                                                 drive->track);
    drive->seek_time += floppy_seek_time_to_sector(drive->target_sector,
                                                   drive->sector,
                                                   floppy_sector_count(drive));
    drive->sector_offset = 0;
    drive->status = FLOPPY_STATUS_SEEK;
}

inline static void floppy_seek_read(floppy_drive* drive)
{
    floppy_seek(drive, 0);
    if (drive->status == FLOPPY_STATUS_SEEK)
    {
        drive->status = FLOPPY_STATUS_SEEK_READ;
        drive->seek_time += floppy_sector_rw_time(floppy_sector_count(drive));
#if _FLOPPY_DEBUG
        printf("Seeking floppy drive for reading, will take %d ms\n",
                drive->seek_time);
        printf("seeking from T=%3d/S=%2d to T=%3d/S=%2d\n",
                drive->track, drive->sector,
                drive->target_track, drive->target_sector);
#endif

        if (drive->seek_time == 0)
            floppy_seek_done(drive);
    }
}

inline static void floppy_seek_write(floppy_drive* drive)
{
    floppy_seek(drive, 1);
    if (drive->status == FLOPPY_STATUS_SEEK)
    {
        drive->status = FLOPPY_STATUS_SEEK_WRITE;
#if _FLOPPY_DEBUG
        printf("Seeking floppy drive for writing, will take %d ms\n",
                drive->seek_time);
#endif

        if (drive->seek_time == 0)
            floppy_seek_done(drive);
    }
}

static inline void floppy_control(floppy_drive* drive, BYTE b)
{
    drive->doirq = (b >> 5) & 1;

    if (b & 64)
        floppy_clear_error(drive);
    else if (drive->status == FLOPPY_STATUS_ERROR)
        return;

    switch (b & 3)
    {
    case 1: floppy_seek_read(drive); break;
    case 2: floppy_seek_write(drive); break;
    case 3: 
        floppy_seek(drive, 0);
        if (drive->status == FLOPPY_STATUS_SEEK && drive->seek_time == 0)
            floppy_seek_done(drive);
        break;
    }
}

static inline BYTE floppy_read_byte(floppy_drive* drive)
{
    if (drive->status != FLOPPY_STATUS_READING) return 0;
    BYTE v = drive->buffer[drive->sector_offset++];
    if (drive->sector_offset >= _FLOPPY_SECTOR_SIZE)
    {
        drive->sector_offset = 0;
        drive->status = FLOPPY_STATUS_READY;
    }
    return v;
}

static inline void floppy_write_byte(floppy_drive* drive, BYTE b)
{
    if (drive->status != FLOPPY_STATUS_WRITING) return;
    drive->buffer[drive->sector_offset++] = b;
    if (drive->sector_offset >= _FLOPPY_SECTOR_SIZE)
    {
        drive->sector_offset = 0;
        floppy_write_sector(drive);
    }
}

int floppy_has_media(int drivenum)
{
    floppy_drive* drive;
    switch (drivenum)
    {
    case 0: drive = &drive1; break;
    case 1: drive = &drive2; break;
    default: return 0;
    }

    return drive->media != FLOPPY_NONE;
}

BYTE floppy_read(int drivenum, int port)
{
    floppy_drive* drive;
    switch (drivenum)
    {
    case 0: drive = &drive1; break;
    case 1: drive = &drive2; break;
    default: return (BYTE)0xFF;
    }

    switch (port)
    {
    case 0:
        return floppy_status(drive);
    case 1:
        return drive->target_sector;
    case 2:
        return drive->target_track;
    case 3:
        if (drive->status == FLOPPY_STATUS_READING)
            return floppy_read_byte(drive);
        else if (drive->status == FLOPPY_STATUS_ERROR)
            return drive->error;
        break;
    }
    return (BYTE)0xFF;
}

void floppy_write(int drivenum, int port, BYTE data)
{
    floppy_drive* drive;
    switch (drivenum)
    {
    case 0: drive = &drive1; break;
    case 1: drive = &drive2; break;
    default: return;
    }

    switch (port)
    {
    case 0:
        floppy_control(drive, data);
        return;
    case 1:
        drive->target_sector = data & 31;
        break;
    case 2:
        drive->target_track = data;
        break;
    case 3:
        if (drive->status == FLOPPY_STATUS_WRITING)
            floppy_write_byte(drive, data);
        return;
    }
}

static inline void floppy_tick_drive(floppy_drive* drive, int deltaMs)
{
    if (drive->seek_time > 0)
    {
        drive->seek_time -= deltaMs;
        if (drive->seek_time <= 0)
        {
            drive->seek_time = 0;
            floppy_seek_done(drive);
        }
    }
}

void floppy_tick(int deltaMs)
{
    floppy_tick_drive(&drive1, deltaMs);
    floppy_tick_drive(&drive2, deltaMs);
}

void floppy_reset(void)
{
    drive1.status = FLOPPY_STATUS_READY;
    drive1.error = FLOPPY_ERROR_NONE;
    drive1.doirq = 0;
    drive1.seek_time = 0;

    drive2.status = FLOPPY_STATUS_READY;
    drive2.error = FLOPPY_ERROR_NONE;
    drive2.doirq = 0;
    drive1.seek_time = 0;
}
