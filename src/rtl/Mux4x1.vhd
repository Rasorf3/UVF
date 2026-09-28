--==============================================================================
-- 4-to-1 multiplexer with one-bit inputs and output
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;

--==============================================================================
-- Entity declaration
--==============================================================================

entity Mux4x1 is
    port (
        I0  : in  std_logic; -- Input 0
        I1  : in  std_logic; -- Input 1
        I2  : in  std_logic; -- Input 2
        I3  : in  std_logic; -- Input 3
        SEL : in  std_logic_vector(1 downto 0); -- Select input
        Y   : out std_logic  -- Multiplexer output
    );
end entity Mux4x1;

--==============================================================================
-- Architecture: behavioral description of the 4-to-1 multiplexer
--==============================================================================

architecture beh of Mux4x1 is
begin

    --==========================================================================
    -- Combinational multiplexer process
    --==========================================================================

    process (I0, I1, I2, I3, SEL) is
    begin
        case SEL is
            when "00" =>
                Y <= I0;

            when "01" =>
                Y <= I1;

            when "10" =>
                Y <= I2;

            when "11" =>
                Y <= I3;

            when others =>
                Y <= '0';
        end case;
    end process; -- End of combinational multiplexer process

end architecture beh; -- End of behavioral architecture

--==============================================================================
