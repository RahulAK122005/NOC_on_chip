`timescale 1ns/1ps

// ============================================================
// Self-checking testbench for 5x5 crossbar
// Tests: directed per-port/per-select, invalid selects,
//        multicast, permutation, and constrained-random.
// ============================================================
module crossbar_tb;

    parameter DATA_WIDTH = 32;

    // ---------------- DUT signals ----------------
    reg  [DATA_WIDTH-1:0] in_north, in_south, in_east, in_west, in_local;
    reg  [2:0]            sel_north, sel_south, sel_east, sel_west, sel_local;
    wire [DATA_WIDTH-1:0] out_north, out_south, out_east, out_west, out_local;

    integer errors;
    integer tests;
    integer i, p, s;

    // ---------------- DUT ----------------
    crossbar #(.DATA_WIDTH(DATA_WIDTH)) dut (
        .in_north (in_north),  .in_south (in_south),
        .in_east  (in_east),   .in_west  (in_west),
        .in_local (in_local),
        .sel_north(sel_north), .sel_south(sel_south),
        .sel_east (sel_east),  .sel_west (sel_west),
        .sel_local(sel_local),
        .out_north(out_north), .out_south(out_south),
        .out_east (out_east),  .out_west (out_west),
        .out_local(out_local)
    );

    // ---------------- Reference model ----------------
    function [DATA_WIDTH-1:0] expected;
        input [2:0] sel;
        begin
            case (sel)
                3'b000:  expected = in_north;
                3'b001:  expected = in_south;
                3'b010:  expected = in_east;
                3'b011:  expected = in_west;
                3'b100:  expected = in_local;
                default: expected = {DATA_WIDTH{1'b0}};
            endcase
        end
    endfunction

    // ---------------- Helpers ----------------
    task check_port;
        input [8*6-1:0]        name;
        input [DATA_WIDTH-1:0] got;
        input [2:0]            sel;
        reg   [DATA_WIDTH-1:0] exp;
        begin
            exp   = expected(sel);
            tests = tests + 1;
            if (got !== exp) begin
                errors = errors + 1;
                $display("[FAIL] t=%0t %0s: sel=%b expected=%h got=%h",
                         $time, name, sel, exp, got);
            end
        end
    endtask

    // Check all five outputs against the reference model
    task check_all;
        begin
            #1; // let combinational logic settle
            check_port("north", out_north, sel_north);
            check_port("south", out_south, sel_south);
            check_port("east ", out_east,  sel_east);
            check_port("west ", out_west,  sel_west);
            check_port("local", out_local, sel_local);
        end
    endtask

    task set_all_sel;
        input [2:0] n, so, e, w, l;
        begin
            sel_north = n; sel_south = so; sel_east = e;
            sel_west  = w; sel_local = l;
        end
    endtask

    task set_one_sel;
        input integer port;
        input [2:0]   val;
        begin
            case (port)
                0: sel_north = val;
                1: sel_south = val;
                2: sel_east  = val;
                3: sel_west  = val;
                4: sel_local = val;
            endcase
        end
    endtask

    task randomize_inputs;
        begin
            in_north = $random; in_south = $random; in_east = $random;
            in_west  = $random; in_local = $random;
        end
    endtask

    task randomize_sels;
        begin
            sel_north = $random; sel_south = $random; sel_east = $random;
            sel_west  = $random; sel_local = $random;
        end
    endtask

    // ---------------- Waveform dump ----------------
    initial begin
        $dumpfile("crossbar_tb.vcd");
        $dumpvars(0, crossbar_tb);
    end

    // ---------------- Main stimulus ----------------
    initial begin
        errors = 0;
        tests  = 0;

        // Distinct, easily recognizable data on each input
        in_north = 32'hAAAA_0001;
        in_south = 32'hBBBB_0002;
        in_east  = 32'hCCCC_0003;
        in_west  = 32'hDDDD_0004;
        in_local = 32'hEEEE_0005;
        set_all_sel(0, 0, 0, 0, 0);
        check_all;

        // ---- Test 1: each output port x each select value (0..7) ----
        // Other ports get random selects to catch cross-coupling bugs.
        $display("--- Test 1: per-port, per-select sweep (incl. invalid 5-7) ---");
        for (p = 0; p < 5; p = p + 1) begin
            for (s = 0; s < 8; s = s + 1) begin
                randomize_sels;
                set_one_sel(p, s[2:0]);
                check_all;
            end
        end

        // ---- Test 2: multicast (all outputs from the same input) ----
        $display("--- Test 2: multicast ---");
        for (s = 0; s < 5; s = s + 1) begin
            set_all_sel(s[2:0], s[2:0], s[2:0], s[2:0], s[2:0]);
            check_all;
        end

        // ---- Test 3: permutations (straight, reverse, rotate) ----
        $display("--- Test 3: permutations ---");
        set_all_sel(3'd0, 3'd1, 3'd2, 3'd3, 3'd4); check_all; // identity
        set_all_sel(3'd4, 3'd3, 3'd2, 3'd1, 3'd0); check_all; // reverse
        set_all_sel(3'd1, 3'd2, 3'd3, 3'd4, 3'd0); check_all; // rotate left
        set_all_sel(3'd4, 3'd0, 3'd1, 3'd2, 3'd3); check_all; // rotate right

        // ---- Test 4: all invalid selects -> all zeros ----
        $display("--- Test 4: invalid selects ---");
        for (s = 5; s < 8; s = s + 1) begin
            set_all_sel(s[2:0], s[2:0], s[2:0], s[2:0], s[2:0]);
            check_all;
        end

        // ---- Test 5: data corner cases (all 0s, all 1s, alternating) ----
        $display("--- Test 5: data corner cases ---");
        in_north = {DATA_WIDTH{1'b0}};
        in_south = {DATA_WIDTH{1'b1}};
        in_east  = {DATA_WIDTH/2{2'b01}};
        in_west  = {DATA_WIDTH/2{2'b10}};
        in_local = {DATA_WIDTH{1'b0}} | 1'b1;
        for (s = 0; s < 5; s = s + 1) begin
            set_all_sel(s[2:0], s[2:0], s[2:0], s[2:0], s[2:0]);
            check_all;
        end

        // ---- Test 6: input change with static selects (combinational response) ----
        $display("--- Test 6: input changes under fixed selects ---");
        set_all_sel(3'd0, 3'd1, 3'd2, 3'd3, 3'd4);
        for (i = 0; i < 50; i = i + 1) begin
            randomize_inputs;
            check_all;
        end

        // ---- Test 7: constrained-random (valid + invalid selects) ----
        $display("--- Test 7: random ---");
        for (i = 0; i < 5000; i = i + 1) begin
            randomize_inputs;
            randomize_sels;
            check_all;
        end

        // ---------------- Summary ----------------
        $display("==========================================");
        if (errors == 0)
            $display("PASS: %0d checks, 0 errors", tests);
        else
            $display("FAIL: %0d checks, %0d errors", tests, errors);
        $display("==========================================");
        $finish;
    end

endmodule
