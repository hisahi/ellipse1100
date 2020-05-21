CC=cc
AS=wla-65816
LD=wlalink
AFLAGS=-v
LDFLAGS=-d -v -S
CFLAGS=

default: all

e1100cs: e1100cs.c
	$(CC) $(CFLAGS) -o $@ $^
makeelfs: makeelfs.c
	$(CC) $(CFLAGS) -o $@ $^

ellipse.obj: *.asm
	$(AS) $(AFLAGS) -o $@ ellipse.asm
ellipse.rom: e1100cs ellipse.obj
	$(LD) $(LDFLAGS) ellipse.lnk $@ && ./e1100cs ellipse.rom

floppies/hellow.obj: floppies/hellow.asm
	$(AS) $(AFLAGS) -o $@ $^
hellow.img: floppies/hellow.obj
	$(LD) $(LDFLAGS) hellow.lnk $@

floppies/memopad.obj: floppies/memopad.asm
	$(AS) $(AFLAGS) -o $@ $^
memopad.img: floppies/memopad.obj
	$(LD) $(LDFLAGS) memopad.lnk $@

dos/dos.obj: dos/dos.asm
	$(AS) $(AFLAGS) -o $@ $<
DOS.SYS: dos/dos.obj
	$(LD) $(LDFLAGS) dossys.lnk $@
floppies/dos.obj: floppies/dos.asm dos/*.asm
	$(AS) $(AFLAGS) -o $@ $<
dos.img: makeelfs DOS.SYS floppies/dos.obj floppies/dos.fs
	$(LD) $(LDFLAGS) dos.lnk $@ && ./makeelfs dos.img floppies/dos.fs

all: ellipse.rom hellow.img memopad.img dos.img

.DELETE_ON_ERROR:

.PHONY: all
.PHONY: clean
.PHONY: .DELETE_ON_ERROR

clean:
	rm -f *.obj *.rom *.img floppies/*.obj
