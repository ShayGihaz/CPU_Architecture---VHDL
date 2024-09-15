				-- Top Level Structural Model for MCU 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

ENTITY MCU IS

	PORT( CLK_in							: IN 	STD_LOGIC; 
		SW								: IN    STD_LOGIC_VECTOR (7 DOWNTO 0);
		-- Output important signals to pins for easy display in Simulator
		PC								: OUT   STD_LOGIC_VECTOR( 9 DOWNTO 0 );
     	Instruction_out					: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		push0, push1, push2, push3		: IN    STD_LOGIC;
		PWM								: OUT   STD_LOGIC;
		LED								: OUT   STD_LOGIC_VECTOR (7 DOWNTO 0);
		HEX0							: OUT   STD_LOGIC_VECTOR (6 DOWNTO 0);
		HEX1							: OUT   STD_LOGIC_VECTOR (6 DOWNTO 0);
		HEX2							: OUT   STD_LOGIC_VECTOR (6 DOWNTO 0);
		HEX3							: OUT   STD_LOGIC_VECTOR (6 DOWNTO 0);
		HEX4							: OUT   STD_LOGIC_VECTOR (6 DOWNTO 0);
		HEX5							: OUT   STD_LOGIC_VECTOR (6 DOWNTO 0));
END 	MCU;

ARCHITECTURE structure OF MCU IS
	
	COMPONENT PLL port(
	     areset		: IN STD_LOGIC  := '0';
		  inclk0		: IN STD_LOGIC  := '0';
		  c0     		: OUT STD_LOGIC ;
		  locked		: OUT STD_LOGIC );
    END COMPONENT;
	 

	COMPONENT MIPS IS
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
			INT_ACK							: OUT STD_LOGIC;
			GIE								: OUT STD_LOGIC;
			interupt_signal					: IN STD_LOGIC );
	END COMPONENT;

	COMPONENT Timer IS
	   PORT( 	
			clock, reset	: IN 	STD_LOGIC;
			addres			: IN 	STD_LOGIC_VECTOR( 4 DOWNTO 0 );
			data_buf		: INOUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			MemRead 		: IN 	STD_LOGIC;
			MemWrite 		: IN 	STD_LOGIC;
			PWM  			: OUT   STD_LOGIC;
			BTIFG			: OUT   STD_LOGIC );
	END COMPONENT;
	
	
	COMPONENT GPIO IS
	   PORT( 	
			clock, reset	: IN 	STD_LOGIC;
			addres			: IN 	STD_LOGIC_VECTOR( 4 DOWNTO 0 );
			data_buf		: INOUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			add_defrential	: IN	STD_LOGIC;
			MemRead 		: IN 	STD_LOGIC;
			MemWrite 		: IN 	STD_LOGIC;
			switches		: IN 	STD_LOGIC_VECTOR (7 DOWNTO 0);
			LEDs 			: OUT   STD_LOGIC_VECTOR (7 DOWNTO 0);
			portHX0			: OUT   STD_LOGIC_VECTOR (7 DOWNTO 0);
			portHX1			: OUT   STD_LOGIC_VECTOR (7 DOWNTO 0);
			portHX2			: OUT   STD_LOGIC_VECTOR (7 DOWNTO 0);
			portHX3			: OUT   STD_LOGIC_VECTOR (7 DOWNTO 0);
			portHX4			: OUT   STD_LOGIC_VECTOR (7 DOWNTO 0);
			portHX5			: OUT   STD_LOGIC_VECTOR (7 DOWNTO 0) );
	END COMPONENT;
	
	
	COMPONENT intControl IS
	   PORT( 	
			clock			: IN 	STD_LOGIC;
			reset_perfrial	: OUT 	STD_LOGIC;
			addres			: IN 	STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			data_buf		: INOUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			MemRead 		: IN 	STD_LOGIC;
			MemWrite 		: IN 	STD_LOGIC;
			IRQ				: IN	STD_LOGIC_VECTOR (7 DOWNTO 0);
			GIE				: IN 	STD_LOGIC;
			RST				: IN 	STD_LOGIC;
			INT_ACK			: IN	STD_LOGIC;
			interupt_signal	: OUT   STD_LOGIC );
	END COMPONENT;
	
	
	COMPONENT Divider_env IS

		PORT (	DIVIFG											: OUT STD_LOGIC;
				DIVCLK, Reset									: IN  STD_LOGIC;
				
				--MEMORY--
				addres											: IN 	STD_LOGIC_VECTOR( 4 DOWNTO 0 );
				data_buf										: INOUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				MemRead 										: IN 	STD_LOGIC;
				MemWrite 										: IN 	STD_LOGIC);
	END COMPONENT;
	
	
	COMPONENT convComp IS
	  PORT 
	  (  
		  bin_num: IN STD_LOGIC_VECTOR (3 DOWNTO 0); 
		  seven_seg: OUT STD_LOGIC_VECTOR (6 DOWNTO 0)      
	  );
	END COMPONENT;

	
	


					-- declare signals used to connect VHDL components
	SIGNAL MemRead			: STD_LOGIC;
	SIGNAL MemWrite 		: STD_LOGIC;
	SIGNAL reset			: STD_LOGIC;
	
	SIGNAL GPIOadd			: STD_LOGIC_VECTOR (4 DOWNTO 0);
	SIGNAL TMRadd			: STD_LOGIC_VECTOR (4 DOWNTO 0);
	SIGNAL intConAdd		: STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL DIVadd			: STD_LOGIC_VECTOR (4 DOWNTO 0);
	
	
	SIGNAL tempHX0, tempHX1, tempHX2, tempHX3, tempHX4 ,tempHX5		: STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	SIGNAL read_data_1_out 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL read_data_2_out 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL write_data_out		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL ALU_result_out 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Branch_out 			: STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	SIGNAL Regwrite_out 		: STD_LOGIC;
	SIGNAL Zero_out 			: STD_LOGIC; 
	SIGNAL clock				:std_logic;
	
	SIGNAL data_buf			: STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL address_per		: STD_LOGIC_VECTOR (11 DOWNTO 0);
	
	SIGNAL push0t, push1t, push2t, push3t  : STD_LOGIC;
	
	SIGNAL GIE, INT_ACK, interupt_signal : STD_LOGIC;
	SIGNAL BTIFG, DIVIFG			: STD_LOGIC; -- HERE TO ADD THE IFG OF THE DIV

BEGIN
 
  MPS : MIPS
	PORT MAP ( PC 				=> PC,
			   clock 			=> clock,
        	   reset 			=> reset,
			   Instruction_out 	=> Instruction_out,
			   ALU_result_out 	=> ALU_result_out,
			   read_data_1_out 	=> read_data_1_out,
			   read_data_2_out 	=> read_data_2_out,
			   write_data_out  	=> write_data_out,
			   Branch_out 		=> Branch_out,
			   Zero_out 		=> Zero_out,
			   RegWrite_out 	=> Regwrite_out,
			   MemWrite_out 	=> MemWrite,
			   MemRead_out	    => MemRead,		   
			   data_buf			=> data_buf,
			   address_per		=> address_per,
			   INT_ACK			=> INT_ACK,
			   GIE				=> GIE,
			   interupt_signal  => interupt_signal );

   TMR : Timer
   	PORT MAP (	clock 		=> clock,
        		reset 		=> reset,
        		addres 		=> TMRadd,
        		data_buf 	=> data_buf,
				MemRead 	=> MemRead,
				MemWrite 	=> MemWrite,
				PWM 		=> PWM,
				BTIFG 		=> BTIFG );


   GP:   GPIO
	PORT MAP ( 	clock 			=> clock,
        		reset 			=> reset,
				addres			=> GPIOadd,
				data_buf 		=> data_buf,
				add_defrential 	=> address_per(5),
				MemRead 		=> MemRead,
				MemWrite 		=> MemWrite,
				switches 		=> SW,
				LEDs			=> LED,
				portHX0			=> tempHX0,
				portHX1 		=> tempHX1,
                portHX2 		=> tempHX2,
				portHX3 		=> tempHX3,
				portHX4			=> tempHX4,
				portHX5			=> tempHX5	);
				
				
				
   intCon: intControl
	port map ( clock			=> clock,
			   reset_perfrial	=> reset,
			   addres			=> intConAdd,
			   data_buf			=> data_buf,
			   MemRead 			=> MemRead,
			   MemWrite 		=> MemWrite,
			   IRQ(0)			=> '0',
			   IRQ(1)			=> '0',
			   IRQ(2)			=> BTIFG,
			   IRQ(3)			=> push1t,
			   IRQ(4)			=> push2t,
			   IRQ(5)			=> push3t,
			   IRQ(6)			=> DIVIFG,  -- here to put the divider IFG
			   IRQ(7)			=> '0',
			   RST				=> push0t,
			   GIE				=> GIE,
			   INT_ACK			=> INT_ACK,
			   interupt_signal  => interupt_signal );
	
	
   DIV: Divider_env
	port map ( DIVIFG 			=> DIVIFG,
			   DIVCLK			=> clock,
			   Reset			=> reset,
			   addres			=> DIVadd,
			   data_buf			=> data_buf,
			   MemRead			=> MemRead,
			   MemWrite			=> MemWrite );
				
				
				
	push0t <= not(push0);
	push1t <= not(push1);
	push2t <= not(push2);
	push3t <= not(push3);

			-- convertion of the number to seven segment represntation
	pllComp: PLL
	PORT MAP (
	           inclk0	=> CLK_in,
	           c0     => clock);
	            
	
	
	
	HEX0conv: convComp
	PORT MAP (	bin_num 	=> tempHX0(3 DOWNTO 0),
				seven_seg 	=> HEX0);
				
	HEX1conv: convComp
	PORT MAP (	bin_num 	=> tempHX1(3 DOWNTO 0),
				seven_seg 	=> HEX1);
				
	HEX2conv: convComp
	PORT MAP (	bin_num 	=> tempHX2(3 DOWNTO 0),
				seven_seg 	=> HEX2);
				
	HEX3conv: convComp
	PORT MAP (	bin_num 	=> tempHX3(3 DOWNTO 0),
				seven_seg 	=> HEX3);
				
	HEX4conv: convComp
	PORT MAP (	bin_num 	=> tempHX4(3 DOWNTO 0),
				seven_seg 	=> HEX4);
				
	HEX5conv: convComp
	PORT MAP (	bin_num 	=> tempHX5(3 DOWNTO 0),
				seven_seg 	=> HEX5);


				
		
			-- THIS IS THE INPUT ADDRESS TO THE PERIFERIALS
	TMRadd 		<= address_per(11) & address_per(5 DOWNTO 2);
	GPIOadd 	<= address_per(11) & address_per(4 DOWNTO 2) & address_per(0);
	intConAdd 	<= address_per(11) & address_per(5 DOWNTO 0);
	DIVadd		<= address_per(11) & address_per(5 DOWNTO 2);
END structure;

