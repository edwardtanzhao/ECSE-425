library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pc is 
port(
	clk : in std_logic;
	reset : in std_logic;
	pcInput : in std_logic_vector(31 downto 0);
	pcOutput : out std_logic_vector(31 downto 0) := x"00000000");
end pc;

architecture pc_archecture of pc is

begin 

process (clk, reset)
begin
-- counter starts at zero
-- change output according to the input
-- if the reset is 1 then reset to zero

	if(reset = '1') then
		pcOutput <= x"00000000";
	elsif (clk'event and clk = '1') then 
		pcOutput <= pcInput;
	end if;

end prccess;

end pc_architecture;
