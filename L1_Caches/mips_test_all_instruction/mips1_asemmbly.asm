.data
filename: .asciiz "C:\Users\elado\Desktop\CPU\mips1_cpu.txt"  # Change the path to the file you want to open
flags:    .word 0x0000                 # Example flags, adjust as needed (e.g., O_RDONLY)

.text
main:

    lw $t0, 0           # $t0 = 1
    lw $t1, 4           # $t1 = 2
    lw $t2, 8		# $t2 = 3
    
    add $t3,$t2,$t1   	# $t3 = 5
    move $t4,$t3	# $t4 = 5
    sub $t4,$t3,$t0	# t4 = 4
    mul $t5, $t3,$t1	# t5 = 5*2 = 10
    
    sll $t6, $t0, 2          # $t6 = $t0 << 2 (logical shift left) = 4
    srl $t7, $t4, 1          # $t7 = $t1 >> 1 (logical shift right) = 2
    
    slt $t6, $t5, $t1        # $t6 = 1 if $t0 < $t1, else $t8 = 0 --> 0
    slti $t7, $t0, 15        # $t7 = 1 if $t0 < 15, else $t9 = 0 --> 1
    
    
    addi $t0,$t4,-50	# t0 = 2 - 50 = -48
    
    move $a0, $t0 #move a1 to a0 now a0 should be ao(1)+a1 
    
    and $s1, $t0, $t1        # $s1 = $t0 & $t1
    andi $s2, $t0, 0x0F      # $s2 = $t0 & 0x0F
    or $s3, $t0, $t1         # $s3 = $t0 | $t1
    ori $s4, $t0, 0x0F       # $s4 = $t0 | 0x0F
    xor $s5, $t0, $t1        # $s5 = $t0 ^ $t1
    xori $s6, $t0, 0x0F      # $s6 = $t0 ^ 0x0F
    
    lui $t0, 0x1234

    jal subroutine
    j end
    
    subroutine:
    # Some code here
    jr $ra                   # Return from subroutine
    
    end:
    
    
    
    li $v0, 10       # Exit syscall
    syscall