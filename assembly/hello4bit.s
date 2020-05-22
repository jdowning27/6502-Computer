PORTB = $6000
; PORTA = $6001
DDRB = $6002
; DDRA = $6003
PORTB_MODE_OUT = %01111111
PORTB_MODE_IN = %01110000

E  = %00010000
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

message: .asciiz "Hello World!"

lcd_init:
  ; lcd is initalized to 8 bit mode, our first command is sent in this mode
  lda #(%00000010 | 0) ; switch from 4 to 8 bit mode
  sta PORTB 
  lda #(%00000010 | E) ; set E bit to send
  sta PORTB
  lda #(%00000010 | 0) ; clear rs/rw/e bits
  sta PORTB

  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear the display
  jsr lcd_instruction

print_message:
  ldx #0
print_loop:
  lda message,x
  beq print_end
  jsr print_char
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
  pha            ; save instruction on the stack
  lsr A          ; logical shift down 4 bits
  lsr A
  lsr A
  lsr A          ; RS/RW/E are cleared
  sta PORTB      ; write the top four bits
  ora #E         ; pulse enable
  sta PORTB
  and #%11101111 ; clear enable bit
  sta PORTB
  pla            ; retrieve instruction from stack
  and #%00001111 ; mask off the top 4 bits
  sta PORTB      ; write the bottom 4 bits
  ora #E         ; pulse enable
  sta PORTB
  and #%11101111 ; clear enable bit
  sta PORTB
  rts

print_char:
  jsr lcd_wait
  pha             ; save instruction on the stack
  lsr A           ; logical shift down 4 bits
  lsr A
  lsr A
  lsr A           ; RS/RW/E are cleared
  ora #RS         ; Set RS; Clear RW/E bits
  sta PORTB       ; write the top four bits
  ora #E          ; pulse enable
  sta PORTB
  and #%11101111 ; clear enable bit
  sta PORTB
  pla             ; retrieve instruction from stack
  and #%00001111  ; mask off the top 4 bits
  ora #RS         ; Set RS; Clear RW/E bits
  sta PORTB       ; write the bottom 4 bits
  ora #E          ;pulse enable
  sta PORTB
  and #%11101111  ; clear enable bit
  sta PORTB
  rts

loop:
  jmp loop

  .org $fffc
  .word reset
  .word $0000