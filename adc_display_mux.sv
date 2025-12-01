// adc_display_mux.sv
// Chooses RAW / AVERAGED / VOLTAGE view for each ADC
// based on display_mode, and also decides decimal_point pattern.

module adc_display_mux (
    input  logic [1:0]  display_mode,   // 00=RAW, 01=AVG, 10=VOLT

    // XADC views
    input  logic [15:0] xadc_raw,
    input  logic [15:0] xadc_scaled,
    input  logic [15:0] xadc_mv,

    // PWM views
    input  logic [15:0] pwm_raw16,
    input  logic [15:0] pwm_scaled16,
    input  logic [15:0] pwm_mv,

    // R2R views
    input  logic [15:0] r2r_raw16,
    input  logic [15:0] r2r_scaled16,
    input  logic [15:0] r2r_mv,

    // Outputs to the ADC-select mux
    output logic [15:0] adc0_val,   // XADC view
    output logic [15:0] adc1_val,   // PWM view
    output logic [15:0] adc2_val,   // R2R view

    // Decimal point control (for voltage mode)
    output logic [3:0]  decimal_point
);

    always_comb begin
        // default
        adc0_val      = 16'd0;
        adc1_val      = 16'd0;
        adc2_val      = 16'd0;
        decimal_point = 4'b0000;

        case (display_mode)
            // --------------------------------------------------
            // RAW codes
            // --------------------------------------------------
            2'b00: begin
                // XADC: full raw (12 bits in [15:4])
                adc0_val = xadc_raw;

                // PWM/R2R: only the raw 8-bit code in the low byte
                adc1_val = {8'd0, pwm_raw16[7:0]};
                adc2_val = {8'd0, r2r_raw16[7:0]};
                // no decimal point in RAW mode
                decimal_point = 4'b0000;
            end

            // --------------------------------------------------
            // AVERAGED codes
            // --------------------------------------------------
            2'b01: begin
                adc0_val = xadc_scaled;

                // show the averaged 8-bit value (Q[15:8]) only
                adc1_val = {8'd0, pwm_scaled16[15:8]};
                adc2_val = {8'd0, r2r_scaled16[15:8]};
                decimal_point = 4'b0000;
            end

            // --------------------------------------------------
            // VOLTAGE in mV (0-3300)
            // --------------------------------------------------
            2'b10: begin
                adc0_val = xadc_mv;
                adc1_val = pwm_mv;
                adc2_val = r2r_mv;

                // put a decimal point for voltage display
                // (e.g. X.xxx). Adjust pattern if you want a
                // different digit to have the DP.
                decimal_point = 4'b1000;
            end

            default: begin
                adc0_val      = 16'd0;
                adc1_val      = 16'd0;
                adc2_val      = 16'd0;
                decimal_point = 4'b0000;
            end
        endcase
    end

endmodule
