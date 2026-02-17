module regfile (
    input  logic        clk,
    input  logic        rst,

    // Read ports
    input  logic [4:0]  rs1_addr,
    input  logic [4:0]  rs2_addr,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,

    // Write port
    input  logic        we,
    input  logic [4:0]  rd_addr,
    input  logic [31:0] rd_data
);

logic [31:0] regs [31:0];



assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : regs[rs1_addr];
assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : regs[rs2_addr];



always_ff @(posedge clk) begin
    if (rst) begin
        integer i;
        for (i = 0; i < 32; i++)
            regs[i] <= 32'd0;
    end
    else if (we && rd_addr != 5'd0) begin
        regs[rd_addr] <= rd_data;
    end
end

endmodule
