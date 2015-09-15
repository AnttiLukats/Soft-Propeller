library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AXIS_WS2811_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Parameters of Axi Slave Bus Interface S_AXIS
		C_S_AXIS_TDATA_WIDTH	: integer	:= 32
	);
	port (
		-- Users to add ports here
        DOUT	        : out std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Ports of Axi Slave Bus Interface S_AXIS
		s_axis_aclk	    : in std_logic;
		s_axis_aresetn	: in std_logic;
		s_axis_tready	: out std_logic;
		s_axis_tdata	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		s_axis_tlast	: in std_logic;
		s_axis_tvalid	: in std_logic
	);
end AXIS_WS2811_v1_0;

architecture arch_imp of AXIS_WS2811_v1_0 is

signal bitcount : std_logic_vector(4 downto 0) := "10111";
signal subbitcount : std_logic_vector(4 downto 0) := "10011";

signal ws_shift_en : std_logic;
signal ready : std_logic;
signal transfer : std_logic;
signal subbitclk_enable : std_logic;

signal ws_shiftreg : std_logic_vector(23 downto 0); 
signal next_dout : std_logic;

begin
    s_axis_tready <= ready;

transfer <= s_axis_tvalid and ready;



process(s_axis_aclk)
begin
	if (rising_edge(s_axis_aclk)) then
		if (transfer = '1') then
			bitcount <= (others => '0');
			subbitcount <= (others => '0');
		elsif (subbitclk_enable = '1') then
			subbitcount <= std_logic_vector(unsigned(subbitcount) + 1);
			if (subbitcount = "10011") then
				bitcount <= std_logic_vector(unsigned(bitcount) + 1);
				subbitcount <= (others => '0');
			end if;
		end if;
	end if;
end process;

ws_shift_en <= '1' when subbitcount = "10011" else '0';

process(s_axis_aclk)
begin
	if(rising_edge(s_axis_aclk)) then
		if (transfer = '1') then
			ws_shiftreg <= s_axis_tdata(23 downto 0);
		elsif (ws_shift_en = '1') then
			ws_shiftreg <= ws_shiftreg(22 downto 0) & "0";
		end if;
	end if;
end process;

process(s_axis_aclk)
begin
	if(rising_edge(s_axis_aclk)) then
        DOUT <= next_dout;	
	end if;
end process;

subbitclk_enable <= '0' when bitcount = "10111" and subbitcount = "10011" else '1';
ready <= not subbitclk_enable;

next_dout <= '1' when subbitcount(4 downto 2) = "000" else
              '0' when subbitcount(4 downto 2) = "100" else
              ws_shiftreg(23);



end arch_imp;
