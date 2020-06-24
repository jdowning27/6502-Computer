;0x0100-0x01ff = virtual registers
AX = $0100
BX = $0101
CX = $0102
LCD_PORT = $7001
; PORTA = $6001
DDR_LCD = $7003
; DDRA = $6003
LCD_PORT_MODE_OUT = %01111111
LCD_PORT_MODE_IN = %01110000


E  = %00010000
CE = %11101111
RW = %00100000
RS = %01000000

  .org $8000

reset:
  ldx #$ff ; set the stack to 01ff
  txs

  lda #LCD_PORT_MODE_OUT ; Set LCD_PORT to output mode
  sta DDR_LCD

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

  lda #LCD_PORT_MODE_IN  ; bottom 4 bits of Port B are input 
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
  lda #LCD_PORT_MODE_OUT  ; Port B is output
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