// xadc_subsystem
// Authors: Yassin Shehata, Abdelrahman Salem, Ahmed Attiya

module xadc_subsystem (
    input  logic        clk,
    input  logic        reset,
    input  logic        vauxp15,
    input  logic        vauxn15,
    output logic [15:0] raw_out,
    output logic [15:0] scaled_out
);

    // DRP interface
    logic [6:0]  daddr_in;
    logic        den_in;
    logic [15:0] di_in;
    logic        dwe_in;

    logic        busy_out;
    logic [4:0]  channel_out;
    logic [15:0] do_out;
    logic        drdy_out;
    logic        eoc_out;
    logic        eos_out;
    logic        alarm_out;

    // Read VAUX15 on each EOC
    assign daddr_in = 7'h1F; 
    assign di_in    = 16'd0;
    assign dwe_in   = 1'b0;
    assign den_in   = eoc_out;

    localparam logic VP_UNUSED = 1'b0;
    localparam logic VN_UNUSED = 1'b0;

    xadc_wiz_0 XADC_IP (
        .daddr_in   (daddr_in),
        .dclk_in    (clk),
        .den_in     (den_in),
        .di_in      (di_in),
        .dwe_in     (dwe_in),
        .reset_in   (reset),

        .vauxp15    (vauxp15),
        .vauxn15    (vauxn15),

        .busy_out   (busy_out),
        .channel_out(channel_out),
        .do_out     (do_out),
        .drdy_out   (drdy_out),
        .eoc_out    (eoc_out),
        .eos_out    (eos_out),
        .alarm_out  (alarm_out),

        .vp_in      (VP_UNUSED),
        .vn_in      (VN_UNUSED)
    );

      // Take DO[15:4] as 12-bit result
    logic [15:0] xadc_sample_16;

    always_comb begin
        xadc_sample_16 = {4'b0000, do_out[15:4]};
    end

    assign raw_out = xadc_sample_16;

    // Compress 12-bit XADC sample into 8-bit code for oversampling
    logic [7:0] xadc_sample_8;
    assign xadc_sample_8 = xadc_sample_16[11:4];   // drop 4 LSBs

    // Moving average / oversampling using averager_simple
    logic [15:0] xadc_avg_full;
    logic [7:0]  xadc_avg8;

    averager_simple #(
        .power(8)      // 2^8 = 256-sample moving average
    ) XADC_AVG (
        .clk   (clk),
        .reset (reset),
        .EN    (drdy_out),        // new XADC sample ready
        .Din   (xadc_sample_8),   // 8-bit version of the XADC value
        .Q     (xadc_avg_full)
    );

    assign xadc_avg8  = xadc_avg_full[15:8];

    // Expand averaged 8-bit code back to a 12-bit-style 16-bit value (<< 4)
    assign scaled_out = {4'b0000, xadc_avg8, 4'b0000};

endmodule


