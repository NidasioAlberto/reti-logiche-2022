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

architecture priject_arch of project_reti_logiche is
    type state_type is (IDLE, REQUEST_W, FETCH_W, REQUEST_U, FETCH_U, COMPUTE_U, WRITE_Z1, WRITE_Z2, DONE);
    signal current_state   : state_type                    := IDLE;
    signal next_state      : state_type                    := IDLE;
    signal W               : integer range 0 to 255        := 0;
    signal current_U_count : integer range 0 to 255        := 0;
    signal next_U_count    : integer range 0 to 255        := 0;
    signal conv_state      : std_logic_vector(9 downto 0)  := "0000000000";
    signal next_conv_state : std_logic_vector(9 downto 0)  := "0000000000";
    signal Z               : std_logic_vector(15 downto 0) := "0000000000000000";
    signal next_Z          : std_logic_vector(15 downto 0) := "0000000000000000";
begin
    -- Handle reset and clock inputs and updates the state
    process (i_rst, i_clk)
    begin
        if (i_rst = '1') then
            -- Reset the state whenever the reset signal is up
            conv_state    <= "0000000000";
            current_state <= IDLE;
        elsif falling_edge(i_clk) then
            -- Advance to the next state at the clock's rising edge
            current_state   <= next_state;
            current_U_count <= next_U_count;
            conv_state      <= next_conv_state;
            Z               <= next_Z;
        end if;
    end process;

    -- Finite state machine
    process (current_state, i_start)
    begin
        -- Default outputs
        o_address <= "0000000000000000";
        o_done    <= '0';
        o_en      <= '0';
        o_we      <= '0';
        o_data    <= "00000000";

        case current_state is
            when IDLE =>
                if (i_start = '1') then
                    next_state <= REQUEST_W;
                else
                    W            <= 0;
                    next_U_count <= 0;
                    next_state   <= IDLE;
                end if;
            when REQUEST_W =>
                -- Request the first address in memory where W is located
                o_address <= std_logic_vector(to_unsigned(0, o_address'length));
                o_en      <= '1';

                next_state <= FETCH_W;
            when FETCH_W =>
                -- Read W from the memory data bus
                W <= CONV_INTEGER(i_data);

                next_state <= REQUEST_U;
            when REQUEST_U =>
                -- Request the current U byte address
                o_address <= std_logic_vector(to_unsigned(current_U_count + 1, o_address'length));
                o_en      <= '1';

                next_state <= FETCH_U;
            when FETCH_U =>
                -- Shift the current value and append U from memory
                next_conv_state <= conv_state(1 downto 0) & i_data;

                next_state <= COMPUTE_U;
            when COMPUTE_U =>
                -- Run the 1/2 convolutional code
                for k in 7 downto 0 loop
                    -- Compute P1k and P2k
                    next_Z(k * 2 + 1) <= conv_state(k + 2) xor conv_state(k);
                    next_Z(k * 2)     <= conv_state(k + 2) xor (conv_state(k + 1) xor conv_state(k));
                end loop;

                -- Next we need to write P1 and P2
                next_state <= WRITE_Z1;
            when WRITE_Z1 =>
                -- Write P1
                o_address <= std_logic_vector(to_unsigned(1000 + current_U_count * 2, o_address'length));
                o_data    <= Z(15 downto 8);
                o_we      <= '1';
                o_en      <= '1';

                -- Next write P2
                next_state <= WRITE_Z2;
            when WRITE_Z2 =>
                -- Write P2
                o_address <= std_logic_vector(to_unsigned(1000 + current_U_count * 2 + 1, o_address'length));
                o_data    <= Z(7 downto 0);
                o_we      <= '1';
                o_en      <= '1';

                if (current_U_count = W - 1) then
                    -- If all U bytes have been read stop here
                    o_done     <= '1';
                    next_state <= DONE;
                else
                    -- Otherwise update the current_U_count and continue
                    next_U_count <= current_U_count + 1;
                    next_state   <= REQUEST_U;
                end if;
            when DONE =>
                if (i_start = '0') then
                    -- If the start signal goes back to 0, reset the done signal
                    o_done <= '0';

                    -- Reset internal state
                    next_conv_state <= "0000000000";

                    -- Go back to IDLE
                    next_state <= IDLE;
                end if;
        end case;
    end process;

end priject_arch;