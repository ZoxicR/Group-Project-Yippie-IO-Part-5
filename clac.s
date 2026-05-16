// Ivan Dibrova
// CS3B - clac.s - RPN keypad calculator (Part 4/5)
// 5/15/2026
// RPN calculator: getkey + keypad map, number buffer, stack from stack.s
// putch echoes keys; printf only for floating-point results
// Algorithm/Pseudocode:
//	main loop: getkey -> map to ASCII
//	digits and '.' go into buffer and echo with putch
//	E flushes buffer with cstr2dfp then stackPush
//	+ - x / flush then pop two values, compute, stackPush, printf
//	two empty E prints top (peek); three empty E calls stackDestructor and exits

.global main

.extern getkey, stackConstructor, stackDestructor, stackPush, stackPop, delete
.extern cstr2dfp, putch, printf
.extern istackBaseAddress, icounter

    .bss
    .align 4
achInBuf:
    .skip 128
    .align 4
iInBufLen:
    .skip 4
    .align 4
iEnterStreak:
    .skip 4

    .data
    .align 3
achPadMap:
    .byte '1','2','3','/'
    .byte '4','5','6','x'
    .byte '7','8','9','-'
    .byte '.','0','E','+'
    .align 3
szFmtOut:
    .asciz "%.10g\n"

    .text

//*****************************************************************************
// Function main:  RPN calculator main loop
//
//  W0: getkey return (1..16)
//  W10: mapped ASCII from keypad
//  X0: return code to libc
//
// Description:
// - Builds stack, reads keys until three empty Enters
// - Routes digits, operators, and Enter
//
// Registers X0 - X8, W0 - W16, D0 are modified and not preserved
//*****************************************************************************
main:

	BL	stackConstructor			// malloc stack
	LDR	X0, =istackBaseAddress
	LDR	X0, [X0]
	CBNZ	X0, clacInitOk
	MOV	X0, #1					// malloc failed
	RET

clacInitOk:
	BL	delete					// counter must be 0
	LDR	X0, =iInBufLen
	STR	WZR, [X0]
	LDR	X0, =iEnterStreak
	STR	WZR, [X0]

mainLoop:
	MOV	W0, #1
	BL	getkey
	SUBS	W2, W0, #1				// index 0..15
	B.MI	mainLoop
	CMP	W2, #15
	B.HI	mainLoop

	LDR	X3, =achPadMap
	LDRB	W10, [X3, W2, UXTW]			// ASCII key

	CMP	W10, #'E'
	B.EQ	ProcEnter
	CMP	W10, #'.'				// dot before digit test (46 < 48)
	B.EQ	ProcDigit
	CMP	W10, #'0'
	B.LT	chkOps
	CMP	W10, #'9'
	B.LE	ProcDigit

chkOps:
	CMP	W10, #'-'
	B.EQ	chkMinus
	CMP	W10, #'+'
	B.EQ	ProcBinOp
	CMP	W10, #'x'
	B.EQ	ProcBinOp
	CMP	W10, #'/'
	B.EQ	ProcBinOp
	B	mainLoop

//*****************************************************************************
// Function chkMinus:  unary minus or binary subtract
//
//  W10: '-' character
//
// Description:
// - If still typing a number or stack has values, treat as operator
// - Else start a negative number in the buffer
//*****************************************************************************
chkMinus:
	LDR	X4, =iInBufLen
	LDR	W5, [X4]
	CBNZ	W5, ProcBinOp
	LDR	X1, =icounter
	LDR	X0, [X1]
	CBNZ	X0, ProcBinOp
	B	ProcDigit

//*****************************************************************************
// Function ProcDigit:  append char to number buffer and echo
//
//  W10: digit or '.'
//*****************************************************************************
ProcDigit:
	LDR	X11, =iEnterStreak
	STR	WZR, [X11]
	LDR	X4, =iInBufLen
	LDR	W5, [X4]
	CMP	W5, #120
	B.GE	mainLoop
	LDR	X6, =achInBuf
	ADD	X6, X6, W5, UXTW
	STRB	W10, [X6]
	ADD	W5, W5, #1
	STR	W5, [X4]
	MOV	W0, W10
	BL	putch
	B	mainLoop

//*****************************************************************************
// Function ProcEnter:  flush number or handle empty Enter streak
//*****************************************************************************
ProcEnter:
	MOV	W0, #10
	BL	putch					// newline after E
	LDR	X4, =iInBufLen
	LDR	W5, [X4]
	CBNZ	W5, flushNum
	LDR	X12, =iEnterStreak
	LDR	W13, [X12]
	ADD	W13, W13, #1
	STR	W13, [X12]
	CMP	W13, #2
	B.EQ	printTopAct
	CMP	W13, #3
	B.EQ	ProcExit
	B	mainLoop

flushNum:
	BL	ProcFlush
	LDR	X12, =iEnterStreak
	STR	WZR, [X12]
	B	mainLoop

printTopAct:
	BL	ProcPrintTop
	B	mainLoop

//*****************************************************************************
// Function ProcExit:  free stack and return
//*****************************************************************************
ProcExit:
	BL	stackDestructor
	MOV	X0, #0
	RET

//*****************************************************************************
// Function ProcFlush:  NUL terminate buffer, cstr2dfp, stackPush
//
//  D0: double from cstr2dfp
//*****************************************************************************
ProcFlush:
	STP	X29, X30, [SP, #-16]!
	MOV	X29, SP
	LDR	X4, =iInBufLen
	LDR	W5, [X4]
	CBZ	W5, flushDone
	LDR	X0, =achInBuf
	ADD	X7, X0, W5, UXTW
	STRB	WZR, [X7]				// ASCIZ (use X7 not X4 after BL)
	LDR	X0, =achInBuf
	BL	cstr2dfp
	BL	stackPush
	CBZ	X0, flushDone				// overflow: keep buffer
	LDR	X4, =iInBufLen
	STR	WZR, [X4]
	LDR	X0, =achInBuf
	STRB	WZR, [X0]
flushDone:
	LDP	X29, X30, [SP], #16
	RET

//*****************************************************************************
// Function ProcPrintTop:  pop, printf, push back (peek)
//*****************************************************************************
ProcPrintTop:
	STP	X29, X30, [SP, #-48]!
	MOV	X29, SP
	LDR	X1, =icounter
	LDR	X0, [X1]
	CMP	X0, #0
	B.LE	printTopDone
	BL	stackPop
	STR	D0, [X29, #24]
	LDR	D0, [X29, #24]
	LDR	X0, =szFmtOut
	FMOV	X1, D0
	BL	printf
	LDR	D0, [X29, #24]
	BL	stackPush
printTopDone:
	LDP	X29, X30, [SP], #48
	RET

//*****************************************************************************
// Function ProcBinOp:  flush buffer, pop two, compute, push, printf
//
//  W10: operator + - x /
//*****************************************************************************
ProcBinOp:
	STP	X29, X30, [SP, #-32]!
	MOV	X29, SP
	STR	W10, [SP, #28]
	MOV	W0, W10
	BL	putch
	MOV	W0, #10
	BL	putch

	LDR	X4, =iInBufLen
	LDR	W14, [X4]
	LDR	X1, =icounter
	LDR	X0, [X1]
	CMP	W14, #2					// reject merged digits like 34 without E
	B.LT	opDoFlush
	CBNZ	X0, opDoFlush
	STR	WZR, [X4]
	BL	delete
	B	opDone

opDoFlush:
	BL	ProcFlush
	LDR	X12, =iEnterStreak
	STR	WZR, [X12]

	LDR	X1, =icounter
	LDR	X2, [X1]
	CMP	X2, #2
	B.LT	opDone

	BL	stackPop
	FMOV	D2, D0					// rhs
	BL	stackPop					// lhs in D0
	FMOV	D1, D2

	LDR	W10, [SP, #28]
	CMP	W10, #'+'
	B.EQ	opAdd
	CMP	W10, #'-'
	B.EQ	opSub
	CMP	W10, #'x'
	B.EQ	opMul
	CMP	W10, #'/'
	B.EQ	opDiv
	B	opDone

opAdd:
	FADD	D0, D0, D1
	B	opPush

opSub:
	FSUB	D0, D0, D1
	B	opPush

opMul:
	FMUL	D0, D0, D1
	B	opPush

opDiv:
	FDIV	D0, D0, D1

opPush:
	BL	stackPush
	LDR	X0, =szFmtOut
	FMOV	X1, D0
	BL	printf

opDone:
	LDP	X29, X30, [SP], #32
	B	mainLoop

.end
