In this project I plan to build a simple 8-bit computer based on the 6502 microprocessor. 
I will be using the design created by Ben Eater (eater.net/6502) as a starting point
for my design and plan to add additional features and modifications to the design.

Ben's design is very simple, with a 2x8 character display for output, and a few push 
buttons for input. I would like to add more IO functionality to this. For my project
I would like to modify the design to include a larger display that can show multiple
lines of text and simple graphics. In addition to a better display I want this 
computer to be able to interface with a full sized keyboard. These improved peripherals
will probably interface with the 6502 processor directly through the 6522 or may need to
implement some sort of serial communication through SPI, I^2C, etc. 

Although this project is mostly based in assembly I would like to use this project
to practice programming in C. After finalizing the hardware design I plan to work more
on the software. I would like to write a simple operating system for
this computer based on my work in CS3650 Computer Systems. In addition I want to 
experiment whith programming simple games like pong and tetris. I think this could be
a good challenge since this computer will be extremely limited resources when compared
to the modern computers I am used to developing with. 


MODIFIED ADDRESS SPACE DESIGN

I have modified ben's design to use more complicated addressing logic. This allows
me to use the entire address space and allow more space for RAM. This logic can be 
implemented using two 74HC00s and one 74HC04. I used these chips to implement the 
following logic. 

RAM enabled = ~A15 & ~(A14 & A13 & A12)
I/O enabled = ~A15 & A14 & A13 & A12
ROM enabled = A15

To select specific I/O devices I will be using the 74HC138 Demultiplexer to 
use A11-A9 to address up to 8 peripherals. This can be expanding to 16 devices 
by using another demultiplexer.

This table shows the the modified address space. 

addr | Top 8-bits | enabled
0000 |    0000    | RAM
1000 |    0001    | RAM
...  |  0010-0101 | RAM
6000 |    0110    | RAM
7000 |    0100    | I/O
8000 |    1000    | ROM
...  |  1001-1110 | ROM
F000 |    1111    | ROM

HARDWARE IMPROVEMENTS

In addition to the push buttons and LCD screen included in the origional design,
I plan to add a serial interface through the use of the 6850 ACIA. This allows me
to design and test software for the 6502 without having to implement a video interface. 

The starting design had no way of storing anything in nonvolitile memory. This meant 
that program output could not be saved and recalled after a system restart. To solve
this issue I am going to be using the shift registers on a 6522 VIA to communicate
with an SD card module using SPI. This should give the new design plenty of storage
space to save program results or even store larger user programs.

 

SOFTWARE IMPROVMENTS

Compile C to 6502 ASM using cc65. While it will most likely run a lot slower than 
fine tuned assembly. cc65 seems to be the best way to get a modern language running
on hardware as old as the 6502. I saw one tech talk about running C++ on the 6502 with
"no-overhead". This was done with some clever compiler tricks to fully optimize the 
final assembly. The process involved compiling C++ to X86 and then "translating" that
asembly code to 6502 ASM. This might be a better option down the line if cc65 cannot
optimize my code well enough. For now I plan on using cc65 since writing a custom
target for the compiler is very straight forward. 

Create Interupt routines using the 6522 timers. The 6522 has two timer types 
(one-shot, regular interval) that can be used to send an interupt request to the 6502. 
This could be very useful for some programs, or for implementing simple operating 
systems (task scheduling, delays, ...). 

Implement bash/shell interface over the serial port. This will be super helpful for
running my own programs on the 6502. It also gives me an output that is more than the
16x2 characters that the origional LCD allows. I may be able to reuse the code from
CS3650 Computer Systems that includes a shell, file system and malloc.  
