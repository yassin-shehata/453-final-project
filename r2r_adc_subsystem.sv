// r2r_adc_subsystem.sv
// Ramp/SAR selectable + averaging

module r2r_adc_subsystem (
    input  logic        clk,
    input  logic        reset,
    input  logic        comp_r2r,
    input  logic        sar_mode,     // 0 = ramp ADC, 1 = SAR ADC

    output logic [7:0]  r2r_out,
    output logic [15:0] raw_out,      // zero-extended raw code for display
    output logic [15:0] scaled_out,   // oversampled & averaged
    output logic        scaled_ready  // pulse when new sample enters averager
);

    // ---------------- RAMP path ----------------
    logic [7:0] r2r_ramp_code;
    logic       r2r_ramp_ready;
    logic [7:0] r2r_ramp_bus;

    r2r_ramp_adc #(
        .RAMP_WIDTH  (8),
        .STEP_PERIOD (100000)    // faster ramp than original 50000
    ) R2R_RAMP (
        .clk      (clk),
        .reset    (reset),
        .comp_in  (comp_r2r),
        .r2r_bus  (r2r_ramp_bus),
        .adc_code (r2r_ramp_code),
        .adc_ready(r2r_ramp_ready)
    );

    // ---------------- SAR path ----------------
    logic [7:0] r2r_sar_code;
    logic       r2r_sar_ready;
    logic [7:0] r2r_sar_bus;

    r2r_sar_adc #(
        .RAMP_WIDTH    (8),
        .SETTLE_CYCLES (2000000)
    ) R2R_SAR (
        .clk      (clk),
        .reset    (reset),
        .comp_in  (comp_r2r),
        .r2r_bus  (r2r_sar_bus),
        .adc_code (r2r_sar_code),
        .adc_ready(r2r_sar_ready)
    );

    // -------- Select active algorithm (common code stream) --------
    logic [7:0] r2r_code_sel;
    logic       r2r_ready_sel;

    always_comb begin
        if (sar_mode) begin
            r2r_out       = r2r_sar_bus;
            r2r_code_sel  = r2r_sar_code;
            r2r_ready_sel = r2r_sar_ready;
        end else begin
            r2r_out       = r2r_ramp_bus;
            r2r_code_sel  = r2r_ramp_code;
            r2r_ready_sel = r2r_ramp_ready;
        end
    end

    // -------- Throttled raw display (so SAR raw isn't too glitchy) --------
    logic [7:0] r2r_raw_disp;
    logic [7:0] r2r_raw_div_cnt;

    always_ff @(posedge clk) begin
        if (reset) begin
            r2r_raw_disp    <= 8'd0;
            r2r_raw_div_cnt <= 8'd0;
        end else begin
            if (!sar_mode) begin
                // RAMP MODE: show every conversion
                if (r2r_ready_sel)
                    r2r_raw_disp <= r2r_code_sel;
                r2r_raw_div_cnt <= 8'd0;
            end else begin
                // SAR MODE: update raw display every 8 conversions
                if (r2r_ready_sel) begin
                    if (r2r_raw_div_cnt == 8'd7) begin
                        r2r_raw_disp    <= r2r_code_sel;
                        r2r_raw_div_cnt <= 8'd0;
                    end else begin
                        r2r_raw_div_cnt <= r2r_raw_div_cnt + 1'b1;
                    end
                end
            end
        end
    end

    // Zero-extend raw display value
    logic [15:0] r2r_raw_ext;
    assign r2r_raw_ext = {8'd0, r2r_raw_disp};
    assign raw_out     = r2r_raw_ext;

    // ---------------- Averaging (power = 8) ----------------
    logic [15:0] avg_out;

    averager_simple #(
        .power(8)   // <<< back to 8
    ) R2R_AVG (
        .clk   (clk),
        .reset (reset),
        .EN    (r2r_ready_sel),
        .Din   (r2r_code_sel),
        .Q     (avg_out)
    );

    assign scaled_out   = avg_out;
    assign scaled_ready = r2r_ready_sel;

endmodule
