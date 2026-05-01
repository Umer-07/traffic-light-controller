// ============================================================
// Traffic Light Controller — Finite State Machine
// Features: RED → GREEN → YELLOW → RED cycle
//           Pedestrian button triggers WALK state
// ============================================================

module traffic_light (
    input  logic clk,        // Clock signal
    input  logic rst_n,      // Active-low synchronous reset
    input  logic ped_btn,    // Pedestrian button (1 = pressed)

    // Car traffic lights
    output logic red,
    output logic yellow,
    output logic green,

    // Pedestrian signal
    output logic walk
);

    // ----------------------------------------------------------
    // State encoding
    // ----------------------------------------------------------
    typedef enum logic [1:0] {
        S_RED    = 2'b00,
        S_GREEN  = 2'b01,
        S_YELLOW = 2'b10,
        S_WALK   = 2'b11
    } state_t;

    state_t state, next_state;

    // ----------------------------------------------------------
    // Timer — counts clock cycles per state
    // Adjust these for your simulation speed.
    // With a 10ns clock: 500 = 5µs, scale up for real hardware.
    // ----------------------------------------------------------
    localparam int RED_TIME    = 10;   // cycles in RED
    localparam int GREEN_TIME  = 12;   // cycles in GREEN
    localparam int YELLOW_TIME = 4;    // cycles in YELLOW
    localparam int WALK_TIME   = 8;    // cycles in WALK

    logic [4:0] timer;
    logic       timer_done;
    logic       ped_latched;   // holds ped_btn until it can be served

    // ----------------------------------------------------------
    // Timer counter (sequential)
    // ----------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            timer <= '0;
        end else if (timer_done) begin
            timer <= '0;          // reset on state change
        end else begin
            timer <= timer + 1'b1;
        end
    end

    // ----------------------------------------------------------
    // Timer done — combinational decode
    // ----------------------------------------------------------
    always_comb begin
        case (state)
            S_RED    : timer_done = (timer == RED_TIME    - 1);
            S_GREEN  : timer_done = (timer == GREEN_TIME  - 1);
            S_YELLOW : timer_done = (timer == YELLOW_TIME - 1);
            S_WALK   : timer_done = (timer == WALK_TIME   - 1);
            default  : timer_done = 1'b0;
        endcase
    end

    // ----------------------------------------------------------
    // Latch pedestrian request (sequential)
    // Clears when WALK state begins.
    // ----------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            ped_latched <= 1'b0;
        end else if (state == S_WALK) begin
            ped_latched <= 1'b0;   // served — clear the latch
        end else if (ped_btn) begin
            ped_latched <= 1'b1;   // remember the press
        end
    end

    // ----------------------------------------------------------
    // State register (sequential)
    // ----------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n)
            state <= S_RED;
        else
            state <= next_state;
    end

    // ----------------------------------------------------------
    // Next-state logic (combinational)
    // ----------------------------------------------------------
    always_comb begin
        next_state = state;   // default: stay
        case (state)
            S_RED    : if (timer_done)               next_state = S_GREEN;
            S_GREEN  : if (timer_done)               next_state = S_YELLOW;
            S_YELLOW : if (timer_done && ped_latched) next_state = S_WALK;
                  else if (timer_done)               next_state = S_RED;
            S_WALK   : if (timer_done)               next_state = S_RED;
            default  : next_state = S_RED;
        endcase
    end

    // ----------------------------------------------------------
    // Output logic (combinational — Moore FSM)
    // ----------------------------------------------------------
    always_comb begin
        // Safe defaults (all off)
        red    = 1'b0;
        yellow = 1'b0;
        green  = 1'b0;
        walk   = 1'b0;

        case (state)
            S_RED    : red    = 1'b1;
            S_GREEN  : green  = 1'b1;
            S_YELLOW : yellow = 1'b1;
            S_WALK   : begin
                         red  = 1'b1;   // cars stay stopped
                         walk = 1'b1;   // pedestrians go
                       end
            default  : red = 1'b1;
        endcase
    end

endmodule
