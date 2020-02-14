library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity cache is
generic(
	ram_size : INTEGER := 32768
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

--address struct: 25 bits tag, 5 bits index, 2 bits offset
--the states we have to consider are
--1. just starting the cache
--2. reading from cache
--3. writing to cache
--4. read from memory
--5. write to memory
--6. write from memory
--7. waiting for response from memory
type MyState_T is (s0, s1, s2, s3, s4, s5, s6);
signal state : MyState_T;
signal state_transition : MyState_T;

--Address struct
--25 bits of tag
--5 bis of index
--2 bits of offset


-- Cache struct [32]
--Cache: 1 bit for valid, 1 bit for dirty, 25 bits for tag, 128 bit blocks (data) 
--4096/128 = 32
type cache_def is array (0 to 31) of std_logic_vector (154 downto 0);
signal cache2 : cache_def;
--1 bit valid
--1 bit dirty
--25 bit tag
--128 bit data

begin
process (clock, reset)
--process to reset or continue
begin
--if reset signal was sent, tell FSM to go back to start
	if reset = '1' then
		state <= s0;
--if clock signal is 1 and just recently changed to 1
	elsif (clock'event and clock = '1') then
		state <= state_transition;
	end if;
end process;	

--process to know when to read, write, evict or overwrite, the main FSM
process (s_read, s_write, m_waitrequest, state)

	--variable for the tag, index, and offset to check for hit
	--variable for the addr that is needed for the read or write
	--the s_addr at input is split into three parts: tag (25 bits), index (5 bits), offset (2 bits)
	--index is integer to use in cache
	variable index : INTEGER;	
	variable Offset : INTEGER := 0;
	variable off : INTEGER := Offset - 1;
	variable count : INTEGER := 0;
	variable addr : std_logic_vector (14 downto 0);
begin
	index := to_integer(unsigned(s_addr(6 downto 2)));
	Offset := to_integer(unsigned(s_addr(1 downto 0))) + 1;
	off :=  Offset - 1;

	case state is
	
		when s0 =>
			--if we are not reading or writing anything, send back a s_waitrequest
			s_waitrequest <= '1';
			--now check if we need to read or write;
			if s_read = '1' then state_transition <= s1;
			elsif s_write = '1' then state_transition <= s2;
			else state_transition <= s0;
			end if;
			
		when s1 =>
			--check to make sure data is there and valid
			if cache2(index)(154) = '1' and cache2(index)(152 downto 128) = s_addr (31 downto 7) then --Hit in the main cache
				s_readdata <= cache2(index)(127 downto 0) ((Offset * 32) -1 downto 32*off);
				s_waitrequest <= '0'; state_transition <= s0;
			elsif cache2(index)(153) = '1' then state_transition <= s4; --Miss with dirty bit enabled
			elsif cache2(index)(153) = '0' or  cache2(index)(153) = 'U' then state_transition <= s3; --Miss with dirty bit set to 0
			else state_transition <= s1;
			end if;
			
		when s4 =>
			--check if we are writing to main memory
			if count < 4 and m_waitrequest = '1' and state_transition /= s3 then addr := cache2(index)(135 downto 128) & s_addr (6 downto 0);
				m_addr <= to_integer(unsigned (addr)) + count ;
				m_write <= '1'; m_read <= '0';
				m_writedata <= cache2(index)(127 downto 0) ((count * 8) + 7 + 32*off downto  (count * 8) + 32*off);
				state_transition <= s4; count := count + 1;
			--once updates to main memory is finished, go to read from memory state
			elsif count = 4 then count := 0;
				state_transition <=s3;
			else	m_write <= '0';
				state_transition <= s4;
			end if;
			
		when s3 =>
			--make sure we are reading the correct parts in the main memory
			if m_waitrequest = '1' then m_addr <= to_integer(unsigned(s_addr (14 downto 0))) + count;
				m_read <= '1'; 	m_write <= '0';	state_transition <= s5;
			else
				state_transition <= s3;
			end if;
			
		when s5 =>
			--increment each time to make sure we are accessing the correct spots in main memory until we have it all
			if count < 3 and m_waitrequest = '0' then cache2(index)(127 downto 0)((count * 8) + 7 + 32*off downto  (count * 8) + 32*off) <= m_readdata;
				count := count + 1; m_read <= '0';
				state_transition <= s3;
			elsif count = 3 and m_waitrequest = '0' then cache2(index)(127 downto 0)((count * 8) + 7 + 32*off downto  (count * 8) + 32*off) <= m_readdata;
				count := count + 1; m_read <= '0';
				state_transition <= s5;
			elsif count = 4 then s_readdata <= cache2(index)(127 downto 0) ((Offset * 32) -1 downto 32*off);
				cache2(index)(152 downto 128) <= s_addr (31 downto 7); 
				cache2(index)(154) <= '1'; 
				cache2(index)(153) <= '0'; 
				m_read <= '0';
				m_write <= '0';
				s_waitrequest <= '0';
				count := 0;
				state_transition <= s0;
			else
				state_transition <= s5;
			end if;
		
		when s2 =>
			--check to make sure we are writing to the correct block or not
			if cache2(index)(153) = '1' and state_transition /= s0 and ( cache2(index)(154) /= '1' or cache2(index)(152 downto 128) /= s_addr (31 downto 7)) then 
				state_transition <= s6;
			else
				--if we are writing to the correct block, start writing and update bookeeping bits
				cache2(index)(153) <= '1'; cache2(index)(154) <= '1'; 
				cache2(index)(127 downto 0)((Offset * 32) -1 downto 32*off) <= s_writedata; 
				cache2(index)(152 downto 128) <= s_addr (31 downto 7); 
				s_waitrequest <= '0';
				state_transition <= s0;
					
				end if;
		
		when s6 =>
			--update the data within the main memory  	
			if count < 4 and m_waitrequest = '1' then 
				addr := cache2(index)(135 downto 128) & s_addr (6 downto 0);
				m_addr <= to_integer(unsigned (addr)) + count ;
				m_write <= '1';
				m_read <= '0';
				m_writedata <= cache2(index)(127 downto 0) ((count * 8) + 7 + 32*off downto  (count * 8) + 32*off);
				count := count + 1;
				state_transition <= s6;
			elsif count = 4 then 
			--once main memory is updated write back to cache
				cache2(index)(127 downto 0)((Offset * 32) -1 downto 32*off) <= s_writedata (31 downto 0);   
				cache2(index)(152 downto 128) <= s_addr (31 downto 7); 
				cache2(index)(153) <= '1'; 
				cache2(index)(154) <= '1'; 
				count := 0;
				s_waitrequest <= '0';
				m_write <= '0';
				state_transition <=s0;
			else
				m_write <= '0';
				state_transition <= s6;
			end if;
	end case;
end process;


end arch;
