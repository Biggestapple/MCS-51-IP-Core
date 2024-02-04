library verilog;
use verilog.vl_types.all;
entity mcs_51 is
    port(
        clk             : in     vl_logic;
        sys_rst_n       : in     vl_logic;
        mem_addr        : out    vl_logic_vector(15 downto 0);
        mem_rdata       : in     vl_logic_vector(7 downto 0);
        psen_n          : out    vl_logic;
        int_n_0         : in     vl_logic;
        int_n_1         : in     vl_logic;
        tx              : out    vl_logic;
        rx              : in     vl_logic;
        p1              : inout  vl_logic_vector(7 downto 0);
        p2              : inout  vl_logic_vector(7 downto 0);
        ready_in        : in     vl_logic
    );
end mcs_51;
