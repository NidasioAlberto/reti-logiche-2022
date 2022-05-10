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
    type state_type is (IDLE, REQUEST_W, FETCH_W, REQUEST_U, COMPUTE_U, WRITE_P1, WRITE_P2, DONE);
    signal current_state   : state_type             := IDLE;
    signal next_state      : state_type             := IDLE;
    signal W               : integer range 0 to 255 := 0;
    signal current_U_count : integer range 0 to 255 := 0;
    signal current_U       : std_logic_vector(7 downto 0);
begin
    -- Handle reset and clock inputs and updates the state
    process (i_rst, i_clk)
    begin
        if (i_rst = '1') then
            -- Reset the state whenever the reset signal is up
            current_U     <= "00000000";
            current_state <= IDLE;
        elsif falling_edge(i_clk) then
            -- Advance to the next state at the clock's rising edge
            current_state <= next_state;
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
                    W               <= 0;
                    current_U_count <= 0;
                    next_state      <= IDLE;
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

                next_state <= COMPUTE_U;
            when COMPUTE_U =>
                -- Read the current U byte from the memory data bus
                current_U <= i_data;

                -- Run the 1/2 convolutional code
                -- TODO

                -- TODO: Move this to WRITE_P2
                if (current_U_count = W) then
                    -- If all U bytes have been read stop here
                    o_done     <= '1';
                    next_state <= DONE;
                else
                    -- Otherwise update the current_U_count and continue
                    current_U_count <= current_U_count + 1;
                    next_state      <= REQUEST_U;
                end if;
            when WRITE_P1 =>
            when WRITE_P2 =>
            when DONE     =>
                if (i_start = '0') then
                    -- If the start signal goes back to 0, reset the done signal
                    o_done <= '0';
                end if;
        end case;
    end process;

end priject_arch;