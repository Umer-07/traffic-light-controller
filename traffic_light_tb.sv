// ============================================================
// Testbench — traffic_light
// Tests:
//   1. Basic cycle: RED → GREEN → YELLOW → RED
//   2. Pedestrian: press during GREEN, verify WALK fires
//   3. No stray walk if button never pressed
// ============================================================

`timescale 1ns/1ps

module traffic_light_tb;

    // ---- DUT signals ----------------------------------------
    logic clk;
    logic rst_n;
    logic ped_btn;
    logic red, yellow, green, walk;

    // ---- Instantiate DUT ------------------------------------
    traffic_light dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .ped_btn (ped_btn),
        .red     (red),
        .yellow  (yellow),
        .green   (green),
        .walk    (walk)
    );

    // ---- Clock generator: 10 ns period (100 MHz) ------------
    initial clk = 0;
    always #5 clk = ~clk;

    // ---- Helper task: wait N rising edges -------------------
    task wait_cycles(input int n);
        repeat (n) @(posedge clk);
        #1;  // small delta so outputs settle
    endtask

    // ---- Helper task: check a single output -----------------
    task check(
        input string  sig_name,
        input logic   actual,
        input logic   expected
    );
        if (actual !== expected) begin
            $display("FAIL  [%0t] %s = %b, expected %b", $time, sig_name, actual, expected);
        end else begin
            $display("PASS  [%0t] %s = %b", $time, sig_name, actual);
        end
    endtask

    // ---- Main test sequence ---------------------------------
    integer cycle;

    initial begin
        // Waveform dump (works with Icarus + GTKWave)
        $dumpfile("traffic_light.vcd");
        $dumpvars(0, traffic_light_tb);

        $display("=== Traffic Light Controller Testbench ===");

        // ---- Reset ------------------------------------------
        rst_n   = 0;
        ped_btn = 0;
        wait_cycles(2);
        rst_n = 1;
        wait_cycles(1);

        $display("\n--- TEST 1: verify reset lands in RED ---");
        check("red",    red,    1'b1);
        check("green",  green,  1'b0);
        check("yellow", yellow, 1'b0);
        check("walk",   walk,   1'b0);

        // ---- Let full basic cycle run without ped_btn -------
        $display("\n--- TEST 2: basic cycle (no pedestrian) ---");

        // RED → GREEN (RED_TIME = 10 cycles)
        wait_cycles(10);
        $display("[%0t] Expecting GREEN", $time);
        check("green",  green,  1'b1);
        check("red",    red,    1'b0);

        // GREEN → YELLOW (GREEN_TIME = 12 cycles)
        wait_cycles(12);
        $display("[%0t] Expecting YELLOW", $time);
        check("yellow", yellow, 1'b1);
        check("green",  green,  1'b0);

        // YELLOW → RED (YELLOW_TIME = 4 cycles, no ped_btn → no WALK)
        wait_cycles(4);
        $display("[%0t] Expecting RED (no walk)", $time);
        check("red",    red,    1'b1);
        check("walk",   walk,   1'b0);

        // ---- Pedestrian test --------------------------------
        $display("\n--- TEST 3: pedestrian button pressed during GREEN ---");

        // Wait through RED into GREEN
        wait_cycles(10);   // RED expires → GREEN
        $display("[%0t] In GREEN; pressing ped_btn for 2 cycles", $time);
        ped_btn = 1;
        wait_cycles(2);
        ped_btn = 0;

        // Let GREEN expire → YELLOW
        wait_cycles(10);   // remaining GREEN time
        $display("[%0t] Expecting YELLOW", $time);
        check("yellow", yellow, 1'b1);

        // YELLOW expires → should go to WALK (ped_btn was latched)
        wait_cycles(4);
        $display("[%0t] Expecting WALK (pedestrians cross, cars stay RED)", $time);
        check("walk",   walk,   1'b1);
        check("red",    red,    1'b1);   // cars still stopped
        check("green",  green,  1'b0);

        // WALK expires → back to RED, latch cleared
        wait_cycles(8);
        $display("[%0t] Back to RED after WALK", $time);
        check("red",    red,    1'b1);
        check("walk",   walk,   1'b0);

        // ---- One more clean cycle (no ped_btn) --------------
        $display("\n--- TEST 4: second clean cycle after WALK ---");
        wait_cycles(10);   // RED → GREEN
        check("green", green, 1'b1);
        wait_cycles(12);   // GREEN → YELLOW
        check("yellow", yellow, 1'b1);
        wait_cycles(4);    // YELLOW → RED (no ped_btn)
        check("red",   red,   1'b1);
        check("walk",  walk,  1'b0);

        $display("\n=== All tests complete. Check waveform: traffic_light.vcd ===");
        $finish;
    end

    // ---- Timeout watchdog (prevents infinite hangs) ---------
    initial begin
        #10000;
        $display("TIMEOUT — simulation exceeded 10000 ns");
        $finish;
    end

endmodule
