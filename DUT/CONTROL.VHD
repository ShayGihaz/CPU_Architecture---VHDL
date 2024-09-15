		-- control module (implements MIPS control unit)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY control IS
   PORT( 	
	Opcode 			: IN 	STD_LOGIC_VECTOR( 5 DOWNTO 0 );
	function_opcode : IN 	STD_LOGIC_VECTOR( 5 DOWNTO 0 );
	RegDst 			: OUT 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	ALUSrc 			: OUT 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	MemtoReg 		: OUT 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	RegWrite 		: OUT 	STD_LOGIC;
	MemRead 		: OUT 	STD_LOGIC;
	MemWrite 		: OUT 	STD_LOGIC;
	Branch 			: OUT 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	Jump 			: OUT   STD_LOGIC;
	JumpReg			: OUT   STD_LOGIC;
	ALUop 			: OUT 	STD_LOGIC_VECTOR( 3 DOWNTO 0 );
	clock, reset	: IN 	STD_LOGIC;
	jrReg			: IN    STD_LOGIC_VECTOR (4 DOWNTO 0);
	MUX_forID		: OUT   STD_LOGIC_VECTOR (1 DOWNTO 0);
	INT_ACK			: OUT   STD_LOGIC;
	PC_noChange		: OUT 	STD_LOGIC;
	ISR_branch		: OUT 	STD_LOGIC;
	interupt_signal : IN    STD_LOGIC );

END control;

ARCHITECTURE behavior OF control IS

	SIGNAL  R_format, Mul, reti												: STD_LOGIC;
	SIGNAL  Beq, Bne, Addi, Slti, Andi, Xori, Ori, Lui, Lw, Sw, Move  	: STD_LOGIC;
	SIGNAL  j, jal, jr 													: STD_LOGIC;
	SIGNAL  ackStat														: STD_LOGIC_VECTOR (1 DOWNTO 0);
	SIGNAL disablSignal_inter 											: STD_LOGIC_VECTOR (1 DOWNTO 0);
	
	
-- 	To hendle the interupts we gets from the priferial components we add several things
--		reti --> this is an instruction that get '1' if we are doing jr instruction and also 
--				 the register we need to put in the PC is R27 --> $k1 --> jrReg = "11011"
--				 reti: Return from Interrupt
--				 when reti = '1' --> RegDst = '11', MemtoReg = '11'
--				 by RegDst = '11' we will write to register R26 --> $k0 --> write_reg_address = "11010"
--				 by MemtoReg = '11' we will chose to write "000...001" to $k0 register

--      GIE  --> 0th bit of the $k0 register indicate us to go to the return address stored in $k1
--
--


BEGIN           
				-- Code to generate control signals using opcode bits
	R_format 	<=  '1'  WHEN  Opcode = "000000"  ELSE '0';
			-- R_ format is for the instructions: add,sub,and,or,sll,srl,Slt
			-- we will differ between them using the function_opcode
	Mul 		<=  '1'  WHEN  Opcode = "011100"  ELSE '0';
	--Move        <=  '1'  WHEN  Opcode = "000000" and function_opcode = "100001" ELSE '0';

	
				-- I type instructions
	Beq         <=  '1'  WHEN  Opcode = "000100"  ELSE '0';
	Bne         <=  '1'  WHEN  Opcode = "000101"  ELSE '0';
	Addi        <=  '1'  WHEN  Opcode = "001000"  ELSE '0';
	Slti        <=  '1'  WHEN  Opcode = "001010"  ELSE '0';
	Andi        <=  '1'  WHEN  Opcode = "001100"  ELSE '0';
	Ori         <=  '1'  WHEN  Opcode = "001101"  ELSE '0';
	Xori        <=  '1'  WHEN  Opcode = "001110"  ELSE '0';
	Lui         <=  '1'  WHEN  Opcode = "001111"  ELSE '0';
	Lw          <=  '1'  WHEN  Opcode = "100011"  ELSE '0';
 	Sw          <=  '1'  WHEN  Opcode = "101011"  ELSE '0';
   	
				-- J type instructions
	j           <=  '1'  WHEN  Opcode = "000010"  ELSE '0';
	jal         <=  '1'  WHEN  Opcode = "000011"  ELSE '0';
	jr          <=  '1'  WHEN  Opcode = "000000" AND function_opcode = "001000"  ELSE '0';
	reti        <=  '1'  WHEN  Opcode = "000000" AND function_opcode = "001000" and jrReg = "11011"  ELSE '0';
	
	
--####################################################################################--
--					###	instructions registers explantion ###
--
--		R_format   -->  RegDst=01,  ALUOp=0010, RegWrite=1
--		Mul        -->  RegDst=01,  ALUOp=0110, RegWrite=1
--		cx
--		Beq        -->  Branch=01, ALUOp=0001
--		Bne		   -->  Branch=10, ALUOp=0001
--		Addi	   -->  ALUSrc=01, ALUOp=0000, RegWrite=1
--		Andi	   -->  ALUSrc=11, ALUOp=0011, RegWrite=1
--		Ori		   -->  ALUSrc=11, ALUOp=0100, RegWrite=1ite=1
--		Xori	   -->  ALUSrc=11, ALUOp=0101, RegWrite=1
--		Slti	   -->  ALUSrc=01, ALUOp=1001, RegWrite=1
--		Lui		   -->  ALUSrc=01, ALUOp=1000, RegWrite=1
--		Lw	  	   -->  MemRead=1, MemtoReg=01, ALUSrc=01, RegWrite=1
--		Sw		   -->  MemWrite=1, ALUSrc=01
--		Move	   -->  ??????
--
--		j		   -->  Jump=1
--		jal		   -->  Jump=1, RegDst=10, MemtoReg=10, RegWrite=1
--		jr		   -->  JumpReg=1
--
--####################################################################################--


				
  	RegDst(0)    	<=  R_format OR Mul OR reti when disablSignal_inter = "00" else '0';
	RegDst(1)    	<=  jal OR reti when disablSignal_inter = "00" else '0';
	
	Jump 			<= j or jal when disablSignal_inter = "00" else '0';
	
	Branch(0)       <=  Beq when disablSignal_inter = "00" else '0';
	Branch(1)      	<=  Bne when disablSignal_inter = "00" else '0'; 
	
	MemRead 		<=  Lw when disablSignal_inter = "00" else '0';
	
	MemtoReg(0) 	<=  Lw OR reti when disablSignal_inter = "00" else '0';
	MemtoReg(1) 	<=  jal OR reti when disablSignal_inter = "00" else '0';
	
	ALUOp(3) 		<=  lui or Slti when disablSignal_inter = "00" else '0';
	ALUOp(2) 		<=  Ori or Xori or Mul when disablSignal_inter = "00" else '0';
	ALUOp(1) 		<=  R_format or Andi or Mul when disablSignal_inter = "00" else '0';
	ALUOp(0) 		<=  Beq or Bne or Xori or Andi or Slti when disablSignal_inter = "00" else '0'; 
	
	MemWrite 		<=  Sw when disablSignal_inter = "00" else '0'; 
	
	-- 01 to instructions lw,sw,lui,slti --> sign extention as we know
	-- 11 to instructions xori,ori,andi --> zero sign extention
 	ALUSrc(0)  		<=  Lw OR Sw OR Lui OR Slti OR Addi OR Andi OR Xori OR Ori when disablSignal_inter = "00" else '0';
	ALUSrc(1)  		<=  Andi OR Xori OR Ori when disablSignal_inter = "00" else '0';
	
	JumpReg     	<= R_format and jr when disablSignal_inter = "00" else '0'; 
	
		-- int his control register when one of the disablSignal_inter bit in '1' we want him to be '1'
	RegWrite 		<=  R_format OR Lw OR Addi OR Lui OR Slti OR Andi OR Xori OR Ori OR Mul OR jal when disablSignal_inter = "00" else
						(disablSignal_inter(0) or disablSignal_inter(1));
	
	
  	
			-- here we add 2 state interupt ack when interrupt accure
			-- this 2 stats will creat us mux: 00-as usual, 01-write to $k1, 10-write to $k0 
			-- we will wrap every register that need to be 0 while we handeling interrups by the case of this mux = 00
			-- when this signal will be not 00 we disable the necessary control signals ( this is the disablSignal_inter :))
	process(reset, clock, interupt_signal)
	begin
		if reset = '1' then
			ackStat <= "00";
		elsif ((clock'event) and (clock = '1')) then
			ackStat(0) <= interupt_signal and (not ackStat(1));  --this is mean that anly in the case we r not handeling onther interupt
			ackStat(1) <= ackStat(0);
		end if;
	end process;
	
	MUX_forID(0) <= ackStat(0);
	MUX_forID(1) <= ackStat(1);
	
	INT_ACK      <= NOT (ackStat(1));	-- ackStat(1) = '1' --> RESET OF GIE --> we want the INT_ACK to be '0' 
										--(becouse how we use it in intCon)
										
	disablSignal_inter(0)  <= ackStat(0);
	disablSignal_inter(1)  <= ackStat(1);
	
			-- so now we are going to difine 2 signal
			-- dont change pc signal --> this signal will sign to the pc_plus_4 to dont change and save the return pc 
										--after the interrupt
			-- isr branch --> this signal indicate to the signal next_pc to jump to the address for the interrupt
	PC_noChange <= '1' when (ackStat(0) = '1' or ackStat(1) = '1') else '0';
	ISR_branch	<= '1' when ackStat(1) = '1' else '0';


   END behavior;


