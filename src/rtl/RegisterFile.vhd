--==============================================================================
-- Generic N-register by N-bit register file
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--==============================================================================
-- Package declaration
--==============================================================================

package RegisterFilePkg is
    -- Return the minimum number of bits required to address N registers.
    function clog2(N : positive) return positive;
end package RegisterFilePkg;

package body RegisterFilePkg is
    function clog2(N : positive) return positive is
        variable width : natural := 0;
        variable value : natural := 1;
    begin
        while value < N loop
            value := value * 2;
            width := width + 1;
        end loop;

        if width = 0 then
            return 1;
        else
            return width;
        end if;
    end function clog2;
end package body RegisterFilePkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RegisterFilePkg.all;

--==============================================================================
-- Entity declaration
--==============================================================================

entity RegisterFile is
    generic (
        N : positive := 8 -- Number of registers and bits per register
    );
    port (
        CLK            : in  std_logic;                            -- Clock signal
        RESET          : in  std_logic;                            -- Asynchronous reset, active low
        WRITE_ENABLE   : in  std_logic;                            -- Write enable, active high
        WRITE_ADDRESS  : in  std_logic_vector(clog2(N) - 1 downto 0); -- Write address
        DATA_IN        : in  std_logic_vector(N - 1 downto 0);      -- Single data input
        READ_ADDRESS_A : in  std_logic_vector(clog2(N) - 1 downto 0); -- Read address A
        READ_ADDRESS_B : in  std_logic_vector(clog2(N) - 1 downto 0); -- Read address B
        DATA_OUT_A     : out std_logic_vector(N - 1 downto 0);      -- Read data bus A
        DATA_OUT_B     : out std_logic_vector(N - 1 downto 0)       -- Read data bus B
    );
end entity RegisterFile;

--==============================================================================
-- Architecture: structural description using RegisterNbits instances
--==============================================================================

architecture structural of RegisterFile is

    --==========================================================================
    -- Internal types and signals
    --==========================================================================

    type register_array_t is array (0 to N - 1) of std_logic_vector(N - 1 downto 0);

    signal registers           : register_array_t;
    signal decoded_write_enable : std_logic_vector(N - 1 downto 0);

begin

    --==========================================================================
    -- Write address decoder
    --==========================================================================

    process (WRITE_ENABLE, WRITE_ADDRESS) is
        variable address : natural;
    begin
        decoded_write_enable <= (others => '0');
        address := to_integer(unsigned(WRITE_ADDRESS));

        if WRITE_ENABLE = '1' and address < N then
            decoded_write_enable(address) <= '1';
        end if;
    end process; -- End of write address decoder

    --==========================================================================
    -- Register bank
    --==========================================================================

    gen_registers : for i in 0 to N - 1 generate
        register_i : entity work.RegisterNbits(structural)
            generic map (
                N => N
            )
            port map (
                D      => DATA_IN,
                CLK    => CLK,
                RESET  => RESET,
                ENABLE => decoded_write_enable(i),
                Q      => registers(i)
            );
    end generate gen_registers;

    --==========================================================================
    -- Dual asynchronous read ports
    --==========================================================================

    process (registers, READ_ADDRESS_A, READ_ADDRESS_B) is
        variable address_a : natural;
        variable address_b : natural;
    begin
        DATA_OUT_A <= (others => '0');
        DATA_OUT_B <= (others => '0');

        address_a := to_integer(unsigned(READ_ADDRESS_A));
        address_b := to_integer(unsigned(READ_ADDRESS_B));

        if address_a < N then
            DATA_OUT_A <= registers(address_a);
        end if;

        if address_b < N then
            DATA_OUT_B <= registers(address_b);
        end if;
    end process; -- End of dual asynchronous read ports

end architecture structural; -- End of structural architecture

--==============================================================================
