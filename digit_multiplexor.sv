module digit_multiplexor (
    input  logic [15:0] value,        // 4 digits: [15:12] [11:8] [7:4] [3:0]
    input  logic [1:0]  digit_select, // which digit (0..3)
    input  logic [3:0]  decimal_point,
    output logic [3:0]  current_digit,
    output logic        dp_out
);

    always_comb begin
        case (digit_select)
            2'b00: current_digit = value[3:0];
            2'b01: current_digit = value[7:4];
            2'b10: current_digit = value[11:8];
            2'b11: current_digit = value[15:12];
            default: current_digit = 4'd0;
        endcase
    end

    always_comb begin
        case (digit_select)
            2'b00: dp_out = decimal_point[0];
            2'b01: dp_out = decimal_point[1];
            2'b10: dp_out = decimal_point[2];
            2'b11: dp_out = decimal_point[3];
            default: dp_out = 1'b1;
        endcase
    end

endmodule
