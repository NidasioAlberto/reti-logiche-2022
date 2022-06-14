LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY project_tb IS
END project_tb;

ARCHITECTURE projecttb OF project_tb IS
    CONSTANT c_CLOCK_PERIOD : TIME := 15 ns;
    SIGNAL tb_done : STD_LOGIC;
    SIGNAL mem_address : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_rst : STD_LOGIC := '0';
    SIGNAL tb_start : STD_LOGIC := '0';
    SIGNAL tb_clk : STD_LOGIC := '0';
    SIGNAL mem_o_data, mem_i_data : STD_LOGIC_VECTOR (7 DOWNTO 0);
    SIGNAL enable_wire : STD_LOGIC;
    SIGNAL mem_we : STD_LOGIC;
    --signal   test_read              : std_logic;
    --signal   test_process           : integer;
    --signal   test_write             : integer;
    --signal   test_address           : std_logic_vector (15 downto 0);
    --signal   test_end_address       : std_logic_vector (15 downto 0);

    TYPE ram_type IS ARRAY (2047 DOWNTO 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL RAM : ram_type := (
        0 => STD_LOGIC_VECTOR(to_unsigned(6, 8)),
        1 => STD_LOGIC_VECTOR(to_unsigned(163, 8)),
        2 => STD_LOGIC_VECTOR(to_unsigned(47, 8)),
        3 => STD_LOGIC_VECTOR(to_unsigned(4, 8)),
        4 => STD_LOGIC_VECTOR(to_unsigned(64, 8)),
        5 => STD_LOGIC_VECTOR(to_unsigned(67, 8)),
        6 => STD_LOGIC_VECTOR(to_unsigned(13, 8)),
        OTHERS => (OTHERS => '0'));
    -- Expected Output  1000 -> 209                         
    -- Expected Output  1001  -> 206                         
    -- Expected Output  1002  -> 189                         
    -- Expected Output  1003  -> 37
    -- Expected Output  1004  -> 176 
    -- Expected Output  1005  -> 55 
    -- Expected Output  1006  -> 55 
    -- Expected Output  1007  -> 0 
    -- Expected Output  1008  -> 55 
    -- Expected Output  1009  -> 14 
    -- Expected Output  1010  -> 176 
    -- Expected Output  1011  -> 232                         

    COMPONENT project_reti_logiche IS
        PORT (
            i_clk : IN STD_LOGIC;
            i_rst : IN STD_LOGIC;
            i_start : IN STD_LOGIC;
            i_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_done : OUT STD_LOGIC;
            o_en : OUT STD_LOGIC;
            o_we : OUT STD_LOGIC;
            o_data : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
            --      t_read        : out std_logic;
            --      t_process     : out integer;
            --      t_write       : out integer;
            --      t_address     : out std_logic_vector(15 downto 0);
            --      t_end_addr    : out std_logic_vector(15 downto 0) 
        );
    END COMPONENT project_reti_logiche;
BEGIN
    UUT : project_reti_logiche
    PORT MAP(
        i_clk => tb_clk,
        i_rst => tb_rst,
        i_start => tb_start,
        i_data => mem_o_data,
        o_address => mem_address,
        o_done => tb_done,
        o_en => enable_wire,
        o_we => mem_we,
        o_data => mem_i_data
        --          t_read        => test_read,
        --          t_process     => test_process,
        --          t_write       => test_write,
        --          t_address     => test_address,
        --          t_end_addr    => test_end_address
    );

    p_CLK_GEN : PROCESS IS
    BEGIN
        WAIT FOR c_CLOCK_PERIOD/2;
        tb_clk <= NOT tb_clk;
    END PROCESS p_CLK_GEN;
    MEM : PROCESS (tb_clk)
    BEGIN
        IF tb_clk'event AND tb_clk = '1' THEN
            IF enable_wire = '1' THEN
                IF mem_we = '1' THEN
                    RAM(conv_integer(mem_address)) <= mem_i_data;
                    mem_o_data <= mem_i_data AFTER 2 ns;
                ELSE
                    mem_o_data <= RAM(conv_integer(mem_address)) AFTER 2 ns;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    test : PROCESS IS
    BEGIN
        WAIT FOR 100 ns;
        WAIT FOR c_CLOCK_PERIOD;
        tb_rst <= '1';
        WAIT FOR c_CLOCK_PERIOD;
        WAIT FOR 100 ns;
        tb_rst <= '0';
        WAIT FOR c_CLOCK_PERIOD;
        WAIT FOR 100 ns;
        tb_start <= '1';
        WAIT FOR c_CLOCK_PERIOD;
        WAIT UNTIL tb_done = '1';
        WAIT FOR c_CLOCK_PERIOD;
        tb_start <= '0';
        WAIT UNTIL tb_done = '0';
        WAIT FOR 100 ns;

        -- Input=  [163, 47, 4, 64, 67, 13]  
        -- Output =  [209, 206, 189, 37, 176, 55, 55, 0, 55, 14, 176, 232]  

        ASSERT RAM(1000) = STD_LOGIC_VECTOR(to_unsigned(209, 8)) REPORT "TEST FALLITO (WORKING ZONE). Expected  209  found " & INTEGER'image(to_integer(unsigned(RAM(1000)))) SEVERITY failure;
        ASSERT RAM(1001) = STD_LOGIC_VECTOR(to_unsigned(206, 8)) REPORT "TEST FALLITO (WORKING ZONE). Expected  206  found " & INTEGER'image(to_integer(unsigned(RAM(1001)))) SEVERITY failure;
        ASSERT RAM(1002) = STD_LOGIC_VECTOR(to_unsigned(189, 8)) REPORT "TEST FALLITO (WORKING ZONE). Expected  189  found " & INTEGER'image(to_integer(unsigned(RAM(1002)))) SEVERITY failure;
        ASSERT RAM(1003) = STD_LOGIC_VECTOR(to_unsigned(37, 8)) REPORT "TEST FALLITO (WORKING ZONE). Expected  37   found " & INTEGER'image(to_integer(unsigned(RAM(1003)))) SEVERITY failure;
        ASSERT RAM(1004) = STD_LOGIC_VECTOR(to_unsigned(176, 8)) REPORT "TEST FALLITO (WORKING ZONE). Expected  176  found " & INTEGER'image(to_integer(unsigned(RAM(1004)))) SEVERITY failure;
        ASSERT RAM(1005) = STD_LOGIC_VECTOR(to_unsigned(55, 8)) REPORT "TEST FALLITO (WORKING ZONE). Expected  55   found " & INTEGER'image(to_integer(unsigned(RAM(1005)))) SEVERITY failure;
        ASSERT RAM(1006) = STD_LOGIC_VECTOR(to_unsigned(55, 8)) REPORT "TEST FALLITO (WORKING ZONE). Expected  55   found " & INTEGER'image(to_integer(unsigned(RAM(1006)))) SEVERITY failure;
        ASSERT RAM(1007) = STD_LOGIC_VECTOR(to_unsigned(0, 8)) REPORT "TEST FALLITO (WORKING ZONE). Expected  0    found " & INTEGER'image(to_integer(unsigned(RAM(1007)))) SEVERITY failure;
        ASSERT RAM(1008) = STD_LOGIC_VECTOR(to_unsigned(55, 8)) REPORT "TEST FALLITO (WORKING ZONE). Expected  55   found " & INTEGER'image(to_integer(unsigned(RAM(1008)))) SEVERITY failure;
        ASSERT RAM(1009) = STD_LOGIC_VECTOR(to_unsigned(14, 8)) REPORT "TEST FALLITO (WORKING ZONE). Expected  14   found " & INTEGER'image(to_integer(unsigned(RAM(1009)))) SEVERITY failure;
        ASSERT RAM(1010) = STD_LOGIC_VECTOR(to_unsigned(176, 8)) REPORT "TEST FALLITO (WORKING ZONE). Expected  176  found " & INTEGER'image(to_integer(unsigned(RAM(1010)))) SEVERITY failure;
        ASSERT RAM(1011) = STD_LOGIC_VECTOR(to_unsigned(232, 8)) REPORT "TEST FALLITO (WORKING ZONE). Expected  232  found " & INTEGER'image(to_integer(unsigned(RAM(1011)))) SEVERITY failure;
        ASSERT false REPORT "Simulation Ended! TEST PASSATO" SEVERITY failure;
    END PROCESS test;

END projecttb;