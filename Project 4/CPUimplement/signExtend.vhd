library ieee;
use IEEE.std_logic_1164.all;

entity signExtend is
port(
	input : in std_logic_vector(15 downto 0);
	signExt : in std_logic;
	output : out std_logic_vector(31 downto 0));
end signExtend;

architecture signExtend_architecture of signExtend is
	
begin 
	process(input, signExt)
		begin 
		-- if signExt is 1 then copy the most significant bit of the data into positions 31 to 16 
		-- else fill with 0
			if(signExt = '1') then 
				output <= (31 downto 16 => input(15)) & input(15 downto 0);
			else
				output <= (31 downto 16 => '0') & input(15 downto 0);
			end if;
		end process;
end signExtend_architecture;
