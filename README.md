# NES Hardware Demo

![screensot](readme_files/scr1.png)

### Controls

U/D/L/R - move ship
A - Shoot
Start - Begin demo

### Assembly

1. ca65 src/main.asm
2. ca65 src/reset.asm
3. ld65 src/reset.o src/main.o -C nes.cfg -o output.nes