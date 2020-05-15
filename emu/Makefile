CC=gcc
FLAGS=-O2 -pedantic -std=c99 -g
CFLAGS=-L. -lSDL2
ACOFLAGS=-O2
DEPS = e1100.h emulator.h emuterm.h coro.h backend.h cpu.h alu.h io.h \
		mem.h vpu.h
OBJ = alu.o cpu_am.o cpu_in.o cpu.o dbg.o mem.o disasm.o \
		floppy.o io.o vpu.o emulator.o emuterm.o e1100.o coro.o \
		backend/sdl2.o
OUT = e1100em

DEPS_LIBACO := $(DEPS) coro/libaco/aco.h
DEPS_LIBCO := $(DEPS) coro/libco/libco.h

OBJ_LIBACO := $(OBJ) coro/libaco/aco.o coro/libaco/acosw.o
OBJ_LIBCO := $(OBJ) coro/libco/libco.c

default: specifycoerr

coro/libaco/acosw.o: coro/libaco/acosw.S
	$(CC) $(ACOFLAGS) -c -o $@ $^ $(ACOCFLAGS)
coro/libaco/aco.o: coro/libaco/aco.c
	$(CC) $(ACOFLAGS) -c -o $@ $^ $(ACOCFLAGS)

%.o: %.c $(HEADERS) $(DEPS)
	$(CC) $(FLAGS) -c -o $@ $< $(CFLAGS)

libco: DEPS = ${DEPS_LIBCO}
libco: FLAGS := ${FLAGS} -D_CORO_LIBCO
libaco: DEPS = ${DEPS_LIBACO}
libaco: FLAGS := ${FLAGS} -D_CORO_LIBACO

libco: $(OBJ_LIBCO)
	$(CC) -o $(OUT) $^ $(CFLAGS)
libaco: $(OBJ_LIBACO)
	$(CC) -o $(OUT) $^ $(CFLAGS)

.PHONY: clean
.PHONY: specifycoerr

clean:
	rm -f *.o backend/*.o coro/libco/libco.o coro/libaco/aco.o e1100em

specifycoerr:
	$(error Specify coroutine lib to use: make libco or make libaco)
