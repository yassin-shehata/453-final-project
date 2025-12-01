
module debug_led_driver (
    input  logic [1:0]  adc_select,
    input  logic [1:0]  bin_bcd_select,
    input  logic [7:0]  pwm_raw_code,
    input  logic        pwm_scaled_ready,
    input  logic        comp_pwm,       
    output logic [15:0] led
);
    always_comb begin
        led           = 16'd0;
        led[7:0]      = pwm_raw_code;
        led[9:8]      = adc_select;
        led[11:10]    = bin_bcd_select;
        led[12]       = pwm_scaled_ready;
        led[15]       = comp_pwm;       //show raw comparator on LED15
    end
endmodule
