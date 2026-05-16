// Programmer: Ivan Dibrova
// CS3B - driver4yippieio.s - getkey demo (Part 4)
// Date: 5/15/2026
// Purpose: Demonstrate getkey blocking (two keys) then non-blocking poll loop.
// Algorithm/Pseudocode:
//    Input: user presses keypad hardware
//    Processing: two blocking getkey calls then 500x poll with 10 ms sleep
//    Output: "key press detected" lines on stdout then exit 0

.global _start
.extern getkey

    .equ __NR_write, 64
    .equ __NR_exit, 93
    .equ __NR_nanosleep, 101

    .text

//*****************************************************************************
// _start
// Function: program entry for bare link ld
// Input:    none
// Output:   process exit 0
// Registers used:     W19, X0-X3, X8
// Registers preserved: none (_start is entry)
//*****************************************************************************
_start:
    MOV     X1, #1                             // FD STDOUT
    LDR     X2, =szMsgBlock                    // STRING PTR BLOCKING BANNER
    MOV     X3, #iLenMsgBlock                  // LENGTH WITHOUT NUL
    BL      ProcWriteBuf                       // WRITE BANNER

    MOV     W19, #2                            // TWO KEY PRESSES
LblBlockLoop:
    MOV     W0, #1                             // BLOCKING FLAG
    BL      getkey                             // WAIT KEY CODE W0
    BL      ProcPrintKeyMsg                    // PRINT ROW COL
    SUBS    W19, W19, #1                       // DEC LOOP COUNT
    B.NE    LblBlockLoop                       // REPEAT

    MOV     X1, #1                             // FD STDOUT
    LDR     X2, =szMsgPoll                     // POLL BANNER
    MOV     X3, #iLenMsgPoll                   // LENGTH
    BL      ProcWriteBuf                       // WRITE

    MOV     W19, #500                          // POLL ITERATIONS
LblPollLoop:
    MOV     W0, #0                             // NONBLOCKING POLL
    BL      getkey                             // MAY RETURN ZERO
    CMP     W0, #0                             // KEY?
    B.EQ    LblPollSleep                      // SKIP PRINT IF NONE
    BL      ProcPrintKeyMsg                    // PRINT ROW COL
LblPollSleep:
    BL      ProcSleep10ms                      // 10 MS DELAY
    SUBS    W19, W19, #1                       // DEC ITERATION
    B.NE    LblPollLoop                        // CONTINUE POLL

    MOV     X0, #0                             // EXIT STATUS OK
    MOV     X8, #__NR_exit                     // SYSCALL EXIT
    SVC     #0                                 // KERNEL EXIT

//*****************************************************************************
// ProcPrintKeyMsg
// Function: convert getkey code 1..16 to row col 1..4 and print message
// Input:    W0 keypad id
// Output:   tty line to stdout
// Registers used:     W0-W6, X1-X3, X7, X8
// Registers preserved: X29, X30
//*****************************************************************************
ProcPrintKeyMsg:
    STP     X29, X30, [SP, #-16]!              // SAVE FP LR
    MOV     X29, SP                            // FRAME
    SUB     W1, W0, #1                         // ZERO BASE INDEX
    MOV     W2, #4                             // FOUR COLS
    UDIV    W3, W1, W2                         // ROW INDEX 0..3
    MSUB    W4, W3, W2, W1                     // COL INDEX 0..3
    ADD     W3, W3, #1                         // ROW HUMAN 1..4
    ADD     W4, W4, #1                         // COL HUMAN 1..4
    ADD     W5, W3, #'0'                      // ROW ASCII DIGIT
    ADD     W6, W4, #'0'                      // COL ASCII DIGIT
    LDR     X7, =bRowDigit                     // STOR CELL ROW
    STRB    W5, [X7]                           // SAVE BYTE
    LDR     X7, =bColDigit                     // STOR CELL COL
    STRB    W6, [X7]                           // SAVE BYTE
    MOV     X1, #1                             // STDOUT
    LDR     X2, =szPrefix                      // PREFIX STRING
    MOV     X3, #iLenPrefix                    // LENGTH
    BL      ProcWriteBuf                       // WRITE PREFIX
    MOV     X1, #1                             // STDOUT
    LDR     X2, =bRowDigit                     // ONE CHAR ROW
    MOV     X3, #1                             // LENGTH 1
    BL      ProcWriteBuf                       // WRITE ROW DIGIT
    MOV     X1, #1                             // STDOUT
    LDR     X2, =szMiddle                      // MIDDLE STRING
    MOV     X3, #iLenMiddle                    // LENGTH
    BL      ProcWriteBuf                       // WRITE
    MOV     X1, #1                             // STDOUT
    LDR     X2, =bColDigit                     // COL CHAR
    MOV     X3, #1                             // ONE BYTE
    BL      ProcWriteBuf                       // WRITE COL
    MOV     X1, #1                             // STDOUT
    LDR     X2, =szNewline                     // NL
    MOV     X3, #1                             // LENGTH
    BL      ProcWriteBuf                       // WRITE NL
    LDP     X29, X30, [SP], #16                // RESTORE
    RET                                        // RETURN

//*****************************************************************************
// ProcWriteBuf
// Function: Linux write syscall wrapper
// Input:    X1 fd X2 buf X3 nbytes
// Output:   none
// Registers used:     X0, X1, X2, X8
// Registers preserved: X3, X29, X30
//*****************************************************************************
ProcWriteBuf:
    MOV     X0, X1                             // FD FIRST ARG
    MOV     X1, X2                             // BUF SECOND
    MOV     X2, X3                             // COUNT THIRD
    MOV     X8, #__NR_write                    // WRITE NUMBER
    SVC     #0                                 // TRAP
    RET                                        // RETURN

//*****************************************************************************
// ProcSleep10ms
// Function: nanosleep 10 milliseconds
// Input:    none
// Output:   none
// Registers used:     X0, X1, X8
// Registers preserved: all except X0, X1
//*****************************************************************************
ProcSleep10ms:
    LDR     X0, =qwTs10ms                      // REQ TIME PTR
    LDR     X1, =qwTs10ms                      // REM TIME PTR
    MOV     X8, #__NR_nanosleep                // NANOSLEEP ID
    SVC     #0                                 // SLEEP
    RET                                        // RETURN

    .data
szMsgBlock:
    .asciz  "Blocking test (press 2 keys)\n"
iLenMsgBlock = . - szMsgBlock - 1

szMsgPoll:
    .asciz  "Non-blocking test (poll loop)\n"
iLenMsgPoll = . - szMsgPoll - 1

szPrefix:
    .asciz  "key press detected: row "
iLenPrefix = . - szPrefix - 1

szMiddle:
    .asciz  ", column "
iLenMiddle = . - szMiddle - 1

szNewline:
    .asciz  "\n"

bRowDigit:
    .byte   '0'
bColDigit:
    .byte   '0'

qwTs10ms:
    .quad   0
    .quad   10000000

.end
