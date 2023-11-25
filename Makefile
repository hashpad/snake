all: run
	qemu-system-i386 snake -monitor stdio

run:
	nasm snake.asm -o snake
