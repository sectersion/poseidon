`timescale 1ns/1ps

module if_stage_tb;

    // =============================
    // Signals
    // =============================
    logic clk;
    logic rst;
    logic stall;
    logic redirect;
    logic [31:0] redirect_pc;

    logic [31:0] pc_out;
    logic [31:0] instr_out;
    logic valid_out;

    // =============================
    // DUT
    // =============================
    if_stage dut (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .redirect(redirect),
        .redirect_pc(redirect_pc),
        .pc_out(pc_out),
        .instr_out(instr_out),
        .valid_out(valid_out)
    );

    // =============================
    // Clock (10ns period)
    // =============================
    always #5 clk = ~clk;

    // =============================
    // Monitor
    // =============================
    always @(posedge clk) begin
        $display("Time=%0t | PC=%h | Stall=%b | Redirect=%b | Valid=%b | Instr=%h",
                 $time, pc_out, stall, redirect, valid_out, instr_out);
    end

    // =============================
    // Stimulus (Clock Synchronous)
    // =============================
    initial begin
        $dumpfile("if_stage.vcd");
        $dumpvars(0, if_stage_tb);

        clk = 0;
        rst = 1;
        stall = 0;
        redirect = 0;
        redirect_pc = 0;

        // Hold reset for 2 cycles
        repeat (2) @(negedge clk);
        rst = 0;

        // Let PC increment for 4 cycles
        repeat (4) @(negedge clk);

        // Trigger redirect
        @(negedge clk);
        redirect_pc = 32'h00000020;
        redirect = 1;

        @(negedge clk);
        redirect = 0;

        // Let it increment
        repeat (3) @(negedge clk);

        // Trigger stall
        @(negedge clk);
        stall = 1;

        repeat (3) @(negedge clk);

        stall = 0;

        // Let it increment again
        repeat (3) @(negedge clk);

        $display("IF stage behavioral test complete.");
        $finish;
    end

endmodule
