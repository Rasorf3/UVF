--==============================================================================
-- Testbench for the generic UVF datapath
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RegisterFilePkg.all;

--==============================================================================
-- Testbench entity
--==============================================================================

entity tb_Datapath is
end entity tb_Datapath;

--==============================================================================
-- Testbench architecture
--==============================================================================

architecture sim of tb_Datapath is

    --==========================================================================
    -- Testbench constants
    --==========================================================================

    constant N           : positive := 8;
    constant ADDR_WIDTH  : positive := clog2(N);
    constant CLOCK_PERIOD : time := 10 ns;

    --==========================================================================
    -- Clock and reset signals
    --==========================================================================

    signal clk   : std_logic := '0';
    signal reset : std_logic := '0';

    --==========================================================================
    -- Register file signals
    --==========================================================================

    signal rf_write_enable   : std_logic := '0';
    signal rf_write_address  : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal rf_read_address_a : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal rf_read_address_b : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');

    --==========================================================================
    -- External data signals
    --==========================================================================

    signal data_a_in : std_logic_vector(N - 1 downto 0) := (others => '0');
    signal data_b_in : std_logic_vector(N - 1 downto 0) := (others => '0');

    --==========================================================================
    -- Datapath control signals
    --==========================================================================

    signal alu_op       : std_logic_vector(3 downto 0) := "1000"; -- PASS_A
    signal alu_carry_in : std_logic := '0';
    signal s1           : std_logic := '0';
    signal s2           : std_logic := '0';
    signal s3           : std_logic_vector(1 downto 0) := "01";
    signal s4           : std_logic := '0';
    signal bus_c_select : std_logic_vector(1 downto 0) := "00"; -- Register IN
    signal reg_d_select : std_logic_vector(1 downto 0) := "00"; -- Hold

    signal reg_a_enable   : std_logic := '0';
    signal reg_b_enable   : std_logic := '0';
    signal reg_c_enable   : std_logic := '0';
    signal reg_d_enable   : std_logic := '0';
    signal reg_in_enable  : std_logic := '0';
    signal reg_out_enable : std_logic := '0';
    signal carry_enable   : std_logic := '0';

    --==========================================================================
    -- Datapath outputs
    --==========================================================================

    signal bus_a      : std_logic_vector(N - 1 downto 0);
    signal bus_b      : std_logic_vector(N - 1 downto 0);
    signal bus_c      : std_logic_vector(N - 1 downto 0);
    signal data_out   : std_logic_vector(N - 1 downto 0);
    signal carry_out  : std_logic;
    signal carry_flag : std_logic;
    signal q0         : std_logic;

begin

    --==========================================================================
    -- Clock generation
    --==========================================================================

    clock_process : process
    begin
        loop
            clk <= '0';
            wait for CLOCK_PERIOD / 2;
            clk <= '1';
            wait for CLOCK_PERIOD / 2;
        end loop;
    end process;

    --==========================================================================
    -- Device under test
    --==========================================================================

    dut : entity work.Datapath(structural)
        generic map (
            N => N
        )
        port map (
            CLK               => clk,
            RESET             => reset,
            RF_WRITE_ENABLE   => rf_write_enable,
            RF_WRITE_ADDRESS  => rf_write_address,
            RF_READ_ADDRESS_A => rf_read_address_a,
            RF_READ_ADDRESS_B => rf_read_address_b,
            DATA_A_IN         => data_a_in,
            DATA_B_IN         => data_b_in,
            ALU_OP            => alu_op,
            ALU_CARRY_IN      => alu_carry_in,
            S1                => s1,
            S2                => s2,
            S3                => s3,
            S4                => s4,
            BUS_C_SELECT      => bus_c_select,
            REG_D_SELECT      => reg_d_select,
            REG_A_ENABLE      => reg_a_enable,
            REG_B_ENABLE      => reg_b_enable,
            REG_C_ENABLE      => reg_c_enable,
            REG_D_ENABLE      => reg_d_enable,
            REG_IN_ENABLE     => reg_in_enable,
            REG_OUT_ENABLE    => reg_out_enable,
            CARRY_ENABLE      => carry_enable,
            BUS_A             => bus_a,
            BUS_B             => bus_b,
            BUS_C             => bus_c,
            DATA_OUT          => data_out,
            CARRY_OUT         => carry_out,
            CARRY_FLAG        => carry_flag,
            Q0                => q0
        );

    --==========================================================================
    -- Stimulus process
    --==========================================================================

    stimulus_process : process
        variable observed_value : integer;
    begin
        -- Apply the asynchronous reset.
        reset <= '0';
        wait for 22 ns;
        reset <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;

        -- Load values 30 through 37 into the eight register file entries.
        -- Register IN captures the input first, then the register file writes it.
        for i in 0 to N - 1 loop
            data_a_in        <= std_logic_vector(to_unsigned(30 + i, N));
            rf_write_address <= std_logic_vector(to_unsigned(i, ADDR_WIDTH));

            reg_in_enable <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;

            reg_in_enable  <= '0';
            rf_write_enable <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;

            rf_write_enable <= '0';

            report "Loaded register " & integer'image(i) &
                   " with value " & integer'image(30 + i)
                   severity note;
        end loop;

        -- Read each register through bus A and capture it in Register OUT.
        for i in 0 to N - 1 loop
            rf_read_address_a <= std_logic_vector(to_unsigned(i, ADDR_WIDTH));
            reg_out_enable   <= '1';

            wait for 1 ns;
            wait until rising_edge(clk);
            wait for 1 ns;

            reg_out_enable <= '0';
            observed_value := to_integer(unsigned(data_out));

            report "Register OUT, address " & integer'image(i) &
                   ", value = " & integer'image(observed_value)
                   severity note;

            assert observed_value = 30 + i
                report "Unexpected value at register address " & integer'image(i)
                severity error;
        end loop;

        report "Datapath register file test completed successfully."
            severity note;

        wait;
    end process;

end architecture sim; -- End of testbench architecture

--==============================================================================
