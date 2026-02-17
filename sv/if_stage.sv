import core_pkg::*;

module if_stage #(
    parameter RESET_VECTOR = 32'h00000000
)(
    input  logic clk,
    input  logic rst,

    input  logic stall,
    input  logic flush,

    input  logic        redirect_valid,
    input  logic [31:0] redirect_pc,

    output if_id_t      if_id_out
);

logic [31:0] pc;
logic [31:0] next_pc;
logic [31:0] instr;

if_id_t if_id_next;



always_comb begin
    if (redirect_valid)
        next_pc = redirect_pc;
    else
        next_pc = pc + 32'd4;
end



reg_en #(
    .WIDTH(32),
    .RESET_VALUE(RESET_VECTOR)
) pc_reg (
    .clk(clk),
    .rst(rst),
    .en(!stall),
    .d(next_pc),
    .q(pc)
);



always_comb begin
    case (pc)
        32'h00000000: instr = 32'h00000013; // NOP
        32'h00000004: instr = 32'h00100093; // ADDI x1,x0,1
        32'h00000008: instr = 32'h00200113; // ADDI x2,x0,2
        32'h0000000C: instr = 32'h00308193; // ADDI x3,x1,3
        default:      instr = 32'h00000013;
    endcase
end



always_comb begin
    if_id_next.valid = 1'b1;
    if_id_next.pc    = pc;
    if_id_next.instr = instr;
end

reg_en_flush #(
    .WIDTH($bits(if_id_t))
) if_id_reg (
    .clk(clk),
    .rst(rst),
    .en(!stall),
    .flush(flush),
    .d(if_id_next),
    .q(if_id_out)
);

endmodule
