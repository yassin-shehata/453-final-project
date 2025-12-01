// Lab 7 Top Level - Discrete ADC System
// Authors: Yassin Shehata, Abdelrahman Salem, Ahmed Attiya

module lab_7_top_level (
    input  logic        clk,
    input  logic        reset,

    // SW0: HEX(0) / DEC(1) format for 7-seg (we only use bit 0).
    input  logic [1:0]  bin_bcd_select,

    // SW2-SW3: select which ADC path the display shows:
    //   00 = XADC, 01 = PWM, 10 = R2R, 11 = 0 (unused).
    input  logic [1:0]  adc_select,

    // XADC analog input pins.
    input  logic        vauxp15,
    input  logic        vauxn15,

    // Comparator output from the discrete PWM ADC circuit.
    input  logic        comp_pwm,

    // R-2R comparator.
    input  logic        comp_r2r,

    // 7-segment outputs.
    output logic        CA, CB, CC, CD, CE, CF, CG, DP,
    output logic        AN1, AN2, AN3, AN4,

    // Debug LEDs.
    output logic [15:0] led,

    // PWM output that feeds the RC filter + comparator.
    output logic        pwm_out,

    // R-2R bus that drives the ladder.
    output logic [7:0]  r2r_out,

    // What to show for the selected ADC:
    //   00 = raw code, 01 = averaged code, 10 = voltage in mV.
    input  logic [1:0]  display_mode,

    // SW6: 0 = Ramp ADC, 1 = SAR ADC (for both PWM and R2R)
    input  logic        sar_mode
);
    logic [3:0] decimal_pt;

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


    // ---------- Select RAW / AVG / VOLT ----------
 logic [15:0] adc0_val;   // XADC view
logic [15:0] adc1_val;   // PWM view
logic [15:0] adc2_val;   // R2R view
logic [15:0] adc3_val;   // unused

assign adc3_val = 16'd0;

always_comb begin
    case (display_mode)
        2'b00: begin // RAW codes
            // XADC: full 16-bit raw (12 bits used)
            adc0_val = xadc_raw;

            // PWM/R2R: ***ONLY 8 bits*** forced into low byte
            adc1_val = {8'd0, pwm_raw16[7:0]};   // 0..255 max
            adc2_val = {8'd0, r2r_raw16[7:0]};   // 0..255 max
        end

        2'b01: begin // AVERAGED
            adc0_val = xadc_scaled;

            // show only averaged 8-bit code (top byte of averager)
            adc1_val = {8'd0, pwm_scaled16[15:8]};  // 0..255
            adc2_val = {8'd0, r2r_scaled16[15:8]};  // 0..255
        end

        2'b10: begin // VOLTAGE (0-3300 mV)
            adc0_val = xadc_mv;
            adc1_val = pwm_mv;
            adc2_val = r2r_mv;
        end

        default: begin
            adc0_val = 16'd0;
            adc1_val = 16'd0;
            adc2_val = 16'd0;
        end
    endcase
end
    // Decimal point: only on in VOLTAGE mode (display_mode = 2'b10)
    // Pattern decides *where* the dot appears.
    //  - Try 4'b1000 first: DP after left-most digit → X.xxx
    //  - If it's in the wrong spot, try 4'b0100 or 4'b0010.
    always_comb begin
        if (display_mode == 2'b10) begin
            decimal_pt = 4'b1000;   // DP after the first digit
        end else begin
            decimal_pt = 4'b0000;   // DP off in RAW / AVERAGED modes
        end
    end


    // ---------- ADC select mux (SW2-SW3) ----------
    logic [15:0] display_value;

    mux4_16_bits DISPLAY_MUX (
        .in0          (adc0_val),   // 00 = XADC
        .in1          (adc1_val),   // 01 = PWM
        .in2          (adc2_val),   // 10 = R2R
        .in3          (adc3_val),   // 11 = 0
        .select       (adc_select),
        .mux_out      (display_value),
        .decimal_point()            // unused, left unconnected
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
