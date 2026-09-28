--==============================================================================
-- Generic UVF datapath
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RegisterFilePkg.all;

--==============================================================================
-- Entity declaration
--==============================================================================

entity Datapath is
    generic (
        N : positive := 8 -- Datapath width in bits
    );
    port (
        CLK              : in  std_logic;                            -- Clock signal
        RESET            : in  std_logic;                            -- Asynchronous reset, active low

        -- Register file control
        RF_WRITE_ENABLE  : in  std_logic;                             -- Register file write enable
        RF_WRITE_ADDRESS : in  std_logic_vector(clog2(N) - 1 downto 0); -- Register file write address
        RF_READ_ADDRESS_A : in std_logic_vector(clog2(N) - 1 downto 0); -- Register file read address A
        RF_READ_ADDRESS_B : in std_logic_vector(clog2(N) - 1 downto 0); -- Register file read address B

        -- External data inputs
        DATA_A_IN        : in  std_logic_vector(N - 1 downto 0);     -- External data input A
        DATA_B_IN        : in  std_logic_vector(N - 1 downto 0);     -- External data input B

        -- ALU and datapath controls
        ALU_OP           : in  std_logic_vector(3 downto 0);         -- ALU operation selector
        ALU_CARRY_IN     : in  std_logic;                             -- External ALU carry input
        S1               : in  std_logic;                             -- Carry source selector
        S2               : in  std_logic;                             -- D-register serial fill selector
        S3               : in  std_logic_vector(1 downto 0);          -- ALU A-input selector
        S4               : in  std_logic;                             -- External input selector
        BUS_C_SELECT     : in  std_logic_vector(1 downto 0);          -- Bus C source selector
        REG_D_SELECT     : in  std_logic_vector(1 downto 0);          -- D-register operation selector

        -- Register enables
        REG_A_ENABLE     : in  std_logic;                             -- Register A enable
        REG_B_ENABLE     : in  std_logic;                             -- Register B enable
        REG_C_ENABLE     : in  std_logic;                             -- Register C enable
        REG_D_ENABLE     : in  std_logic;                             -- Register D enable
        REG_IN_ENABLE    : in  std_logic;                             -- Register IN enable
        REG_OUT_ENABLE   : in  std_logic;                             -- Register OUT enable
        CARRY_ENABLE     : in  std_logic;                             -- Carry flag enable

        -- Datapath outputs
        BUS_A            : out std_logic_vector(N - 1 downto 0);     -- Register file bus A
        BUS_B            : out std_logic_vector(N - 1 downto 0);     -- Register file bus B
        BUS_C            : out std_logic_vector(N - 1 downto 0);     -- Register file bus C
        DATA_OUT         : out std_logic_vector(N - 1 downto 0);     -- External registered output
        CARRY_OUT        : out std_logic;                             -- ALU carry or borrow output
        CARRY_FLAG       : out std_logic;                             -- Registered carry flag
        Q0               : out std_logic                              -- Least significant bit of register D
    );
end entity Datapath;

--==============================================================================
-- Architecture: structural datapath description
--==============================================================================

architecture structural of Datapath is

    --==========================================================================
    -- Internal buses and register signals
    --==========================================================================

    signal bus_a_internal       : std_logic_vector(N - 1 downto 0);
    signal bus_b_internal       : std_logic_vector(N - 1 downto 0);
    signal bus_c_internal       : std_logic_vector(N - 1 downto 0);
    signal reg_a_data           : std_logic_vector(N - 1 downto 0);
    signal reg_b_data           : std_logic_vector(N - 1 downto 0);
    signal reg_c_data           : std_logic_vector(N - 1 downto 0);
    signal reg_d_data           : std_logic_vector(N - 1 downto 0);
    signal reg_in_data          : std_logic_vector(N - 1 downto 0);
    signal reg_out_data         : std_logic_vector(N - 1 downto 0);

    --==========================================================================
    -- Internal datapath signals
    --==========================================================================

    signal alu_a_data           : std_logic_vector(N - 1 downto 0);
    signal alu_b_data           : std_logic_vector(N - 1 downto 0);
    signal alu_result           : std_logic_vector(N - 1 downto 0);
    signal alu_carry_out        : std_logic;
    signal selected_carry_in    : std_logic;
    signal carry_flag_data      : std_logic;
    signal d_serial_in          : std_logic;
    signal reg_in_selected_data : std_logic_vector(N - 1 downto 0);

begin

    --==========================================================================
    -- Register file
    --==========================================================================

    register_file_i : entity work.RegisterFile(structural)
        generic map (
            N => N
        )
        port map (
            CLK             => CLK,
            RESET           => RESET,
            WRITE_ENABLE    => RF_WRITE_ENABLE,
            WRITE_ADDRESS   => RF_WRITE_ADDRESS,
            DATA_IN         => bus_c_internal,
            READ_ADDRESS_A  => RF_READ_ADDRESS_A,
            READ_ADDRESS_B  => RF_READ_ADDRESS_B,
            DATA_OUT_A      => bus_a_internal,
            DATA_OUT_B      => bus_b_internal
        );

    --==========================================================================
    -- Registers A and B
    --==========================================================================

    register_a_i : entity work.RegisterNbits(structural)
        generic map (
            N => N
        )
        port map (
            D      => bus_a_internal,
            CLK    => CLK,
            RESET  => RESET,
            ENABLE => REG_A_ENABLE,
            Q      => reg_a_data
        );

    register_b_i : entity work.RegisterNbits(structural)
        generic map (
            N => N
        )
        port map (
            D      => bus_b_internal,
            CLK    => CLK,
            RESET  => RESET,
            ENABLE => REG_B_ENABLE,
            Q      => reg_b_data
        );

    --==========================================================================
    -- ALU A-input multiplexer bank using one Mux4x1 per bit
    --==========================================================================

    gen_alu_a_mux : for i in 0 to N - 1 generate
        alu_a_mux_i : entity work.Mux4x1(beh)
            port map (
                I0  => reg_a_data(i), -- Register A
                I1  => bus_a_internal(i), -- Bus A
                I2  => reg_c_data(i), -- Register C
                I3  => reg_d_data(i), -- Register D
                SEL => S3,
                Y   => alu_a_data(i)
            );
    end generate gen_alu_a_mux;

    --==========================================================================
    -- Arithmetic and logic unit
    --==========================================================================

    carry_input_mux_i : entity work.Mux2x1(beh)
        port map (
            I0  => ALU_CARRY_IN,
            I1  => carry_flag_data,
            SEL => S1,
            Y   => selected_carry_in
        );

    alu_b_data <= reg_b_data;

    alu_i : entity work.ALU(beh)
        generic map (
            N => N
        )
        port map (
            A         => alu_a_data,
            B         => alu_b_data,
            OP        => ALU_OP,
            CARRY_IN  => selected_carry_in,
            RESULT    => alu_result,
            CARRY_OUT => alu_carry_out
        );

    --==========================================================================
    -- Register C
    --==========================================================================

    register_c_i : entity work.RegisterNbits(structural)
        generic map (
            N => N
        )
        port map (
            D      => alu_result,
            CLK    => CLK,
            RESET  => RESET,
            ENABLE => REG_C_ENABLE,
            Q      => reg_c_data
        );

    --==========================================================================
    -- Register D and serial input selector
    --==========================================================================

    d_serial_mux_i : entity work.Mux2x1(beh)
        port map (
            I0  => '0',
            I1  => '1',
            SEL => S2,
            Y   => d_serial_in
        );

    register_d_i : entity work.ShiftRegister(structural)
        generic map (
            N => N
        )
        port map (
            CLK          => CLK,
            RESET        => RESET,
            ENABLE       => REG_D_ENABLE,
            SEL          => REG_D_SELECT,
            PARALLEL_IN  => reg_c_data,
            SERIAL_IN    => d_serial_in,
            PARALLEL_OUT => reg_d_data,
            SERIAL_OUT   => open
        );

    --==========================================================================
    -- Register IN and external input multiplexer
    --==========================================================================

    input_mux_i : entity work.Mux2x1N(beh)
        generic map (
            N => N
        )
        port map (
            I0  => DATA_A_IN,
            I1  => DATA_B_IN,
            SEL => S4,
            Y   => reg_in_selected_data
        );

    register_in_i : entity work.RegisterNbits(structural)
        generic map (
            N => N
        )
        port map (
            D      => reg_in_selected_data,
            CLK    => CLK,
            RESET  => RESET,
            ENABLE => REG_IN_ENABLE,
            Q      => reg_in_data
        );

    --==========================================================================
    -- Register OUT
    --==========================================================================

    register_out_i : entity work.RegisterNbits(structural)
        generic map (
            N => N
        )
        port map (
            D      => bus_a_internal,
            CLK    => CLK,
            RESET  => RESET,
            ENABLE => REG_OUT_ENABLE,
            Q      => reg_out_data
        );

    --==========================================================================
    -- Bus C source multiplexer bank using one Mux4x1 per bit
    --==========================================================================

    gen_bus_c_mux : for i in 0 to N - 1 generate
        bus_c_mux_i : entity work.Mux4x1(beh)
            port map (
                I0  => reg_in_data(i), -- Register IN
                I1  => reg_c_data(i),  -- Register C
                I2  => reg_d_data(i),  -- Register D
                I3  => alu_result(i),  -- ALU result
                SEL => BUS_C_SELECT,
                Y   => bus_c_internal(i)
            );
    end generate gen_bus_c_mux;

    --==========================================================================
    -- Carry flag register
    --==========================================================================

    carry_flag_i : entity work.FlipFlopD(beh)
        port map (
            D      => alu_carry_out,
            CLK    => CLK,
            RESET  => RESET,
            ENABLE => CARRY_ENABLE,
            Q      => carry_flag_data
        );

    --==========================================================================
    -- External outputs
    --==========================================================================

    BUS_A     <= bus_a_internal;
    BUS_B     <= bus_b_internal;
    BUS_C     <= bus_c_internal;
    DATA_OUT  <= reg_out_data;
    CARRY_OUT <= alu_carry_out;
    CARRY_FLAG <= carry_flag_data;
    Q0        <= reg_d_data(0);

end architecture structural; -- End of structural architecture

--==============================================================================
