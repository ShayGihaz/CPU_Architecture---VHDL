				-- Top Level Structural Model for MIPS Processor Core
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

ENTITY MIPS IS
	GENERIC ( modelsim: integer := 0);
	PORT( reset, clock					: IN 	STD_LOGIC; 
		-- Output important signals to pins for easy display in Simulator
		PC								: OUT  STD_LOGIC_VECTOR( 9 DOWNTO 0 );
		ALU_result_out, read_data_1_out, read_data_2_out, write_data_out,	
     	Instruction_out					: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		Zero_out, Memwrite_out, 
		Regwrite_out, MemRead_out		: OUT 	STD_LOGIC;
		data_buf						: inout STD_LOGIC_VECTOR (31 DOWNTO 0);
		Branch_out						: OUT 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		address_per						: OUT   STD_LOGIC_VECTOR (11 DOWNTO 0);
		INT_ACK							: OUT STD_LOGIC := '1';
		GIE								: OUT STD_LOGIC;
		interupt_signal					: IN STD_LOGIC := '0' );
END 	MIPS;

ARCHITECTURE structure OF MIPS IS

	COMPONENT Ifetch
   	     PORT(	Instruction 	: OUT	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				PC_plus_4_out 	: OUT	STD_LOGIC_VECTOR( 9 DOWNTO 0 );		
				Add_result 		: IN 	STD_LOGIC_VECTOR( 7 DOWNTO 0 );		
				Branch 			: IN 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );	
				Zero 			: IN 	STD_LOGIC;							
				PC_out 			: OUT	STD_LOGIC_VECTOR( 9 DOWNTO 0 );		
				clock, reset 	: IN 	STD_LOGIC;								
				JumpAddr		: IN 	STD_LOGIC_VECTOR( 7 DOWNTO 0 ); 
				Jump 			: IN	STD_LOGIC;
				JumpReg			: IN	STD_LOGIC;			
				read_data_1		: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				PC_noChange		: IN	STD_LOGIC;
				ISR_branch		: IN	STD_LOGIC;
				ISR_add			: IN   	STD_LOGIC_VECTOR (7 DOWNTO 0));
	END COMPONENT; 

	COMPONENT Idecode
 	     PORT(	read_data_1	: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				read_data_2	: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				Instruction : IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				read_data 	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				ALU_result	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				RegWrite 	: IN 	STD_LOGIC;
				MemtoReg 	: IN 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
				RegDst 		: IN 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
				Sign_extend : OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				Zero_extend : OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				shamt_extend: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				PC_plus_4	: IN    STD_LOGIC_VECTOR( 9 DOWNTO 0 );
				GIE			: OUT	STD_LOGIC;
				MUX_forID	: IN	STD_LOGIC_VECTOR (1 DOWNTO 0);
				clock,reset	: IN 	STD_LOGIC );
	END COMPONENT;

	COMPONENT control
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
	END COMPONENT;

	COMPONENT  Execute
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
	END COMPONENT;


	COMPONENT dmemory
	     PORT(	read_data 			: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		address 			: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		write_data 			: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		MemRead, Memwrite 	: IN 	STD_LOGIC;
				INT_ACK				: IN	STD_LOGIC;
				add_bus				: IN	STD_LOGIC_VECTOR (7 DOWNTO 0);
        		Clock,reset			: IN 	STD_LOGIC );
	END COMPONENT;
	
	COMPONENT BidirPin is
		generic( width: integer:=16 );
		port(   Dout: 	in 		std_logic_vector(width-1 downto 0);
				en:		in 		std_logic;
				Din:	out		std_logic_vector(width-1 downto 0);
				IOpin: 	inout 	std_logic_vector(width-1 downto 0)
		);
	END COMPONENT;

					-- declare signals used to connect VHDL components
	SIGNAL PC_plus_4 		: STD_LOGIC_VECTOR( 9 DOWNTO 0 );
	SIGNAL read_data_1 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL read_data_2 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Sign_Extend 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Add_result 		: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL ALU_result 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL read_data 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL ALUSrc 			: STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	SIGNAL Branch 			: STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	SIGNAL RegDst 			: STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	SIGNAL Regwrite 		: STD_LOGIC;
	SIGNAL Zero 			: STD_LOGIC;
	SIGNAL MemWrite 		: STD_LOGIC;
	SIGNAL MemtoReg 		: STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	SIGNAL MemRead 			: STD_LOGIC;
	SIGNAL ALUop 			: STD_LOGIC_VECTOR(  3 DOWNTO 0 );
	SIGNAL Instruction		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Jump				: STD_LOGIC;
	SIGNAL JumpReg			: STD_LOGIC;
	SIGNAL Zero_extend		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL shamt_extend		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL read_data_dmem	: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL data_f_bus		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL en				: STD_LOGIC;
	
	SIGNAL ack				: STD_LOGIC;
	SIGNAL ISR_branch		: STD_LOGIC;
	SIGNAL PC_noChange		: STD_LOGIC;
	SIGNAL MUX_forID		: STD_LOGIC_VECTOR (1 DOWNTO 0);

BEGIN
	BDP: BidirPin
		generic map( 32 )
		port MAP (  Dout 	=>  read_data_2,
					en		=>  en,
					Din		=>  data_f_bus,
					IOpin	=> 	data_buf );


					-- if the 11th ALU_Result bit is 1 --> we are not in the data memoty region (bigger then 0x800)
					-- then we are not reading anything from the memory so we will take 
					-- read_data = data_f_bus = read_data_2 = R[t]
					--
					-- if the 11th ALU_Result bit is 0 --> we are in the data memoty region (less then 0x800)
					-- then we are reading from the memory so we will take 
					-- read_data = read_data_dmem 
	en <= '1' WHEN (MemWrite ='1' and ALU_Result(11) ='1') ELSE '0';
	
	read_data <= read_data_dmem WHEN (ALU_Result(11) = '0' or ack='0' ) ELSE data_f_bus;
	
	INT_ACK <= ack;

					-- copy important signals to output pins for easy 
					-- display in Simulator
   Instruction_out 	<= Instruction;
   ALU_result_out 	<= ALU_result;
   read_data_1_out 	<= read_data_1;
   read_data_2_out 	<= read_data_2;
   write_data_out  	<= read_data WHEN MemtoReg(0) = '1' ELSE ALU_result;
   Branch_out 		<= Branch;
   Zero_out 		<= Zero;
   RegWrite_out 	<= RegWrite;
   MemWrite_out 	<= MemWrite;
   MemRead_out		<= MemRead;
   address_per		<= ALU_Result(11 DOWNTO 0);
					-- connect the 5 MIPS components   
  IFE : Ifetch
	PORT MAP (	Instruction 	=> Instruction,
    	    	PC_plus_4_out 	=> PC_plus_4,
				Add_result 		=> Add_result,
				Branch 			=> Branch,
				Zero 			=> Zero,
				PC_out 			=> PC,
				Jump			=> Jump,
				JumpReg			=> JumpReg,
				JumpAddr		=> Instruction(7 DOWNTO 0),
				read_data_1     => read_data_1,
				clock 			=> clock,  
				reset 			=> reset,
				PC_noChange		=> PC_noChange,
				ISR_branch		=> ISR_branch,
				ISR_add			=> read_data (9 DOWNTO 2) );

   ID : Idecode
   	PORT MAP (	read_data_1 	=> read_data_1,
        		read_data_2 	=> read_data_2,
        		Instruction 	=> Instruction,
        		read_data 		=> read_data,
				ALU_result 		=> ALU_result,
				RegWrite 		=> RegWrite,
				MemtoReg 		=> MemtoReg,
				RegDst 			=> RegDst,
				Sign_extend 	=> Sign_extend,
				Zero_extend		=> Zero_extend,
				shamt_extend    => shamt_extend,
				PC_plus_4		=> PC_plus_4,
        		clock 			=> clock,  
				reset 			=> reset,
				GIE				=> GIE,
				MUX_forID		=> MUX_forID );


   CTL:   control
	PORT MAP ( 	Opcode 			=> Instruction( 31 DOWNTO 26 ),
				Function_opcode => Instruction(5 DOWNTO 0),
				RegDst 			=> RegDst,
				ALUSrc 			=> ALUSrc,
				MemtoReg 		=> MemtoReg,
				RegWrite 		=> RegWrite,
				MemRead 		=> MemRead,
				MemWrite 		=> MemWrite,
				Branch 			=> Branch,
				Jump			=> Jump,
				JumpReg			=> JumpReg,
				ALUop 			=> ALUop,
                clock 			=> clock,
				reset 			=> reset,
				jrReg			=> Instruction (25 DOWNTO 21),
				INT_ACK			=> ack,
				MUX_forID		=> MUX_forID,
				PC_noChange		=> PC_noChange,
				ISR_branch		=> ISR_branch,
				interupt_signal => interupt_signal );

   EXE:  Execute
   	PORT MAP (	Read_data_1 	=> read_data_1,
             	Read_data_2 	=> read_data_2,
				Sign_extend 	=> Sign_extend,
				Zero_extend		=> Zero_extend,
				shamt_extend    => shamt_extend,
                Function_opcode	=> Instruction( 5 DOWNTO 0 ),
				ALUOp 			=> ALUop,
				ALUSrc 			=> ALUSrc,
				Zero 			=> Zero,
                ALU_Result		=> ALU_Result,
				Add_Result 		=> Add_Result,
				PC_plus_4		=> PC_plus_4,
                Clock			=> clock,
				Reset			=> reset );

   MEM:  dmemory
	PORT MAP (	read_data 		=> read_data_dmem,
				--read_data		=> read_data,
				address 		=> ALU_Result,
				write_data 		=> read_data_2,
				MemRead 		=> MemRead, 
				Memwrite 		=> MemWrite,
				INT_ACK			=> ack,
				add_bus			=> data_f_bus (7 DOWNTO 0),
                clock 			=> clock,  
				reset 			=> reset );
END structure;

