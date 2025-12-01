// pwm_ramp_adc
// Authors: Yassin Shehata, Abdelrahman Salem, Ahmed Attiya

module pwm_ramp_adc #(
    parameter int RAMP_WIDTH  = 8,
    parameter int STEP_PERIOD = 2000
)(
    input  logic                  clk,
    input  logic                  reset,
    input  logic                  comp_in,     // from comparator (JA1)
    output logic                  pwm_out,     // to RC filter
    output logic [RAMP_WIDTH-1:0] adc_code,    // captured code
    output logic                  adc_ready    // 1-cycle pulse when adc_code updates
);

    // Step timer: pulse every STEP_PERIOD clocks
    logic step_pulse;

    downcounter #(
        .PERIOD(STEP_PERIOD)
    ) STEP_TIMER (
        .clk    (clk),
        .reset  (reset),
        .enable (1'b1),
        .zero   (step_pulse)
    );

    // Ramp code: 0 → max, then wrap
    logic [RAMP_WIDTH-1:0] ramp_code;

    always_ff @(posedge clk) begin
        if (reset) begin
            ramp_code <= '0;
        end else if (step_pulse) begin
            if (ramp_code == {RAMP_WIDTH{1'b1}})
                ramp_code <= '0;
            else
                ramp_code <= ramp_code + 1'b1;
        end
    end

    // Drive PWM with ramp_code as duty cycle
    pwm #(
        .WIDTH(RAMP_WIDTH)
    ) PWM_CORE (
        .clk        (clk),
        .reset      (reset),
        .enable     (1'b1),
        .duty_cycle (ramp_code),
        .pwm_out    (pwm_out)
    );

    // Sync comparator and detect falling edge
    logic comp_sync1, comp_sync2;
    logic comp_prev;
    logic captured;
    logic comp_edge;

    always_ff @(posedge clk) begin
        if (reset) begin
            comp_sync1 <= 1'b0;
            comp_sync2 <= 1'b0;
            comp_prev  <= 1'b0;
        end else begin
            comp_sync1 <= comp_in;
            comp_sync2 <= comp_sync1;
            comp_prev  <= comp_sync2;
        end
    end

    always_comb begin
        comp_edge = (comp_prev == 1'b1 && comp_sync2 == 1'b0);
    end

    // Capture adc_code on first edge in each ramp
    always_ff @(posedge clk) begin
        if (reset) begin
            adc_code  <= '0;
            adc_ready <= 1'b0;
            captured  <= 1'b0;
        end else begin
            adc_ready <= 1'b0;

            // allow new capture when ramp wraps
            if (step_pulse && (ramp_code == {RAMP_WIDTH{1'b1}})) begin
                captured <= 1'b0;
            end

            // first comparator edge this ramp
            if (!captured && comp_edge) begin
                adc_code  <= ramp_code;
                adc_ready <= 1'b1;
                captured  <= 1'b1;
            end
        end
    end

endmodule
