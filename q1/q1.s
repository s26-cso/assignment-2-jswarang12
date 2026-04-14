.section .text


# struct Node memory layout
# offset 0: int val (4 bytes) + 4 bytes padding for alignment ... 
# offset 8: struct Node* left (8 bytes cause 64-bit pointers)
# offset 16: struct Node* right (8 bytes)
# total sizeof(Node) = 24 bytes ... need to know for malloc


.global make_node

make_node:
                            # prologue... making space for ra and s0 on the stack
    addi sp, sp, -16       # make 16 bytes of room on the stack
    sd ra, 8(sp)           # save return address at offset 8
    sd s0, 0(sp)           # save s0 at offset 0 so we dont lose it

    mv s0, a0              # save val in s0 for later
    li a0, 24              # load 24 for sizeof node ... 24 bytes total for our struct
    call malloc            # call malloc... a0 will now have the new allocated pointer

    # filling in the struct fields based on our memory layout 
    sw s0, 0(a0)           # store the val into node->val (offset 0)
    sd x0, 8(a0)           # set left child to null ... using x0 at offset 8
    sd x0, 16(a0)          # set right child to null ... offset 16

    # epilogue... cleaning up the stack
    ld ra, 8(sp)           # restore ra
    ld s0, 0(sp)           # restore s0
    addi sp, sp, 16        # put stack pointer back up
    ret                    # go back to caller

.global insert

insert:
    # prologue for insert... needs more space for recursive calls
    addi sp, sp, -32       # make space for ra and vars ... 32 bytes
    sd ra, 24(sp)          # save return address
    sd s0, 16(sp)          # save s0 for root
    sd s1, 8(sp)           # save s1 for val

    mv s0, a0              # s0 has root pointer
    mv s1, a1              # s1 has the val we want to insert into the bst

    bne a0, x0, not_null   # base case: check if root is null... if it has stuff jump to not_null
    mv a0, s1              # put val in a0 to make a brand new node
    call make_node         # a0 now has the new node ... base case for recursion done
    j insert_done          # jump to done

not_null:
    lw t0, 0(s0)           # load current root val into t0 from offset 0
    blt s1, t0, go_left    # bst logic: if val to insert is less than root val... recurse left

                            # ifwe are here, val is >= root val ... so go right
    ld a0, 16(s0)          # load right child pointer into a0 (offset 16)
    mv a1, s1              # setup val to insert in right subtree
    call insert            # recursive call!
    sd a0, 16(s0)          # update right child with the new node pointer returned in a0
    j insert_return        # jump out

go_left:
    ld a0, 8(s0)           # load left child pointer into a0 (offset 8)
    mv a1, s1              # setup val
    call insert            # recursive call to left subtree
    sd a0, 8(s0)           # update left child with the new node pointer

insert_return:
    mv a0, s0              # move original root back to a0 to return it unchanged

insert_done:
    # epilogue... pop everything off
    ld ra, 24(sp)          # restore everything
    ld s0, 16(sp)          
    ld s1, 8(sp)           
    addi sp, sp, 32        # reset stack pointer
    ret

.global get

get:
    addi sp, sp, -16       # prep stack for recursion
    sd ra, 8(sp)           
    sd s0, 0(sp)           

    mv s0, a0              # keep root safe in s0

    beq a0, x0, get_done   # base case: if root is null... nothing to find so jump to done (returns null)

    lw t0, 0(a0)           # t0 gets root val from offset 0
    beq a1, t0, get_found  # check if we found the exact val... jump to get_found
    blt a1, t0, get_left   # bst logic: if target val is smaller... jump left

    # otherwise target is bigger... go right
    ld a0, 16(s0)          # load right child from offset 16
    call get               # keep searching right
    j get_done             # jump out when done

get_left:
    ld a0, 8(s0)           # load left child from offset 8
    call get               # keep searching left
    j get_done             

get_found:
    mv a0, s0              # move the matching node pointer to a0 to return it

get_done:
    ld ra, 8(sp)           # clean up stack
    ld s0, 0(sp)           
    addi sp, sp, 16        
    ret

.global getAtMost

getAtMost:
    # finding the largest value <= given val
    #  this iteratively instead of recursively to save stack space
    addi sp, sp, -32       # setup stack
    sd ra, 24(sp)          
    sd s0, 16(sp)          
    sd s1, 8(sp)           
    sd s2, 0(sp)           

    mv s0, a0              # s0 has the query val
    mv s1, a1              # s1 is our current node pointer
    li s2, -1              # start answer at -1 ... means none found yet

search_loop:
    beq s1, x0, search_done # if current node is null we hit a leaf and are done searching

    lw t0, 0(s1)           # load node val from offset 0
    bgt t0, s0, search_left # if node val is bigger than query... need smaller so go left

                            # ifnode->val <= val, valid candidate for our answer
    mv s2, t0              # node val is valid! save it as best answer so far
    ld s1, 16(s1)          # move to right child (offset 16) to try to find a bigger valid one
    j search_loop          # jump back to start of loop

search_left:
    ld s1, 8(s1)           # move to left child (offset 8)
    j search_loop          # go back to loop

search_done:
    mv a0, s2              # return the best answer we found (will be -1 if none)

    ld ra, 24(sp)          # restore everything
    ld s0, 16(sp)          
    ld s1, 8(sp)           
    ld s2, 0(sp)           
    addi sp, sp, 32        
    ret