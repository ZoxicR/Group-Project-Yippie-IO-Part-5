// Programmer: Ivan Dibrova
// CS3B - putch.s - console output
// Date: 5/15/2026
// Purpose: Output one ASCII byte to stdout using write syscall.
// Algorithm/Pseudocode:
//    Input:  W0 = character code (low 8 bits)
//    Processing: store byte in bOutByte; write syscall fd 1
//    Output: one byte on console

.global putch

.equ __NR_write, 64

    .data
bOutByte:
    .byte   0

    .text

//*****************************************************************************
// PutCh
// Function: write one character to stdout
// Input:    W0 = ASCII character
// Output:   none
// Registers used:     X0, X1, X2, X8
// Registers preserved: X29, X30
//*****************************************************************************
PutCh:
putch:
    STP     X29, X30, [SP, #-16]!              // SAVE FP LR
    MOV     X29, SP                            // FRAME POINTER
    LDR     X1, =bOutByte                      // ONE BYTE BUFFER
    STRB    W0, [X1]                           // STORE CHARACTER
    MOV     X0, #1                             // STDOUT FD
    MOV     X2, #1                             // LENGTH 1
    MOV     X8, #__NR_write                    // WRITE SYSCALL
    SVC     #0
    LDP     X29, X30, [SP], #16                // RESTORE FP LR
    RET                                        // RETURN

.end
