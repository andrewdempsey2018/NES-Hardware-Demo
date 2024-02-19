.include "constants.inc"

.segment "ZEROPAGE"
.importzp player_x, player_y

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

  ; initialise player_x and player_y to center of screen
  LDA #$80
  STA player_x
  LDA #$78
  STA player_y

vblankwait:
  BIT PPUSTATUS
  BPL vblankwait
vblankwait2:
  BIT PPUSTATUS
  BPL vblankwait2

  JMP main
.endproc