module pc #(
    parameter RESET_VECTOR = 32'h00000000
)(
    input  logic clk,
    input  logic rst,
    input  logic stall,

    input  logic        redirect_valid,
    input  logic [31:0] redirect_pc,

    output logic [31:0] pc
);

logic [31:0] next_pc;

always_comb begin
    if (redirect_valid)
        next_pc = redirect_pc;
    else
        next_pc = pc + 32'd4;
end

always_ff @(posedge clk) begin
    if (rst)
        pc <= RESET_VECTOR;
    else if (!stall)
        pc <= next_pc;
end

endmodule
