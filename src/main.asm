.include "constants.inc" 
.include "header.inc"

.import reset_handler

.segment "ZEROPAGE"
x_pos: .res 1
y_pos: .res 1
sleeping: .res 1
world: .res 2
.exportzp x_pos, y_pos

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
  LDA #$00

  ;;
  LDA #$00
  STA sleeping

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP

  RTI
.endproc

.proc move_square

  LDA y_pos
  STA $0200
  LDA #$01
  STA $0201
  LDA #$01
  STA $0202
  LDX x_pos
  INX
  STX x_pos
  STX $0203

  RTS
.endproc

.export main
.proc main
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR

load_palettes:
  LDA palettes,X
  STA PPUDATA
  INX
  CPX #$20 ; there are 32 colours to load
  BNE load_palettes

  ;initialize world to point to world data
  LDA #<nametable ;point to low byte of nametable
  STA world
  LDA #>nametable ;point to high byte of nametable
  STA world+1

;using the ppuADDR and the ppuDATA read buffer (PPUADDR and PPUDATA)
;tell the ppu we are going to start filling up the first nametable (which starts at $2000 in ppu ram)
loadBackground:
  LDA PPUSTATUS ;read ppu status to reset the high/low latch
  LDA #$20
  STA PPUADDR ;write the high byte of $2000 address
  LDA #$00
  STA PPUADDR ;write the low byte of $2000 address

  LDX #$00
  LDY #$00
loadWorld:
  LDA (world), Y
  STA PPUDATA
  INY
  CPX #$03
  BNE label
  CPY #$c0
  BEQ doneLoadingWorld
label:
  CPY #$00
  BNE loadWorld
  INX
  INC world+1
  JMP loadWorld

doneLoadingWorld:
  LDX #$00

;each nametable has an associated attribute table
;the nametable takes up 960 bytes and the remaining 64 bytes belong to the attribute table (960 + 64 = 1,024)
;as the first nametable starts at $2000 and takes up 960 bytes, the attributes start at $23c0 (960 decimal = 3c0 hex)
loadAttribute:
  LDA PPUSTATUS ;read PPU status to reset the high/low latch
  LDA #$23
  STA PPUADDR ;write the high byte of $23c0 address
  LDA #$c0
  STA PPUADDR ;write the low byte of $23c0 address
  LDX #$00 ;start out at 0

;load all 64 attribues for this nametable
loadAttributeLoop:
  LDA attribute, x ;load data from address (attribute + the value in x)
  STA PPUDATA ;write to PPU
    inx
    cpx #$40 ;compare x to hex $40, decimal 64 - copying 64 bytes
    bne loadAttributeLoop

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

mainloop:

  JSR move_square

  ;loop
  INC sleeping
sleep:
  LDA sleeping
  BNE sleep

  JMP mainloop
.endproc

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "new_gfx.chr"

.segment "RODATA"
palettes:
  ; background
  .byte $31, $12, $23, $27 ; skyblue,blue,purple,orange
  .byte $31, $2b, $3c, $39 ; skyblue,green,lightblue,mint
  .byte $31, $0c, $07, $13 ; skyblue,blue,brown,purple
  .byte $31, $19, $09, $29 ; skyblue,green,green,lightgreen

  ; sprites
  .byte $31, $2d, $10, $15 ; skyblue,grey,grey,pink
  .byte $31, $21, $23, $27 ; skyblue,blue,pink,orange
  .byte $31, $2a, $17, $01 ; skyblue,lightgreen,brown,darkblue
  .byte $31, $19, $09, $29 ; skyblue,green,green,lightgreen

nametable:
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01
  .byte $00,$00,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01
  .byte $00,$00,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

attribute:
  .byte $aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa
  .byte $aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa
  .byte $aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa
  .byte $aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a