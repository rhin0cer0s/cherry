ARCH=elf32
EXECS=code_11 code_121 code_122

all :: $(EXECS)

%.o : %.asm
	nasm -f $(ARCH) -o $@ -g $<

$(EXECS) : %: %.o
	ld -m elf_i386 -o $@ $@.o

clean :
	rm *.o $(EXECS)
