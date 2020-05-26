;0x0100-0x01ff = virtual registers
AX = $0100
BX = $0101
CX = $0102
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
PORTB_MODE_OUT = %01111111
PORTB_MODE_IN = %01110000
PORTA_MODE_OUT = %11111100
PORTA_MODE_IN = %00000000


; buttons connected to PORTA
UP_BUTTON = %10000000
DOWN_BUTTON = %01000000
LEFT_BUTTON = %00100000
RIGHT_BUTTON = %00010000
A_BUTTON = %00001000
B_BUTTON = %00000100

; flags for the lcd display on PORTB
E  = %00010000
CE = %11101111
RW = %00100000
RS = %01000000


  .org $8000

reset:
  ldx #$ff              ; set the stack to 01ff
  txs

  lda #PORTB_MODE_OUT   ; Set PORTB to output mode
  sta DDRB

  lda #PORTA_MODE_IN    ; set PORTA to input mode
  sta DDRA

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

  lda PORTA             ; read the button value from PORTA
  
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

  lda #PORTB_MODE_IN  ; bottom 4 bits of Port B are input 
  sta DDRB
lcd_busy:
  lda #RW         ; Set RW; clear RS/E bits
  sta PORTB
  lda #(RW | E)   ; Set E bit to send instruction
  sta PORTB
  lda PORTB       ; Read  the top 4 bits from PORTB
  pha
  lda #RW         ; Set RW; clear RS/E bits
  sta PORTB
  lda #(RW | E)
  sta PORTB  
  lda PORTB       ; read the bottom 4 bits from PORTB
  pla             ; pull top 4 off the stack, disguarding bottom 4
  and #%00001000
  bne lcd_busy    ; jump to top of loop if busy
  lda #RW
  sta PORTB       ; clear enable bit
  lda #PORTB_MODE_OUT  ; Port B is output
  sta DDRB
  
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
  sta PORTB
  ora #E          ; set E bit to send
  sta PORTB
  and #CE         ; clear E bit
  sta PORTB
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