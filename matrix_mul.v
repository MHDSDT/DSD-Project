

module tester();
    initial begin
        #100;
        A[31 : 0] = 1;
        A[63: 32] = 0;
        A[95: 64] = 10;
        A[127: 96] = 1;
        B[31 : 0] = 1;
        B[63: 32] = 0;
        B[95: 64] = 1;
        B[127: 96] = 1;
        #100;
        $display( C[31 : 0],
        C[63: 32],
        C[95: 64],
        C[127: 96]);
    end
    reg [32 * 2 * 2 - 1 : 0] A;
    reg [32 * 2 * 2 - 1 : 0] B;
    wire [32 * 2 * 2 - 1: 0] C;
    mul_matrix  #(2) m1(A, B, C);
endmodule



module mul_matrix
#(parameter n = 2)
(input [32 * n * n - 1: 0] mat_A, input [32 * n * n  - 1: 0] mat_B, output [32 * n * n - 1 : 0] mat_out);
initial begin
    #2000
    $monitor(acc_res[0][0][1]);
    $display("acc", acc_res[0][0][1]);
    $display("acc", acc_res[0][0][0]);
    $monitor("mul", mul_res[0][0][1][31 : 0]);
    $display("mul", mul_res[0][0][1][31 : 0]);
    $display("A", mat_A[63 : 32]);
    $monitor(mat_A[63 : 32]);
    $display("B", mat_B[95: 64]);
    $monitor(mat_B[95 : 64]);
    
    $display("acc", mul_res[0][0][1]);
    $display("acc", mul_res[0][0][0]);
    
    $display("acc", mul_res[0][1][1]);
    $display("acc", mul_res[0][1][0]);
    
    $display("acc", mul_res[1][0][1]);
    $display("acc", mul_res[1][0][0]);
    
    $display("acc", mul_res[1][1][1]);
    $display("acc", mul_res[1][1][0]);
    
    $display("acc1", acc_res[0][0][1]);
    $display("acc1", acc_res[0][0][0]);
    
    $display("acc1", acc_res[0][1][1]);
    $display("acc1", acc_res[0][1][0]);
    
    $display("acc1", acc_res[1][0][1]);
    $display("acc1", acc_res[1][0][0]);
    
    $display("acc1", acc_res[1][1][1]);
    $display("acc1", acc_res[1][1][0]);
    
    $display( mat_out[31 : 0],
        mat_out[63: 32],
        mat_out[95: 64],
        mat_out[127: 96]);
    
end
//(input [32 * n * n  : 0] mat_A, input [31: 0] mat_B[n : 0], output [31: 0] mat_out [n : 0][n : 0]);
//input [32 * n * n  : 0] mat_A
    
    wire [31: 0] mul_res [n - 1 : 0][n - 1 : 0][n - 1 : 0]; 
    wire [31: 0] acc_res [n - 1 : 0][n - 1 : 0][n - 1: 0];
    genvar i, j, k, l;
    
    generate 
        
        for (i = 0; i < n; i = i + 1)
            for (j = 0; j < n; j = j + 1)
                for (k = 0; k < n; k = k + 1)
                begin
                    //mul i_j_k(mat_A[i][j], mat_B[j][k], mul_res[i][k][j]);
                    mul i_j_k(mat_A[(i +  n * j) * 32 + 31 : (i + n *  j) * 32], mat_B[(j + n * k) * 32 + 31 : (j + n * k) * 32], mul_res[i][k][j][31 : 0]);
                    //$display("in matrix mul", mat_A[(i * n +  j) * 32 + 31 : (i * n +  j) * 32]);
                end
        
        for (i = 0; i < n; i = i + 1)
            for (j = n - 1; j < n; j = j + 1)
                for (k = 0; k < n; k = k + 1)
                    assign acc_res[i][k][j][31 : 0] = mul_res[i][k][j][31: 0];
                
        for (i = 0; i < n; i = i + 1)
            for (j = 1; j < n; j = j + 1)
                for (k = 0; k < n; k = k + 1)
                    adder i_j_k(acc_res[i][k][j][31 : 0], mul_res[i][k][j - 1][31 : 0], acc_res[i][k][j - 1][31 : 0]);
        
        for (i = 0; i < n; i = i + 1)
            for (k = 0; k < n; k = k + 1)
                //assign mat_out[i][k] = acc_res[i][k][0];
                if (n > 1)
                    assign mat_out[(i + n * k)*32 + 31 : (i + n * k)*32] = acc_res[i][k][0][31 : 0];
                else
                    assign mat_out[(i + n * k)*32 + 31 : (i + n * k)*32] = mul_res[i][k][0][31 : 0];
    endgenerate

endmodule

module mul(input [31: 0] a, input [31: 0] b, output [31: 0] c);
    assign c = a * b;
endmodule


module adder(input [31 : 0] a, input [31: 0] b, output [31: 0] c);
    assign c = a + b;
endmodule
