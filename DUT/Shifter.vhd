library ieee;
USE ieee.std_logic_1164.all;

entity shifter is
	GENERIC (n : INTEGER := 32;
			 k : INTEGER := 5;
			 m : integer := 16	); -- m=2^(k-1)
	port ( inp: in STD_LOGIC_VECTOR (n-1 downto 0);--input (y vector)
			sel: in STD_LOGIC_VECTOR (n-1 downto 0);--selector (x vector only 3 bits will matter)
			control: in STD_LOGIC;
			res: out STD_LOGIC_VECTOR (n-1 downto 0);
			c_out: OUT STD_LOGIC);
			
end shifter;
--------------------------------------------------------------
architecture shift of shifter is
	type mat is array (k downto 0) of STD_LOGIC_VECTOR (n downto 0);
	signal wires: mat;--this is an array of vectors in which the first vector is the signals entering the firs muxes and the
	                  --last is the signals going out of the muxes while the other vectors are the signals between the muxes
					  --an additional signal has been added in each vector for saving the carry
	
begin

	wires(0)(n) <= '0'; --default carry is 0
	c_out <= wires(k)(n);--cout is the left most bit of the last vector
	L1: for i in 0 to n-1 generate--initialise first vector
		with control select
			wires(0)(i) <= inp(i) when '0',--when shift left the signals enter as is
							inp(n-i-1) when others;--when shift right we revers the order of the bits and making shift left on the reversed order
	end generate;
	
	L2: for i in 0 to n-1 generate--inisialise output
		with control select
			res(i) <= wires(k)(i) when '0',--when shift left we get the result out as is
						wires(k)(n-i-1) when others;--when shift right the result need to be reversed back
	end generate; 			   
	
	L3: for i in 0 to k-1 generate--loop to initialise all other vectors
		L4: for j in 0 to n generate--loop to initialise the signals between the "muxes"
			L5: if (j<2**i) generate--if the signal is index less than 2^i then the signal bit is the output of a mux between 0 and previous line signal
				wires(i+1)(j) <= wires(i)(j) and (not sel(i));--implementation of th mux (when sel is 1 out is 0 and else out is the signal from prev line)
			end generate;
			L6: if (j>=2**i) generate--else the mux imlemented as such that the signal stays the same when sel is 0 and shifted if sel is 1
				wires(i+1)(j) <= (wires(i)(j) and (not sel(i))) or (wires(i)(j-(2**i)) and sel(i));
			end generate;
			
		end generate;
	end generate;
	
end shift;


			
			
	