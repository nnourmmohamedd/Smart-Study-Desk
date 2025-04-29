library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SmartStudyDesk is
    Port (
        clk            : in  STD_LOGIC;
        rst            : in  STD_LOGIC;
        pir_sensor     : in  STD_LOGIC;
        ldr_sensor     : in  STD_LOGIC;
        servo_pwm      : out STD_LOGIC;
        lamp_control   : out STD_LOGIC;
        drawer_control : out STD_LOGIC;
        time_display   : out STD_LOGIC_VECTOR(13 downto 0);
        led            : out STD_LOGIC
    );
end SmartStudyDesk;

architecture Behavioral of SmartStudyDesk is
    signal time_counter : integer := 0;
    signal display_time : integer := 0;
    signal counting     : STD_LOGIC := '0';
    signal lamp_on      : STD_LOGIC := '0';
    signal drawer_open  : STD_LOGIC := '0';
    signal pwm_high     : integer := 0;
    signal servo_pos    : integer := 0;

    constant clk_freq   : integer := 50000000;
    constant min_pulse  : integer := clk_freq / 1000;
    constant max_pulse  : integer := 2 * clk_freq / 1000;
    constant mid_pulse  : integer := (min_pulse + max_pulse) / 2;

    signal motion_active : STD_LOGIC := '0';
    signal grace_counter : integer := 0;
    constant grace_period : integer := clk_freq * 2;

    signal pwm_signal : STD_LOGIC;

begin
    process(clk, rst)
        variable previous_motion : STD_LOGIC := '0';
    begin
        if rst = '0' then
            time_counter <= 0;
            display_time <= 0;
            counting <= '0';
            lamp_on <= '0';
            led <= '0';
            drawer_open <= '0';
            pwm_high <= mid_pulse;
            motion_active <= '0';
            grace_counter <= 0;
            previous_motion := '0';
            servo_pos <= 0;
        elsif rising_edge(clk) then
            if pir_sensor = '1' then
                motion_active <= '1';
                grace_counter <= 0;
            elsif motion_active = '1' then
                if grace_counter < grace_period then
                    grace_counter <= grace_counter + 1;
                else
                    motion_active <= '0';
                end if;
            end if;

            if motion_active = '1' and previous_motion = '0' then
                display_time <= 0;
                time_counter <= 0;
            end if;

            if motion_active = '1' then
                if time_counter < clk_freq - 1 then
                    time_counter <= time_counter + 1;
                else
                    time_counter <= 0;
                    if display_time < 99 then
                        display_time <= display_time + 1;
                    end if;
                end if;
            end if;

            if motion_active = '1' then
                led <= '1';
                counting <= '1';
                if drawer_open = '0' then
                    drawer_open <= '1';
                    servo_pos <= 1;
                end if;

                if ldr_sensor = '1' then
                    lamp_on <= '1';
                else
                    lamp_on <= '0';
                end if;
            else
                led <= '0';
                counting <= '0';
                drawer_open <= '0';
                servo_pos <= 0;
            end if;

            previous_motion := motion_active;
        end if;
    end process;

    process(display_time)
    begin
        case (display_time / 10) is
            when 0 => time_display(13 downto 7) <= "1000000";
            when 1 => time_display(13 downto 7) <= "1111001";
            when 2 => time_display(13 downto 7) <= "0100100";
            when 3 => time_display(13 downto 7) <= "0110000";
            when 4 => time_display(13 downto 7) <= "0011001";
            when 5 => time_display(13 downto 7) <= "0010010";
            when 6 => time_display(13 downto 7) <= "0000010";
            when 7 => time_display(13 downto 7) <= "1111000";
            when 8 => time_display(13 downto 7) <= "0000000";
            when 9 => time_display(13 downto 7) <= "0010000";
            when others => time_display(13 downto 7) <= "1111111";
        end case;

        case (display_time mod 10) is
            when 0 => time_display(6 downto 0) <= "1000000";
            when 1 => time_display(6 downto 0) <= "1111001";
            when 2 => time_display(6 downto 0) <= "0100100";
            when 3 => time_display(6 downto 0) <= "0110000";
            when 4 => time_display(6 downto 0) <= "0011001";
            when 5 => time_display(6 downto 0) <= "0010010";
            when 6 => time_display(6 downto 0) <= "0000010";
            when 7 => time_display(6 downto 0) <= "1111000";
            when 8 => time_display(6 downto 0) <= "0000000";
            when 9 => time_display(6 downto 0) <= "0010000";
            when others => time_display(6 downto 0) <= "1111111";
        end case;
    end process;

    servo_inst : entity work.servo
        generic map (
            clk_hz => real(clk_freq),
            pulse_hz => 50.0,
            min_pulse_us => 500.0,
            max_pulse_us => 2500.0,
            step_count => 2
        )
        port map (
            clk => clk,
            rst => rst,
            position => servo_pos,
            pwm => pwm_signal
        );

    lamp_control <= lamp_on;
    drawer_control <= drawer_open;
    servo_pwm <= pwm_signal;

end Behavioral;
