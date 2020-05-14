_Disclaimer: the product and the corporation that designed it as presented
in this document and this repository are fictitious. No identification with
actual companies (active or defunct), products, persons (living or deceased)
places or buildings is intended or should be inferred._

# TODO

_This is a fictional computer product designed to simulate a high-end machine
released in the mid-1980s. This repository includes design notes, an emulator
and will include the code for the ROM, including the bootloader and DOS, as well
as a graphical user interface at some point._

_The emulator is written in C and requires a backend (so far SDL2 is implemented)
and a coroutine library (both [libco](https://byuu.org/projects/libco) and [libaco](https://github.com/hnes/libaco) are supported)._

# Sources

## CPU; 65c816 emulation
* [65C816 Opcodes by Bruce Clark](http://6502.org/tutorials/65c816opcodes.html)
* [6502 documentation by John West and Marko Mäkelä](http://nesdev.com/6502_cpu.txt)
* [65816 Opcode matrix](http://www.oxyron.de/html/opcodes816.html)

