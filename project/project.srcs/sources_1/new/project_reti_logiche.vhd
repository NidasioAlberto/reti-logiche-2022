-------------------------------------------------------------------------------
-- Prova Finale (Progetto di Reti Logiche)
-- Prof. Fabio Salice - Anno 2021/2022
--
-- Author: Alberto Nidasio
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity project_reti_logiche is
    port (
        i_clk     : in std_logic;
        i_rst     : in std_logic;
        i_start   : in std_logic;
        i_data    : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done    : out std_logic;
        o_en      : out std_logic;
        o_we      : out std_logic;
        o_data    : out std_logic_vector(7 downto 0)
    );
end project_reti_logiche;

architecture project_arch of project_reti_logiche is
    type state_type is (IDLE, PREPARE_W, REQUEST_W, WAIT_W, FETCH_W, PREPARE_U, REQUEST_U, WAIT_U, COMPUTE_P, WRITE_P1, WRITE_P2, DONE);
    signal o_address_next : std_logic_vector(15 downto 0) := "0000000000000000";
    signal o_done_next    : std_logic;
    signal o_en_next      : std_logic;
    signal o_we_next      : std_logic;
    signal o_data_next    : std_logic_vector(7 downto 0);
    signal current_state  : state_type                    := IDLE;
    signal next_state     : state_type                    := IDLE;
    signal W              : integer range 0 to 255        := 0;
    signal next_W         : integer range 0 to 255        := 0;
    signal U_count        : integer range 0 to 255        := 0;
    signal next_U_count   : integer range 0 to 255        := 0;
    signal U_buffer       : std_logic_vector(1 downto 0)  := "00";
    signal next_U_buffer  : std_logic_vector(1 downto 0)  := "00";
    signal P_buffer       : std_logic_vector(15 downto 0) := "0000000000000000";
    signal next_P_buffer  : std_logic_vector(15 downto 0) := "0000000000000000";
begin
    -- Handle reset and clock inputs and updates the state
    process (i_rst, i_clk)
    begin
        if i_rst = '1' then
            -- Reset the state whenever the reset signal is up
            o_address     <= "0000000000000000";
            o_done        <= '0';
            o_en          <= '0';
            o_we          <= '0';
            o_data        <= "00000000";
            current_state <= IDLE;
            W             <= 0;
            U_count       <= 0;
            U_buffer      <= "00";
            P_buffer      <= "0000000000000000";
        elsif rising_edge(i_clk) then
            -- Advance to the next state at the clock's rising edge
            o_address     <= o_address_next;
            o_done        <= o_done_next;
            o_en          <= o_en_next;
            o_we          <= o_we_next;
            o_data        <= o_data_next;
            current_state <= next_state;
            W             <= next_W;
            U_count       <= next_U_count;
            U_buffer      <= next_U_buffer;
            P_buffer      <= next_P_buffer;
        end if;
    end process;

    -- Finite state machine
    process (current_state, i_start)
        variable current_U : std_logic_vector(9 downto 0) := "0000000000";
    begin
        -- Default outputs
        o_address_next <= "0000000000000000";
        o_done_next    <= '0';
        o_en_next      <= '0';
        o_we_next      <= '0';
        o_data_next    <= "00000000";

        -- By default keep this values the same
        next_state    <= current_state;
        next_W        <= W;
        next_U_count  <= U_count;
        next_U_buffer <= U_buffer;
        next_P_buffer <= P_buffer;

        case current_state is
            when IDLE =>
                -- Wait for the start signal
                if (i_start = '1') then
                    next_state <= PREPARE_W;
                else
                    next_W       <= 0;
                    next_U_count <= 0;
                    next_state   <= IDLE;
                end if;
            when PREPARE_W =>
                -- Request the first address in memory where W is located
                o_address_next <= std_logic_vector(to_unsigned(0, o_address'length));
                o_en_next      <= '1';

                next_state <= REQUEST_W;
            when REQUEST_W =>
                -- Wait the signals to be propagated to the memory
                next_state <= WAIT_W;
            when WAIT_W =>
                -- Whait for the memory to read the data
                next_state <= FETCH_W;
            when FETCH_W =>
                -- Read W from the memory data bus
                next_W <= CONV_INTEGER(i_data);

                -- Immediately stop of the lenght of U is 0
                if CONV_INTEGER(i_data) = 0 then
                    -- If the input stream is empty
                    o_done_next <= '1';
                    next_state  <= DONE;
                else
                    next_state <= PREPARE_U;
                end if;
            when PREPARE_U =>
                -- Request the current U byte address
                o_address_next <= std_logic_vector(to_unsigned(U_count + 1, o_address'length));
                o_en_next      <= '1';

                next_state <= REQUEST_U;
            when REQUEST_U =>
                -- Wait the signals to be propagated to the memory
                next_state <= WAIT_U;
            when WAIT_U =>
                -- Whait for the memory to read the data
                next_state <= COMPUTE_P;
            when COMPUTE_P =>
                -- Shift the current value and append U from memory
                next_U_buffer <= i_data(1 downto 0);
                current_U := U_buffer(1 downto 0) & i_data;

                -- Compute the 1/2 convolutional code
                for k in 7 downto 0 loop
                    -- Compute P1k and P2k
                    next_P_buffer(k * 2 + 1) <= current_U(k + 2) xor current_U(k);
                    next_P_buffer(k * 2)     <= current_U(k + 2) xor current_U(k + 1) xor current_U(k);
                end loop;

                -- Next we need to write P1
                next_state <= WRITE_P1;
            when WRITE_P1 =>
                -- Write P1
                o_address_next <= std_logic_vector(to_unsigned(1000 + U_count * 2, o_address'length));
                o_data_next    <= P_buffer(15 downto 8);
                o_we_next      <= '1';
                o_en_next      <= '1';

                -- Next write P2
                next_state <= WRITE_P2;
            when WRITE_P2 =>
                -- Write P2
                o_address_next <= std_logic_vector(to_unsigned(1000 + U_count * 2 + 1, o_address'length));
                o_data_next    <= P_buffer(7 downto 0);
                o_we_next      <= '1';
                o_en_next      <= '1';

                if (U_count = W - 1) then
                    -- If all U bytes have been read stop here
                    o_done_next <= '1';
                    next_state  <= DONE;
                else
                    -- Otherwise update the U_count and continue
                    next_U_count <= U_count + 1;
                    next_state   <= PREPARE_U;
                end if;
            when DONE =>
                if (i_start = '0') then
                    -- If the start signal goes back to 0, reset the done signal
                    o_done_next <= '0';

                    -- Reset internal state
                    next_w        <= 0;
                    next_U_count  <= 0;
                    next_U_buffer <= "00";
                    next_P_buffer <= "0000000000000000";

                    -- Go back to IDLE
                    next_state <= IDLE;
                end if;
        end case;
    end process;
end project_arch;