// Manuel Ruiz
// CS3B - YippieIO Part 5 - Stack
// 5/7/2026
// Creating our own stack,freeing the stack memory, pushing onto the 
// stack, popping off the stack, and deleting which would empty the 
// stack by implementing five stack functions push(), pop(), delete(), 
// stackConstructor(), and stackDestructor()

.global stackConstructor, stackDestructor, stackPush, stackPop, delete  // Provide program starting address 

.extern malloc
.extern free

.EQU STACK_SZ, 5 					// size for our stack
.EQU DATA_SZ, 8 					// data size for 8 byte doubles
.EQU TOTAL_SZ, STACK_SZ * DATA_SZ	// total size of stack 

.text  // code section

//*****************************************************************************
// Function stackConstructor:  Creates the stack
//
//  X0: Contains data value to store in node
//  X0 (return): Pointer to newly allocated node
//
// Description:
// - Allocates 16 bytes using malloc
// - 
// - 
// - 
//
// Registers X0 - X8 are modified and not preserved
//*****************************************************************************
stackConstructor:
	
	MOV X0, #TOTAL_SZ			// Move the malloc size into X0
	BL malloc					// Allocate memory
	
	LDR X1, =istackBaseAddress	// Load the address of istackBaseAddress into X1
	STR X0, [X1]				// Store the base address into X1
	
	LDR X1, =icounter			// Load the adress of icounter into X1
	MOV X2, #0					// Move 0 into X2
	STR X2, [X1]				// Initialize the counter to 0
	
	RET 						// Return to caller

//*****************************************************************************
// Function stackDestructor:  Frees the stack memory
//
//  X0: Contains 
//  X0 (return): Pointer to newly allocated node
//
// Description:
// - Allocates 16 bytes using malloc
// - 
// - 
// - 
//
// Registers X0 - X8 are modified and not preserved
//*****************************************************************************
stackDestructor:

	LDR X0, =istackBaseAddress	// Load the address of the variable into X0
	LDR X0, [X0]				// Retrieve the base address 
	BL free						// Free the memory
	
	RET							// Return to caller

//*****************************************************************************
// Function stackPush:  Pushes values onto the stack 
//
//  X0: Contains data value to store in node
//  X0 (return): Returns 0
//
// Description:
// - Allocates 16 bytes using malloc
// - 
// - 
// - 
//
// Registers X0 - X8 are modified and not preserved
//*****************************************************************************
stackPush:

	LDR X1, =icounter			// Load the address of the icounter into X1
	LDR X2, [X1]				// Load the value at icounter into X2
	
	CMP X2, #STACK_SZ			// Comapring X2 with the stack size 
	B.GE pushfail				// If greater than stack size then jump to pushfail
	
	// STORE THE INPUT INTO SP
	
	LDR X3, =istackBaseAddress	// Load the address of istackBaseAddress in X3
	LDR X3, [X3]				// Load the value at istackBaseAddress into X3
	
	LSL X4, X2, #3				// Offset it by 8 bits 
	ADD X4, X3, X4				// Add to get the actual memory location
	
	STR D0, [X4]				// Store double into X4
	
	ADD X2, X2, #1				// Increment the counter 
	STR X2, [X1]				// Save the new counter 
	
	MOV X0, #1					// Return a non-zero for success

	RET							// Return to caller	
		
pushfail:
	
	MOV X0, #0					// Return 0 if push would exceed the size 
	
	RET							// Return to caller 

//*****************************************************************************
// Function stackPop:  Pushes values onto the stack 
//
//  X0: Contains data value to store in node
//  X0 (return): Returns 0
//
// Description:
// - Allocates 16 bytes using malloc
// - 
// - 
// - 
//
// Registers X0 - X8 are modified and not preserved
//*****************************************************************************
stackPop:

	LDR X1, =icounter			// Load the address of the icounter into X1
	LDR X2, [X1]				// Load the value at icounter into X2
	
	CMP X2, #0					// Checking if the stack is empty
	B.EQ donePop				// If empty then jump to done
	
	SUB X2, X2, #1				// Decrement the counter 
	STR X2, [X1]				// Save the new counter 
	
	LDR X3, =istackBaseAddress	// Load the address of istackBaseAddress in X3
	LDR X3, [X3]				// Load the value at istackBaseAddress into X3
	
	LSL X4, X2, #3				// Offset it by 8 bits 
	ADD X4, X3, X4				// Add to get the actual memory location
	
	LDR D0, [X4]				// Load from stack into double
	
donePop:
	
	RET							// Return to caller	

//*****************************************************************************
// Function delete:  Pushes values onto the stack 
//
//  X0: Contains data value to store in node
//  X0 (return): Returns 0
//
// Description:
// - Allocates 16 bytes using malloc
// - 
// - 
// - 
//
// Registers X0 - X8 are modified and not preserved
//*****************************************************************************			
delete:

	// COUNTER = 0 
	
	LDR X0, =icounter			// Load the adress of icounter into X0
	MOV X1, #0					// Move a 0 into X1
	STR X1, [X0]				// Store the 0 into icounter (Resetting it)
	
	RET							// Return to caller

	.data  // data section
istackBaseAddress:	.quad 0
icounter:			.quad 0

.end // end of program
