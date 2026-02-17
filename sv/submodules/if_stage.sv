module if_stage (
    input  logic        clk,
    input  logic        rst,

    input  logic        stall,
    input  logic        redirect,
    input  logic [31:0] redirect_pc,

    output logic [31:0] pc_out,
    output logic [31:0] instr_out,
    output logic        valid_out
);

    logic [31:0] pc;

    instr_mem imem (
        .addr(pc),
        .instr(instr_out)
    );

    always_ff @(posedge clk or posedge rst) begin
    if (rst)
        pc <= 32'h00000000;
    else if (redirect)
        pc <= redirect_pc;        // redirect wins
    else if (!stall)
        pc <= pc + 4;
    end


    assign pc_out = pc;
    assign valid_out = !stall;

endmodule
