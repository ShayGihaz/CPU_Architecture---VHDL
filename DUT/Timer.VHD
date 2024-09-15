		-- Timer component
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY Timer IS
   PORT( 	
		clock, reset	: IN 	STD_LOGIC;
		addres			: IN 	STD_LOGIC_VECTOR( 4 DOWNTO 0 );
		data_buf		: INOUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		MemRead 		: IN 	STD_LOGIC;
		MemWrite 		: IN 	STD_LOGIC;
		PWM 			: OUT   STD_LOGIC;
		BTIFG			: OUT   STD_LOGIC );

END Timer;

ARCHITECTURE behavior OF Timer IS

	SIGNAL  BTCTL								: STD_LOGIC_VECTOR (7 DOWNTO 0);
	SIGNAL  BTCNT 								: STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL  CCR0, CCR1 							: STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL  CCR0_LTCH, CCR1_LTCH 				: STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL  clk_2, clk_4, clk_8, selected_clk 	: STD_LOGIC;
	SIGNAL	add_selector						: STD_LOGIC_VECTOR (3 DOWNTO 0);
	SIGNAL  PWM_MODE							: STD_LOGIC;
	SIGNAL 	Timer_registers						: STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL 	dataFromBus							: STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL 	BDP_T_EN							: STD_LOGIC;
	SIGNAL  PWM_TEMP							: STD_LOGIC;

	
	COMPONENT BidirPin is
		generic( width: integer:=16 );
		port(   Dout: 	in 		std_logic_vector(width-1 downto 0);
				en:		in 		std_logic;
				Din:	out		std_logic_vector(width-1 downto 0);
				IOpin: 	inout 	std_logic_vector(width-1 downto 0)
		);
	END COMPONENT;

BEGIN           
	

	
-------------------------------------------clocks---------------------------------------------------
----------------------------------------------------------------------------------------------------	
					--BTCTL(4 DOWNTO 3) = BTSSEL
	selected_clk <= clock when BTCTL(4 DOWNTO 3) = "00"			
					else clk_2 when BTCTL(4 DOWNTO 3) = "01"
					else clk_4 when BTCTL(4 DOWNTO 3) = "10"
					else clk_8 when BTCTL(4 DOWNTO 3) = "11"
					else clock;
	
	PWM_MODE <= BTCTL(7);
----------------------------------------------------------------------------------------------------	
					-- clock divider by 2
	process (reset, clock) 
	begin
		if reset = '1' then
			clk_2 <= '0';
		elsif (clock'event) and ( clock = '1') then
			clk_2 <= not clk_2;
		end if;
	end process;
	
					-- clock divider by 2
	process (reset, clk_2) 
	begin
		if reset = '1' then
			clk_4 <= '0';
		elsif (clk_2'event) and ( clk_2 = '1') then
			clk_4 <= not clk_4;
		end if;
	end process;
	
					-- clock divider by 2
	process (reset, clk_4) 
	begin
		if reset = '1' then
			clk_8 <= '0';
		elsif (clk_4'event) and ( clk_4 = '1') then
			clk_8 <= not clk_8;
		end if;
	end process;
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------


-------------------------------------CCRx + CCRx letch----------------------------------------------
----------------------------------------------------------------------------------------------------	
					-- adres is 5 bit of ADDERESS: bits 11, 5, 4, 3, 2.
			-- IN THE MCU THAT ACT LIKE A TOP WE DO THE CONNECT BETWEEN addres TO THE ADDRESS

	with addres select
		add_selector <= "0001" when "10111", 		-- BTCTL addres is 0x81C = 1000 0001 1100     
						"0010" when "11000",		-- BTCNT addres is 0x820 = 1000 0010 0000	  
						"0100" when "11001",		-- CCRO addres is 0x824 =  1000 0010 0100	  
						"1000" when "11010",		-- CCR1 addres is 0x828 =  1000 0010 1000	  
						"0000" when others;			 -- LEDS addres is 0x800 = 1000 0000 0000
													 -- HEX0 addres is 0x804 = 1000 0000 0100
													 -- HEX1 addres is 0x805 = 1000 0000 0101
													 -- HEX2 addres is 0x808 = 1000 0000 1000
													 -- HEX3 addres is 0x809 = 1000 0000 1001
													 -- HEX4 addres is 0x80C = 1000 0000 1100
													 -- HEX5 addres is 0x80D = 1000 0000 1101
													 --  SW  addres is 0x810 = 1000 0001 0000

----------------------------------------------------------------------------------------------------
			-- we want to read the data only when we do sw instruction --> MemWrite = '1'
					-- BTCTL
	process (reset, clock) 
	begin
		if reset = '1' then
			BTCTL <= "00100000" ;							-- BTCTL(5) = BTHOLD
		elsif (clock'event) and ( clock = '1') then
			if (MemWrite = '1' and add_selector = "0001") then
				BTCTL <= dataFromBus(7 DOWNTO 0);
			end if;
		end if;
	end process;

					-- CCR0
	process (reset, clock) 
	begin
		if reset = '1' then
			CCR0 <= X"00000000";
		elsif (clock'event) and ( clock = '1') then
			if (MemWrite = '1' and add_selector = "0100") then
				CCR0 <= dataFromBus;
			end if;
		end if;
	end process;
	
					-- CCR1
	process (reset, clock) 
	begin
		if reset = '1' then
			CCR1 <= X"00000000";
		elsif (clock'event) and ( clock = '1') then
			if (MemWrite = '1' and add_selector = "1000") then
				CCR1 <= dataFromBus;
			end if;
		end if;
	end process;
	
						-- CCR0 LATCH
	process (reset, clock) 
	begin
		if reset = '1' then
			CCR0_LTCH <= X"00000000";
		elsif (clock'event) and ( clock = '1') then
			CCR0_LTCH <= CCR0;
		end if;
	end process;
	
						-- CCR1 LATCH
	process (reset, clock) 
	begin
		if reset = '1' then
			CCR1_LTCH <= X"00000000";
		elsif (clock'event) and ( clock = '1') then
			CCR1_LTCH <= CCR1;
		end if;
	end process;

----------------------------------------------------------------------------------------------------	

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------	
	BDP_Timer: BidirPin
	generic map (32)
	PORT MAP (	Dout 	=> Timer_registers,
				en 		=> BDP_T_EN,
				Din 	=> dataFromBus,
				IOpin 	=> data_buf);
				
				
				-- when we want to "download" back the values of the Timer registers 
				-- we will do a lw instruction to the exact memory location of the register (of the timer)
	BDP_T_EN <= '1' when (MemRead = '1' AND (add_selector(0) = '1' OR add_selector(1) = '1' OR add_selector(2) = '1' OR add_selector(3) = '1' )) else '0';
	
	Timer_registers <= X"000000" & BTCTL when (MemRead = '1' and add_selector(0) = '1') else
					   BTCNT when (MemRead = '1' and add_selector(1) = '1') else
					   CCR0 when (MemRead = '1' and add_selector(2) = '1') else
					   CCR1 when (MemRead = '1' and add_selector(3) = '1') else
					   (others => '0');
					   
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
				-- here we want to choose when the flag is up
				-- BTCNT is the counter of the timer there for it depends on the 
				-- BTCTL(2 DOWNTO 0) = BTIP --> "choose" the value of the counter to rise the flag
	with BTCTL(2 DOWNTO 0) select
	BTIFG <= BTCNT(0) when "000",
			 BTCNT(3) when "001",
			 BTCNT(7) when "010",
			 BTCNT(11) when "011",
			 BTCNT(15) when "100",
			 BTCNT(19) when "101",
			 BTCNT(23) when "110",
			 BTCNT(25) when "111",
			 BTCNT(0) when others;

------------------------------------------Main process----------------------------------------------
----------------------------------------------------------------------------------------------------	

	process (reset, selected_clk, CCR0_LTCH, CCR1_LTCH, PWM_TEMP)
	BEGIN
		if (reset ='1') then
			BTCNT <= X"00000000";
			PWM <= '0';
		elsif (selected_clk'event) and ( selected_clk = '1') then
				-- BTCTL(5) = BTHOLD
			if BTCTL(5) = '0' then
				BTCNT <= BTCNT + 1; 		-- COUNTER++
						-- IF THE EN = 1 AND ALSO COUNTER = LATCH
				if (BTCTL(6) = '1' AND BTCNT(31 DOWNTO 0) = CCR0_LTCH(31 DOWNTO 0)) then
					--PWM_TEMP <= '1';
					if BTCTL(7) = '0' then 		-- BTCTL(7) = BTOUTMD --> the mode of the pwm
						PWM <= '1';
					elsif BTCTL(7) = '1' then 
						PWM <= '0';
					end if;
				elsif (BTCTL(6) = '1' AND BTCNT(31 DOWNTO 0) = CCR1_LTCH(31 DOWNTO 0)) then
					--PWM_TEMP <= '0';
					if BTCTL(7) = '0' then 		-- BTCTL(7) = BTOUTMD --> the mode of the pwm
						PWM <= '0';
					elsif BTCTL(7) = '1' then 
						PWM <= '1';
					end if;
				end if;
			
			elsif BTCTL(5) = '1' and (MemWrite = '1' and add_selector(1) = '1') then
				BTCNT <= dataFromBus;
			end IF;
		end IF;
	end process;
					
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------	

END behavior;


