library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pc is 
port(
	clock : in std_logic;
	reset : in std_logic;
	enable : in std_logic;
	pc_sel : in std_logic;
	pcInput : in std_logic_vector(31 downto 0);
	pcOutput : out std_logic_vector(31 downto 0));
	--next_pc_out : out std_logic_vector(31 downto 0));
end pc;

architecture pc_architecture of pc is
	signal count : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";

begin 

process (clock, reset, enable)
begin
-- counter starts at zero
-- change output according to the input
-- if the reset is 1 then reset to zero

	if(reset = '1') then
		count <= "00000000000000000000000000000000";
	elsif rising_edge(clock) then 
		if (enable = '1') then
			if (pc_sel = '1') then
				count <= pcInput;
			else
				count <= std_logic_vector(to_unsigned(to_integer(unsigned(count)) + 4, 32));
			end if;
		end if;
	end if;

end process;

pcOutput <= count;

end pc_architecture;
