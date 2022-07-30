`include "DSD-Project/fp_consts.sv"
`include "DSD-Project/fp_negator.sv"

module FP_Adder (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire add_sub_not,
    output reg [31:0] result,
    output reg underflow,
    output reg overflow,
    output reg inexcat
);

    wire [31:0] b_negated, b_to_accumlate;

    FP_Negator negator(b, b_negated);

    // We only do the summation in this module. If the operation was sub, we use the -b
    assign b_to_accumlate = add_sub_not ? b : b_negated;

    // Registers needed in normalizing the exponents
    reg [2+22:0] a_fraction, b_fraction; // one more bit for real number
    reg [7:0] result_exponent, counter;
    wire [7:0] a_exponent = a[30:23];
    wire [7:0] b_exponent = b[30:23];
    wire same_signs = b_to_accumlate[31] == a[31];

    // Normalize is used twice in the very end. So we macro it
    `define NORMALIZE \
        while (a_fraction[23] == 0) begin \
            a_fraction <<= 1; \
            result_exponent--; \
            if (result_exponent == 0) begin \
                underflow = a[31]; \
                overflow = ~a[31]; \
            end \
        end

    always_comb begin
        // Reset everything
        {underflow, overflow, inexcat} = 0;
        {a_fraction, b_fraction, result_exponent} = 0;
        counter = 0;
        // If one of them is NaN the result is NaN
        if (a ==? `SNAN_CONST | b ==? `SNAN_CONST) begin // Signaling is more powerful than quiet
            result = `SNAN_SAMPLE_CONST;
        end else if (a ==? `QNAN_CONST | b ==? `QNAN_CONST) begin
            result = `QNAN_SAMPLE_CONST;
        end else if (b == 0) begin // If b is zero then a is the result!
            result = a;
        end else if (a == 0) begin
            result = b_to_accumlate;
        // Infinity checks
        end else if (a == `INFINITY_POSITIVE_CONST) begin
            if (b_to_accumlate == `INFINITY_NEGATIVE_CONST) begin
                result = `QNAN_SAMPLE_CONST;
            end else begin
                result = `INFINITY_POSITIVE_CONST;
            end
        end else if (a == `INFINITY_NEGATIVE_CONST) begin
            if (b_to_accumlate == `INFINITY_POSITIVE_CONST) begin
                result = `QNAN_SAMPLE_CONST;
            end else begin
                result = `INFINITY_NEGATIVE_CONST;
            end
        end else if (b_to_accumlate == `INFINITY_NEGATIVE_CONST | b_to_accumlate == `INFINITY_POSITIVE_CONST) begin
            // We know that a is not infinity (positive or negative). So the result is simply b!
            result = b_to_accumlate;
        end else begin // Now we are talking real numbers...
            // Set the registers
            a_fraction = {2'b1, a[22:0]};
            b_fraction = {2'b1, b_to_accumlate[22:0]};
            // At first we have to normalize the numbers
            if (a_exponent > b_exponent) begin
                result_exponent = a_exponent;
                for (counter = 0; counter < a_exponent - b_exponent; counter++) begin
                    if (b_fraction[0] == 1)
                        inexcat = 1; // We are loosing digits!
                    b_fraction >>= 1; // shift
                end
            end else if (b_exponent > a_exponent) begin
                result_exponent = b_exponent;
                for (counter = 0; counter < b_exponent - a_exponent; counter++) begin
                    if (a_fraction[0] == 1)
                        inexcat = 1; // We are loosing digits!
                    a_fraction >>= 1; // shift
                end
            end else begin
                result_exponent = a_exponent;
            end
            // We have normalized fractions
            if (same_signs) begin
                a_fraction += b_fraction;
                if (a_fraction[24]) begin
                    result_exponent++;
                    if (a_fraction[0])
                        inexcat = 1;
                    a_fraction >>= 1;
                end
                result = {a[31], result_exponent, a_fraction[22:0]};
                underflow = result_exponent == 8'b1111_1111 & a[31];
                overflow = result_exponent == 8'b1111_1111 & (~a[31]);
            end else begin
                a_fraction = a_fraction + {1'b0, ~b_fraction[23:0]} + 1;
                if (a_fraction[24]) begin
                    if (a_fraction[23:0] == 0) begin
                        result = 0;
                    end else begin
                        `NORMALIZE
                        result = {a[31], result_exponent, a_fraction[22:0]};
                    end
                end else begin
                    a_fraction = -a_fraction;
                    `NORMALIZE
                    result = {~a[31], result_exponent, a_fraction[22:0]};
                end
            end
            // Check overflow underflow
            if (overflow)
                result = `INFINITY_POSITIVE_CONST;
            else if (underflow)
                result = `INFINITY_NEGATIVE_CONST;
        end
    end
endmodule
