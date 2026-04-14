.section .rodata
fmt:    .string "%ld"       # format string for printing just the integer
fmt_sp: .string " "         # format string for space
fmt_nl: .string "\n"        # format string for newline

.section .text
.globl main

main:
    addi sp, sp, -64       # make some room on the stack
    sd ra, 56(sp)          # save return address
    sd s0, 48(sp)          # s0 has our total num of elements (n)
    sd s1, 40(sp)          # s1 has the argv pointer
    sd s2, 32(sp)          # s2 will hold our arr pointer
    sd s3, 24(sp)          # s3 will hold our result pointer
    sd s4, 16(sp)          # s4 will hold our stack pointer
    sd s5, 8(sp)           # s5 has stack size
    sd s6, 0(sp)           # s6 is our loop counter i

    addi s0, a0, -1        # get num of elements (argc - 1)
    blez s0, done          # check if no numbers to process... then jump to done

    addi s1, a1, 8         # skip argv[0] to point to the first number string

    slli t0, s0, 3         # multiply n by 8 to get byte size
    li t1, 3               
    mul a0, t0, t1         # multiply by 3 to fit our 3 arrays
    call malloc            # ask for memory...
    
    beq a0, x0, done       # check if malloc failed... then jump out to done
    
    mv s2, a0              # store base pointer in s2 for arr
    add s3, s2, t0         # result array starts after arr
    add s4, s3, t0         # stack array starts after result

    and s6, s6, x0         # initialize i to 0
    j parse_loop           # jump to parse loop

parse_loop:
    bge s6, s0, algo_start # check if all args are parsed... then jump to algo
    ld a0, 0(s1)           # load current string pointer for inner logic
    call atoi              # convert string to an int
    
    slli t0, s6, 3         # get byte offset for arr
    add t1, s2, t0         # get memory address for arr[i]
    sd a0, 0(t1)           # store the parsed integer
    
    addi s1, s1, 8         # move to the next argv string
    addi s6, s6, 1         # increment i to count nums processed
    j parse_loop           # go back to parse loop to take the next string

algo_start:
    addi s6, s0, -1        # initialize i to n - 1 to go backwards
    and s5, s5, x0         # initialize stack size to 0
    j algo_loop            # jump to algo loop

algo_loop:
    bltz s6, print_start   # check if we checked all elements... then jump to print

stack_check:
    beq s5, x0, store_res  # check if stack is empty... jump out to store result

    addi t0, s5, -1        # get stack.size - 1
    slli t0, t0, 3         # offset for stack
    add t1, s4, t0         
    ld t2, 0(t1)           # load top index in t2

    slli t3, t2, 3         # offset for arr[top_idx]
    add t3, s2, t3
    ld t4, 0(t3)           # load arr[top_idx] in t4

    slli t5, s6, 3         # offset for arr[i]
    add t5, s2, t5
    ld t6, 0(t5)           # load arr[i] in t6

    bgt t4, t6, store_res  # if arr[top] > arr[i], we found it! jump to store

    addi s5, s5, -1        # otherwise pop the stack... decrement stack size
    j stack_check          # jump to stack_check for the next top element

store_res:
    slli t5, s6, 3         
    add t6, s3, t5         # get memory address for result[i]

    beq s5, x0, stack_empty # check if stack is empty... jump to empty handler
    
    addi t0, s5, -1        # get top index again
    slli t0, t0, 3
    add t1, s4, t0
    ld t2, 0(t1)           # load stack.top()
    sd t2, 0(t6)           # store stack top in result
    j push_curr            # jump over the empty logic

stack_empty:
    li t0, -1              # load -1
    sd t0, 0(t6)           # store -1 in result

push_curr:
    slli t0, s5, 3         # get offset for stack[size]
    add t1, s4, t0
    sd s6, 0(t1)           # push i onto the stack
    addi s5, s5, 1         # increment stack size
    
    addi s6, s6, -1        # decrement i
    j algo_loop            # jump to algo_loop for the next element

print_start:
    and s6, s6, x0         # initialize i to 0
    j print_loop           # jump to print loop

print_loop:
    bge s6, s0, cleanup    # check if all results are printed... then jump to cleanup
    
    la a0, fmt             # load our format string (just the number)
    slli t0, s6, 3         # get byte offset
    add t1, s3, t0
    ld a1, 0(t1)           # load result[i]
    call printf            # print it...
    
    addi t0, s0, -1        # get n - 1
    bge s6, t0, skip_space # check if we are at the last element... jump to skip space
    
    la a0, fmt_sp          # load space string
    call printf            # print space...

skip_space:
    addi s6, s6, 1         # increment i
    j print_loop           # jump back to print the next one

cleanup:
    la a0, fmt_nl          # load newline
    call printf            # print newline at the very end...

    mv a0, s2              # grab the base pointer for our memory
    call free              # free it up
    j done                 # jump to done

done:
    and a0, a0, x0         # initialize to 0 to return success
    
    ld ra, 56(sp)
    ld s0, 48(sp)
    ld s1, 40(sp)
    ld s2, 32(sp)
    ld s3, 24(sp)
    ld s4, 16(sp)
    ld s5, 8(sp)
    ld s6, 0(sp)
    addi sp, sp, 64
    ret