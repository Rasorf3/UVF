--==============================================================================
-- N-bit register with asynchronous reset and enable
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;

--==============================================================================
-- Entity declaration
--==============================================================================

entity RegisterNbits is
    generic (
        N : positive := 8 -- Register width in bits
    );
    port (
        D      : in  std_logic_vector(N - 1 downto 0); -- Data input
        CLK    : in  std_logic;                        -- Clock signal
        RESET  : in  std_logic;                        -- Asynchronous reset, active low
        ENABLE : in  std_logic;                        -- Enable, active high
        Q      : out std_logic_vector(N - 1 downto 0)  -- Stored output
    );
end entity RegisterNbits;

--==============================================================================
-- Architecture: structural description of the N-bit register
--==============================================================================

architecture structural of RegisterNbits is
begin

    --==========================================================================
    -- One D-type flip-flop is instantiated for each register bit
    --==========================================================================

    gen_flip_flops : for i in 0 to N - 1 generate
        flip_flop_i : entity work.FlipFlopD(beh)
            port map (
                D      => D(i),
                CLK    => CLK,
                RESET  => RESET,
                ENABLE => ENABLE,
                Q      => Q(i)
            );
    end generate gen_flip_flops;

end architecture structural; -- End of structural architecture

--==============================================================================
