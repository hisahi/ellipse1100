_Disclaimer: the product and the corporation that designed it as presented
in the following section and all of its subesctions are fictitious. No
identification with actual companies (active or defunct), products, persons
(living or deceased) places or buildings is intended or should be inferred._

# Ellipse 1100
![Ellipse 1100 Banner](https://raw.githubusercontent.com/hisahi/ellipse1100/master/assets/banner.png)

Some time in early 1986, a relatively obscure corporation called the
''Ellipse Data Electronics'' released a new computer model, the 16-bit
''Ellipse 1100'' that many considered a continuation of their earlier 8-bit
Ellipse 100 line, which had been a marginal market success. However, the 1100
was not compatible with the old 8-bit line despite Ellipse's best efforts, and
they instead banked on selling the 1100 in the market gap they perceived
existed between home computers and workstations.

This failed, as the 1100 was a marked failure. It was too expensive to be a
home computer, while it was not popular as a workstation due to limited
networking capabilities and because it didn't run UNIX. Ellipse was pushed into
bankrupcy by early 1987. Their computers soon fell into obscurity.

Despite this, the 1100 was a powerful machine for its time - with 1 MB of
RAM, fast CPU, bitmap screen with up to 256 colors, stereo analog audio output,
simple networking with Ellipse's own Conicnet protocol and SublimOS, a
multi-tasking graphical operating system.

## Specifications & documentation
* [Hardware specifications](https://github.com/hisahi/ellipse1100/blob/master/doc/HARDWARE.TXT)
* [Memory-mapped IO registers](https://github.com/hisahi/ellipse1100/blob/master/doc/IO.TXT)
* Ellipse ROM functions (TODO)
* Ellipse DOS functions (TODO)
* Emulator documentation (TODO)

# e1100em (Ellipse 1100 Emulator) and this repository

This repository includes design notes for the Ellipse 1100, a fictional
16-bit home computer, as well as a cross-platform emulator for it
and the code for the ROM, including the bootloader and DOS, as well
as a graphical user interface at some point (on a floppy).

The emulator is written in C and requires a backend (so far SDL2 is implemented)
and a coroutine library (both [libco](https://byuu.org/projects/libco) and [libaco](https://github.com/hnes/libaco) are supported).

# Sources
_These are the sources I (Sampo Hippeläinen) used to create the emulator._

## CPU; 65c816 emulation
* [65C816 Opcodes by Bruce Clark](http://6502.org/tutorials/65c816opcodes.html)
* [6502 documentation by John West and Marko Mäkelä](http://nesdev.com/6502_cpu.txt)
* [65816 Opcode matrix](http://www.oxyron.de/html/opcodes816.html)
