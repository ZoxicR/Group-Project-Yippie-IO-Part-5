# CS3B Part 4 — stack.out (STACK_SZ=5), clac.out (STACK_SZ=100), yippieio4.out
# Submit: make clean && make && make makefile.txt
# Valgrind: valgrind --leak-check=full ./stack.out
#           valgrind --leak-check=full ./clac.out

ifdef DEBUG
DEBUGFLGS = -g
else
DEBUGFLGS =
endif

ASM_CPP = gcc -c $(DEBUGFLGS) -x assembler-with-cpp

YIPPIEOBJS   = driver4yippieio.o getkey.o
STACKOBJS    = driverStack.o stack5.o putstring.o putch.o
CLACOBJS     = clac.o getkey.o stack100.o cstr2dfp.o putch.o

all: yippieio4.out stack.out clac.out

%.o : %.S
	$(ASM_CPP) $< -o $@

getkey.o: getkey.S gpiomem.S fileio.S
	$(ASM_CPP) -I. getkey.S -o getkey.o

putch.o: putch.s
	gcc -c $(DEBUGFLGS) putch.s -o putch.o

stack5.o: stack.s
	$(ASM_CPP) -DSTACK_SZ=5 stack.s -o stack5.o

stack100.o: stack.s
	$(ASM_CPP) -DSTACK_SZ=100 stack.s -o stack100.o

%.o : %.s
	gcc -c $(DEBUGFLGS) $< -o $@

yippieio4.out: $(YIPPIEOBJS)
	ld -o yippieio4.out $(YIPPIEOBJS)

stack.out: $(STACKOBJS)
	gcc -o stack.out $(STACKOBJS) -lm

clac.out: $(CLACOBJS)
	gcc -o clac.out $(CLACOBJS) -lm

makefile.txt: makefile
	cp makefile makefile.txt

clean:
	rm -f *.o yippieio4.out stack.out clac.out
