# Group-Project-Yippie-IO-Part-5
Group Project Yippie IO Part 5

to start do Part 5 we should: 
Redo Yippie IO Part 4:
    -  Coding standard (class header, function/main descriptions (Add comments)
    -  Getkey should be an evolution of the author's code with your additions from previous assignmen (Move old main and flashmain to getkey, remake logic cuz now we have super complicated version of math, we do (lenght of gpio-1)/2 to get lines, and for column we do (lenght of gpio -1)%2 (we should use like professor showed, and old style), also we used #include wich migh looks like ai (c style), also we do open devmem, and code super clear no commands and explaning which looks like ai as well.

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
