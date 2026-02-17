`timescale 1ns/1ps

module pc_tb;

initial begin
    $dumpfile("pc_tb.vcd");
    $dumpvars(0, pc_tb);
end


logic clk;
logic rst;
logic stall;
logic redirect_valid;
logic [31:0] redirect_pc;
logic [31:0] pc;

// Instantiate DUT
pc #(
    .RESET_VECTOR(32'h00000000)
) dut (
    .clk(clk),
    .rst(rst),
    .stall(stall),
    .redirect_valid(redirect_valid),
    .redirect_pc(redirect_pc),
    .pc(pc)
);

// Clock generation
always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    stall = 0;
    redirect_valid = 0;
    redirect_pc = 0;

    #20;
    rst = 0;

    #40;
    stall = 1;      // freeze PC

    #20;
    stall = 0;

    #20;
    redirect_valid = 1;
    redirect_pc = 32'h00000100;

    #10;
    redirect_valid = 0;

    #40;
    $finish;
end

endmodule
