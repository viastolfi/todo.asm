.PHONY: all clean

all: todo

todo:
	nasm -f elf64 -g -F dwarf todo.asm -o todo.o
	ld -o todo todo.o

clean:
	rm todo
	rm todo.o
