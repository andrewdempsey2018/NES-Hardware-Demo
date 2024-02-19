.include "constants.inc"

.segment "ZEROPAGE"
.importzp x_pos, y_pos

.segment "CODE"
.import main
.export reset_handler
.proc reset_handler
  SEI ; ignore interrupts
  CLD ; turn off decimal mode
  LDX #$00
  STX PPUCTRL
  STX PPUMASK ; By storing $00 to both PPUCTRL and PPUMASK, we turn off NMIs and disable rendering to the screen during startup.

  LDX #$00
	LDA #$ff
clear_oam:
	STA $0200,X ; set sprite y-positions off the screen
	INX
	INX
	INX
	INX
	BNE clear_oam

  ; initialise x_pos and y_pos to center of screen
  LDA #$80
  STA x_pos
  LDA #$78
  STA y_pos

vblankwait:
  BIT PPUSTATUS
  BPL vblankwait
vblankwait2:
  BIT PPUSTATUS
  BPL vblankwait2

  JMP main
.endproc