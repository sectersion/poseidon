module instr_mem (
    input  logic [31:0] addr,
    output logic [31:0] instr
);

    logic [31:0] mem [0:255];  // 256 words = 1KB

    // Word-aligned access
    assign instr = mem[addr[9:2]];

endmodule
