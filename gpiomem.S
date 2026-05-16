// Various macros to access the GPIO pins
// on the Raspberry Pi.
//
// X9 - memory map address.
//

#include "fileio.S"

.equ    pagelen,        4096
.equ    setregoffset,   28      // 0x1C GPSET0
.equ    clrregoffset,   40      // 0x28 GPCLR0
.equ    levregoffset,   52      // 0x34 GPLEV0
.equ    gppudoffset,    148     // 0x94 GPPUD    (Pi3/BCM2835)
.equ    gppudclkoffset, 152     // 0x98 GPPUDCLK0(Pi3/BCM2835)
.equ    PROT_READ,      1
.equ    PROT_WRITE,     2
.equ    MAP_SHARED,     1

// Macro to map memory for GPIO Registers
.macro mapMem
    openFile    devmem, O_RDWR     // open /dev/gpiomem
    ADDS        X4, XZR, X0        // fd for memmap
    // check for error
    B.PL        1f
    MOV         X1, #1
    LDR         X2, =memOpnsz
    LDR         W2, [X2]
    writeFile   X1, memOpnErr, X2
    B           _end

1:  ldr         X5, =gpioaddr
    ldr         X5, [X5]
    mov         X1, #pagelen
    mov         X2, #(PROT_READ + PROT_WRITE)
    mov         X3, #MAP_SHARED
    mov         X0, #0
    mov         X8, #__NR_mmap
    svc         0
    ADDS        X9, XZR, X0
    B.PL        2f
    MOV         X1, #1
    LDR         X2, =memMapsz
    LDR         W2, [X2]
    writeFile   X1, memMapErr, X2
    B           _end
2:
.endm

// mapMemKeypad - same as mapMem (mainmem.S) but returns instead of B _end
// Sets X9 to GPIO base; X0=1 success, X0=0 fail. Closes fd on mmap fail.
.macro  mapMemKeypad
    openFile    devmem, O_RDWR
    ADDS        X4, XZR, X0
    B.MI        9f
    LDR         X5, =gpioaddr
    LDR         X5, [X5]
    MOV         X1, #pagelen
    MOV         X2, #(PROT_READ + PROT_WRITE)
    MOV         X3, #MAP_SHARED
    MOV         X0, #0
    MOV         X8, #__NR_mmap
    SVC         #0
    ADDS        X9, XZR, X0
    B.MI        8f
    MOV         X0, #1
    B           7f
8:  MOV         X0, X4
    MOV         X8, #__NR_close
    SVC         #0
9:  MOV         X0, #0
7:
.endm

// nanoSleep - sleep ~0.1 s
.macro  nanoSleep
        ldr         X0, =timespecsec
        ldr         X1, =timespecsec
        mov         X8, #__NR_nanosleep
        svc         0
.endm

// GPIODirectionOut: configure pin as output (001 in GPFSEL bits)
.macro  GPIODirectionOut   pin
    ldr     X2, =\pin           // pointer to pin table
    ldr     W2, [X2]            // byte offset of GPFSEL register
    ldr     W1, [X9, X2]        // read current GPFSEL value
    ldr     X3, =\pin
    add     X3, X3, #4          // point to shift-amount entry
    ldr     W3, [X3]            // shift amount (3 * pin-in-register)
    mov     X0, #0b111          // 3-bit mask
    lsl     X0, X0, X3          // position mask
    bic     X1, X1, X0          // clear the 3 bits
    mov     X0, #1              // output = 001
    lsl     X0, X0, X3
    orr     X1, X1, X0
    str     W1, [X9, X2]
.endm

// GPIODirectionIn: configure pin as input (000 in GPFSEL bits)
.macro  GPIODirectionIn    pin
    ldr     X2, =\pin
    ldr     W2, [X2]            // GPFSEL register offset
    ldr     W1, [X9, X2]
    ldr     X3, =\pin
    add     X3, X3, #4
    ldr     W3, [X3]            // shift amount
    mov     X0, #0b111
    lsl     X0, X0, X3
    bic     X1, X1, X0          // clear bits → 000 = input
    str     W1, [X9, X2]
.endm

// GPIOPullDown: enable pull-down resistor for a pin (BCM2835 / Pi 3).
//
// Sequence required by BCM2835 datasheet:
//   1. Write pull-down control (1) to GPPUD
//   2. Wait ≥150 cycles (nanoSleep is more than enough)
//   3. Write clock bit for the target pin to GPPUDCLK0
//   4. Wait ≥150 cycles
//   5. Clear GPPUD
//   6. Clear GPPUDCLK0
//
// For Pi 4 (BCM2711) the pull-down is written directly into
// GPIO_PUP_PDN_CNTRL_REGn; this macro handles Pi 3.
// (On Pi 4 under /dev/gpiomem the kernel already defaults
//  newly-configured inputs to no-pull; wire the pull-down physically
//  or use raspi-gpio/config.txt if you need a guaranteed pull-down.)
.macro  GPIOPullDown   pin
    // Step 1: write 1 (pull-down) to GPPUD
    mov     W1, #1
    str     W1, [X9, #gppudoffset]

    // Step 2: wait
    nanoSleep

    // Step 3: clock in the target pin
    mov     X0, #1
    ldr     X3, =\pin
    add     X3, X3, #8          // third word = bit number in SET/CLR/LEV regs
    ldr     W3, [X3]
    lsl     X0, X0, X3
    str     W0, [X9, #gppudclkoffset]

    // Step 4: wait
    nanoSleep

    // Step 5 & 6: clear both registers
    str     WZR, [X9, #gppudoffset]
    str     WZR, [X9, #gppudclkoffset]
.endm

// GPIOTurnOn: write bit to GPSET0
.macro  GPIOTurnOn   pin
    mov     X2, X9
    add     X2, X2, #setregoffset
    mov     X0, #1
    ldr     X3, =\pin
    add     X3, X3, #8
    ldr     W3, [X3]
    lsl     X0, X0, X3
    str     W0, [X2]
.endm

// GPIOTurnOff: write bit to GPCLR0
.macro  GPIOTurnOff   pin
    mov     X2, X9
    add     X2, X2, #clrregoffset
    mov     X0, #1
    ldr     X3, =\pin
    add     X3, X3, #8
    ldr     W3, [X3]
    lsl     X0, X0, X3
    str     W0, [X2]
.endm

// GPIOReadLevel: read GPLEV0 and isolate the bit for 'pin'.
// Result (0 or 1) is placed in W10.
.macro  GPIOReadLevel   pin
    ldr     W1, [X9, #levregoffset]   // read GPLEV0
    ldr     X3, =\pin
    add     X3, X3, #8                // bit position entry
    ldr     W3, [X3]
    lsr     W10, W1, W3               // shift bit down
    and     W10, W10, #1              // isolate
.endm

.data
timespecsec:    .dword  0
timespecnano:   .dword  100000000
devmem:         .asciz  "/dev/gpiomem"
memOpnErr:      .asciz  "Failed to open /dev/gpiomem\n"
memOpnsz:       .word   .-memOpnErr
memMapErr:      .asciz  "Failed to map memory\n"
memMapsz:       .word   .-memMapErr
                .align  4
gpioaddr:       .dword  0x0     // 0 when using /dev/gpiomem (kernel maps base)

// Output pin tables
pin4:       .word 0
            .word 12
            .word 4

pin17:      .word 4
            .word 21
            .word 17

pin22:      .word 8
            .word 6
            .word 22

pin27:      .word 8
            .word 21
            .word 27

//new
pin18:      .word 4
            .word 24 
            .word 18

pin23:      .word 8
            .word 9 
            .word 23

pin24:      .word 8
            .word 12
            .word 24

pin25:      .word 8
            .word 15
            .word 25

.text
