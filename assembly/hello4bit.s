;0x0100-0x01ff = virtual registers
AX = $0100
BX = $0101
CX = $0102
PORTB = $6000
; PORTA = $6001
DDRB = $6002
; DDRA = $6003
PORTB_MODE_OUT = %01111111
PORTB_MODE_IN = %01110000


E  = %00010000
CE = %11101111
RW = %00100000
RS = %01000000

  .org $8000

reset:
  ldx #$ff ; set the stack to 01ff
  txs

  lda #PORTB_MODE_OUT ; Set PORTB to output mode
  sta DDRB

  jsr lcd_init
  jsr print_message
  jmp loop

message: .asciiz "Hello Dave!"

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