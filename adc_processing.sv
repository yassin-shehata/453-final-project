module adc_processing #(
    parameter int POWER = 8    // default: 2^8 = 256-sample moving average
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        ready,
    input  logic [15:0] data,
    output logic [15:0] scaled_adc_data, // = averaged raw
    output logic        ready_pulse
);


    logic [15:0] ave_data;
    logic        ready_r;

    always_ff @(posedge clk) begin
        if (reset)
            ready_r <= 1'b0;
        else
            ready_r <= ready;
    end

    assign ready_pulse = (~ready_r & ready);

    averager #(
        .power(2),
        .N(16)
    ) AVERAGER (
        .reset (reset),
        .clk   (clk),
        .EN    (ready_pulse),
        .Din   (data),
        .Q     (ave_data)
    );

    always_ff @(posedge clk) begin
        if (reset)
            scaled_adc_data <= 16'd0;
        else if (ready_pulse)
            scaled_adc_data <= ave_data;  // JUST averaged raw
    end

endmodule
