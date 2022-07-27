
module matrix_mul
#(parameter n = 2)
(input [32 * n * n  : 0] mat_A, input [32 * n * n : 0] mat_B, output [32 * n * n : 0] mat_out);
//(input [32 * n * n  : 0] mat_A, input [31: 0] mat_B[n : 0], output [31: 0] mat_out [n : 0][n : 0]);
//input [32 * n * n  : 0] mat_A
    
    wire [31: 0] mul_res [n : 0][n : 0][n : 0]; 
    wire [31: 0] acc_res [n : 0][n : 0][n : 0];
    genvar i, j, k, l;
    
    generate 
        
        for (i = 0; i < n; i = i + 1)
            for (j = 0; j < n; j = j + 1)
                for (k = 0; k < n; k = k + 1)
                begin
                    //mul i_j_k(mat_A[i][j], mat_B[j][k], mul_res[i][k][j]);
                    mul i_j_k(mat_A[(i * n +  j) * 32 + 31 : (i * n +  j) * 32], mat_B[(j * n + k) * 32 + 31 : (j * n + k) * 32], mul_res[i][k][j]);
                end
        
        for (i = 0; i < n; i = i + 1)
            for (j = n - 1; j < n; j = j + 1)
                for (k = 0; k < n; k = k + 1)
                    assign acc_res[i][k][j] = 0;
                
        for (i = 0; i < n; i = i + 1)
            for (j = 1; j < n; j = j + 1)
                for (k = 0; k < n; k = k + 1)
                    adder i_j_k(acc_res[i][k][j], mul_res[i][k][j], acc_res[i][k][j - 1]);
        
        for (i = 0; i < n; i = i + 1)
            for (j = n - 1; j < n; j = j + 1)
                for (k = 0; k < n; k = k + 1)
                    //assign mat_out[i][k] = acc_res[i][k][0];
                    assign mat_out[(i * n + k)*32 + 31 : (i * n + k)*32] = acc_res[i][k][0];
    endgenerate

endmodule

module adder(input [31 : 0] a, input [31: 0] b, output [31: 0] c);
    assign c = a + b;
endmodule
module mul(input [31: 0] a, input [31: 0] b, output [31: 0] c);
    assign c = a * b;
endmodule
