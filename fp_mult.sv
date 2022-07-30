`include "DSD-Project/fp_consts.sv";

module FP_Multiplicator (
    input [31:0] a,
    input [31:0] b,
    output reg [31:0] result,
    output reg overflow,
    output reg underflow
);

// mantissa + exponent + sign extraction
wire sign_a = a[31];
wire sign_b = b[31];

wire [7:0] exp_a = a[30:23];
wire [7:0] exp_b = b[30:23];

wire [23:0] mnts_a = {1'b1, a[22:0]};
wire [23:0] mnts_b = {1'b1, b[22:0]};

// combinational logic
reg [47:0] result_mnts_mul;
reg [7:0] result_exp_mul;
always_comb begin
    underflow = 0;
    overflow = 0;
    result_exp_mul = 0;
    result_mnts_mul = 0;
    // case: a = zero
    if (a == `ZERO) begin
        // case: b is either NAN or infinity
        if (b ==? `SNAN_CONST || b ==? `QNAN_CONST || b == `INFINITY_NEGATIVE_CONST || b == `INFINITY_POSITIVE_CONST)
            result = `QNAN_SAMPLE_CONST;
        // case: b is a number
        else 
            result = `ZERO;
    // case: b = 0
    end else if (b == `ZERO) begin
        // case: a is either NAN or infinity
        if (a ==? `SNAN_CONST || a ==? `QNAN_CONST || a == `INFINITY_NEGATIVE_CONST || a == `INFINITY_POSITIVE_CONST)
            result = `QNAN_SAMPLE_CONST;
        // case: b is a number
        else 
            result = `ZERO;
    // Infinity check
    end else if (a ==? `INFINITY_GENERAL_PATTERN && b ==? `INFINITY_GENERAL_PATTERN) begin
        result = `INFINITY_POSITIVE_CONST;
        result[31] = sign_a ^ sign_b;
    end else begin
        // compute sign of result
        result[31] = sign_a ^ sign_b;
        // compute exponent result
        result_exp_mul = exp_a + exp_b - 127;

        if (exp_a > 127 && exp_b > 127 && result_exp_mul < 127)  begin // overflow
            overflow = 1;       
            result = `INFINITY_POSITIVE_CONST;
            result[31] = sign_a ^ sign_b;       
        end else if (exp_a < 127 && exp_b < 127 && result_exp_mul > 127) begin // underflow
            underflow = 1;
            result = `ZERO;
        end else begin
            // compute mantissa of result
            result_mnts_mul = 0; // reseting this reg
            result_mnts_mul = mnts_a * mnts_b;
            // normalisation of mantissa multiplication result 
            case (result_mnts_mul[47:46])
                2'd0: begin
                    result_mnts_mul <<= 1;
                    result_exp_mul--;
                end
                2'd1: begin
                    // We are good!
                end
                2'd2: begin
                    result_mnts_mul >>= 1;
                    result_exp_mul++;
                end
                2'd3: begin
                    result_mnts_mul >>= 1;
                    result_exp_mul++;
                end
            endcase
            result[22:0] = result_mnts_mul[45 -: 23];
            result[30:23] = result_exp_mul;        
        end     
    end
end

endmodule