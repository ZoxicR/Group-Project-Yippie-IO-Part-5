// Programmer: Ivan Dibrova
// CS3B - putstring.s - ASCIZ output via putch
// Date: 5/15/2026
// Purpose: Print null-terminated string using putch (author-style I/O chain).
// Algorithm/Pseudocode:
//    Input:  X0 = pointer to ASCIZ string
//    Processing: byte loop until NUL; each byte -> putch
//    Output: characters on stdout

.global putstring
.extern putch

    .text

//*****************************************************************************
// PutString
// Function: output ASCIZ string using PutCh
// Input:    X0 = address of first character
// Output:   none
// Registers used:     W0, X19
// Registers preserved: X29, X30
//*****************************************************************************
PutString:
putstring:
    STP     X29, X30, [SP, #-32]!              // FRAME
    MOV     X29, SP                            // FP
    STR     X19, [SP, #24]                     // SAVE X19
    MOV     X19, X0                            // STRING POINTER
LblPutStrLoop:
    LDRB    W0, [X19], #1                      // LOAD BYTE ADVANCE
    CBZ     W0, LblPutStrDone                  // END OF STRING
    BL      putch                              // ONE CHARACTER
    B       LblPutStrLoop                      // NEXT
LblPutStrDone:
    LDR     X19, [SP, #24]                     // RESTORE X19
    LDP     X29, X30, [SP], #32                // RESTORE FP LR
    RET                                        // RETURN

.end
