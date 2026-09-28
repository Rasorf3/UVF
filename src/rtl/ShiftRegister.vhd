--==============================================================================
-- Generic N-bit shift register with parallel and serial data paths
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;

--==============================================================================
-- Entity declaration
--==============================================================================

entity ShiftRegister is
    generic (
        N : positive := 8 -- Register width in bits
    );
    port (
        CLK          : in  std_logic;                        -- Clock signal
        RESET        : in  std_logic;                        -- Asynchronous reset, active low
        ENABLE       : in  std_logic;                        -- Enable, active high
        SEL          : in  std_logic_vector(1 downto 0);     -- Operation selector
        PARALLEL_IN  : in  std_logic_vector(N - 1 downto 0); -- Parallel data input
        SERIAL_IN    : in  std_logic;                        -- Serial data input
        PARALLEL_OUT : out std_logic_vector(N - 1 downto 0); -- Parallel data output
        SERIAL_OUT   : out std_logic                         -- Serial data output
    );
end entity ShiftRegister;

--==============================================================================
-- Architecture: structural description using Mux4x1 and FlipFlopD
--==============================================================================

architecture structural of ShiftRegister is

    --==========================================================================
    -- Internal signals
    --==========================================================================

    signal register_data : std_logic_vector(N - 1 downto 0);
    signal next_data     : std_logic_vector(N - 1 downto 0);
    signal shift_left    : std_logic_vector(N - 1 downto 0);
    signal shift_right   : std_logic_vector(N - 1 downto 0);

begin

    --==========================================================================
    -- Serial shift data paths
    --==========================================================================

    gen_bits : for i in 0 to N - 1 generate

        -- Shift-left path: SERIAL_IN enters the least significant bit
        gen_shift_left_serial : if i = 0 generate
            shift_left(i) <= SERIAL_IN;
        end generate gen_shift_left_serial;

        gen_shift_left_register : if i > 0 generate
            shift_left(i) <= register_data(i - 1);
        end generate gen_shift_left_register;

        -- Shift-right path: SERIAL_IN enters the most significant bit
        gen_shift_right_serial : if i = N - 1 generate
            shift_right(i) <= SERIAL_IN;
        end generate gen_shift_right_serial;

        gen_shift_right_register : if i < N - 1 generate
            shift_right(i) <= register_data(i + 1);
        end generate gen_shift_right_register;

        --======================================================================
        -- One 4-to-1 multiplexer and one D-type flip-flop per bit
        --======================================================================

        mux_i : entity work.Mux4x1(beh)
            port map (
                I0  => register_data(i), -- Hold current value
                I1  => PARALLEL_IN(i),   -- Load parallel input
                I2  => shift_left(i),    -- Shift left
                I3  => shift_right(i),   -- Shift right
                SEL => SEL,
                Y   => next_data(i)
            );

        flip_flop_i : entity work.FlipFlopD(beh)
            port map (
                D      => next_data(i),
                CLK    => CLK,
                RESET  => RESET,
                ENABLE => ENABLE,
                Q      => register_data(i)
            );

    end generate gen_bits;

    --==========================================================================
    -- Outputs
    --==========================================================================

    PARALLEL_OUT <= register_data;

    -- The serial output is the bit that will be shifted out on the next clock
    with SEL select
        SERIAL_OUT <= register_data(N - 1) when "10", -- Shift left
                      register_data(0)     when "11", -- Shift right
                      '0'                  when others;

end architecture structural; -- End of structural architecture

--==============================================================================
