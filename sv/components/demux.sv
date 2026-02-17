`timescale 1ns/1ps

module dmux #(
    parameter WIDTH  = 32,
    parameter OUTPUTS = 2
)(
    input  logic [WIDTH-1:0] in,
    input  logic [$clog2(OUTPUTS)-1:0] sel,
    output logic [WIDTH-1:0] out [OUTPUTS]
);

integer i;

always_comb begin
    // Default all outputs to zero
    for (i = 0; i < OUTPUTS; i = i + 1)
        out[i] = '0;

    // Drive selected output
    out[sel] = in;
end

endmodule
