library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity add is
port (
	clock : in std_logic;
	pcOutput : in std_logic_vector(31 downto 0);
	sum : out std_logic_vector(31 downto 0)
);
end add;

archetiecture add_architecture of add is
--add four to the output from PC and send over to mux after
begin 
	process (clock)
		begin 
			if(rising_edge(clock)) then
				sum <= std_logic_vector(to_unsigned(to_integer(unsigned(pcOutput)) + 4, 32));
			end if;
		end process;
end adder_arch;
