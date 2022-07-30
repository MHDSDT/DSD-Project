`include "DSD-Project/fp_consts.sv";

module FP_Negator (
    input wire [31:0] a,
    output reg [31:0] result
);
    assign result = {~a[31], a[30:0]};
endmodule
