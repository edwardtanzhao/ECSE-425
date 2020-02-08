library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
generic(
	ram_size : INTEGER := 32768;
);
port(
	clock : in std_logic;
	reset : in std_logic;
	
	-- Avalon interface --
	s_addr : in std_logic_vector (31 downto 0);
	s_read : in std_logic;
	s_readdata : out std_logic_vector (31 downto 0);
	s_write : in std_logic;
	s_writedata : in std_logic_vector (31 downto 0);
	s_waitrequest : out std_logic; 
    
	m_addr : out integer range 0 to ram_size-1;
	m_read : out std_logic;
	m_readdata : in std_logic_vector (7 downto 0);
	m_write : out std_logic;
	m_writedata : out std_logic_vector (7 downto 0);
	m_waitrequest : in std_logic
);
end cache;

architecture arch of cache is

-- declare signals here

	--address struct: 25 bits tag, 5 bits index, 2 bits offset
	type state_type is (start, r, w, r_memread, r_memwrite, r_memwait, w_memwrite);
	signal current_state : state_type;
	signal next_state : state_type; 

	--Cache: 1 bit for valid, 1 bit for dirty, 25 bits for tag, 128 bit blocks (data) 
	--4096/128 = 32
	type cache_type is array (0 to 31) of std_logic_vector (154 downto 0);
	signal cache2 : cache_type;

begin

-- make circuits here

	--process to reset or continue
	process(clock, reset)
		begin
		--if reset signal was sent, tell FSM to go back to start
			if reset = '1' then
				state <= start;
		--if clock signal is 1 and just recently changed to 1
			elsif (clock = '1' and clock'event) then
				state <= next_state;
			end if;
	end process

	--process to know when to read, write, evict or overwrite, the main FSM
	process (s_read, s_write, m_waitrequest, state)

		begin

		end process;

end arch;
