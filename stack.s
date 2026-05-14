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

.global stackConstructor, stackDestructor, stackPush, stackPop, delete  // Provide program starting address 

.extern malloc
.extern free

.EQU STACK_SZ, 5 					// size for our stack
.EQU DATA_SZ, 8 					// data size for 8 byte doubles
.EQU TOTAL_SZ, STACK_SZ * DATA_SZ	// total size of stack 

.text  // code section

//*****************************************************************************
// Function stackConstructor:  Creates the stack and initializes the stack
//
//  X0: Contains total number of bytes to allocate for the stack
//  X0 (return): Returns the base address of the stack using malloc
//
//	X7: Temporarily stores LR before malloc is called
//
//	LR: Must contain the return address (automatic when BL
//      is used for the call)
//
// Description:
// - Allocates enough memory for STACK_SZ using malloc
// - Saves the base address of the stack into istackBaseAddress
// - Initializes icounter to 0
//
// Registers X0 - X8 are modified and not preserved
//*****************************************************************************
stackConstructor:		// stackConstructor() function
	
	MOV X7, LR					// Save return address before LR
	
	MOV X0, #TOTAL_SZ			// Move the malloc size into X0
	BL malloc					// Allocate memory
	
	LDR X1, =istackBaseAddress	// Load the address of istackBaseAddress into X1
	STR X0, [X1]				// Store the base address into X1
	
	LDR X1, =icounter			// Load the adress of icounter into X1
	MOV X2, #0					// Move 0 into X2
	STR X2, [X1]				// Initialize the counter to 0
	
	MOV LR, X7					// Restore the orginal return address
	
	RET 						// Return to caller

//*****************************************************************************
// Function stackDestructor:  Frees the stack memory
//
//  X0: Contains the address istackBaseAddress
//
//	X7: Temporarily stores LR before malloc is called
//	
//	LR: Must contain the return address (automatic when BL
//      is used for the call)	
//
// Description:
// - Loads base address of the stack from istackBaseAddress into X0
// - Retrieve the base address and save it into X0
// - Frees the dynamically allocated stack memory using free
//
// Registers X0 - X8 are modified and not preserved
//*****************************************************************************
stackDestructor:	// stackDestructor() function
	
	MOV X7, LR					// Save return address before LR
	
	LDR X0, =istackBaseAddress	// Load the address of the variable into X0
	LDR X0, [X0]				// Retrieve the base address 
	BL free						// Free the memory
	
	MOV LR, X7					// Restore the orginal return address
	
	RET							// Return to caller

//*****************************************************************************
// Function stackPush:  Pushes values (double) onto the stack 
//
//  D0: Contains the double value to push onto the stack
//  X0 (return): Returns 1 on success and returns 0 upon failure
//
//	LR: Must contain the return address (automatic when BL
//      is used for the call)
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

	LDR X1, =icounter			// Load the address of the icounter into X1
	LDR X2, [X1]				// Load the value at icounter into X2
	
	CMP X2, #STACK_SZ			// Comapring X2 with the stack size 
	B.GE pushfail				// If greater than stack size then jump to pushfail
	
	// STORE THE INPUT INTO SP
	
	LDR X3, =istackBaseAddress	// Load the address of istackBaseAddress in X3
	LDR X3, [X3]				// Load the value at istackBaseAddress into X3
	
	LSL X4, X2, #3				// Offset it by 8 bytes 
	ADD X4, X3, X4				// Add to get the actual memory location
	
	STR D0, [X4]				// Store double into X4
	
	ADD X2, X2, #1				// Increment the counter 
	STR X2, [X1]				// Save the new counter 
	
	MOV X0, #1					// Return a non-zero for success

	RET							// Return to caller	
		
pushfail:	// label for pushfail
	
	MOV X0, #0					// Return 0 if push would exceed the size 
	
	RET							// Return to caller 

//*****************************************************************************
// Function stackPop:  Pops a double value off the stack 
//
//  D0 (return): Returns the popped value from the stack
//
//	LR: Must contain the return address (automatic when BL
//      is used for the call)
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

	LDR X1, =icounter			// Load the address of the icounter into X1
	LDR X2, [X1]				// Load the value at icounter into X2
	
	CMP X2, #0					// Checking if the stack is empty
	B.EQ donePop				// If empty then jump to done
	
	SUB X2, X2, #1				// Decrement the counter 
	STR X2, [X1]				// Save the new counter 
	
	LDR X3, =istackBaseAddress	// Load the address of istackBaseAddress in X3
	LDR X3, [X3]				// Load the value at istackBaseAddress into X3
	
	LSL X4, X2, #3				// Offset it by 8 bytes 
	ADD X4, X3, X4				// Add to get the actual memory location
	
	LDR D0, [X4]				// Load from stack into double
	
donePop:	// label for donePop
	
	RET							// Return to caller	

//*****************************************************************************
// Function delete:  Empties the stack by resetting to 0
//
//  X0: Contains the address of icounter
//
//	LR: Must contain the return address (automatic when BL
//      is used for the call)
//
// Description:
// - Resets the stack counter to 0
//
// Registers X0 - X8 are modified and not preserved
//*****************************************************************************			
delete:		// delete() function

	// COUNTER = 0 
	
	LDR X0, =icounter			// Load the adress of icounter into X0
	MOV X1, #0					// Move a 0 into X1
	STR X1, [X0]				// Store the 0 into icounter (Resetting it)
	
	RET							// Return to caller

	.data  // data section
istackBaseAddress:	.quad 0
icounter:			.quad 0

.end // end of program
