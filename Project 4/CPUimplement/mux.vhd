library ieee;
use IEEE.std_logic_1164.all;

entity mux is
port(
	a : in std_logic_vector(31 downto 0);
	b : in std_logic_vector(31 downto 0);
	sel : in std_logic;
	output : out std_logic_vector(31 downto 0));
end mux;

architecture mux_architecture of mux is
-- 2 to 1 mux 
-- if sel is 1 then go with a else with b
	begin 
		output <= a when (sel = '1') else b;
	end mux_architecture; 
