module seven_segment_digit_selector (
    input  logic clk,
    input  logic reset,
    output logic [1:0] digit_select_2bit, // 0..3 for MUX
    output logic [3:0] digit_select_1hot  // 1-hot for anodes
);

    logic [16:0] count;
    logic [3:0] q, d;

    // clock divider (~763 Hz)
    always_ff @(posedge clk) begin
        if (reset)
            count <= 17'd0;
        else
            count <= count + 1;
    end

    // rotating 1-hot
    always_ff @(posedge clk) begin
        if (reset)
            q <= 4'b1000;          // FIXED - start on digit 3
        else if (count == 17'd0)
            q <= d;
    end

    assign d[0] = q[3];
    assign d[1] = q[0];
    assign d[2] = q[1];
    assign d[3] = q[2];

    assign digit_select_1hot = q;

    // convert one-hot → 2-bit index for digit_multiplexor
    always_comb begin
        case (q)
            4'b0001: digit_select_2bit = 2'd0;
            4'b0010: digit_select_2bit = 2'd1;
            4'b0100: digit_select_2bit = 2'd2;
            4'b1000: digit_select_2bit = 2'd3;
            default: digit_select_2bit = 2'd0;
        endcase
    end

endmodule
