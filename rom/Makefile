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

dos/dossys.obj: dos/*.asm
	$(AS) $(AFLAGS) -o $@ dos/dos.asm
DOS.SYS: dos/dossys.obj
	$(LD) $(LDFLAGS) dossys.lnk $@
floppies/edos.obj: floppies/dos.asm dos/*.asm
	$(AS) $(AFLAGS) -o $@ $<

dos/hello.obj: dos/hello.asm
	$(AS) $(AFLAGS) -o $@ $<
HELLO.COM: dos/hello.obj
	$(LD) $(LDFLAGS) -b hello.lnk $@

dos/console.obj: dos/console.asm
	$(AS) $(AFLAGS) -o $@ $<
CONSOLE.COM: dos/console.obj
	$(LD) $(LDFLAGS) -b console.lnk $@

edos.img: makeelfs DOS.SYS CONSOLE.COM HELLO.COM \
			dos/dossys.obj floppies/edos.obj floppies/dos.fs
	$(LD) $(LDFLAGS) edos.lnk $@ && ./makeelfs edos.img floppies/dos.fs

all: ellipse.rom hellow.img memopad.img edos.img

.DELETE_ON_ERROR:

.PHONY: all
.PHONY: clean
.PHONY: .DELETE_ON_ERROR

clean:
	rm -f *.obj *.rom *.img DOS.SYS CONSOLE.COM floppies/*.obj
