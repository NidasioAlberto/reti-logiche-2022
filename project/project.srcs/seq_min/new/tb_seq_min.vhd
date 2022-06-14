-- test : sequenza di lunghezza nulla, cioè RAM(0) = "00000000"

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY project_tb IS
END project_tb;

ARCHITECTURE projecttb OF project_tb IS
    CONSTANT c_CLOCK_PERIOD : TIME := 100 ns;
    SIGNAL tb_done : STD_LOGIC;
    SIGNAL mem_address : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_rst : STD_LOGIC := '0';
    SIGNAL tb_start : STD_LOGIC := '0';
    SIGNAL tb_clk : STD_LOGIC := '0';
    SIGNAL mem_o_data, mem_i_data : STD_LOGIC_VECTOR (7 DOWNTO 0);
    SIGNAL enable_wire : STD_LOGIC;
    SIGNAL mem_we : STD_LOGIC;

    TYPE ram_type IS ARRAY (65535 DOWNTO 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL RAM : ram_type := (
        0 => STD_LOGIC_VECTOR(to_unsigned(0, 8)),
        1 => STD_LOGIC_VECTOR(to_unsigned(107, 8)),
        2 => STD_LOGIC_VECTOR(to_unsigned(84, 8)),
        3 => STD_LOGIC_VECTOR(to_unsigned(22, 8)),
        4 => STD_LOGIC_VECTOR(to_unsigned(59, 8)),
        5 => STD_LOGIC_VECTOR(to_unsigned(213, 8)),
        OTHERS => (OTHERS => '0'));

    COMPONENT project_reti_logiche IS
        PORT (
            i_clk : IN STD_LOGIC;
            i_rst : IN STD_LOGIC;
            i_start : IN STD_LOGIC;
            i_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            so_address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_done : OUT STD_LOGIC;
            o_en : OUT STD_LOGIC;
            o_we : OUT STD_LOGIC;
            o_data : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
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
        tb_rst <= '0';
        WAIT FOR c_CLOCK_PERIOD;
        tb_start <= '1';
        WAIT FOR c_CLOCK_PERIOD;
        WAIT UNTIL tb_done = '1';
        WAIT FOR c_CLOCK_PERIOD;
        tb_start <= '0';
        WAIT UNTIL tb_done = '0';
        WAIT FOR 100 ns;

        ASSERT RAM(1000) = STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)) REPORT "TEST FALLITO" SEVERITY failure;
        ASSERT RAM(1001) = STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)) REPORT "TEST FALLITO" SEVERITY failure;
        ASSERT RAM(1002) = STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)) REPORT "TEST FALLITO" SEVERITY failure;
        ASSERT RAM(1003) = STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)) REPORT "TEST FALLITO" SEVERITY failure;
        ASSERT RAM(1004) = STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)) REPORT "TEST FALLITO" SEVERITY failure;
        ASSERT RAM(1005) = STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)) REPORT "TEST FALLITO" SEVERITY failure;
        ASSERT RAM(1006) = STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)) REPORT "TEST FALLITO" SEVERITY failure;
        ASSERT RAM(1007) = STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)) REPORT "TEST FALLITO" SEVERITY failure;
        ASSERT RAM(1008) = STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)) REPORT "TEST FALLITO" SEVERITY failure;
        ASSERT RAM(1009) = STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)) REPORT "TEST FALLITO" SEVERITY failure;

        ASSERT false REPORT "Simulation Ended! TEST PASSATO" SEVERITY failure;

    END PROCESS test;

END projecttb;