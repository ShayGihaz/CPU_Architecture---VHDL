LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;


ENTITY Divider_tb IS

END Divider_tb ;
ARCHITECTURE struct OF Divider_tb IS


   -- Internal signal declarations
   SIGNAL DIVCLK :std_logic :='0';
   SIGNAL disable_clk : boolean := FALSE;
   SIGNAL Ena :std_logic :='0';
   SIGNAL reset : std_logic :='0';
   
   
   
   SIGNAL Dividend 	:STD_LOGIC_VECTOR( 31 DOWNTO 0 );
   SIGNAL Divisor 	:STD_LOGIC_VECTOR( 31 DOWNTO 0 );   
   SIGNAL Divisor_in 	:STD_LOGIC;   
   SIGNAL Quotient 	:STD_LOGIC_VECTOR( 31 DOWNTO 0 ); 
   SIGNAL Residue_REG	:STD_LOGIC_VECTOR( 31 DOWNTO 0 ); 
   SIGNAL Quotient_REG 	:STD_LOGIC_VECTOR( 31 DOWNTO 0 ); 
   SIGNAL Residue 	:STD_LOGIC_VECTOR( 31 DOWNTO 0 );
   SIGNAL DIVIFG 	:STD_LOGIC;
	



component Divide_Datapath is
port(	Dividend 	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		Divisor		: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		Divisor_in 	: IN 	STD_LOGIC;
		Residue		: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		Quotient 	: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		DIVIFG		: OUT 	STD_LOGIC;
		DIVCLK, Reset, Ena	: IN 	STD_LOGIC );

end component;



BEGIN

   U_0 : Divide_Datapath
      PORT MAP (
         Dividend    => Dividend,
         Divisor     => Divisor,
         Divisor_in  => Divisor_in,
         Quotient    => Quotient,
		 Residue    => Residue,
         DIVIFG      => DIVIFG,
         DIVCLK         => DIVCLK,
         Reset       => Reset,
         Ena         => Ena
);

  -------dividend  and  divisor---------
	 Dividend <= X"00000009" ; --1
	 Divisor <= X"00000002" ;
	 
 -------------------------------------------	 
  -- CLK PROCESS ---
   clk_proc: PROCESS
   BEGIN
      WHILE NOT disable_clk LOOP
         DIVCLK <= '0', '1' AFTER 50 ns;
         WAIT FOR 100 ns;
      END LOOP;
      WAIT;
   END PROCESS clk_proc;
   disable_clk <= TRUE AFTER 5000 ns;
   
   -- RESET PROCESS ---
   reset_proc: PROCESS
   BEGIN
      reset <= 
         '0',
         '1' AFTER 20 ns,
         '0' AFTER 120 ns;
      WAIT;
    END PROCESS reset_proc;

   -- ENA PROCESS ---
   Ena_proc: PROCESS
   BEGIN
      Ena <= 
         '0',
         '1' AFTER 20 ns;
      WAIT;
    END PROCESS Ena_proc;


   -- RESET PROCESS ---
   Divisor_in_prc: PROCESS
   BEGIN
      Divisor_in <= 
         '0',
         '1' AFTER 180 ns,
		 '0' AFTER 280 ns;
      WAIT;
    END PROCESS Divisor_in_prc;
	
	
	
	-- Quotient_REG---
    process(DIVCLK,reset,Ena)
	begin
		if (reset='1') then   ------ reset - all the registers are reset
			Quotient_REG <= X"00000000";
		elsif (DIVCLK'event and DIVCLK='1' and DIVIFG = '1') then
			  Quotient_REG <= Quotient;
		end if;
	end process;
	
	-- Residue_REG ---
    process(DIVCLK,reset,Ena)
	begin
		if (reset='1') then   ------ reset - all the registers are reset
			Residue_REG <= X"00000000";
		elsif (DIVCLK'event and DIVCLK='1' and DIVIFG = '1') then
			  Residue_REG <= Residue;
		end if;
	end process;
	

END struct;
