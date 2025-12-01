module seven_segment_display_subsystem (
    input  logic        clk,
    input  logic        reset,
    input  logic [15:0] value,          // raw/scaled/mux'd ADC data
    input  logic        bin_bcd_select, // 0 = HEX, 1 = DEC

    output logic AN1, AN2, AN3, AN4,
    output logic CA, CB, CC, CD, CE, CF, CG, DP
);

    // ---------------------------------------------------------
    // Optional binary → BCD converter
    // ---------------------------------------------------------
    logic [15:0] bcd_value;

    generate
        if (1) begin : GEN_BCD
            logic [15:0] bcd_temp;
            bin_to_bcd B2B (
                .bin_in (value),
                .bcd_out(bcd_temp),
                .clk    (clk),
                .reset  (reset)
            );

            assign bcd_value = bin_bcd_select ? bcd_temp : value;
        end
    endgenerate

    // ---------------------------------------------------------
    // Digit selector
    // ---------------------------------------------------------
    logic [1:0] digit_sel_index;
    logic [3:0] digit_sel_1hot;

    seven_segment_digit_selector DIGSEL (
        .clk               (clk),
        .reset             (reset),
        .digit_select_2bit (digit_sel_index),
        .digit_select_1hot (digit_sel_1hot)
    );

    // ---------------------------------------------------------
    // Digit multiplexer
    // ---------------------------------------------------------
    logic [3:0] current_digit;
    logic       dp_signal;

    digit_multiplexor DMUX (
        .value         (bcd_value),
        .digit_select  (digit_sel_index),
        .decimal_point (4'b1111),    // all decimal points OFF
        .current_digit (current_digit),
        .dp_out        (dp_signal)
    );

    // ---------------------------------------------------------
    // Segment decoder
    // ---------------------------------------------------------
   seven_segment_decoder DEC (
    .data (current_digit),
    .dp_in(1'b0),     // FORCE DP OFF - Basys3 active low
    .CA(CA), .CB(CB), .CC(CC), .CD(CD),
    .CE(CE), .CF(CF), .CG(CG), .DP(DP)
);


    // ---------------------------------------------------------
    // Active-low anodes
    // ---------------------------------------------------------
    assign AN1 = ~digit_sel_1hot[0];
    assign AN2 = ~digit_sel_1hot[1];
    assign AN3 = ~digit_sel_1hot[2];
    assign AN4 = ~digit_sel_1hot[3];

endmodule
