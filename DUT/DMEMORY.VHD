						--  Dmemory module (implements the data
						--  memory for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY dmemory IS
	GENERIC ( modelsim: integer := 0);
	PORT(	read_data 			: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        	address 			: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        	write_data 			: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	   		MemRead, Memwrite 	: IN 	STD_LOGIC;
			INT_ACK				: IN	STD_LOGIC;
			add_bus				: IN	STD_LOGIC_VECTOR (7 DOWNTO 0);
            clock,reset			: IN 	STD_LOGIC );
END dmemory;

ARCHITECTURE behavior OF dmemory IS
SIGNAL write_clock 		: STD_LOGIC;
SIGNAL DataMemWrite_en 	: STD_LOGIC;
SIGNAL add_temp			: STD_LOGIC_VECTOR(7 DOWNTO 0);
signal add_quartus		: STD_LOGIC_VECTOR(9 DOWNTO 0);
BEGIN
	simulation: if (modelsim = 1) generate
		data_memory : altsyncram
		GENERIC MAP  (
			operation_mode => "SINGLE_PORT",
			width_a => 32,
			widthad_a => 8,    			-- 0x800/4 = 512 = 2^9
			lpm_type => "altsyncram",
			outdata_reg_a => "UNREGISTERED",
			init_file => "C:\Program Files\Notepad++\CPU LABS\project\ModelSim\L1_Caches\asm_ver1\dmemory.hex",
			intended_device_family => "Cyclone"
		)
		PORT MAP (
			--wren_a => Memwrite,
			wren_a => DataMemWrite_en,
			clock0 => write_clock,
			address_a => add_temp,
			data_a => write_data,
			q_a => read_data	);
	end generate;
	
	quartus: if (modelsim = 0) generate
		data_memory : altsyncram
		GENERIC MAP  (
			operation_mode => "SINGLE_PORT",
			width_a => 32,
			widthad_a => 10,
			
			numwords_a => 1024,
			lpm_hint => "ENABLE_RUNTIME_MOD = YES,INSTANCE_NAME = DTCM",
			
			lpm_type => "altsyncram",
			outdata_reg_a => "UNREGISTERED",
			init_file => "C:\Mac\Home\Downloads\cpu_project\Test_files\SW_QA_ASM_codes\Interrupt_based_IO\test2\DTCM.hex",
			intended_device_family => "Cyclone"
		)
		PORT MAP (
			--wren_a => Memwrite,
			wren_a => DataMemWrite_en,
			clock0 => write_clock,
			address_a => add_quartus,
			data_a => write_data,
			q_a => read_data	);
	end generate;

		
		-- Load memory address register with write clock
		write_clock <= NOT clock;
		
		-- if the adress we want to write to is less then 0x800 and also memwrite is on
		-- only then we can write to the data memory
		DataMemWrite_en <= '1' when (address(31 DOWNTO 11) = X"00000" & B"0" AND Memwrite = '1') else '0';
		add_temp <= address(9 DOWNTO 2) when INT_ACK = '1' else "00" & add_bus(7 DOWNTO 2);
		add_quartus <=  add_temp & "00";
		
		
END behavior;

