-- Ifetch module (provides the PC and instruction 
--memory for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY Ifetch IS
	GENERIC ( modelsim: integer := 0);
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
			ISR_add			: IN   	STD_LOGIC_VECTOR (7 DOWNTO 0)
        );
END Ifetch;

ARCHITECTURE behavior OF Ifetch IS
	SIGNAL PC, PC_plus_4 	 : STD_LOGIC_VECTOR( 9 DOWNTO 0 );
	SIGNAL next_PC, next_PC_c, next_PC_b, Mem_Addr : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL add_quartus	: STD_LOGIC_VECTOR (9 DOWNTO 0);
BEGIN

	add_quartus <= Mem_Addr & "00";
						--ROM for Instruction Memory
	simulation: if (modelsim = 1) generate
		inst_memory: altsyncram
		GENERIC MAP (
			operation_mode => "ROM",
			width_a => 32,
			widthad_a => 8,
			lpm_type => "altsyncram",
			outdata_reg_a => "UNREGISTERED",
			init_file => "C:\Program Files\Notepad++\CPU LABS\project\ModelSim\L1_Caches\big_test\program.hex",
			intended_device_family => "Cyclone"
		)
		PORT MAP (
			clock0     => clock,
			address_a 	=> Mem_Addr, 
			q_a 			=> Instruction );
	end generate;
	
	quartus: if (modelsim = 0) generate
		inst_memory: altsyncram
		GENERIC MAP (
			operation_mode => "ROM",
			width_a => 32,
			widthad_a => 10,
			
			numwords_a => 1024,
			lpm_hint => "ENABLE_RUNTIME_MOD = YES,INSTANCE_NAME = ITCM",
			
			lpm_type => "altsyncram",
			outdata_reg_a => "UNREGISTERED",
			init_file => "C:\Program Files\Notepad++\CPU LABS\project\ModelSim\L1_Caches\big_test\program.hex",
			intended_device_family => "Cyclone"
		)
		PORT MAP (
			clock0     => clock,
			address_a 	=> add_quartus, 
			q_a 			=> Instruction );
	end generate;
	
					-- Instructions always start on word address - not byte
		PC(1 DOWNTO 0) <= "00";
					-- copy output signals - allows read inside module
		PC_out 			<= PC;
		PC_plus_4_out 	<= PC_plus_4;
						-- send address to inst. memory address register
		Mem_Addr <= Next_PC;
						-- Adder to increment PC by 4        
      	PC_plus_4( 9 DOWNTO 2 )  <= PC( 9 DOWNTO 2 ) WHEN PC_noChange = '1' ELSE
									PC( 9 DOWNTO 2 ) + 1;
       	PC_plus_4( 1 DOWNTO 0 )  <= "00";
						-- Mux to select Branch Address or PC + 4        
		next_PC_c  <= X"00" WHEN Reset = '1' 							 
					ELSE Add_result  WHEN (((Branch(0) ='1') AND (Zero = '1')) OR ( (Branch(1) = '1') AND (Zero = '0')))  
					ELSE PC_plus_4( 9 DOWNTO 2 );
					
					--junmp,jal
		
		next_PC_b	<= next_PC_c WHEN Jump = '0' ELSE
						JumpAddr WHEN Jump = '1' ;
		
		next_PC		<=  ISR_add					   WHEN ISR_branch = '1' ELSE
						next_PC_b 				   WHEN JumpReg ='0' ELSE
						read_data_1 ( 9 DOWNTO 2 ) WHEN	JumpReg ='1' ;
	PROCESS
		BEGIN
			WAIT UNTIL ( clock'EVENT ) AND ( clock = '1' );
			IF reset = '1' THEN
				   PC( 9 DOWNTO 2) <= "00000000" ; 
			ELSE 
				   PC( 9 DOWNTO 2 ) <= next_PC;
			END IF;
	END PROCESS;
END behavior;


