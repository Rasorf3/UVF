--==============================================================================
-- 2-to-1 multiplexer with one-bit inputs and output
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;

--==============================================================================
-- Entity declaration
--==============================================================================

entity Mux2x1 is
    port (
        I0  : in  std_logic; -- Input 0
        I1  : in  std_logic; -- Input 1
        SEL : in  std_logic; -- Select input
        Y   : out std_logic  -- Multiplexer output
    );
end entity Mux2x1;

--==============================================================================
-- Architecture: behavioral description of the 2-to-1 multiplexer
--==============================================================================

architecture beh of Mux2x1 is
begin

    --==========================================================================
    -- Combinational multiplexer process
    --==========================================================================

    process (I0, I1, SEL) is
    begin
        case SEL is
            when '0' =>
                Y <= I0;

            when '1' =>
                Y <= I1;

            when others =>
                Y <= '0';
        end case;
    end process; -- End of combinational multiplexer process

end architecture beh; -- End of behavioral architecture

--==============================================================================
