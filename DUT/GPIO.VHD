		-- GPIO component
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY GPIO IS
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

END GPIO;

ARCHITECTURE behavior OF GPIO IS

	SIGNAL  LEDs_temp 							: STD_LOGIC_VECTOR (7 DOWNTO 0);
	SIGNAL  portHX0_temp 						: STD_LOGIC_VECTOR (7 DOWNTO 0);
	SIGNAL  portHX1_temp 						: STD_LOGIC_VECTOR (7 DOWNTO 0);
	SIGNAL  portHX2_temp 						: STD_LOGIC_VECTOR (7 DOWNTO 0);
	SIGNAL  portHX3_temp 						: STD_LOGIC_VECTOR (7 DOWNTO 0);
	SIGNAL  portHX4_temp 						: STD_LOGIC_VECTOR (7 DOWNTO 0);
	SIGNAL  portHX5_temp 						: STD_LOGIC_VECTOR (7 DOWNTO 0);
	
	SIGNAL	add_selector						: STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL 	dataFromBus_gpio					: STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL  dataInSw							: STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL 	BDP_gpio_EN							: STD_LOGIC;
	SIGNAL  hex0_en, hex1_en, hex2_en, hex3_en, hex4_en, hex5_en : STD_LOGIC;

	
	COMPONENT BidirPin is
		generic( width: integer:=16 );
		port(   Dout: 	in 		std_logic_vector(width-1 downto 0);
				en:		in 		std_logic;
				Din:	out		std_logic_vector(width-1 downto 0);
				IOpin: 	inout 	std_logic_vector(width-1 downto 0)
		);
	END COMPONENT;

BEGIN           
	

---------------------------------------- I/O address -----------------------------------------------
----------------------------------------------------------------------------------------------------	
					-- adres is 5 bit of ADDERESS: bits 11, 4, 3, 2. 
				-- IN THE MCU THAT ACT LIKE A TOP WE DO THE CONNECT BETWEEN addres TO THE ADDRESS
	with addres(4 DOWNTO 1) select
		add_selector <= "0000001" when "1000", 		-- LEDS addres is 0x800 = 1000 0000 0000
						"0000010" when "1001",		-- HEX0 addres is 0x804 = 1000 0000 0100 
						--"0000100" when "1001",		-- HEX1 addres is 0x805 = 1000 0000 0101
						"0000100" when "1010",		-- HEX2 addres is 0x808 = 1000 0000 1000
						--"0010000" when "1010",		-- HEX3 addres is 0x809 = 1000 0000 1001
						"0001000" when "1011",		-- HEX4 addres is 0x80C = 1000 0000 1100
						--"1000000" when "1011",		-- HEX5 addres is 0x80D = 1000 0000 1101
						"0010000" when "1100",		--  SW  addres is 0x810 = 1000 0001 0000
						"0000000" when others;
	hex0_en <= MemWrite and add_selector(1) and (not addres(0));
	hex1_en <= MemWrite and add_selector(1) and ( addres(0));	
	hex2_en <= MemWrite and add_selector(2) and (not addres(0));	
	hex3_en <= MemWrite and add_selector(2) and ( addres(0));	
	hex4_en <= MemWrite and add_selector(3) and (not addres(0));	
	hex5_en <= MemWrite and add_selector(3) and (addres(0));	
	

----------------------------------------------------------------------------------------------------
			-- we want to read the data only when we do sw instruction --> MemWrite = '1'
			-- add_defrential is the 5th bit of the address --> when we want to do somthing in the GPIO
			-- address, always this bit will be 0
			
					-- LED'S
	process (reset, clock) 
	begin
		if reset = '1' then
			LEDs_temp <= X"00" ;							
		elsif (clock'event) and ( clock = '1') then
			if (MemWrite = '1' and add_selector(0) = '1' and add_defrential = '0') then
				LEDs_temp <= dataFromBus_gpio(7 DOWNTO 0);
			end if;
		end if;
	end process;
	
					-- HEX0
	process (reset, clock) 
	begin
		if reset = '1' then
			portHX0_temp <= X"00" ;							
		elsif (clock'event) and ( clock = '1') then
			if (hex0_en = '1' and add_defrential = '0' ) then
				portHX0_temp <= dataFromBus_gpio(7 DOWNTO 0);
			end if;
		end if;
	end process;
	
					-- HEX1
	process (reset, clock) 
	begin
		if reset = '1' then
			portHX1_temp <= X"00" ;							
		elsif (clock'event) and ( clock = '1') then
			if (hex1_en = '1' and add_defrential = '0' ) then
				portHX1_temp <= dataFromBus_gpio(7 DOWNTO 0);
			end if;
		end if;
	end process;
	
					-- HEX2
	process (reset, clock) 
	begin
		if reset = '1' then
			portHX2_temp <= X"00" ;							
		elsif (clock'event) and ( clock = '1') then
			if (hex2_en = '1' and add_defrential = '0' ) then
				portHX2_temp <= dataFromBus_gpio(7 DOWNTO 0);
			end if;
		end if;
	end process;
	
					-- HEX3
	process (reset, clock) 
	begin
		if reset = '1' then
			portHX3_temp <= X"00" ;							
		elsif (clock'event) and ( clock = '1') then
			if (hex3_en = '1' and add_defrential = '0') then
				portHX3_temp <= dataFromBus_gpio(7 DOWNTO 0);
			end if;
		end if;
	end process;
	
					-- HEX4
	process (reset, clock) 
	begin
		if reset = '1' then
			portHX4_temp <= X"00" ;							
		elsif (clock'event) and ( clock = '1') then
			if (hex4_en = '1' and add_defrential = '0') then
				portHX4_temp <= dataFromBus_gpio(7 DOWNTO 0);
			end if;
		end if;
	end process;
	
					-- HEX5
	process (reset, clock) 
	begin
		if reset = '1' then
			portHX5_temp <= X"00" ;							
		elsif (clock'event) and ( clock = '1') then
			if (hex5_en = '1' and add_defrential = '0') then
				portHX5_temp <= dataFromBus_gpio(7 DOWNTO 0);
			end if;
		end if;
	end process;	

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------	
	BDP_Timer: BidirPin
	generic map (32)
	PORT MAP (	Dout 	=> dataInSw,
				en 		=> BDP_gpio_EN,
				Din 	=> dataFromBus_gpio,
				IOpin 	=> data_buf);
				
	BDP_gpio_EN <= '1' when (MemRead = '1' AND add_selector(4) = '1') else '0';
	dataInSw <= X"000000" & switches;
	
	LEDs <= LEDs_temp;
	portHX0 <= portHX0_temp;
	portHX1 <= portHX1_temp;
	portHX2 <= portHX2_temp;
	portHX3 <= portHX3_temp;
	portHX4 <= portHX4_temp;
	portHX5 <= portHX5_temp;
					   
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

END behavior;


