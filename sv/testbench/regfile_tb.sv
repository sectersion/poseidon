`timescale 1ns/1ps

module regfile_tb;


    //basic stuff
    logic clk;
    logic rst;
    //read port interface (x2)
    logic [4:0] rs1_addr;
    logic [31:0] rs1_data;
    logic [4:0] rs2_addr;
    logic [31:0] rs2_data;
    //write port interface
    logic we;
    logic [4:0] rd_addr;
    logic [31:0] rd_data;

regfile dut (
    .clk(clk),
    .rst(rst),
    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .we(we),
    .rd_addr(rd_addr),
    .rd_data(rd_data)
);


always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    we  = 0;

    #20;
    rst = 0;

    // Write to x1
    rd_addr = 5'd1;
    rd_data = 32'hDEADBEEF;
    we = 1;
    #10;
    we = 0;

    // Read from x1
    rs1_addr = 5'd1;
    #10;

    //read x0 (should be 0)
    rs1_addr = 5'd0;
    #10;
    // Try writing x0 (should not change)
    rd_addr = 5'd0;
    rd_data = 32'hFFFFFFFF;
    we = 1;
    #10;
    we = 0;
    //read x0 again
    rs1_addr = 5'd0;
    #20;

    $finish;
end

endmodule