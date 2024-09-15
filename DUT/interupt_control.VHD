		-- intControl component
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY intControl IS
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

END intControl;

ARCHITECTURE behavior OF intControl IS

	SIGNAL add_selector					: STD_LOGIC_VECTOR (2 DOWNTO 0);
	SIGNAL IE  							: STD_LOGIC_VECTOR (7 DOWNTO 0);
	SIGNAL IFG, IFGtemp					: STD_LOGIC_VECTOR (7 DOWNTO 0);
	SIGNAL TYPEout, TYPE_temp			: STD_LOGIC_VECTOR (7 DOWNTO 0);
	SIGNAL clearIRQ			 			: STD_LOGIC_VECTOR (7 DOWNTO 0);
	SIGNAL IRQimidi  					: STD_LOGIC_VECTOR (7 DOWNTO 0);
	
	SIGNAL dataIn  						: STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL BDP_intCON_EN				: STD_LOGIC;
	SIGNAL dataFromBus_intCON			: STD_LOGIC_VECTOR (31 DOWNTO 0);
	
	SIGNAL reset1, reset2 				: STD_LOGIC ;
	SIGNAL reset, clearRST				: STD_LOGIC;
	
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
					-- adres is 5 bit of ADDERESS: bits 11, 5, 4, 3, 2, 1, 0. 
				-- IN THE MCU THAT ACT LIKE A TOP WE DO THE CONNECT BETWEEN addres TO THE ADDRESS
	with addres select
		add_selector <= "001" when "1111100", 		--   IE addres is 0x83C = 1000 0011 1100
						"010" when "1111101",			--  IFG addres is 0x83D = 1000 0011 1101
						"100" when "1111110",			-- TYPE addres is 0x83E = 1000 0011 1110
						"000" when others;


				-- here we difine interupt signal that will connact to MIPS processor
				-- this signal difine the interupt we recived from all the components that can give us interupts
				-- if this signal is '1' than the core will stop until we will finish to handel the interupt
				-- NOTE: also this signal controld by the GIE --> 0th bit of $k0 --> register(26)[0]
	interupt_signal <= ((GIE and (IFG(0) or IFG(1) or IFG(2) or IFG(3) or IFG(4) or IFG(5) or IFG(6) or IFG(7))) or reset2);
	
	
				-- the type of the interupt choose by the IFG
				-- this is the type of interupt that is in use.
	TYPE_temp <= "00000000" when reset2 = '1' else      -- RESET
				 "00000100" when IFG(0) = '1' else 		-- error uart
				 "00001000" when IFG(0) = '1' else		-- RX
				 "00001100" when IFG(1) = '1' else		-- TX
				 "00010000" when IFG(2) = '1' else		-- TIMER
				 "00010100" when IFG(3) = '1' else		-- KEY 1
				 "00011000" when IFG(4) = '1' else		-- KEY 2
				 "00011100" when IFG(5) = '1' else		-- KEY 3
				 "00100000" when IFG(6) = '1' else		-- DIVIDER
				 "00100100" when IFG(7) = '1' else		-- EXTRA
				 "00000000";
	
			-- in which time we sould clear the interupts??
				-- there are several seqences:
				
					-- THIS CASE IS TO CLEAR THE IRQ BY THE USER
					-- 1. adres is 11101 --> IFG, and MemWrite = '1'
					-- 	  to choose which one we need to clear we will use the adress that we get from the dataFromBus_intCON
					-- 	  in this case we to write the IFG register, if we wirte for example to timer IFG we want to clear the 
					--    IRQ --> IRQ = '0'
					
					-- THIS CASE IS TO CLEAR THE IRQ BY THE HARDWARE
					-- 2. as we know when interupts happends we "talk" to the MIPS core.
					-- 	  the core will send as acknoleg signal to say 2 options:
					--													a) "hi, im aware to the interupts" --> '0'
					--													b) "oh, there is no inturepts that im aware of" --> '1'
					--    so if in ack = '0' and we know the TYPE of the interupt we can clear the IRQ
					
					-- timer
	clearIRQ(2) <= '1' when ((add_selector(1) = '1' and MemWrite = '1' and dataFromBus_intCON(2) = '0') or ( TYPEout(7 DOWNTO 2) = "000100" AND INT_ACK = '0')) else '0';
	
					-- divider
	clearIRQ(6) <= '1' when ((add_selector(1) = '1' and MemWrite = '1' and dataFromBus_intCON(6) = '0') or ( TYPEout(7 DOWNTO 2) = "010000" AND INT_ACK = '0')) else '0';
	
	clearIRQ(0) <= '1' when ((add_selector(1) = '1' and MemWrite = '1' and dataFromBus_intCON(0) = '0') or ( (TYPEout(7 DOWNTO 2) = "000001" or TYPEout(7 DOWNTO 2) = "000010") AND INT_ACK = '0')) else '0';
	
					-- divider
	clearIRQ(1) <= '1' when ((add_selector(1) = '1' and MemWrite = '1' and dataFromBus_intCON(1) = '0') or ( TYPEout(7 DOWNTO 2) = "010000" AND INT_ACK = '0')) else '0';
	
					-- key1
	clearIRQ(3) <= '1' when (add_selector(1) = '1' and MemWrite = '1' and dataFromBus_intCON(3) = '0') else '0';
					-- key2
	clearIRQ(4) <= '1' when (add_selector(1) = '1' and MemWrite = '1' and dataFromBus_intCON(4) = '0') else '0';
					-- key3
	clearIRQ(5) <= '1' when (add_selector(1) = '1' and MemWrite = '1' and dataFromBus_intCON(5) = '0') else '0';
	clearIRQ(7) <= '1' when (add_selector(1) = '1' and MemWrite = '1' and dataFromBus_intCON(7) = '0') else '0'; 
	
	
	IFGtemp <= IRQimidi and IE;

----------------------------------------------------------------------------------------------------
			-- reset: we get our reset from key0 --> RST
	process (reset, RST, clearRST)
	BEGIN
		if clearRST = '1' then
			reset1 <= '0';
		elsif ((RST'event) and (RST = '1')) then
			reset1 <= '1';
		end if;
	end process;
	
			-- IFG
	process (clock, reset, reset1)
	begin
		if ((clock'event) and (clock = '1')) then
			reset2 <= reset1;
			if reset = '1' then
				IFG <= X"00";
			elsif (add_selector(1) = '1' AND MemWrite = '1') then
				IFG <= dataFromBus_intCON( 7 DOWNTO 0);
			else
				IFG <= IFGtemp;
			end if;
		end if;
	end process;
	
	clearRST 		<=  '1' when reset2 = '1' else '0';   	
	reset 			<=  '1' when reset1 = '1' else '0';		-- RST = '1' --> reset1 = '1' --> RESET EVERYTHING
	reset_perfrial	<=  reset;

			-- IE
	process (clock, reset)
	begin
		if reset = '1' then
			IE <= X"00";
		elsif ((clock'event) and (clock = '1')) then
			if (add_selector(0) = '1' and MemWrite = '1') then
				IE <= dataFromBus_intCON( 7 DOWNTO 0);
			end if;
		end if;
	end process;

			-- TYPE
	process (clock, reset)
	begin
		if reset = '1' then
			TYPEout <= X"00";
		elsif ((clock'event) and (clock = '1')) then
			TYPEout <= TYPE_temp;
		end if;
	end process;	
----------------------------------------------------------------------------------------------------

			-- we want to read the data only when we do sw instruction --> MemWrite = '1'
			-- IRQ - interupt request
					-- the IRQ is geting the btifg, the divifg and the 3 push buttens
					-- push butten 0 aka key0 is the RST input signal
			
					-- RX
	process (reset, IRQ(0), clearIRQ(0)) 
	begin
		if (reset = '1' OR clearIRQ(0) = '1') then
			IRQimidi(0) <= '0';
		elsif ((IRQ(0)'event) and ( IRQ(0) = '1')) then
			IRQimidi(0) <= '1';
		end if;
	end process;

					-- TX
	process (reset, IRQ(1), clearIRQ(1)) 
	begin
		if (reset = '1' OR clearIRQ(1) = '1') then
			IRQimidi(1) <= '0';
		elsif ((IRQ(1)'event) and ( IRQ(1) = '1')) then
			IRQimidi(1) <= '1';
		end if;
	end process;

					-- TIMER
	process (reset, IRQ(2), clearIRQ(2)) 
	begin
		if (reset = '1' OR clearIRQ(2) = '1') then
			IRQimidi(2) <= '0';
		elsif ((IRQ(2)'event) and ( IRQ(2) = '1')) then
			IRQimidi(2) <= '1';
		end if;
	end process;

					-- key 1 
	process (reset, IRQ(3), clearIRQ(3)) 
	begin
		if (reset = '1' OR clearIRQ(3) = '1') then
			IRQimidi(3) <= '0';
		elsif ((IRQ(3)'event) and ( IRQ(3) = '1')) then
			IRQimidi(3) <= '1';
		end if;
	end process;

					-- key 2
	process (reset, IRQ(4), clearIRQ(4)) 
	begin
		if (reset = '1' OR clearIRQ(4) = '1') then
			IRQimidi(4) <= '0';
		elsif ((IRQ(4)'event) and ( IRQ(4) = '1')) then
			IRQimidi(4) <= '1';
		end if;
	end process;

					-- key 3
	process (reset, IRQ(5), clearIRQ(5)) 
	begin
		if (reset = '1' OR clearIRQ(5) = '1') then
			IRQimidi(5) <= '0';
		elsif ((IRQ(5)'event) and ( IRQ(5) = '1')) then
			IRQimidi(5) <= '1';
		end if;
	end process;

					-- DIVIDER
	process (reset, IRQ(6), clearIRQ(6)) 
	begin
		if (reset = '1' OR clearIRQ(6) = '1') then
			IRQimidi(6) <= '0';
		elsif ((IRQ(6)'event) and ( IRQ(6) = '1')) then
			IRQimidi(6) <= '1';
		end if;
	end process;

					-- extra
	process (reset, IRQ(7), clearIRQ(7)) 
	begin
		if (reset = '1' OR clearIRQ(7) = '1') then
			IRQimidi(7) <= '0';
		elsif ((IRQ(7)'event) and ( IRQ(7) = '1')) then
			IRQimidi(7) <= '1';
		end if;
	end process;	
	

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------	
	BDP_Timer: BidirPin
	generic map (32)
	PORT MAP (	Dout 	=> dataIn,
				en 		=> BDP_intCON_EN,
				Din 	=> dataFromBus_intCON,
				IOpin 	=> data_buf );
				
	BDP_intCON_EN <= '1' when (INT_ACK = '0' or (MemRead = '1' AND (add_selector(0) = '1' or add_selector(1) = '1' or add_selector(2) = '1'))) else '0';
	
	dataIn <= X"000000" & IE when ( add_selector(0) = '1' and MemRead = '1') else
			  X"000000" & IFG when ( add_selector(1) = '1' and MemRead = '1') else
			  X"000000" & TYPEout when (( add_selector(0) = '1' and MemRead = '1') OR INT_ACK = '0') else
			  (others => '0');
	

					   
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

END behavior;


