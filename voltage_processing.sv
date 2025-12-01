module voltage_calc (
    input  logic [15:0] xadc_raw,    // 0..4095 from XADC subsystem
    input  logic [15:0] pwm_scaled,  // averager_simple Q for PWM
    input  logic [15:0] r2r_scaled,  // averager_simple Q for R2R

    output logic [15:0] xadc_mv,     // 0..3300 mV
    output logic [15:0] pwm_mv,      // 0..3300 mV
    output logic [15:0] r2r_mv       // 0..3300 mV
);

    // Extract averaged 8-bit codes from the averager
    logic [7:0] pwm_code_8;
    logic [7:0] r2r_code_8;

    assign pwm_code_8 = pwm_scaled[15:8];  // 0..255 (average)
    assign r2r_code_8 = r2r_scaled[15:8];  // 0..255 (average)

    // 32-bit products to avoid overflow
    logic [31:0] xadc_mult;
    logic [31:0] pwm_mult;
    logic [31:0] r2r_mult;

    always_comb begin
        // ---- XADC: code * 3300 / 4096 ----
        xadc_mult = xadc_raw * 32'd3300;
        xadc_mv   = xadc_mult >> 12;       // divide by 2^12

        // ---- PWM: averaged 8-bit code * 3300 / 256 ----
        pwm_mult  = pwm_code_8 * 32'd3300;
        pwm_mv    = pwm_mult >> 8;         // divide by 2^8

        // ---- R2R: same mapping as PWM ----
        r2r_mult  = r2r_code_8 * 32'd3300;
        r2r_mv    = r2r_mult >> 8;
    end

endmodule
