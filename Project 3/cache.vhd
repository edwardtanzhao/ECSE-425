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
	--the states we have to consider are
	--1. just starting the cache
	--2. reading from cache
	--3. writing to cache
	--4. read from memory
	--5. write to memory
	--6. write from memory
	--7. waiting for response from memory

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
				current_state <= start;
		--if clock signal is 1 and just recently changed to 1
			elsif (clock = '1' and clock'event) then
				current_state <= next_state;
			end if;
	end process

	--process to know when to read, write, evict or overwrite, the main FSM
	process (s_read, s_write, m_waitrequest, state)

		begin
		--creating a skeleton for the states that we have to consider
			case current_state is
	
				when start => 
					--if we are not reading or writing anything, send back a s_waitrequest
					s_waitrequest <= '1';	
					--now check if we need to read or write;
					if s_read = '1' then
						next_state <= r;
					elsif s_write = '1' then
						next_state <= w;
					else 
						next_state <= start;		
					end if;
				
				when r => ;
	
				when w => ;
			
				when r_memread => ;
			
				when r_memwrite => ;
	
				when r_memwait -> ;
	
				when w_memwrite => ;
	
			end case;
			

		end process;

end arch;
