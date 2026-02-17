module reg #(
    parameter WIDTH = 32,
    parameter RESET_VALUE = 0
)(
    input  logic clk,
    input  logic rst,
    input  logic en,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);

always_ff @(posedge clk) begin
    if (rst)
        q <= RESET_VALUE;
    else if (en)
        q <= d;
end

endmodule
