// sar_core.sv
// Generic successive-approximation core (MSB -> LSB)
// Assumes comp_in = 1 when Vin > Vdac, 0 when Vin <= Vdac

module sar_core #(
    parameter int WIDTH          = 8,
    parameter int SETTLE_CYCLES  = 50000   // wait time after each bit change
)(
    input  logic                 clk,
    input  logic                 reset,
    input  logic                 comp_in,     // from comparator (synchronized here)
    output logic [WIDTH-1:0]     trial_code,  // current DAC code under test
    output logic                 ready        // 1-cycle pulse when conversion done
);

    // Synchronize comparator to clk
    logic comp_sync1, comp_sync2;
    always_ff @(posedge clk) begin
        if (reset) begin
            comp_sync1 <= 1'b0;
            comp_sync2 <= 1'b0;
        end else begin
            comp_sync1 <= comp_in;
            comp_sync2 <= comp_sync1;
        end
    end
    wire comp = comp_sync2;  // stable comparator value

    // FSM state encoding
    typedef enum logic [2:0] {
        S_IDLE,         // initialize new conversion
        S_SET_BIT,      // set current bit = 1
        S_WAIT_SETTLE,  // wait for analog path to settle
        S_SAMPLE,       // sample comparator and decide bit
        S_DONE          // pulse ready and go back to IDLE
    } sar_state_t;

    sar_state_t state, next_state;

    // Which bit are we testing? Start at MSB and go down to LSB
    int unsigned bit_index;

    // Settling counter
    localparam int SETTLE_WIDTH = $clog2(SETTLE_CYCLES);
    logic [SETTLE_WIDTH-1:0] settle_cnt;

    // State register
    always_ff @(posedge clk) begin
        if (reset)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // Next-state logic
    always_comb begin
        next_state = state;
        case (state)
            S_IDLE:         next_state = S_SET_BIT;
            S_SET_BIT:      next_state = S_WAIT_SETTLE;
            S_WAIT_SETTLE:  next_state = (settle_cnt == SETTLE_CYCLES-1) ? S_SAMPLE : S_WAIT_SETTLE;
            S_SAMPLE:       next_state = (bit_index == 0) ? S_DONE : S_SET_BIT;
            S_DONE:         next_state = S_IDLE;
            default:        next_state = S_IDLE;
        endcase
    end

    // Outputs & internal registers
    always_ff @(posedge clk) begin
        if (reset) begin
            trial_code  <= '0;
            ready       <= 1'b0;
            bit_index   <= 0;
            settle_cnt  <= '0;
        end else begin
            ready <= 1'b0; // default, only high in S_DONE

            case (state)
                S_IDLE: begin
                    // Start a new conversion
                    trial_code <= '0;
                    bit_index  <= WIDTH-1;
                    settle_cnt <= '0;
                end

                S_SET_BIT: begin
                    // Tentatively set current bit to 1
                    trial_code[bit_index] <= 1'b1;
                    settle_cnt            <= '0;
                end

                S_WAIT_SETTLE: begin
                    // Wait for DAC + analog front-end to settle
                    settle_cnt <= settle_cnt + 1'b1;
                end

                S_SAMPLE: begin
                    // Decide whether the bit stays 1 or is cleared to 0
                    // comp == 1 → Vin > Vdac → keep bit at 1
                    // comp == 0 → Vin <= Vdac → clear bit back to 0
                    if (!comp) begin
                        trial_code[bit_index] <= 1'b0;
                    end

                    if (bit_index != 0)
                        bit_index <= bit_index - 1;
                end

                S_DONE: begin
                    // Finished one full MSB→LSB search
                    ready <= 1'b1;  // 1-cycle pulse
                end
            endcase
        end
    end

endmodule
