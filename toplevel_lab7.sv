// Lab 7 Top Level - Discrete ADC System
// Authors: Yassin Shehata, Abdelrahman Salem, Ahmed Attiya

module lab_7_top_level (
    input  logic        clk,
    input  logic        reset,
    input  logic [1:0]  bin_bcd_select,
    input  logic [1:0]  adc_select,
    input  logic        vauxp15,
    input  logic        vauxn15,
    input  logic        comp_pwm,
    input  logic        comp_r2r,
    output logic        CA, CB, CC, CD, CE, CF, CG, DP,
    output logic        AN1, AN2, AN3, AN4,
    output logic [15:0] led,
    output logic        pwm_out,
    output logic [7:0]  r2r_out,
    input  logic [1:0]  display_mode,
    input  logic        sar_mode
);

    // ---------------- XADC path ----------------
    logic [15:0] xadc_raw;
    logic [15:0] xadc_scaled;

    xadc_subsystem XADC_SYS (
        .clk        (clk),
        .reset      (reset),
        .vauxp15    (vauxp15),
        .vauxn15    (vauxn15),
        .raw_out    (xadc_raw),
        .scaled_out (xadc_scaled)
    );

    // ---------------- PWM path ----------------
    logic [15:0] pwm_raw16;
    logic [15:0] pwm_scaled16;
    logic        pwm_scaled_ready;

    pwm_adc_subsystem PWM_SYS (
        .clk          (clk),
        .reset        (reset),
        .comp_pwm     (comp_pwm),
        .sar_mode     (sar_mode),
        .pwm_out      (pwm_out),
        .raw_out      (pwm_raw16),
        .scaled_out   (pwm_scaled16),
        .scaled_ready (pwm_scaled_ready)
    );

    // ---------------- R2R path ----------------
    logic [15:0] r2r_raw16;
    logic [15:0] r2r_scaled16;
    logic        r2r_scaled_ready;

    r2r_adc_subsystem R2R_SYS (
        .clk          (clk),
        .reset        (reset),
        .comp_r2r     (comp_r2r),
        .sar_mode     (sar_mode),
        .r2r_out      (r2r_out),
        .raw_out      (r2r_raw16),
        .scaled_out   (r2r_scaled16),
        .scaled_ready (r2r_scaled_ready)
    );

    // ----------- Voltage conversion -----------
    logic [15:0] xadc_mv;
    logic [15:0] pwm_mv;
    logic [15:0] r2r_mv;

    voltage_calc VOLTS (
        .xadc_raw   (xadc_raw),
        .pwm_scaled (pwm_scaled16),
        .r2r_scaled (r2r_scaled16),
        .xadc_mv    (xadc_mv),
        .pwm_mv     (pwm_mv),
        .r2r_mv     (r2r_mv)
    );

    // ---------- Select RAW / AVG / VOLT in a separate module ----------
    logic [15:0] adc0_val;   // XADC view
    logic [15:0] adc1_val;   // PWM view
    logic [15:0] adc2_val;   // R2R view
    logic [15:0] adc3_val;   // unused (still needed by mux4_16_bits)
    logic [3:0]  decimal_pt;

    assign adc3_val = 16'd0;

    adc_display_mux DISPLAY_SEL (
        .display_mode (display_mode),

        .xadc_raw     (xadc_raw),
        .xadc_scaled  (xadc_scaled),
        .xadc_mv      (xadc_mv),

        .pwm_raw16    (pwm_raw16),
        .pwm_scaled16 (pwm_scaled16),
        .pwm_mv       (pwm_mv),

        .r2r_raw16    (r2r_raw16),
        .r2r_scaled16 (r2r_scaled16),
        .r2r_mv       (r2r_mv),

        .adc0_val     (adc0_val),
        .adc1_val     (adc1_val),
        .adc2_val     (adc2_val),
        .decimal_point(decimal_pt)
    );

    // ---------- ADC select mux (SW2-SW3) ----------
    logic [15:0] display_value;

    mux4_16_bits DISPLAY_MUX (
        .in0          (adc0_val),   // 00 = XADC
        .in1          (adc1_val),   // 01 = PWM
        .in2          (adc2_val),   // 10 = R2R
        .in3          (adc3_val),   // 11 = 0
        .select       (adc_select),
        .mux_out      (display_value),
        .decimal_point()           // still unused for now
    );

    // ------------- Seven-segment driver -------------
    seven_segment_display_subsystem SEVENSEG (
        .clk            (clk),
        .reset          (reset),
        .value          (display_value),
        .bin_bcd_select (bin_bcd_select[0]),
        .CA             (CA),
        .CB             (CB),
        .CC             (CC),
        .CD             (CD),
        .CE             (CE),
        .CF             (CF),
        .CG             (CG),
        .DP             (DP),
        .AN1            (AN1),
        .AN2            (AN2),
        .AN3            (AN3),
        .AN4            (AN4)
    );

    // ------------- LED debug -------------
    debug_led_driver DEBUG_LEDS (
        .adc_select       (adc_select),
        .bin_bcd_select   (bin_bcd_select),
        .pwm_raw_code     (pwm_raw16[7:0]),
        .pwm_scaled_ready (pwm_scaled_ready),
        .comp_pwm         (comp_pwm),
        .led              (led)
    );

endmodule
