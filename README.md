# Group-Project-Yippie-IO-Part-5
Group Project Yippie IO Part 5

Stack constrictor(){
    allocate memory (Stack_SZ * DATA_SZ)
        Save in .data
            -Save base address
            -Initialize stackPointer = base address
            -Init counter = 0
}
}

Stack deconstructor(){
    retriave base address
    free (base address)
}

# Push
@heck for max sirz CMP STACK_SIZE (counter < TACK_SZ)
If ok -save input on stack
    -store input -> stackPointer
    -increment stackPoiner or counter++
    -return non-zero
else -> return 0

# Pop
check of base address = stack pointer
if they are equel:
    -return
if they are nor equal:
    -decrement stackPoinyer
    -return value at stackPointer
check if counter = 0 (either or) - call back pop

# Delete
stackPointer =  base address


-ivan 
    - clac.s

-Manuel
    - stack.s and driverStack.s 
