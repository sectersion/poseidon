module mux #(
    parameter WIDTH = 32,
    parameter INPUTS = 2
)(
    input  logic [WIDTH-1:0] in [INPUTS],
    input  logic [$clog2(INPUTS)-1:0] sel,
    output logic [WIDTH-1:0] out
);

always_comb begin
    out = in[sel];
end

endmodule
