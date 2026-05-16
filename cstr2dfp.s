// Programmer: Ivan Dibrova
// CS3B - cstr2dfp.s - string to double (libc strtod wrapper)
// Date: 5/15/2026
// Purpose: Convert ASCIZ keypad buffer to double for stack push.
// Algorithm/Pseudocode:
//    Input:  X0 = pointer to ASCIZ decimal string
//    Processing: call strtod with endptr on stack
//    Output: D0 = double result

.global cstr2dfp
.extern strtod

    .text

//*****************************************************************************
// Cstr2Dfp
// Function: convert ASCIZ decimal string to double using strtod
// Input:    X0 = pointer to string
// Output:   D0 = double result (strtod rules)
// Registers used:     X0, X1, X19, X8 (strtod)
// Registers preserved: X29, X30, D0 (return value)
//*****************************************************************************
Cstr2Dfp:
cstr2dfp:
    STP     X29, X30, [SP, #-48]!              // FRAME
    MOV     X29, SP                            // FP
    STR     X19, [SP, #40]                     // SAVE X19
    STR     XZR, [SP, #24]                     // CLEAR ENDPTR SLOT
    MOV     X19, X0                            // SAVE STRING PTR
    MOV     X0, X19                            // STRTOD ARG0
    ADD     X1, SP, #24                        // STRTOD ARG1 ENDPTR
    BL      strtod                             // LIBC PARSE
    LDR     X19, [SP, #40]                     // RESTORE X19
    LDP     X29, X30, [SP], #48                // RESTORE FP LR
    RET                                        // RETURN D0

.end
