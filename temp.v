
module test_bench
#(parameter n = 2, parameter sqrt_p = 2, parameter n_divide_ps = 1, parameter p = 4)
();
    reg clk = 0;
    reg [32 * n * n : 0] A;
    reg [32 * n * n : 0] B;
    wire [32 * n * n : 0] O;
    reg enable = 1;
    reg reset = 1;
    wire out_ready;
    integer i , j;
    initial begin
        $monitor(clk);
        A[31 : 0] = 1;
        A[63: 32] = 0;
        A[95: 64] = 1;
        A[123: 96] = 1;
        B[31 : 0] = 1;
        B[63: 32] = 0;
        B[95: 64] = 1;
        B[123: 96] = 1;
        
        $display(A[31 : 0],
        A[63: 32],
        A[95: 64],
        A[123: 96]);
        #100;
        reset = 0;
        
        #1000;
        $display(O[31 : 0],
        O[63: 32],
        O[95: 64],
        O[123: 96]);
    end
    always @(*)
    begin
        
        #10 clk = ~clk;
    end
    controller #(2, 2, 1, 4) cc(A, B, clk, enable, reset, O, out_ready);

endmodule




module controller
    #(parameter n = 4, parameter sqrt_p = 2, parameter n_divide_ps = 2, parameter p = 4)
    (input [32 * n * n : 0] matrix_A, input [32 * n * n : 0] matrix_B, input clk, input enable, input reset, output [32 * n * n : 0] out, output reg out_ready);
    initial begin
        #50;
        $display(matrix_A[31 : 0],
        matrix_A[63: 32],
        matrix_A[95: 64],
        matrix_A[123: 96]);
        
        $display(matrix_B[31 : 0],
        matrix_B[63: 32],
        matrix_B[95: 64],
        matrix_B[123: 96]);
    end
    reg [3 : 0] state = 0;
    reg enable_read = 0;
    reg enable_shift = 0;
    reg enable_sum = 0;
    reg [31 : 0] shifted = 0;
    always @(posedge clk)
    begin
        if(!reset)
        begin
            if(enable)
                case(state)
                    0: 
                        begin
                            enable_read = 1;
                            state <= 1;
                        end
                    1:
                        begin
                            enable_read = 0;
                            state <= 2;
                        end
                    
                    2:
                        begin
                            enable_sum = 1;
                            state <= 3;
                        end
                    3:
                        begin
                            enable_sum = 0;
                            enable_shift = 1;
                            state <= 4;
                        end
                    4:
                        begin
                            enable_shift = 0;
                            if (shifted < sqrt_p - 1)
                                state <= 2;
                            else
                                state <= 5;
                        end
                    5:
                        begin
                            out_ready = 1;
                            //get ready the output
                        end
                    default:
                        begin
                            out_ready = 0;
                            enable_shift = 0;
                            enable_sum = 0;
                            enable_read = 0;
                            state <= 0;
                        end
                endcase
            else
                state <= state;
        end
        else
            begin
                out_ready = 0;
                enable_shift = 0;
                enable_sum = 0;
                enable_read = 0;
                state <= 0;
            end
    end
    array_divider #(2, 2, 1, 4) parallel_process(matrix_A, matrix_B, clk, out);
endmodule






module array_divider
    #(parameter n = 4, parameter sqrt_p = 2, parameter n_divide_ps = 2, parameter p = 4)
    //(input [31 : 0] matrix_A [n : 0][n : 0], input [31 : 0] matrix_B [n : 0][n : 0], input clk);
    (input [32 * n * n : 0] matrix_A, input [32 * n * n : 0] matrix_B, input clk, output [32 * n * n : 0] multiple_result);
    
    
    
    initial begin
        #30;
        $display(n);
        $display(matrix_B[31 : 0],
        matrix_B[63: 32],
        matrix_B[95: 64],
        matrix_B[123: 96]);
        #300;
        $display(tmp_A[0][0],
        tmp_A[0][1],
        tmp_A[1][0],
        tmp_A[1][1]);
    end
    
    
    
    
    
    //reg [31 : 0] tmp_A [sqrt_p][sqrt_p][n_divide_ps][n_divide_ps];
    //reg [31 : 0] tmp_B [sqrt_p][sqrt_p][n_divide_ps][n_divide_ps];
    reg [32 * n_divide_ps * n_divide_ps : 0] tmp_A [sqrt_p][sqrt_p];
    reg [32 * n_divide_ps * n_divide_ps : 0] tmp_B [sqrt_p][sqrt_p];
    reg enable_mul = 0;
    reg enable_read = 0;
    reg enable_sum = 0;
    reg enable_shift = 0;
    //reg [31 : 0] out_sum_temp [sqrt_p][sqrt_p][n_divide_ps][n_divide_ps];
    //reg [31 : 0] out_sum [sqrt_p][sqrt_p][n_divide_ps][n_divide_ps];
    wire [32 * n_divide_ps * n_divide_ps : 0] out_sum_temp [sqrt_p][sqrt_p];
    wire [32 * n_divide_ps * n_divide_ps : 0] out_sum_new_temp [sqrt_p][sqrt_p];
    reg [32 * n_divide_ps * n_divide_ps : 0] out_sum [sqrt_p][sqrt_p];
    
    
    genvar i, j, k , v;
    generate
        for (i = 0; i < sqrt_p; i = i + 1)
            for (j = 0; j < sqrt_p; j = j + 1)
                for (k = 0; k < n_divide_ps; k = k + 1)
                    for (v = 0; v < n_divide_ps; v = v + 1)
                        always @(clk)
                            if(enable_read)
                                begin
                                    tmp_A[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32] <= matrix_A[((i + k) * n + (j + v)) * 32 + 31: ((i + k) * n + (j + v)) * 32];
                                    tmp_B[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32] <= matrix_B[((i + k) * n + (j + v)) * 32 + 31: ((i + k) * n + (j + v)) * 32];
                                    
                                end
                        //begin
                            //TODO check correctness
                            //copy i_j_A(.i(i * n_divide_ps),.j(jj * n_divide_ps), .matrix_A(matrix_A), .out_matrix(tmp_A[i][j]), .enable(enable_read), .clk(clk));
                            //copy i_j_B(.i(i * n_divide_ps), .j(jj * n_divide_ps), .matrix_A(matrix_B), .out_matrix(tmp_B[i][j]), .enable(enable_read), .clk(clk));
                        //end
    endgenerate
    
    
    generate    
        for (i = 0; i < sqrt_p; i = i + 1)
                for (j = 0; j < sqrt_p; j = j + 1)
                    for (k = 0; k < n_divide_ps; k = k + 1)
                        for (v = 0; v < n_divide_ps; v = v + 1)
                            assign multiple_result[((i + k) * n + (j + v)) * 32 + 31: ((i + k) * n + (j + v)) * 32] = out_sum[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32];
    endgenerate
    
    //summing procedure
    generate
        for (i = 0; i < sqrt_p; i = i + 1)
            for (j = 0; j < sqrt_p; j = j + 1)
                for (k = 0; k < n_divide_ps; k = k + 1)
                    for (v = 0; v < n_divide_ps; v = v + 1)
                        adder new_sum_temp(out_sum[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32],  out_sum_temp[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32],  out_sum_new_temp[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32]);
    
        for (i = 0; i < sqrt_p; i = i + 1)
            for (j = 0; j < sqrt_p; j = j + 1)
                for (k = 0; k < n_divide_ps; k = k + 1)
                    for (v = 0; v < n_divide_ps; v = v + 1)
                        always @(clk)
                            if (enable_sum)
                                //TODO recorrect this
                                out_sum[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32] <= out_sum[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32] + out_sum_temp[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32];
    endgenerate
    
    
    //multipling procedure
    generate 
        for (i = 0; i < sqrt_p; i = i + 1)
            for (j = 0; j < sqrt_p; j = j + 1)
            begin
                mul_matrix #(n_divide_ps) i_j_AB(tmp_A[i][j], tmp_B[i][j], out_sum_temp[i][j]);
            end
    endgenerate
    
    genvar i_sum, j_sum;
    generate 
        //for (i_sum = 0; i_sum < sqrt_p; i_sum = i_sum + 1)
            //for (j_sum = 0; j_sum < sqrt_p; j_sum = j_sum + 1)
                //adder sum_i_sum_j(out_sum_temp[i_sum][j_sum], out_sum[i_sum][j_sum], enable_sum);
    endgenerate
    
    genvar ii, jj, kk, ll;
    
    //Shifting procedure
    generate
            //shift tmp_A to right
            for (ii = 0; ii < sqrt_p; ii = ii + 1)
                for(jj = 0; jj < sqrt_p; jj = jj + 1)
                    for(kk = 0; kk < n_divide_ps; kk = kk + 1)
                        for(ll = 0; ll < n_divide_ps; ll = ll + 1)
                            if (ii == sqrt_p - 1)
                                //tmp_A[0][j][k][l] <= tmp_A[i][j][k][l];
                                always @(posedge clk)
                                    if(enable_shift)
                                        tmp_A[0][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll)*32] <= tmp_A[ii][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll) * 32];
        
            for (ii = 0; ii < sqrt_p; ii = ii + 1)
                for(jj = 0; jj < sqrt_p; jj = jj + 1)
                    for(kk = 0; kk < n_divide_ps; kk = kk + 1)
                        for(ll = 0; ll < n_divide_ps; ll = ll + 1)
                            if (ii != sqrt_p - 1)
                                always @(posedge clk)
                                    if(enable_shift)
                                        tmp_A[ii + 1][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll)*32] <= tmp_A[ii][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll)*32];
                                
                         
            //shift B to down
            
            for (ii = 0; ii < sqrt_p; ii = ii + 1)
                for(jj = 0; jj < sqrt_p; jj = jj + 1)
                    for(kk = 0; kk < n_divide_ps; kk = kk + 1)
                        for(ll = 0; ll < n_divide_ps; ll = ll + 1)
                            if (jj == sqrt_p - 1)
                                //tmp_A[i][0][k][l] <= tmp_A[i][j][k][l];
                                always @(posedge clk)
                                    if(enable_shift)
                                        tmp_A[ii][0][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll) * 32] <= tmp_A[ii][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll)*32];
    
            for (ii = 0; ii < sqrt_p; ii = ii + 1)
                for(jj = 0; jj < sqrt_p; jj = jj + 1)
                    for(kk = 0; kk < n_divide_ps; kk = kk + 1)
                        for(ll = 0; ll < n_divide_ps; ll = ll + 1)
                            if (jj != sqrt_p - 1)
                                always @(posedge clk)
                                    if(enable_shift)
                                //tmp_A[i][j + 1]][k][l] <= tmp_A[i][j][k][l];
                                        tmp_A[ii][jj + 1][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll)*32] <= tmp_A[ii][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll)*32];
        
    endgenerate
    

endmodule



module mul_matrix
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







