// r2r_sar_adc.sv
// Successive-approximation ADC using R-2R DAC

module r2r_sar_adc #(
    parameter int RAMP_WIDTH     = 8,
    parameter int SETTLE_CYCLES  = 50000
)(
    input  logic                      clk,
    input  logic                      reset,
    input  logic                      comp_in,      // comparator from R-2R
    output logic [RAMP_WIDTH-1:0]     r2r_bus,      // drive ladder
    output logic [RAMP_WIDTH-1:0]     adc_code,     // final SAR code
    output logic                      adc_ready
);

    logic [RAMP_WIDTH-1:0] trial_code;

    sar_core #(
        .WIDTH         (RAMP_WIDTH),
        .SETTLE_CYCLES (SETTLE_CYCLES)
    ) SAR_R2R_CORE (
        .clk        (clk),
        .reset      (reset),
        .comp_in    (comp_in),
        .trial_code (trial_code),
        .ready      (adc_ready)
    );

    // R-2R DAC code = current trial code
    assign r2r_bus  = trial_code;
    assign adc_code = trial_code;

endmodule
