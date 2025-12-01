// pwm_sar_adc.sv
// Successive-approximation ADC using PWM + RC as the DAC

module pwm_sar_adc #(
    parameter int RAMP_WIDTH     = 8,
    parameter int SETTLE_CYCLES  = 50000
)(
    input  logic                      clk,
    input  logic                      reset,
    input  logic                      comp_in,    // comparator from PWM RC filter
    output logic                      pwm_out,    // to RC filter
    output logic [RAMP_WIDTH-1:0]     adc_code,   // final SAR code
    output logic                      adc_ready   // 1-cycle pulse
);

    logic [RAMP_WIDTH-1:0] trial_code;

    // SAR core
    sar_core #(
        .WIDTH         (RAMP_WIDTH),
        .SETTLE_CYCLES (SETTLE_CYCLES)
    ) SAR_PWM_CORE (
        .clk        (clk),
        .reset      (reset),
        .comp_in    (comp_in),
        .trial_code (trial_code),
        .ready      (adc_ready)
    );

    // PWM DAC driven by current trial_code
    pwm #(
        .WIDTH (RAMP_WIDTH)
    ) PWM_CORE (
        .clk        (clk),
        .reset      (reset),
        .enable     (1'b1),
        .duty_cycle (trial_code),
        .pwm_out    (pwm_out)
    );

    // At the end of conversion, adc_code equals trial_code
    assign adc_code = trial_code;

endmodule
