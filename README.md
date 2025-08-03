# BIOS-Size Snake (16-bit x86 Real-Mode Boot-Sector)

This is an attempt to squeeze a working snake game into a single 512-byte boot sector, running entirely in 16-bit x86 real mode.

## Build

```bash
# You need NASM, qemu-system-i386
make all
```

`snake` **must** be exactly 512 bytes and end with the boot signature `0x55 0xAA`.


## Write it directly to a USB stick/virtual floppy:

```bash
sudo dd if=snake.bin of=/dev/sdX bs=512 count=1 conv=notrunc
```

## Implemented features

* Real-mode timer interrupt handler for game loop (INT 1Ch)
* 320×200×256 VGA graphics (mode 0x13)
* Snake head + tail rendering
* Screen clearing
* X/Y wrapping logic
* Direction control via hardcoded movement (modifiable)

## Missing features

* Keyboard input (currently hardcoded movement)
* Food spawning and consumption logic
* Self-collision detection
* Score tracking
* Tail growth logic
