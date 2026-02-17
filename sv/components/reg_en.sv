module reg_en #(
    parameter int WIDTH = 32,
    parameter logic [WIDTH-1:0] RESET_VALUE = '0
)(
    input  logic                     clk,
    input  logic                     rst,     // synchronous reset
    input  logic                     en,      // write enable
    input  logic [WIDTH-1:0]         d,
    output logic [WIDTH-1:0]         q
);

always_ff @(posedge clk) begin
    if (rst)
        q <= RESET_VALUE;
    else if (en)
        q <= d;
end

endmodule
