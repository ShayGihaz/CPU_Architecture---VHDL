library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

--------------------------------------------------------------
entity Divider_Datapath is

port(	Dividend 			: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		Divisor				: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		Divisor_in 			: IN 	STD_LOGIC;							--indicate Divisor presence
		Residue				: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		Quotient 			: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		DIVIFG				: OUT 	STD_LOGIC;							--complete flag
		DIVCLK, Reset, Ena	: IN 	STD_LOGIC );

end Divider_Datapath;
--------------------------------------------------------------
architecture behav of Divider_Datapath is

    COMPONENT  Divider_Control
   	     PORT(		Divisor_in 			: IN 	STD_LOGIC;
					Divisor				: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
					initial 			: OUT 	STD_LOGIC;
					DONE 				: OUT 	STD_LOGIC;
					LAST 	    		: OUT 	STD_LOGIC;
					divide_zero			: OUT 	STD_LOGIC;
					DIV_Ena				: OUT 	STD_LOGIC;							--enable the division process
					DIV_rst				: OUT 	STD_LOGIC;							--reset the division process
					DIVCLK, reset,Ena	: IN 	STD_LOGIC );
	END COMPONENT;
	
--------------------------------------------------------
	SIGNAL  initial			:STD_LOGIC;
	SIGNAL  DIV_Ena			:STD_LOGIC;
	SIGNAL  DIV_rst 		:STD_LOGIC;
	SIGNAL  DONE 			:STD_LOGIC;
	SIGNAL  divide_zero 	:STD_LOGIC;
	SIGNAL  LAST 			:STD_LOGIC;
	SIGNAL  Divisor_Reg		:STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL  Dividend_Reg	:STD_LOGIC_VECTOR( 63 DOWNTO 0 );
	SIGNAL  SUB 	    	:STD_LOGIC_VECTOR( 32 DOWNTO 0 );
	SIGNAL  Quotient_Reg	:STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL  Write_Dev_Res	:STD_LOGIC;

	
 begin			 
 
   Control : Divider_Control
	PORT MAP (	Divisor_in  	=> Divisor_in,
				Divisor         => Divisor,
    	    	LAST  	        => LAST,
				DONE  	   		=> DONE,
				initial  	    => initial,
				divide_zero     => divide_zero,
				DIV_Ena 		=> DIV_Ena,
				DIV_rst			=> DIV_rst,
				DIVCLK 			=> DIVCLK,  
				reset 			=> reset,
				Ena				=> Ena);
				
	-- Subtraction Operation: Subtraction between the upper 32 bits of Dividend_Reg and Divisor_Reg
	SUB <= ('0'&dividend_reg(63 downto 32)) - ('0'&Divisor_Reg);
	
	
	------- OUT operation------
	Residue <= dividend_reg(63 downto 32);
	Quotient <= Quotient_Reg;
	DIVIFG <= DONE;

    ----- Divisor_Reg -----
    process(DIVCLK,DIV_rst,DIV_Ena)
	begin
		if (DIV_rst='1') then   ------ reset - all the registers are reset
			Divisor_Reg <= X"00000000";
			
		elsif (DIVCLK'event and DIVCLK='1' and initial = '1') then
			  Divisor_Reg <= Divisor;
		end if;
	end process;
	
	----- dividend_reg -----
	process(DIVCLK,DIV_rst,DIV_Ena)
	variable sll_dividend : STD_LOGIC_VECTOR(63 downto 0);
	begin
		if (DIV_rst='1') then   ------ reset - all the registers are reset
			dividend_reg <= X"0000000000000000";	
		elsif (DIVCLK'event and DIVCLK='1')  then	
			if (initial = '1')  then	
				dividend_reg(63 downto 32) <= X"0000000"&"000"& Dividend(31);
				dividend_reg(31 downto 0) <= Dividend (30 DOWNTO 0) & '0';
			elsif (DIV_Ena = '1')  then	
				sll_dividend := std_logic_vector(shift_left(unsigned(dividend_reg),1)); -- Shift Dividend_Reg left by 1  
				if (SUB(32) = '0')  then -- If SUB is positive, update the upper 31 bits with SUB result	
			        dividend_reg(63 downto 33) <= SUB(30 downto 0);
					dividend_reg(32 downto 0) <= sll_dividend(32 downto 0);
				else -- If SUB is negative, continue shifting without subtraction
				    dividend_reg <=sll_dividend;
				end if;	
				
			-- If in the last cycle and SUB is non-negative, update Dividend_Reg with SUB result
			elsif (LAST = '1')  then
				if (SUB(32) = '0')  then	
					dividend_reg(63 downto 32) <= SUB(31 downto 0);
				end if;	
			--  Division by zero by setting all bits to '1'
			elsif (divide_zero = '1') then 
				dividend_reg <= X"FFFFFFFFFFFFFFFF";	
			end if;
		end if;
	end process;



			----- Quotient_Reg -----
	process(DIVCLK,DIV_rst,DIV_Ena)
	variable sll_quotient : STD_LOGIC_VECTOR(30 downto 0);
	begin
		if (DIV_rst='1') then   ------ reset - all the registers are reset
			Quotient_Reg <= X"00000000";
		elsif (DIVCLK'event and DIVCLK='1' ) then
			if (initial = '1') then
				Quotient_Reg <= X"0000000"& "000" & not SUB(32);
			elsif (DIV_Ena = '1' or LAST = '1')  then
				sll_quotient := Quotient_Reg(30 downto 0);  -- shl of the quot in evey cycle
				Quotient_Reg(0) <= not SUB(32);				-- Update LSB with the inverse of SUB(32)
				Quotient_Reg(31 downto 1) <= sll_quotient;
			elsif (divide_zero = '1') then 
				Quotient_Reg <= X"FFFFFFFF";	
			end if;
		end if;
	end process;	

	
END behav;