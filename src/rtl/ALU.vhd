--==============================================================================
-- Generic N-bit arithmetic and logic unit
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--==============================================================================
-- Entity declaration
--==============================================================================

entity ALU is
    generic (
        N : positive := 8 -- ALU width in bits
    );
    port (
        A         : in  std_logic_vector(N - 1 downto 0); -- First operand
        B         : in  std_logic_vector(N - 1 downto 0); -- Second operand
        OP        : in  std_logic_vector(3 downto 0);     -- Operation selector
        CARRY_IN  : in  std_logic;                        -- Carry or borrow input
        RESULT    : out std_logic_vector(N - 1 downto 0); -- Operation result
        CARRY_OUT : out std_logic                         -- Carry or borrow output
    );
end entity ALU;

--==============================================================================
-- Architecture: behavioral description of the ALU
--==============================================================================

architecture beh of ALU is

    --==========================================================================
    -- Operation codes
    --==========================================================================

    constant OP_ADD    : std_logic_vector(3 downto 0) := "0000";
    constant OP_SUB    : std_logic_vector(3 downto 0) := "0001";
    constant OP_AND    : std_logic_vector(3 downto 0) := "0010";
    constant OP_OR     : std_logic_vector(3 downto 0) := "0011";
    constant OP_XOR    : std_logic_vector(3 downto 0) := "0100";
    constant OP_NOT    : std_logic_vector(3 downto 0) := "0101";
    constant OP_NAND   : std_logic_vector(3 downto 0) := "0110";
    constant OP_NOR    : std_logic_vector(3 downto 0) := "0111";
    constant OP_PASS_A : std_logic_vector(3 downto 0) := "1000";

begin

    --==========================================================================
    -- Combinational ALU process
    --==========================================================================

    process (A, B, OP, CARRY_IN) is
        variable a_extended     : unsigned(N downto 0);
        variable b_extended     : unsigned(N downto 0);
        variable b_inverted     : unsigned(N downto 0);
        variable carry_extended : unsigned(N downto 0);
        variable temporary      : unsigned(N downto 0);
    begin
        a_extended := resize(unsigned(A), N + 1);
        b_extended := resize(unsigned(B), N + 1);
        b_inverted := resize(not unsigned(B), N + 1);

        carry_extended := (others => '0');
        carry_extended(0) := CARRY_IN;

        RESULT    <= (others => '0');
        CARRY_OUT <= '0';
        temporary := (others => '0');

        case OP is
            when OP_ADD =>
                -- A + B + CARRY_IN
                temporary := a_extended + b_extended + carry_extended;
                RESULT <= std_logic_vector(temporary(N - 1 downto 0));
                CARRY_OUT <= temporary(N);

            when OP_SUB =>
                -- A - B - CARRY_IN using two's complement arithmetic
                carry_extended := (others => '0');
                if CARRY_IN = '0' then
                    carry_extended(0) := '1';
                end if;

                temporary := a_extended + b_inverted + carry_extended;
                RESULT <= std_logic_vector(temporary(N - 1 downto 0));
                CARRY_OUT <= not temporary(N); -- Borrow output

            when OP_AND =>
                RESULT <= A and B;

            when OP_OR =>
                RESULT <= A or B;

            when OP_XOR =>
                RESULT <= A xor B;

            when OP_NOT =>
                RESULT <= not A;

            when OP_NAND =>
                RESULT <= A nand B;

            when OP_NOR =>
                RESULT <= A nor B;

            when OP_PASS_A =>
                RESULT <= A;

            when others =>
                RESULT    <= (others => '0');
                CARRY_OUT <= '0';
        end case;
    end process; -- End of combinational ALU process

end architecture beh; -- End of behavioral architecture

--==============================================================================
