`timescale 1ns/1ps

module reg_en_flush #(
    parameter int WIDTH = 32,
    parameter logic [WIDTH-1:0] RESET_VALUE = '0
)(
    input  logic                     clk,
    input  logic                     rst,
    input  logic                     en,
    input  logic                     flush,
    input  logic [WIDTH-1:0]         d,
    output logic [WIDTH-1:0]         q
);

always_ff @(posedge clk) begin
    if (rst)
        q <= RESET_VALUE;
    else if (flush)
        q <= RESET_VALUE;
    else if (en)
        q <= d;
end

endmodule
