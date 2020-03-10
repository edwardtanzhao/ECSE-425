library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity add is
port (
	four : in integer;
	pcOutput : in std_logic_vector(31 downto 0);
	sum : out std_logic_vector(31 downto 0)
);
end add;

archetiecture add_architecture of add is

signal temp : integer;

--add four to the output from PC and send over to mux after
begin 
	temp <= to_integer(unsigned(pcOutput)) + four;
	sum <= std_logic_vector(to_unsigned(add, sum'length));

end adder_arch;
