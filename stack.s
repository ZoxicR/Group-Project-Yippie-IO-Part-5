// Manuel Ruiz
// CS3B - YippieIO Part 5 - Stack
// 5/7/2026
// Creating our own stack,freeing the stack memory, pushing onto the 
// stack, popping off the stack, and deleting which would empty the 
// stack by implementing five stack functions push(), pop(), delete(), 
// stackConstructor(), and stackDestructor()
// Algorithm/Pseudocode:
// stackConstructor:
//		Allocate memory for TOTAL_SZ using malloc  
//		Save the the base address in istackBaseAddress
//		Init counter to 0
//
// stackDestructor:
//		Load base address from istackBaseAddress
//		Free dynamically allocated stack memory
//
// stackPush:
//		Check if stack is full:
//			if full then: return 0
//
//			else:	
//
//				Get memory location using counter offset
//				Store value onto the stack
//				Increment the counter
//				Return 1
//
// stackPop:
//		Check if stack is empty:
//			if empty: return
//			
//			else:
//
//				Decrement the counter
//				Get memory location using counter offset
//				Load value from the stack onto D0
//
// delete:
//		Reset icounter back to 0
//

#ifndef STACK_SZ
#define STACK_SZ 5
#endif

#define TBYTES (STACK_SZ * 8)

.global stackConstructor, stackDestructor, stackPush, stackPop, delete
.global istackBaseAddress, icounter

.extern malloc
.extern free

    .bss
    .align  3
istackBaseAddress:
    .skip   8
    .align  3
icounter:
    .skip   8

    .text

//*****************************************************************************
// Function stackConstructor:  Creates the stack and initializes the stack
//
//  X0: Contains total number of bytes to allocate for the stack
//  X0 (return): Returns the base address of the stack using malloc
//
//	X7: Temporarily stores X30 before malloc is called
//
//	X30: Must contain the return address (automatic when BL is used)
//
// Description:
// - Allocates enough memory for STACK_SZ using malloc
// - Saves the base address of the stack into istackBaseAddress
// - Initializes icounter to 0
//
// Registers X0 - X8 are modified and not preserved
//*****************************************************************************
stackConstructor:		// stackConstructor() function
	
	STP	X29, X30, [SP, #-16]!			// save frame + return address
	MOV	X29, SP

	MOV	X0, #TBYTES				// malloc size (STACK_SZ * 8)
	BL	malloc					// Allocate memory
	
	CBZ	X0, ctorMallocFail			// avoid push through NULL base
	
	LDR	X1, =istackBaseAddress			// Load the address of istackBaseAddress into X1
	STR	X0, [X1]				// Store the base address into X1
	
	LDR	X1, =icounter				// Load the adress of icounter into X1
	STR	XZR, [X1]				// Initialize the counter to 0
	
	LDP	X29, X30, [SP], #16			// Restore frame and return address
	RET 						// Return to caller

ctorMallocFail:
	LDR	X1, =istackBaseAddress
	STR	XZR, [X1]
	LDP	X29, X30, [SP], #16
	RET

//*****************************************************************************
// Function stackDestructor:  Frees the stack memory
//
//  X0: Contains the address istackBaseAddress
//
//	X7: Temporarily stores X30 before free is called
//	
//	X30: Must contain the return address (automatic when BL is used)	
//
// Description:
// - Loads base address of the stack from istackBaseAddress into X0
// - Retrieve the base address and save it into X0
// - Frees the dynamically allocated stack memory using free
//
// Registers X0 - X8 are modified and not preserved
//*****************************************************************************
stackDestructor:	// stackDestructor() function
	
	STP	X29, X30, [SP, #-16]!
	MOV	X29, SP

	LDR	X0, =istackBaseAddress			// Load the address of the variable into X0
	LDR	X0, [X0]				// Retrieve the base address 
	CBZ	X0, dtorSkipFree			// nothing allocated
	
	BL	free					// Free the memory
	
dtorSkipFree:
	LDP	X29, X30, [SP], #16
	RET							// Return to caller

//*****************************************************************************
// Function stackPush:  Pushes values (double) onto the stack 
//
//  D0: Contains the double value to push onto the stack
//  X0 (return): Returns 1 on success and returns 0 upon failure
//
//	X30: Must contain the return address (automatic when BL is used)
//
// Description:
// - CHecks if the the stack is already full before pushing any values onto the stack
// - Calculates the correct memory location using counter offset
// - Stores value onto stack memory
// - Increments the counter after pushing 
//
// Registers X0 - X8 and D0 are modified and not preserved
//*****************************************************************************
stackPush:		// stackPush() function

	LDR	X1, =icounter				// Load the address of the icounter into X1
	LDR	X2, [X1]				// Load the value at icounter into X2
	
	CMP	X2, #STACK_SZ				// Comapring X2 with the stack size 
	B.GE	pushfail				// If greater than stack size then jump to pushfail
	
	// STORE THE INPUT INTO SP
	
	LDR	X3, =istackBaseAddress			// Load the address of istackBaseAddress in X3
	LDR	X3, [X3]				// Load the value at istackBaseAddress into X3
	CBZ	X3, pushfail				// no heap block
	
	LSL	X4, X2, #3				// Offset it by 8 bytes 
	ADD	X4, X3, X4				// Add to get the actual memory location
	
	STR	D0, [X4]				// Store double into X4
	
	ADD	X2, X2, #1				// Increment the counter 
	STR	X2, [X1]				// Save the new counter 
	
	MOV	X0, #1					// Return a non-zero for success

	RET							// Return to caller	
		
pushfail:	// label for pushfail
	
	MOV	X0, #0					// Return 0 if push would exceed the size 
	
	RET							// Return to caller 

//*****************************************************************************
// Function stackPop:  Pops a double value off the stack 
//
//  D0 (return): Returns the popped value from the stack
//
//	X30: Must contain the return address (automatic when BL is used)
//
// Description:
// - Checks if the stack is empty before popping any values off the stack
// - Decrements the counter
// - Calculates the correct memory location using counter offset
// - Loads the value from the stack into D0
//
// Registers X0 - X8 and D0 are modified and not preserved
//*****************************************************************************
stackPop:	// stackPop() function

	LDR	X1, =icounter				// Load the address of the icounter into X1
	LDR	X2, [X1]				// Load the value at icounter into X2
	
	CMP	X2, #0					// Checking if the stack is empty
	B.EQ	donePopEmpty				// If empty then jump to done
	
	SUB	X2, X2, #1				// Decrement the counter 
	STR	X2, [X1]				// Save the new counter 
	
	LDR	X3, =istackBaseAddress			// Load the address of istackBaseAddress in X3
	LDR	X3, [X3]				// Load the value at istackBaseAddress into X3
	
	LSL	X4, X2, #3				// Offset it by 8 bytes 
	ADD	X4, X3, X4				// Add to get the actual memory location
	
	LDR	D0, [X4]				// Load from stack into double
	
donePop:	// label for donePop
	
	RET							// Return to caller	

donePopEmpty:
	FMOV	D0, XZR
	B	donePop

//*****************************************************************************
// Function delete:  Empties the stack by resetting to 0
//
//  X0: Contains the address of icounter
//
//	X30: Must contain the return address (automatic when BL is used)
//
// Description:
// - Resets the stack counter to 0
//
// Registers X0 - X8 are modified and not preserved
//*****************************************************************************			
delete:		// delete() function

	// COUNTER = 0 
	
	LDR	X0, =icounter				// Load the adress of icounter into X0
	STR	XZR, [X0]				// Store 0 into icounter (Resetting it)
	
	RET							// Return to caller

.end // end of program
