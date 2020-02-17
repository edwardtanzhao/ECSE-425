library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_tb is
end cache_tb;

architecture behavior of cache_tb is

component cache is
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
end component;

component memory is 
GENERIC(
    ram_size : INTEGER := 32768;
    mem_delay : time := 10 ns;
    clock_period : time := 1 ns
);
PORT (
    clock: IN STD_LOGIC;
    writedata: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
    address: IN INTEGER RANGE 0 TO ram_size-1;
    memwrite: IN STD_LOGIC;
    memread: IN STD_LOGIC;
    readdata: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
    waitrequest: OUT STD_LOGIC
);
end component;
	
-- test signals 
signal reset : std_logic := '0';
signal clk : std_logic := '0';
constant clk_period : time := 1 ns;

signal s_addr : std_logic_vector (31 downto 0);
signal s_read : std_logic;
signal s_readdata : std_logic_vector (31 downto 0);
signal s_write : std_logic;
signal s_writedata : std_logic_vector (31 downto 0);
signal s_waitrequest : std_logic;

signal m_addr : integer range 0 to 2147483647;
signal m_read : std_logic;
signal m_readdata : std_logic_vector (7 downto 0);
signal m_write : std_logic;
signal m_writedata : std_logic_vector (7 downto 0);
signal m_waitrequest : std_logic; 

begin

-- Connect the components which we instantiated above to their
-- respective signals.
dut: cache 
port map(
    clock => clk,
    reset => reset,

    s_addr => s_addr,
    s_read => s_read,
    s_readdata => s_readdata,
    s_write => s_write,
    s_writedata => s_writedata,
    s_waitrequest => s_waitrequest,

    m_addr => m_addr,
    m_read => m_read,
    m_readdata => m_readdata,
    m_write => m_write,
    m_writedata => m_writedata,
    m_waitrequest => m_waitrequest
);

MEM : memory
port map (
    clock => clk,
    writedata => m_writedata,
    address => m_addr,
    memwrite => m_write,
    memread => m_read,
    readdata => m_readdata,
    waitrequest => m_waitrequest
);
				

clk_process : process
begin
  clk <= '0';
  wait for clk_period/2;
  clk <= '1';
  wait for clk_period/2;
end process;

test_process : process
begin
	s_read <= '0';                                                       
	s_write <= '0';    
	
	-- invalid write miss clean
	s_addr <= x"00010001";                         
	s_write <= '1';                                                      
	s_writedata <= x"00010000";                                          
	wait until rising_edge(s_waitrequest);   

	wait for clk_period; 

	-- valid read hit clean (done several times to validate write behaviour)                          
	s_read <= '1';                                                       
	s_write <= '0';                                                      
	wait until rising_edge(s_waitrequest);                               
	assert s_readdata = x"00010000" report "failed first write or read" severity error;
	s_read <= '0';                                                       
	s_write <= '0';                                                      
	
	wait for clk_period;
	
	-- invalid read miss clean
	s_addr <=  x"F001A001";                        
	s_read <= '1';                                                       
	s_write <= '0';                                                      
	wait until rising_edge(s_waitrequest);                               
	s_read <= '0';                                                       
	s_write <= '0';     
	
	wait for clk_period;

	-- valid read miss clean 
	s_addr <=  x"0001B001";	
	s_read <= '1';                                                       
	s_write <= '0';                                                      
	wait until rising_edge(s_waitrequest);                               
	s_addr <=  x"0001B001";	
	s_read <= '1';                                                       
	s_write <= '0';                                                      
	wait until rising_edge(s_waitrequest);                               
	s_read <= '0';                                                       
	s_write <= '0';

	wait for clk_period;

	-- valid write hit clean 
	s_addr <= x"0001D001";	
	s_read <= '1';                                                       
	s_write <= '0';                                                      
	wait until rising_edge(s_waitrequest);                               
	s_write <= '1';
	s_read <= '0';
	s_writedata <= x"00000003";
	wait until rising_edge(s_waitrequest);                               
	s_write <= '0';
	s_read <= '0';
	wait for clk_period;
	s_read <= '1';                                                       
	s_write <= '0';                                                      
	wait until rising_edge(s_waitrequest);                               
	assert s_readdata = x"00000003" report "failed valid write clean hit or read" severity error;
	s_read <= '0';                                                       
	s_write <= '0';

	wait for clk_period;
		
	--valid write miss clean
	s_addr <= x"00010D01";		
	s_read <= '1';                                                       
	s_write <= '0';                                                      
	wait until rising_edge(s_waitrequest);                               
	s_addr <= x"00010E01";	
	s_write <= '1';
	s_read <= '0';
	s_writedata <= x"0000000D";
	wait until rising_edge(s_waitrequest);                               
	s_write <= '0';
	s_read <= '0';
	wait for clk_period;
	s_read <= '1';                                                       
	s_write <= '0';                                                      
	wait until rising_edge(s_waitrequest);                               
	assert s_readdata = x"0000000D" report "failed valid write clean hit or read" severity error;
	s_read <= '0';                                                       
	s_write <= '0';
	
	wait for clk_period;
	
	-- valid write hit dirty 
	s_addr <= x"00010D01";	
	s_write <= '1';
	s_read <= '0';
	s_writedata <= x"00000001";
	wait until rising_edge(s_waitrequest);                               
	s_addr <= x"00010D01";	
	s_write <='0';
	wait for clk_period;
	s_write <= '1';
	s_read <= '0';
	s_writedata <= x"00000002";
	wait until rising_edge(s_waitrequest);                               
	s_write <= '0';
	s_read <= '0';
	
	wait for clk_period;
	
	-- valid write miss dirty
	WAIT FOR clk_period;
	s_addr <= x"00010D01";
	s_write <= '1';
	s_writedata <= x"04030201";
	wait until rising_edge(s_waitrequest);
	s_addr <= x"00010F01";
	s_write <= '1';
	s_writedata <= x"000000BA"; 	
	wait until rising_edge(s_waitrequest);
	s_read <= '1';
	s_write <= '0';
	wait until rising_edge(s_waitrequest);
	assert s_readdata = x"000000BA" report "failed to write dirty miss" severity error;
	s_read <= '0';
	s_write <= '0';

	wait;

end process;
	
end;
