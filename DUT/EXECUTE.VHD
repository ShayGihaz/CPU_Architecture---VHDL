--  Execute module (implements the data ALU and Branch Address Adder  
--  for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY  Execute IS
	PORT(	Read_data_1 	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Read_data_2 	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Sign_extend 	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Zero_extend 	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			shamt_extend 	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Function_opcode : IN 	STD_LOGIC_VECTOR( 5 DOWNTO 0 );
			ALUOp 			: IN 	STD_LOGIC_VECTOR( 3 DOWNTO 0 );
			ALUSrc 			: IN 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
			Zero 			: OUT	STD_LOGIC;
			ALU_Result 		: OUT	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Add_Result 		: OUT	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			PC_plus_4 		: IN 	STD_LOGIC_VECTOR( 9 DOWNTO 0 );
			clock, reset	: IN 	STD_LOGIC );
END Execute;

ARCHITECTURE behavior OF Execute IS
SIGNAL Ainput, Binput 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
SIGNAL ALU_output_mux		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
SIGNAL Branch_Add 			: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
SIGNAL ALU_ctl				: STD_LOGIC_VECTOR( 3 DOWNTO 0 );
SIGNAL shifter_control, c   : STD_LOGIC := '0';
SIGNAL shifter_result		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
SIGNAL multiplection_result : STD_LOGIC_VECTOR( 63 DOWNTO 0 );

component shifter is
	GENERIC (n : INTEGER := 32;
			 k : INTEGER := 5;
			 m : integer := 16	); -- m=2^(k-1)
	port ( 	inp: in STD_LOGIC_VECTOR (n-1 downto 0);--input (y vector)
			sel: in STD_LOGIC_VECTOR (n-1 downto 0);--selector (x vector only 3 bits will matter)
			control: in STD_LOGIC;
			res: out STD_LOGIC_VECTOR (n-1 downto 0);
			c_out: OUT STD_LOGIC);
			
end component;

BEGIN

	shfter: shifter generic map (32,5,16) port map (Binput, Ainput, shifter_control, shifter_result, c);
	
------------------------------------------------------------------------------------
		-- if we are in the sll or srl instruction we need to do the shamt (instruction[10:6]) 
	Ainput <= shamt_extend WHEN (ALUop = "0010" and (Function_opcode = "000000" or Function_opcode = "000010"))
		ELSE X"00000000" WHEN (Function_opcode = "100001")
		ELSE Read_data_1;
------------------------------------------------------------------------------------		
						-- ALU input mux
		-- 00 to not needed extention instructions
		-- 01 to instructions lw,sw,lui,slti --> sign extention as we know
		-- else: instructions xori,ori,andi --> zero sign extention
	Binput <= Read_data_2 WHEN ( ALUSrc = "00" ) 
  		ELSE  Sign_extend( 31 DOWNTO 0 ) WHEN (ALUSrc = "01")
		ELSE  Zero_extend( 31 DOWNTO 0 );
------------------------------------------------------------------------------------
						-- Generate ALU control bits
						
						
	PROCESS (ALUOp, Function_opcode)
		BEGIN
		CASE ALUOp IS
					-- defulte: performs +
			WHEN "0000"		=> 		ALU_ctl <= "0010";   
					-- beq --> performs -
			WHEN "0001"		=> 		ALU_ctl <= "0110";
					-- andi --> performs AND
			WHEN "0011"		=> 		ALU_ctl <= "0000";
					-- ori --> performs OR
			WHEN "0100"		=> 		ALU_ctl <= "0001";
					-- xori --> performs XOR
			WHEN "0101"		=> 		ALU_ctl <= "0100";
					-- mul --> performs *
			WHEN "0110"		=> 		ALU_ctl <= "0101";
					-- lui 
			WHEN "1000"		=> 		ALU_ctl <= "1000";
					-- slti --> performs -
			WHEN "1001"		=> 		ALU_ctl <= "0111";
					-- sll and srl --> performs shfter component
			WHEN "0010"		=>
				IF Function_opcode(1) = '0' then
					shifter_control <= '0';
				ELSE
					shifter_control <= '1';
				END IF;
				IF Function_opcode(5 DOWNTO 2) = "0000" then
					ALU_ctl(0) <= '1';
					ALU_ctl(1) <= '1';
					ALU_ctl(2) <= '0';
				ELSE
					
					ALU_ctl(0) <= ( Function_opcode( 0 ) OR Function_opcode( 3 ) ) AND ALUOp(1);  --1
					ALU_ctl(1) <= ( NOT Function_opcode( 2 ) ) OR (NOT ALUOp( 1 ) );   				--1
					ALU_ctl(2) <= ( Function_opcode( 1 ) AND ALUOp( 1 )) OR ALUOp( 0 );				--0 0011
				END IF;
				ALU_ctl(3) <= '0';
			WHEN OTHERS	=>	ALU_ctl 	<= "0000" ;
		END CASE;
	END PROCESS;
				

	
	
------------------------------------------------------------------------------------
						-- Generate Zero Flag
	Zero <= '1' 
		WHEN ( ALU_output_mux( 31 DOWNTO 0 ) = X"00000000"  )
		ELSE '0';    
						-- Select ALU output        
	ALU_result <= X"0000000" & B"000"  & ALU_output_mux( 31 ) 
		WHEN  ALU_ctl = "0111" 
		ELSE  	ALU_output_mux( 31 DOWNTO 0 );
						-- Adder to compute Branch Address
	Branch_Add	<= PC_plus_4( 9 DOWNTO 2 ) +  Sign_extend( 7 DOWNTO 0 ) ;
		Add_result 	<= Branch_Add( 7 DOWNTO 0 );
		
		
	multiplection_result <= Ainput * Binput;
		
------------------------------------------------------------------------------------

PROCESS ( ALU_ctl, Ainput, Binput, shifter_result, multiplection_result)
	BEGIN
					-- Select ALU operation
 	CASE ALU_ctl IS
						-- ALU performs ALUresult = A_input AND B_input
		WHEN "0000" 	=>	ALU_output_mux 	<= Ainput AND Binput; 
						-- ALU performs ALUresult = A_input OR B_input
     	WHEN "0001" 	=>	ALU_output_mux 	<= Ainput OR Binput;
						-- ALU performs ALUresult = A_input + B_input
	 	WHEN "0010" 	=>	ALU_output_mux 	<= Ainput + Binput;
						-- ALU performs sll and srl
 	 	WHEN "0011" 	=>	ALU_output_mux <= shifter_result;
						-- ALU performs xor
 	 	WHEN "0100" 	=>	ALU_output_mux 	<= Ainput xor Binput;
						-- ALU performs multiplection
 	 	WHEN "0101" 	=>	ALU_output_mux 	<= multiplection_result(31 DOWNTO 0);
						-- ALU performs ALUresult = A_input -B_input
 	 	WHEN "0110" 	=>	ALU_output_mux 	<= Ainput - Binput;
						-- ALU performs SLT
  	 	WHEN "0111" 	=>	ALU_output_mux 	<= Ainput - Binput ;
						-- ALU performs lui
		WHEN "1000" 	=>	ALU_output_mux 	<= Binput(15 DOWNTO 0) & X"0000" ;
 	 	WHEN OTHERS	=>	ALU_output_mux 	<= X"00000000" ;
  	END CASE;
  END PROCESS;
END behavior;

