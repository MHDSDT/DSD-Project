module test_bench
#(parameter n = 2, parameter sqrt_p = 2, parameter n_divide_ps = 1, parameter p = 4)
();
    reg clk = 0;
    reg [32 * n * n - 1 : 0] A;
    reg [32 * n * n - 1 : 0] B;
    wire [32 * n * n - 1 : 0] O;
    reg enable = 1;
    reg reset = 1;
    wire out_ready;
    integer i , j;
    integer               data_file    ; // file handler
	integer               scan_file    ; // file handler
	`define NULL 0    

	initial begin
      data_file = $fopen("testA.txt", "r");
      scan_file = $fscanf(data_file, "%b\n", A[31:0]);
      scan_file = $fscanf(data_file, "%b\n", A[63:32]);
      scan_file = $fscanf(data_file, "%b\n", A[95:64]);
      scan_file = $fscanf(data_file, "%b\n", A[127:96]);
      $display("Matrix A:\n",A[31 : 0]," ",
                 A[63: 32],"\n",
               A[95: 64]," ",
                 A[127: 96], "\n");
      data_file = $fopen("testB.txt", "r");
      scan_file = $fscanf(data_file, "%b\n", B[31:0]);
      scan_file = $fscanf(data_file, "%b\n", B[63:32]);
      scan_file = $fscanf(data_file, "%b\n", B[95:64]);
      scan_file = $fscanf(data_file, "%b\n", B[127:96]);
      $display("Matrix B:\n",B[31 : 0]," ",
                 B[63: 32],"\n",
               B[95: 64]," ",
                 B[127: 96], "\n");
       #100;
        enable = 1;
        reset = 0;
        
        #1000;
      $display("Mult Result:\n",O[31 : 0]," ",
                 O[63: 32],"\n",
               O[95: 64]," ",
                O[127: 96], "\n");
        #1000;
        $finish;
	end
    
    always  #50 clk = ~clk;
    controller #(2, 2, 1, 4) cc(A, B, clk, enable, reset, O, out_ready);

endmodule





module controller
    #(parameter n = 4, parameter sqrt_p = 2, parameter n_divide_ps = 2, parameter p = 4)
    (input [32 * n * n - 1 : 0] matrix_A, input [32 * n * n - 1: 0] matrix_B, input clk, input enable, input reset, output [32 * n * n - 1: 0] out, output reg out_ready);
    reg [3 : 0] state = 0;
    reg [3 : 0] nx_state = 0;
    reg enable_read  = 0;
    reg enable_shift = 0;
    reg enable_sum = 0;
    reg [31 : 0] shifted = 0;
    
    always @(posedge clk, posedge reset)
    begin
        //$display(nx_state);
        //$display("setting next state: %d %d", nx_state,  $time);
        if (state == 0)
        begin
            nx_state = 1;
            enable_read = 1;
        end
        if(reset == 1) 
             state <= 0;
         else
             state <= nx_state; 
    end 
    
    always @(state)
    begin
        //$display("set next action %d", $time);
        //$display("set the action %d -> %d %d", state, nx_state, $time);
        if(!reset)
        begin
            if(enable)
                case(state)
                    0: 
                        begin
                            //$display("here %d", $time);
                            nx_state = 1;
                            enable_read = 1;
                        end
                    1:
                        begin
                            enable_read = 1;
                            //$display("we set the enable_read %d %d", $time, enable_read);
                            nx_state = 2;
                        end
                    
                    2:
                        begin
                            //$display("shit hhhhhhh %d", enable_read);
                            //$display("shit %d", $time);
                            
                            
                            enable_read = 0;
                            //$display("set enable read to zero", enable_read);
                            enable_sum = 1;
                            nx_state = 3;
                        end
                    3:
                        begin
                            enable_sum = 0;
                            enable_shift = 1;
                            nx_state = 4;
                        end
                    4:
                        begin
                            enable_shift = 0;
                            if (shifted < sqrt_p - 1)
                                nx_state = 2;
                            else
                                nx_state = 5;
                            shifted = shifted + 1;
                        end
                    5:
                        begin
                            out_ready = 1;
                            nx_state = 6;
                            //get ready the output
                        end
                    6:
                        begin
                            out_ready = 0;
                            nx_state = 0;
                        end
                    default:
                        begin
                            out_ready = 0;
                            enable_shift = 0;
                            enable_sum = 0;
                            enable_read = 0;
                            nx_state = 0;
                        end
                endcase
            else
                nx_state = state;
        end
        else
            begin
                out_ready = 0;
                enable_shift = 0;
                enable_sum = 0;
                enable_read = 0;
                nx_state = 0;
            end
        
    end
    array_divider #(2, 2, 1, 4) parallel_process(matrix_A, matrix_B, clk, out, enable_read, enable_sum, enable_shift, reset);
endmodule






module array_divider
    #(parameter n = 4, parameter sqrt_p = 2, parameter n_divide_ps = 2, parameter p = 4)
    (input [32 * n * n - 1: 0] matrix_A, input [32 * n * n - 1 : 0] matrix_B, input clk, output [32 * n * n - 1 : 0] multiple_result, input enable_read, input enable_sum, input enable_shift, input reset);
    
    
    
    initial begin
        #100
        $display(n);
        
         
        $display(matrix_B[31 : 0],
        matrix_B[63: 32],
        matrix_B[95: 64],
        matrix_B[127: 96]);
        #300;
        $display(tmp_A[0][0],
        tmp_A[0][1],
        tmp_A[1][0],
        tmp_A[1][1]);
    end
    
    
    
    
    
    //reg [31 : 0] tmp_A [sqrt_p][sqrt_p][n_divide_ps][n_divide_ps];
    //reg [31 : 0] tmp_B [sqrt_p][sqrt_p][n_divide_ps][n_divide_ps];
    reg [32 * n_divide_ps * n_divide_ps - 1: 0] tmp_A [sqrt_p][sqrt_p];
    reg [32 * n_divide_ps * n_divide_ps - 1: 0] tmp_B [sqrt_p ][sqrt_p];

    //reg [31 : 0] out_sum_temp [sqrt_p][sqrt_p][n_divide_ps][n_divide_ps];
    //reg [31 : 0] out_sum [sqrt_p][sqrt_p][n_divide_ps][n_divide_ps];
    wire [32 * n_divide_ps * n_divide_ps - 1 : 0] out_sum_temp [sqrt_p][sqrt_p];
    wire [32 * n_divide_ps * n_divide_ps - 1 : 0] out_sum_new_temp [sqrt_p][sqrt_p];
    reg [32 * n_divide_ps * n_divide_ps - 1 : 0] out_sum [sqrt_p][sqrt_p] ;
    
    
    genvar i, j, k , v;
    generate
        for (i = 0; i < sqrt_p; i = i + 1)
            for (j = 0; j < sqrt_p; j = j + 1)
                for (k = 0; k < n_divide_ps; k = k + 1)
                    for (v = 0; v < n_divide_ps; v = v + 1)
                        always @(*)
                        begin
                            //$display("what the fazzz %d %d ", $time, enable_read);
                            if(enable_read)
                                begin
                                    //$display("reading shit");
                                    tmp_A[i][j][(k * n_divide_ps + v) * 32 + 31: (k * n_divide_ps + v)*32] = matrix_A[((i * n_divide_ps + k) + n * (j * n_divide_ps + v)) * 32 + 31: ((i * n_divide_ps + k) + n * (j * n_divide_ps + v)) * 32];
                                    //tmp_A[i][j][(k * n_divide_ps * v)*32 + 31: (k + n_divide_ps * v)*32] = matrix_A[((i * n_divide_ps + k) + n * (j * n_divide_ps + v)) * 32 + 31: ((i * n_divide_ps + k) + n * (j * n_divide_ps + v)) * 32];
                                    //$display("what the Faxxxxxxxxxxx   ", matrix_A[((i + k) * n + (j + v)) * 32 + 31: ((i + k) * n + (j + v)) * 32]);
                                    //$display("hh" , tmp_A[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32] );
                                    //$display("hahah ", i , " j ", j, " k ", k , " v ", v);
                                    tmp_B[i][j][(k * n_divide_ps + v) * 32 + 31: (k * n_divide_ps + v)*32] = matrix_B[((i * n_divide_ps + k) + n * (j * n_divide_ps + v)) * 32 + 31: ((i * n_divide_ps + k) + n * (j * n_divide_ps + v)) * 32];
                                    
                                end
                        end
    endgenerate
    
    
    generate    
        for (i = 0; i < sqrt_p; i = i + 1)
                for (j = 0; j < sqrt_p; j = j + 1)
                    for (k = 0; k < n_divide_ps; k = k + 1)
                        for (v = 0; v < n_divide_ps; v = v + 1)
                            assign multiple_result[((i * n_divide_ps + k) * n + (j * n_divide_ps + v)) * 32 + 31: ((i * n_divide_ps + k) * n + (j * n_divide_ps + v)) * 32] = out_sum[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32];
        for (i = 0; i < sqrt_p; i = i + 1)
            for (j = 0; j < sqrt_p; j = j + 1)
                for (k = 0; k < n_divide_ps; k = k + 1)
                    for (v = 0; v < n_divide_ps; v = v + 1)
                        always @(reset)
                            if(reset)
                                out_sum[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32] = 0;
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
                        always @(posedge enable_sum)
                            if (enable_sum)
                                //TODO recorrect this
                                begin
                                    out_sum[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32] = out_sum[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32] + out_sum_temp[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32];
                                    
                                    //$display("HHHHHH ", out_sum_temp[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32]);
                                    
                                end
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
            //changes don't effect at all
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
                                        tmp_B[ii][0][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll) * 32] = tmp_B[ii][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll)*32];
    
            for (ii = 0; ii < sqrt_p; ii = ii + 1)
                for(jj = 0; jj < sqrt_p; jj = jj + 1)
                    for(kk = 0; kk < n_divide_ps; kk = kk + 1)
                        for(ll = 0; ll < n_divide_ps; ll = ll + 1)
                            if (jj != sqrt_p - 1)
                                always @(posedge clk)
                                    if(enable_shift)
                                //tmp_A[i][j + 1]][k][l] <= tmp_A[i][j][k][l];
                                        tmp_B[ii][jj + 1][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll)*32] = tmp_B[ii][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll)*32];
        
    endgenerate
    

endmodule



//----------------------------------------------------------------------------------------------------------------------------------------------------------------

module mul_matrix
#(parameter n = 2)
(input [32 * n * n - 1: 0] mat_A, input [32 * n * n  - 1: 0] mat_B, output [32 * n * n - 1 : 0] mat_out);

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


module adder(input [31 : 0] a, input [31: 0] b, output [31: 0] c);
    assign c = a + b;
endmodule
module mul(input [31: 0] a, input [31: 0] b, output [31: 0] c);
    assign c = a * b;
endmodule







