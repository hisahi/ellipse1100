CC=cc
AS=wla-65816
LD=wlalink
AFLAGS=-v
LDFLAGS=-d -v -S
CFLAGS=-ansi -pedantic

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

dos/dossys.obj: dos/*.asm
	$(AS) $(AFLAGS) -o $@ dos/dos.asm
DOS.SYS: dos/dossys.obj
	$(LD) $(LDFLAGS) -b dossys.lnk $@
floppies/edos.obj: floppies/dos.asm dos/*.asm
	$(AS) $(AFLAGS) -o $@ $<

dos/hello.obj: dos/progs/hello.asm
	$(AS) $(AFLAGS) -o $@ $<
HELLO.COM: dos/hello.obj
	$(LD) $(LDFLAGS) -b hello.lnk $@
dos/touch.obj: dos/progs/touch.asm
	$(AS) $(AFLAGS) -o $@ $<
TOUCH.COM: dos/touch.obj
	$(LD) $(LDFLAGS) -b touch.lnk $@
dos/reboot.obj: dos/progs/reboot.asm
	$(AS) $(AFLAGS) -o $@ $<
REBOOT.COM: dos/reboot.obj
	$(LD) $(LDFLAGS) -b reboot.lnk $@
dos/format.obj: dos/progs/format.asm
	$(AS) $(AFLAGS) -o $@ $<
FORMAT.COM: dos/format.obj
	$(LD) $(LDFLAGS) -b format.lnk $@
dos/monitor.obj: dos/progs/monitor.asm
	$(AS) $(AFLAGS) -o $@ $<
MONITOR.COM: dos/monitor.obj
	$(LD) $(LDFLAGS) -b monitor.lnk $@
dos/sys.obj: dos/progs/sys.asm
	$(AS) $(AFLAGS) -o $@ $<
SYS.COM: dos/sys.obj
	$(LD) $(LDFLAGS) -b sys.lnk $@
dos/console.obj: dos/console.asm dos/consolec.asm dos/consolef.asm
	$(AS) $(AFLAGS) -o $@ $<
CONSOLE.COM: dos/console.obj
	$(LD) $(LDFLAGS) -b console.lnk $@
	
floppies/elfsdisk.obj: floppies/elfsdisk.asm
	$(AS) $(AFLAGS) -o $@ $<

elfsdisk.img: makeelfs floppies/elfsdisk.obj floppies/elfsdisk.fs
	$(LD) $(LDFLAGS) elfsdisk.lnk $@ && ./makeelfs elfsdisk.img floppies/elfsdisk.fs
edos.img: makeelfs DOS.SYS CONSOLE.COM HELLO.COM TOUCH.COM REBOOT.COM \
			FORMAT.COM MONITOR.COM SYS.COM \
			dos/dossys.obj floppies/edos.obj floppies/dos.fs
	$(LD) $(LDFLAGS) edos.lnk $@ && ./makeelfs edos.img floppies/dos.fs

all: ellipse.rom hellow.img memopad.img edos.img elfsdisk.img

.DELETE_ON_ERROR:

.PHONY: all
.PHONY: clean
.PHONY: .DELETE_ON_ERROR

clean:
	rm -f *.obj *.rom *.img DOS.SYS CONSOLE.COM floppies/*.obj
