.section .rodata
filename:   .string "input.txt"
yes_str:    .string "Yes\n"
no_str:     .string "No\n"

.section .text
.globl main

main:
    addi sp, sp, -48       # make some room on the stack
    sd ra, 40(sp)          # save return address
    sd s0, 32(sp)          # s0 has our fd
    sd s1, 24(sp)          # s1 has the total length
    sd s2, 16(sp)          # s2 is left offset
    sd s3, 8(sp)           # s3 is right offset
    sd s4, 0(sp)           

    li a0, -100            # AT_FDCWD for openat
    la a1, filename
    and a2, a2, x0         # initialize to 0 for O_RDONLY
    and a3, a3, x0         # initialize a3 to 0 too
    li a7, 56              # syscall to open the file...
    ecall
    mv s0, a0              # store fd in s0 to use later

    mv a0, s0
    and a1, a1, x0         # initialize offset to 0
    li a2, 2               # SEEK_END to find file size
    li a7, 62              
    ecall
    mv s1, a0              # store file length in s1

    beq s1, x0, found_yes  # check if length is 0... then it's a palindrome so jump to yes

    and s2, s2, x0         # initialize left pointer to 0
    addi s3, s1, -1        # set right pointer to length minus 1

    addi sp, sp, -8        # make a tiny 1 byte buffer on stack for reading
    sd zero, 0(sp)         # clear it out

    j main_loop            # jump to main loop

main_loop:
    bge s2, s3, found_yes  # check if left and right crossed... then jump to yes

    mv a0, s0
    mv a1, s2              # load left offset in a1
    and a2, a2, x0         # initialize to 0 for SEEK_SET
    li a7, 62
    ecall                  # seek to left side...

    mv a0, s0
    mv a1, sp              # use our stack buffer
    li a2, 1               # just read 1 byte
    li a7, 63
    ecall
    lb t0, 0(sp)           # load left char in t0

    mv a0, s0
    mv a1, s3              # load right offset in a1
    and a2, a2, x0         # initialize to 0 for SEEK_SET
    li a7, 62
    ecall                  # seek to right side...

    mv a0, s0
    mv a1, sp
    li a2, 1
    li a7, 63
    ecall
    lb t1, 0(sp)           # load right char in t1

    bne t0, t1, found_no   # check if characters match... if not jump to no
    j bridge_next          # jump to increment step

bridge_next:
    addi s2, s2, 1         # increment left pointer
    addi s3, s3, -1        # decrement right pointer
    j main_loop            # go back to main loop to check the next pair

found_yes:
    addi sp, sp, 8         # fix stack buffer
    li a0, 1               # set to stdout
    la a1, yes_str
    li a2, 4               # string length
    li a7, 64
    ecall                  # print yes...
    j done                 # jump to done

found_no:
    addi sp, sp, 8         # fix stack buffer
    li a0, 1               # set to stdout
    la a1, no_str
    li a2, 3               # string length
    li a7, 64
    ecall                  # print no...
    j done                 # jump to done

done:
    mv a0, s0              # grab the fd
    li a7, 57              
    ecall                  # close the file

    and a0, a0, x0         # initialize to 0 to return success
    li a7, 93              
    ecall                  # exit syscall...

    ld ra, 40(sp)
    ld s0, 32(sp)
    ld s1, 24(sp)
    ld s2, 16(sp)
    ld s3, 8(sp)
    ld s4, 0(sp)
    addi sp, sp, 48
    ret