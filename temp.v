

module array_divider
    #(parameter n = 4, parameter sqrt_p = 2, parameter n_divide_ps = 2, parameter p = 4)
    (input [31 : 0] matrix_A [n : 0][n : 0], input [31 : 0] matrix_B [n : 0][n : 0], input clk);
    reg [31 : 0] tmp_A [sqrt_p][sqrt_p][n_divide_ps][n_divide_ps];
    reg [31 : 0] tmp_B [sqrt_p][sqrt_p][n_divide_ps][n_divide_ps];
    reg enable_mul = 0;
    reg enable_read = 0;
    reg enable_sum = 0;
    reg enable_shift = 0;
    reg [31 : 0] out_sum_temp [sqrt_p][sqrt_p][n_divide_ps][n_divide_ps];
    reg [31 : 0] out_sum [sqrt_p][sqrt_p][n_divide_ps][n_divide_ps];
    genvar i, j;
    
    generate
        for (i = 0; i < sqrt_p; i = i + 1)
            for (j = 0; j < sqrt_p; j = j + 1)
            begin
                copy i_j(.i(i * n_divide_ps),.j(j * n_divide_ps), .matrix_A(matrix_A), .out_matrix(tmp_A), .enable(enable_read));
                copy i_j(.i(i * n_divide_ps), .j(j * n_divide_ps), .matrix_A(matrix_B), .out_matrix(tmp_B), .enable(enable_read));
            end
    endgenerate
    
    generate 
        for (i = 0; i < sqrt_p; i = i + 1)
            for (j = 0; j < sqrt_p; j = j + 1)
            begin
                mul_matrix i_j(tmp_A[i][j], tmp_B[i][j], out_sum_temp[i][j], enable_mul)
            end
    endgenerate
    
    genvar i_sum, j_sum;
    generate 
        for (i_sum = 0; i_sum < sqrt_p; i_sum = i_sum + 1)
            for (j_sum = 0; j_sum < sqrt_p; j_sum = j_sum + 1)
                adder sum_i_sum_j(out_sum_temp[i_sum][j_sum], out_sum[i_sum][j_sum], enable_sum);
    endgenerate
    
    always @(enable_shift, clk)
    begin
        if (enable_shift)
        begin
            //shift tmp_A to right
            for (i = 0; i < sqrt_p; i = i + 1)
                for(j = 0; j < sqrt_p; j = j + 1)
                    for(k = 0; k < n_divide_ps; k = k + 1)
                        for(l = 0; l < n_divide_ps; l = l + 1)
                            if (i == sqrt_p - 1)
                                tmp_A[0][j][k][l] <= tmp_A[i][j][k][l];
                            else
                                tmp_A[i + 1][j]][k][l] <= tmp_A[i][j][k][l];
                        
            //shift B to down
            
            for (i = 0; i < sqrt_p; i = i + 1)
                for(j = 0; j < sqrt_p; j = j + 1)
                    for(k = 0; k < n_divide_ps; k = k + 1)
                        for(l = 0; l < n_divide_ps; l = l + 1)
                            if (j == sqrt_p - 1)
                                tmp_A[i][0][k][l] <= tmp_A[i][j][k][l];
                            else
                                tmp_A[i][j + 1]][k][l] <= tmp_A[i][j][k][l];
        end
    end
    

endmodule

module adder
#(parameter n = 2)
(input [31: 0] A [n : 0][n : 0], input [31: 0] B[n : 0][n : 0], input enable);

endmodule
module mul_matrix
#(parameter n = 2)
(input [31 : 0] matrix_A[n: 0][n: 0], input [31: 0] matrix_B, reg output [31 : 0] out_mat[n : 0][n : 0], input enable);
    
endmodule

module copy
#(parameter n = 4, parameter sqrt_p = 2, parameter n_divide_ps = 2, parameter p = 4)
(input [31: 0] i, input [31: 0] j, input [31: 0] matrix_A[n: 0][n : 0], output reg [31: 0] out_matrix [n_divide_ps: 0][n_divide_ps: 0], input enable);
    genvar t, r;
    generate
        for (t = 0; t < n_divide_ps; t = t + 1)
            for (r = 0; r < n_divide_ps; r = r + 1)
                send_recieve t_r(out_matrix[t][r], matrix_A[i + t][j + r], enable);
    endgenerate
endmodule

module send_recieve(input [31: 0]a, output reg[31: 0] b, input enable);
    always @(*)
        if (enable)
            b <= a;
        else
            b <= b;
endmodule
