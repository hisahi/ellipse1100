AS=wla-65816
LD=wlalink
AFLAGS=-v
LDFLAGS=-d -v -S

default: all

ellipse.obj: FORCE
	$(AS) $(AFLAGS) -o $@ ellipse.asm
ellipse.rom: ellipse.obj
	$(LD) $(LDFLAGS) ellipse.lnk $@ && ./e1100cs ellipse.rom

floppies/hellow.obj: floppies/hellow.asm
	$(AS) $(AFLAGS) -o $@ $^
hellow.img: floppies/hellow.obj
	$(LD) $(LDFLAGS) hellow.lnk $@

floppies/memopad.obj: floppies/memopad.asm
	$(AS) $(AFLAGS) -o $@ $^
memopad.img: floppies/memopad.obj
	$(LD) $(LDFLAGS) memopad.lnk $@

all: ellipse.rom hellow.img memopad.img

FORCE: ;

.PHONY: all
.PHONY: clean

clean:
	rm -f *.obj *.rom *.img floppies/*.obj
