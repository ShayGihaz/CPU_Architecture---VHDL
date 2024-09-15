#This program implements the following C code
#if (i<j)
#	f=g+h;
#else
#	f=g-h;
#end
.data 
	i: .word 1 
	j: .word 2
	g: .word 3
	h: .word 4
	f: .word 5
.text
# Before running this code make sure that
# Settings -> Memory Configuration -> Compact, Data at Address 0
	lw $t1,0#$t1=i
	lw $t2,4#$t2=j
	lw $t3,8#$t3=g
	lw $t4,12#$t4=h
	slt $t0,$t1,$t2 #if i<j than $t0=1
	beq $t0,$zero,ELSE #if i>=j then go to else part
IF:     add $t5,$t3,$t4 #f=g+h
	beq $t0,$t0,END #jump to END is the same as "j END" which is not yet implemented in our MIPS	 
ELSE:   sub $t5,$t3,$t4 #f=g-h
END: 	sw $t5,f	#save f
