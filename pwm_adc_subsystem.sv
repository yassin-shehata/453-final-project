// pwm_adc_subsystem.sv
// Ramp/SAR selectable + averaging

module pwm_adc_subsystem (
    input  logic        clk,
    input  logic        reset,
    input  logic        comp_pwm,
    input  logic        sar_mode,     // 0 = ramp ADC, 1 = SAR ADC

    output logic        pwm_out,
    output logic [15:0] raw_out,      // zero-extended raw code for display
    output logic [15:0] scaled_out,   // oversampled & averaged
    output logic        scaled_ready  // pulse when new sample enters averager
);

    // ---------------- RAMP path ----------------
    logic [7:0] pwm_ramp_code;
    logic       pwm_ramp_ready;
    logic       pwm_ramp_pwm_out;

    pwm_ramp_adc #(
        .RAMP_WIDTH  (8),
        .STEP_PERIOD (100000)    // faster ramp than original 50000
    ) PWM_RAMP (
        .clk      (clk),
        .reset    (reset),
        .comp_in  (comp_pwm),
        .pwm_out  (pwm_ramp_pwm_out),
        .adc_code (pwm_ramp_code),
        .adc_ready(pwm_ramp_ready)
    );

    // ---------------- SAR path ----------------
    logic [7:0] pwm_sar_code;
    logic       pwm_sar_ready;
    logic       pwm_sar_pwm_out;

    pwm_sar_adc #(
        .RAMP_WIDTH    (8),
        .SETTLE_CYCLES (2000000)
    ) PWM_SAR (
        .clk      (clk),
        .reset    (reset),
        .comp_in  (comp_pwm),
        .pwm_out  (pwm_sar_pwm_out),
        .adc_code (pwm_sar_code),
        .adc_ready(pwm_sar_ready)
    );

    // -------- Select active algorithm (common code stream) --------
    logic [7:0] pwm_code_sel;
    logic       pwm_ready_sel;

    always_comb begin
        if (sar_mode) begin
            pwm_out       = pwm_sar_pwm_out;
            pwm_code_sel  = pwm_sar_code;
            pwm_ready_sel = pwm_sar_ready;
        end else begin
            pwm_out       = pwm_ramp_pwm_out;
            pwm_code_sel  = pwm_ramp_code;
            pwm_ready_sel = pwm_ramp_ready;
        end
    end

    // -------- Throttled raw display (so SAR raw isn't too glitchy) --------
    logic [7:0] pwm_raw_disp;
    logic [7:0] pwm_raw_div_cnt;

    always_ff @(posedge clk) begin
        if (reset) begin
            pwm_raw_disp    <= 8'd0;
            pwm_raw_div_cnt <= 8'd0;
        end else begin
            if (!sar_mode) begin
                // RAMP MODE: show every conversion
                if (pwm_ready_sel)
                    pwm_raw_disp <= pwm_code_sel;
                pwm_raw_div_cnt <= 8'd0;
            end else begin
                // SAR MODE: update raw display every 8 conversions
                if (pwm_ready_sel) begin
                    if (pwm_raw_div_cnt == 8'd7) begin
                        pwm_raw_disp    <= pwm_code_sel;
                        pwm_raw_div_cnt <= 8'd0;
                    end else begin
                        pwm_raw_div_cnt <= pwm_raw_div_cnt + 1'b1;
                    end
                end
            end
        end
    end

    // Zero-extend raw display value
    logic [15:0] pwm_raw_ext;
    assign pwm_raw_ext = {8'd0, pwm_raw_disp};
    assign raw_out     = pwm_raw_ext;

    // ---------------- Averaging (power = 8) ----------------
    logic [15:0] avg_out;

    averager_simple #(
        .power(8)   // <<< back to 8 so slices are valid
    ) PWM_AVG (
        .clk   (clk),
        .reset (reset),
        .EN    (pwm_ready_sel),
        .Din   (pwm_code_sel),
        .Q     (avg_out)
    );

    assign scaled_out   = avg_out;
    assign scaled_ready = pwm_ready_sel;

endmodule
