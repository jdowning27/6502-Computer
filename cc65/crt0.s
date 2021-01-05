; ----------------------------------------------------------------
; crt0.s
; ----------------------------------------------------------------
;Startup code for bread board 6502 computer
; based on the example provided here:
; https://cc65.github.io/doc/customizing.html

.export _init, _exit
.import _main

.export __STARTUP__ : absolute = 1      ; Mark section as startup
.import __RAM_START__, __RAM_SIZE__     ; liker generated values

; importing cc65 startup subrutines
.import copydata, zerobss, initlib, donelib 

.include "zeropage.inc"

; A little light 6502 housekeeping

_init:    LDX     #$FF                 ; Initialize stack pointer to $01FF
          TXS
          CLD                          ; Clear decimal mode

; ---------------------------------------------------------------------------
; Set cc65 argument stack pointer

          LDA     #<(__RAM_START__ + __RAM_SIZE__)
          STA     sp
          LDA     #>(__RAM_START__ + __RAM_SIZE__)
          STA     sp+1

; ---------------------------------------------------------------------------
; Initialize memory storage

          JSR     zerobss              ; Clear BSS segment
          JSR     copydata             ; Initialize DATA segment
          JSR     initlib              ; Run constructors

; ---------------------------------------------------------------------------
; Call main()

          JSR     _main

; ---------------------------------------------------------------------------
; Back from main (this is also the _exit entry):  force a software break

_exit:    JSR     donelib              ; Run destructors
          BRK