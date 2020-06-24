;0x0100-0x01ff = virtual registers
AX = $0100
BX = $0101
CX = $0102
PORTB = $7000
LCD_PORT = $7001
DDRB = $7002
DDR_LCD = $7003
LCD_PORT_MODE_OUT = %01111111
LCD_PORT_MODE_IN = %01110000
PORTB_MODE_OUT = %11111100
PORTB_MODE_IN = %00000000


; buttons connected to PORTB
UP_BUTTON =     %00000010 ;A6
DOWN_BUTTON =   %00000100 ;A5
LEFT_BUTTON =   %00000001 ;A7
RIGHT_BUTTON =  %00001000 ;A4
A_BUTTON =      %00010000 ;A3
B_BUTTON =      %00100000 ;A2

; flags for the lcd display on LCD_PORT
E  = %00010000
CE = %11101111
RW = %00100000
RS = %01000000


  .org $8000

reset:
  ldx #$ff              ; set the stack to 01ff
  txs

  lda #LCD_PORT_MODE_OUT   ; Set LCD_PORT to output mode
  sta DDR_LCD

  lda #PORTB_MODE_IN    ; set PORTB to input mode
  sta DDRB

  jsr lcd_init

main_loop:
  lda #%00000001        ; Clear the display
  jsr lcd_instruction

  jsr print_message     ; print the display message
  jsr display_button    ; read the button value and diaplsy it
  jsr slow_down
  jsr slow_down
  jsr slow_down
  jsr slow_down
  jsr slow_down
  jsr slow_down
  jsr slow_down
  jsr slow_down

  jmp main_loop

message: .asciiz "Btn Press: "

slow_down:
  pha
  txa
  pha

  ldx #0
slow_loop:
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  dex
  bne slow_loop

  pla
  tax
  pla
  rts

display_button:
  pha
  ; A = button pattern / char to print

  lda PORTB             ; read the button value from LCD_PORT
  
  cmp #UP_BUTTON        ; pick the character and load it into A
  beq up_pressed
  cmp #DOWN_BUTTON
  beq down_pressed     
  cmp #LEFT_BUTTON
  beq left_pressed
  cmp #RIGHT_BUTTON
  beq right_pressed
  cmp #A_BUTTON
  beq a_pressed
  cmp #B_BUTTON
  beq b_pressed
  lda #" "
  jmp print_button

up_pressed:
  lda #"U"
  jmp print_button
down_pressed:
  lda #"D"
  jmp print_button
left_pressed:
  lda #"L"
  jmp print_button
right_pressed:
  lda #"R"
  jmp print_button
a_pressed:
  lda #"A"
  jmp print_button
b_pressed:
  lda #"B"
  jmp print_button

print_button:
  jsr lcd_print_char    ; print the character

  pla
  rts

lcd_init:
  ; lcd is initalized to 8 bit mode, our first command is sent in this mode
  ; control bits 000
  ; instruction 0010xxxx
  lda #%00000010
  jsr send_nibble

  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear the display
  jsr lcd_instruction
  rts

print_message:
  ldx #0
print_loop:
  lda message,x
  beq print_end
  jsr lcd_print_char
  inx
  jmp print_loop
print_end:
  rts

lcd_wait:
  pha

  lda #LCD_PORT_MODE_IN  ; bottom 4 bits of Port A are input 
  sta DDR_LCD
lcd_busy:
  lda #RW         ; Set RW; clear RS/E bits
  sta LCD_PORT
  lda #(RW | E)   ; Set E bit to send instruction
  sta LCD_PORT
  lda LCD_PORT       ; Read  the top 4 bits from LCD_PORT
  pha
  lda #RW         ; Set RW; clear RS/E bits
  sta LCD_PORT
  lda #(RW | E)
  sta LCD_PORT  
  lda LCD_PORT       ; read the bottom 4 bits from LCD_PORT
  pla             ; pull top 4 off the stack, disguarding bottom 4
  and #%00001000
  bne lcd_busy    ; jump to top of loop if busy
  lda #RW
  sta LCD_PORT       ; clear enable bit
  lda #LCD_PORT_MODE_OUT  ; Port A is output
  sta DDR_LCD
  
  pla
  rts
  
lcd_instruction:
  jsr lcd_wait
  pha             ; save instruction on the stack
  lda #0          ; clear RS/RW/E flags
  sta AX          ; store flags in virtual register AX
  pla             ; instruction is stored in A
  jsr send_byte
  rts

lcd_print_char:
  jsr lcd_wait
  pha             ; save character on stack
  lda #RS         ; Set RS; clear RW/E flags
  sta AX          ; store flags in virtual register AX
  pla             ; instruction stored in A
  jsr send_byte
  rts


send_nibble:
  ; the pattern we want to send is stored in A
  sta LCD_PORT
  ora #E          ; set E bit to send
  sta LCD_PORT
  and #CE         ; clear E bit
  sta LCD_PORT
  rts

send_byte:
  ; the 8-bit data is stored in A
  ; the flag mask is stored in AX
  pha             ; save instruction on the stack
  lsr A           ; logical shift down 4 bits
  lsr A
  lsr A
  lsr A           ; flags are cleared
  ora AX          ; load the flags stored in AX
  jsr send_nibble

  pla             ; retrieve instruction from stack
  and #%00001111  ; mask off the top 4 bits
  ora AX          ; load the flags stored in AX
  jsr send_nibble
  rts

loop:
  jmp loop

  .org $fffc
  .word reset
  .word $0000