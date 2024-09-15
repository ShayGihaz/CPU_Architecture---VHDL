library ieee;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

--------------------------------------------------------------
entity Divider_Control is

port(	Divisor_in 	: IN 	STD_LOGIC;
		Divisor     : IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		initial 		: OUT 	STD_LOGIC;
		DONE 	: OUT 	STD_LOGIC;
		LAST 	    : OUT 	STD_LOGIC;
		divide_zero	: OUT 	STD_LOGIC;
		DIV_Ena		: OUT 	STD_LOGIC;
		DIV_rst	: OUT 	STD_LOGIC;
		DIVCLK, reset,Ena	: IN 	STD_LOGIC );

end Divider_Control;
--------------------------------------------------------------
architecture behav of Divider_Control is

	SIGNAL  counter	:STD_LOGIC_VECTOR( 5 DOWNTO 0 );
	SIGNAL  pr_state	:STD_LOGIC_VECTOR( 2 DOWNTO 0 ); -- Present state 
	SIGNAL  nx_state	:STD_LOGIC_VECTOR( 2 DOWNTO 0 );
begin	
		 
--------- FSM Mealy Synchronized - Stored Output -------------
  process(DIVCLK,reset,Ena)
  variable count : STD_LOGIC_VECTOR(5 downto 0);
  begin
	if (reset='1') then
		pr_state <= "000";   -- Reset state
		counter <= "000000";
	elsif (DIVCLK'event and DIVCLK='1' and Ena = '1') then
		if nx_state = "100" then
		   counter <= "000000";  -- Reset counter after the last state
		elsif ((nx_state = "001") or (nx_state = "010") or (nx_state = "011")) then
		   count := counter + "000001";
		   counter <= count;
		end if;
		pr_state <= nx_state;  
	end if;	
  end process;
			
			
------ -- FSM Logic Process -------------------------------- 			
			
  process(pr_state,ena,reset,Divisor_in,DIVCLK)
  begin
	case pr_state is
-------------RESET state--------------------------		
		when "000" =>	
			initial <= '0';
			DIV_Ena <= '0';
			DIV_rst <= '1';
			DONE <= '0';
			LAST <= '0';
			divide_zero <= '0';
			nx_state <= "111";  

-------------Division: Working  Process State--------------------------			
		when "001" =>	 
				initial 	<= '0';
				DIV_Ena 	<= '1';
				DIV_rst 	<= '0';
				DONE 		<= '0';
				LAST 		<= '0';  	
				divide_zero <= '0';
			if (counter = "011111") then	
				nx_state <= "010"; -- Move to the last state after 32 cycles
			else
				nx_state <= "001"; -- Stay in the current state 
			end if;
			
	
------------- Last State ("010"): Finalize the division--------------------------			
		when "010" =>	
			initial 	<= '0';
			DIV_Ena 	<= '0';
			DIV_rst 	<= '0';
			DONE 		<= '0';
			LAST 		<= '1';  -- Indicate this is the last step
			divide_zero <= '0';
			nx_state 	<= "100";  -- Move to the Completion State
			
			
------------- Completion State ("100"): Division is done, output the results--------------------------			
		when "100" =>	
			initial <= '0';
			DIV_Ena <= '0';
			DIV_rst <= '0';
			DONE <= '1'; -- Indicate division is complete
			LAST <= '0';
			divide_zero <= '0';
			nx_state <= "111";  
			
			
----------------- Steady State ("111"): Wait for enable and valid divisor --------------------------			
 	 	when others => 
		  	DIV_Ena <= '0';
			DIV_rst <= '0';
			LAST <= '0';
			DONE <= '0';
			if (Ena = '1' and Divisor_in = '1') then
				if (divisor = X"00000000") then
					divide_zero <= '1'; -- Division by zero error
					DONE <= '1';
					nx_state <= "111"; -- Stay in steady state
					initial <= '0';
				else
					divide_zero <= '0';
					
					nx_state <= "001"; -- Start the division process
					initial <= '1';
				end if;
			else
			    nx_state <= "111";  
			end if;
  	END CASE;
  END PROCESS;
END behav;