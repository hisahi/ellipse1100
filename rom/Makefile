AS=wla-65816
LD=wlalink
AFLAGS=-v
LDFLAGS=-d -v -S

default: all

ellipse.obj: FORCE
	$(AS) $(AFLAGS) -o $@ ellipse.asm

ellipse.rom: ellipse.obj
	$(LD) $(LDFLAGS) ellipse.lnk $@

blankimg.obj: blankimg.asm
	$(AS) $(AFLAGS) -o $@ $^

blank.img: blankimg.obj
	$(LD) $(LDFLAGS) blankimg.lnk $@

all: ellipse.rom blank.img

FORCE: ;

.PHONY: all
.PHONY: clean

clean:
	rm -f *.obj *.rom *.img
