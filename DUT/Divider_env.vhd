LIBRARY ieee;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;


ENTITY Divider_env IS

	PORT (	DIVIFG											: OUT STD_LOGIC;
			DIVCLK, Reset										: IN  STD_LOGIC;
			
			--MEMORY--
			addres											: IN 	STD_LOGIC_VECTOR( 4 DOWNTO 0 );
			data_buf											: INOUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			MemRead 											: IN 	STD_LOGIC;
			MemWrite 										: IN 	STD_LOGIC);
END Divider_env;


ARCHITECTURE Behavior OF Divider_env IS
	SIGNAL Dividend 		:STD_LOGIC_VECTOR( 31 DOWNTO 0 );	
	SIGNAL Divisor			:STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Divisor_in 	:STD_LOGIC;	
	SIGNAL Residue			:STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Quotient 		:STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Ena				:STD_LOGIC:= '1';
	 	
	--MEMORY--
	SIGNAL	add_selector					: STD_LOGIC_VECTOR (3 DOWNTO 0);
	SIGNAL 	enable_bus						: STD_LOGIC;
	SIGNAL 	dataFromBus						: STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL 	Divider_registers				: STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL 	IFG_TEMP							: STD_LOGIC;

	
	

	
	COMPONENT BidirPin is
		generic( width: integer:=16 );
		port(   Dout: 	in 		std_logic_vector(width-1 downto 0);
				en:		in 		std_logic;
				Din:	out		std_logic_vector(width-1 downto 0);
				IOpin: 	inout 	std_logic_vector(width-1 downto 0)
		);
	END COMPONENT;
	
	COMPONENT Divider_Datapath is

	port(	
		Dividend 			: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		Divisor				: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		Divisor_in 			: IN 	STD_LOGIC;							--indicate Divisor presence
		Residue				: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		Quotient 			: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		DIVIFG				: OUT 	STD_LOGIC;							--complete flag
		DIVCLK, Reset, Ena	: IN 	STD_LOGIC );

	END COMPONENT;
	
	
    
BEGIN

BidirPin_inst : BidirPin generic map (32) port map (
															Dout  => Divider_registers , 
															en 	  => enable_bus, 
															Din   => dataFromBus, 
															IOpin => data_buf
													);

Divider_inst : 	Divider_Datapath	port map (
															
															Dividend 	=>	Dividend 	,	
															Divisor		=>	Divisor		,
															Divisor_in 	=>	Divisor_in 	,
															Residue		=>	Residue		,
															Quotient 	=>	Quotient 	,
															DIVIFG		=>	IFG_TEMP		,
															DIVCLK		=>	DIVCLK		,
															Reset			=>	Reset			,
															Ena			=>	Ena			
															
													);									
															
															

enable_bus  <= '1' when (MemRead = '1' AND (add_selector(0) = '1' OR add_selector(1) = '1' OR add_selector(2) = '1' OR add_selector(3) = '1' )) else '0';

Divider_registers <=	Dividend when (MemRead = '1' and add_selector(0) = '1') else
							Divisor  when (MemRead = '1' and add_selector(1) = '1') else
							Quotient when (MemRead = '1' and add_selector(2) = '1') else
							Residue  when (MemRead = '1' and add_selector(3) = '1') else
							(others => '0');															
															

----------------------------------------------------------------

	--MEMORY--
	--addres is 5 bit of ADDERESS: bits 11, 5, 4, 3, 2.
	DIVIFG <= IFG_TEMP; --&&
	
	with addres select
		add_selector <= 	"0001" when "11011", 	-- DIVIDEND addres is 0x82C =  1000 0010 1100
								"0010" when "11100",		-- DIVISOR addres is  0x830 =  1000 0011 0000
								"0100" when "11101",		-- QUOITENT addres is 0x834 =  1000 0011 0100
								"1000" when "11110",		-- RESIDUE addres is  0x838 =  1000 0011 1000
								"0000" when others;
						
	---Dividend---
	PROCESS (DIVCLK, Reset) 
	BEGIN
		IF Reset = '1' THEN 
			Dividend <= X"00000000";
		ELSIF (DIVCLK'event) and ( DIVCLK = '1') THEN
			IF (MemWrite = '1' and add_selector = "0001") THEN
				Dividend <= dataFromBus;
			END IF; 
		END IF;
	END PROCESS;
	
	PROCESS (DIVCLK, Reset) 
	BEGIN
		IF Reset = '1' THEN 
			Divisor <= X"00000000";
			--Divisor_in <= '0';--&&
		ELSIF (DIVCLK'event) and ( DIVCLK = '1') THEN
			IF (MemWrite = '1' and add_selector = "0010") THEN
				Divisor <= dataFromBus;
				-- Divisor_in <= '1'; --&&
			END IF;
		END IF;
	END PROCESS;
	
	--Divisor_in--
	PROCESS (DIVCLK, Reset) 
	BEGIN
		IF Reset = '1' THEN 
			Divisor_in <= '0';
		ELSIF (DIVCLK'event) and ( DIVCLK = '1') THEN
			IF (MemWrite = '1' and add_selector = "0010") THEN
				Divisor_in <= '1';
			ELSIF (IFG_TEMP ='1') THEN
				Divisor_in <= '0';
			END IF;
		END IF;
	END PROCESS;
	
	--&&--
	PROCESS (DIVCLK, Reset) 
	BEGIN
		IF Reset = '1' THEN 
			Ena <= '0';
		ELSIF (DIVCLK'event) and ( DIVCLK = '1') THEN
			IF (MemWrite = '1' and (add_selector = "0010" OR add_selector = "0001")) THEN
				Ena <= '1';
			ELSIF ( IFG_TEMP = '1') THEN
				Ena <= '0';
			END IF;
		END IF;
	END PROCESS;
	
	
END Behavior;