// Programmer: Ivan Dibrova
// CS3B - getkey.S
// Date: 5/15/2026
// Purpose: Read matrix keypad via mmap GPIO.
// Algorithm/Pseudocode:
//    Input:  W0 = 0 poll, nonzero = block until key
//    Processing: one-time mapMemKeypad + pin setup (mainmem style); scan rows 0..3;
//                 debounce; wait for release; return code 1..16 row-major
//    Output: W0 = 0 none (poll) else key index 1..16

#include "gpiomem.S"

.global getkey

    .text

//*****************************************************************************
// GetKey
// Function: read one keypad press, blocking or poll
// Input:    W0 = wait flag (nonzero block)
// Output:   W0 = key code 1..16, or 0 if poll and no key
// Registers used:     W19, W20, W21, X9, X10 (macro)
// Registers preserved: X19, X20, X29, X30
//*****************************************************************************
GetKey:
getkey:
    STP     X29, X30, [SP, #-32]!              // SAVE FP LR
    MOV     X29, SP                            // FRAME POINTER
    STR     X19, [SP, #16]                     // SAVE X19
    STR     X20, [SP, #24]                     // SAVE X20
    MOV     W19, W0                            // SAVE BLOCK FLAG
    BL      GpioInitOnce                       // AUTHOR GPIO SETUP
LblPollKeys:
    BL      ScanKeyOnce                        // ONE MATRIX SCAN
    CMP     W0, #0                             // KEY FOUND?
    B.NE    LblGotKey                          // YES
    CMP     W19, #0                            // POLL MODE?
    B.EQ    LblNoKey                           // RETURN 0
    BL      Sleep1ms                           // SHORT DELAY
    B       LblPollKeys                        // RETRY
LblGotKey:
    MOV     W20, W0                            // SAVE KEY CODE
    BL      Sleep5ms                           // DEBOUNCE SETTLE
LblWaitRelease:
    BL      ScanKeyOnce                        // WAIT FOR RELEASE
    CMP     W0, #0                             // STILL PRESSED?
    B.NE    LblWaitRelease                     // YES KEEP WAITING
    MOV     W0, W20                            // RESTORE KEY CODE
    B       LblExitGetKey                      // DONE
LblNoKey:
    MOV     W0, #0                             // NO KEY
LblExitGetKey:
    LDR     X20, [SP, #24]                     // RESTORE X20
    LDR     X19, [SP, #16]                     // RESTORE X19
    LDP     X29, X30, [SP], #32                // RESTORE FP LR
    RET                                        // RETURN

//*****************************************************************************
// GpioInitOnce
// Function: first call runs author mapMemKeypad + keypad pin init (mainmem.S)
// Input:    none
// Output:   X9 = GPIO base; globals bGpioInitDone, qwGpioMmapBase set
// Registers used:     X0-X6, X8, X9
// Registers preserved: X29, X30
//*****************************************************************************
GpioInitOnce:
    STP     X29, X30, [SP, #-16]!              // SAVE FP LR
    MOV     X29, SP                            // FRAME POINTER
    LDR     X1, =bGpioInitDone                 // INIT FLAG BYTE
    LDRB    W2, [X1]                           // LOAD FLAG
    CMP     W2, #1                             // ALREADY DONE?
    B.EQ    LblGioLoaded                       // USE SAVED BASE
    mapMemKeypad                               // AUTHOR MMAP (NO _end)
    CBZ     X0, LblGioFail                     // MMAP FAILED
    LDR     X6, =qwGpioMmapBase                // SAVE BASE POINTER
    STR     X9, [X6]                           // STORE FOR LATER SCANS
    GPIODirectionOut    pin4                   // ROW PINS OUTPUT
    GPIODirectionOut    pin17
    GPIODirectionOut    pin27
    GPIODirectionOut    pin22
    GPIODirectionIn     pin18                  // COLUMN PINS INPUT
    GPIODirectionIn     pin23
    GPIODirectionIn     pin24
    GPIODirectionIn     pin25
    GPIOPullDown        pin18                  // PULL-DOWN COLUMNS
    GPIOPullDown        pin23
    GPIOPullDown        pin24
    GPIOPullDown        pin25
    GPIOTurnOff         pin4                   // ROWS LOW IDLE
    GPIOTurnOff         pin17
    GPIOTurnOff         pin27
    GPIOTurnOff         pin22
    nanoSleep                                  // AUTHOR SETTLE DELAY
    MOV     W2, #1                             // MARK INITIALIZED
    STRB    W2, [X1]                           // SAVE FLAG
    B       LblGioLeave                        // DONE
LblGioLoaded:
    LDR     X6, =qwGpioMmapBase                // LOAD SAVED BASE
    LDR     X9, [X6]                           // INTO X9 FOR MACROS
    B       LblGioLeave
LblGioFail:
    LDR     X6, =qwGpioMmapBase                // CLEAR ON FAIL
    STR     XZR, [X6]
LblGioLeave:
    LDP     X29, X30, [SP], #16                // RESTORE FP LR
    RET                                        // RETURN

//*****************************************************************************
// ScanKeyOnce
// Function: scan 4x4 matrix once (row loop + column reads)
// Input:    none (X9 must be valid GPIO base)
// Output:   W0 = 0 no press, else 1..16
// Registers used:     W21 row, W0, X9, X10 (GPIOReadLevel)
// Registers preserved: X29, X30
//*****************************************************************************
ScanKeyOnce:
    STP     X29, X30, [SP, #-16]!              // SAVE FP LR
    MOV     X29, SP                            // FRAME POINTER
    LDR     X1, =qwGpioMmapBase                // BASE PTR
    LDR     X9, [X1]                           // LOAD MMAP BASE
    CMP     X9, #0                             // MAPPED?
    B.LE    LblSkNone                          // NO HARDWARE
    GPIOTurnOff         pin4                   // ALL ROWS OFF
    GPIOTurnOff         pin17
    GPIOTurnOff         pin27
    GPIOTurnOff         pin22
    MOV     W21, #0                            // ROW INDEX 0..3
LblSkRowLoop:
    CMP     W21, #4                            // PAST LAST ROW?
    B.GE    LblSkNone                          // NO KEY
    BL      ScanRowDrive                       // DRIVE ONE ROW HIGH
    BL      Sleep1ms                           // SETTLE
    BL      ScanColsRead                       // W0=0 OR KEY CODE
    CBNZ    W0, LblSkDone                      // FOUND
    ADD     W21, W21, #1                       // NEXT ROW
    B       LblSkRowLoop                       // CONTINUE
LblSkNone:
    MOV     W0, #0                             // NO KEY
    B       LblSkDone
LblSkDone:
    GPIOTurnOff         pin4                   // ROWS LOW ON EXIT
    GPIOTurnOff         pin17
    GPIOTurnOff         pin27
    GPIOTurnOff         pin22
    LDP     X29, X30, [SP], #16                // RESTORE FP LR
    RET                                        // RETURN W0

//*****************************************************************************
// ScanRowDrive
// Function: drive row W21 high (0..3), others low
// Input:    W21 = row index
// Output:   none
// Registers used:     X9, W21
// Registers preserved: X29, X30, W21
//*****************************************************************************
ScanRowDrive:
    GPIOTurnOff         pin4
    GPIOTurnOff         pin17
    GPIOTurnOff         pin27
    GPIOTurnOff         pin22
    CMP     W21, #0
    B.EQ    LblSr0
    CMP     W21, #1
    B.EQ    LblSr1
    CMP     W21, #2
    B.EQ    LblSr2
    GPIOTurnOn          pin22                   // ROW 3
    RET
LblSr0:
    GPIOTurnOn          pin4                    // ROW 0
    RET
LblSr1:
    GPIOTurnOn          pin17                   // ROW 1
    RET
LblSr2:
    GPIOTurnOn          pin27                   // ROW 2
    RET

//*****************************************************************************
// ScanColsRead
// Function: read four columns; compute key code from W21 row
// Input:    W21 = row 0..3
// Output:   W0 = 0 or key code row*4+col+1
// Registers used:     W0, W10, W21
// Registers preserved: X29, X30, W21
//*****************************************************************************
ScanColsRead:
    GPIOReadLevel       pin18
    CMP     W10, #1
    B.NE    LblSc1
    MOV     W0, W21
    LSL     W0, W0, #2
    ADD     W0, W0, #1
    RET
LblSc1:
    GPIOReadLevel       pin23
    CMP     W10, #1
    B.NE    LblSc2
    MOV     W0, W21
    LSL     W0, W0, #2
    ADD     W0, W0, #2
    RET
LblSc2:
    GPIOReadLevel       pin24
    CMP     W10, #1
    B.NE    LblSc3
    MOV     W0, W21
    LSL     W0, W0, #2
    ADD     W0, W0, #3
    RET
LblSc3:
    GPIOReadLevel       pin25
    CMP     W10, #1
    B.NE    LblSc0
    MOV     W0, W21
    LSL     W0, W0, #2
    ADD     W0, W0, #4
    RET
LblSc0:
    MOV     W0, #0
    RET

//*****************************************************************************
// Sleep1ms
// Function: nanosleep 1 ms (scan settle / poll delay)
// Input:    none
// Output:   none
// Registers used:     X0, X1, X8
// Registers preserved: all other callee-saved
//*****************************************************************************
Sleep1ms:
    LDR     X0, =qwTsSleep1ms
    LDR     X1, =qwTsSleep1ms
    MOV     X8, #__NR_nanosleep
    SVC     #0
    RET

//*****************************************************************************
// Sleep5ms
// Function: nanosleep 5 ms debounce delay
// Input:    none
// Output:   none
// Registers used:     X0, X1, X8
// Registers preserved: all other callee-saved
//*****************************************************************************
Sleep5ms:
    LDR     X0, =qwTsSleep5ms
    LDR     X1, =qwTsSleep5ms
    MOV     X8, #__NR_nanosleep
    SVC     #0
    RET

    .data
bGpioInitDone:
    .byte   0
    .align  3
qwGpioMmapBase:
    .quad   0
qwTsSleep1ms:
    .quad   0
    .quad   1000000
qwTsSleep5ms:
    .quad   0
    .quad   5000000

.end
