// Manuel Ruiz
// CS3B - stackDriver.s
// driver for testing the stack 

.global _start

_start:

	.text	// code section

	BL stackConstructor			// Create stack
	
	// Push 1.1 onto the stack
	LDR X0, =dValue1			// Load address of 1.1
	LDR D0, [X0]				// Load 1.1 into D0
	BL stackPush				// Push 1.1

	// Push 2.2 onto the stack
	LDR X0, =dValue2			// Load address of 2.2
	LDR D0, [X0]				// Load 2.2 into D0
	BL stackPush				// Push 2.2

	// Push 3.3 onto the stack
	LDR X0, =dValue3			// Load address of 3.3
	LDR D0, [X0]				// Load 3.3 into D0
	BL stackPush				// Push 3.3
	
	// Push 4.4 onto the stack
	LDR X0, =dValue4			// Load address of 4.4
	LDR D0, [X0]				// Load 4.4 into D0
	BL stackPush				// Push 4.4

	// Push 5.5 onto the stack
	LDR X0, =dValue5			// Load address of 5.5
	LDR D0, [X0]				// Load 5.5 into D0
	BL stackPush				// Push 5.5

	// Push 6.6 onto the stack
	LDR X0, =dValue6			// Load address of sixth double
	LDR D0, [X0]				// Load double into D0
	
	BL stackPush				// Attempt overflow push

	// Check for overflow
	CMP X0, #0					// Checking if push failed
	
	B.EQ overflowDetected		// If yes then print overflow message

	LDR X0, =szNoOverflow		// Load no overflow string
	BL putstring				// Print no overflow string
	
	B continueProgram			// Skip overflow label

overflowDetected:

	LDR X0, =szOverflow			// Load overflow string
	
	BL putstring				// Print overflow message

continueProgram:

	BL stackPop					// Pop top value into D0

	LDR X0, =szPopMessage		// Load pop message
	
	BL putstring				// Print message

	FMOV D1, D0					// Move popped value into D1
	
	LDR X0, =szFloatFmt			// Load "%.2f\n"
	
	BL printf					// Print floating point value
	
	// Empty the stack
	BL delete					// Reset stack counter

	LDR X0, =szDelete			// Load delete message
	
	BL putstring				// Print delete message

	// Free stack memory
	BL stackDestructor			// Free malloc'd memory

	LDR X0, =szDone				// Load done message
	
	BL putstring				// Print done message

	MOV X0, #0					// Return code
	MOV X8, #93					// Linux exit syscall
	SVC 0						// Exit program

	.data	// data section
szOverflow:		.asciz "Stack overflow detected\n"
szNoOverflow:	.asciz "No overflow detected\n"
szPopMessage:	.asciz "Popped value: "
szDelete:		.asciz "Stack was deleted\n"
szDone:			.asciz "Stack memory was freed\n"
szFloatFmt:		.asciz "%.2f\n"

dValue1:		.double 1.1
dValue2:		.double 2.2
dValue3:		.double 3.3
dValue4:		.double 4.4
dValue5:		.double 5.5
dValue6:		.double 6.6

.end	// end of program
