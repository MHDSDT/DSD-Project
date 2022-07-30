`define INFINITY_POSITIVE_CONST 32'b01111111100000000000000000000000
`define INFINITY_NEGATIVE_CONST 32'b11111111100000000000000000000000
`define INFINITY_GENERAL_PATTERN 32'b?1111111100000000000000000000000
`define QNAN_CONST 32'b?111111111??????????????????????
`define SNAN_CONST 32'b?1111111101?????????????????????
`define QNAN_SAMPLE_CONST 32'b01111111110000000000000000000000
`define SNAN_SAMPLE_CONST 32'b01111111101000000000000000000000
`define ZERO 32'b0
`define POSITIVE_HALF 32'b00111111000000000000000000000000

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
      data_file = $fopen("testB.txt", "r");
      scan_file = $fscanf(data_file, "%b\n", B[31:0]);
      scan_file = $fscanf(data_file, "%b\n", B[63:32]);
      scan_file = $fscanf(data_file, "%b\n", B[95:64]);
      scan_file = $fscanf(data_file, "%b\n", B[127:96]);
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
    reg enable_shift1 = 0;
    reg enable_shift2 = 0;
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
                            enable_shift1 = 1;
                            enable_shift2 = 0;
                            nx_state = 8;
                        end
                    4:
                        begin
                            enable_shift1 = 0;
                            enable_shift2 = 0;
                            if (shifted < sqrt_p - 1)
                            begin
                                nx_state = 2;
                                shifted = 0;
                            end
                            else
                            begin
                                nx_state = 5;
                                shifted = 0;
                            end
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
                    8:
                        begin
                            enable_shift1 = 0;
                            enable_shift2 = 1;
                            nx_state = 4;
                        end
                    default:
                        begin
                            out_ready = 0;
                            enable_shift1 = 0;
                            enable_shift2 = 0;
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
                enable_shift1 = 0;
                enable_shift2 = 0;
                enable_sum = 0;
                enable_read = 0;
                nx_state = 0;
            end
        
    end
    array_divider #(2, 2, 1, 4) parallel_process(matrix_A, matrix_B, clk, out, enable_read, enable_sum, enable_shift1, enable_shift2, reset);
endmodule






module array_divider
    #(parameter n = 4, parameter sqrt_p = 2, parameter n_divide_ps = 2, parameter p = 4)
    (input [32 * n * n - 1: 0] matrix_A, input [32 * n * n - 1 : 0] matrix_B, input clk, output [32 * n * n - 1 : 0] multiple_result, input enable_read, input enable_sum, input enable_shift1, input enable_shift2, input reset);
    
    
    
    wire overflow;
    wire underflow;
    wire inexcat;
    //reg [31 : 0] tmp_A [sqrt_p][sqrt_p][n_divide_ps][n_divide_ps];
    //reg [31 : 0] tmp_B [sqrt_p][sqrt_p][n_divide_ps][n_divide_ps];
    reg [32 * n_divide_ps * n_divide_ps - 1: 0] tmp_A [sqrt_p][sqrt_p];
    reg [32 * n_divide_ps * n_divide_ps - 1: 0] tmp_B [sqrt_p ][sqrt_p];
    
    reg [32 * n_divide_ps * n_divide_ps - 1: 0] tmp_AA [sqrt_p][sqrt_p];
    reg [32 * n_divide_ps * n_divide_ps - 1: 0] tmp_BB [sqrt_p ][sqrt_p];

    //reg [31 : 0] out_sum_temp [sqrt_p][sqrt_p][n_divide_ps][n_divide_ps];
    //reg [31 : 0] out_sum [sqrt_p][sqrt_p][n_divide_ps][n_divide_ps];
    wire [32 * n_divide_ps * n_divide_ps - 1 : 0] out_sum_temp [sqrt_p][sqrt_p];
    wire [32 * n_divide_ps * n_divide_ps - 1 : 0] out_sum_new_temp [sqrt_p][sqrt_p];
    wire [32 * n_divide_ps * n_divide_ps - 1 : 0] out_sum_new_temp_final [sqrt_p][sqrt_p];
    
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
                        FP_Adder new_sum_temp(out_sum[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32],  out_sum_temp[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32],  out_sum_new_temp[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32], overflow, underflow, inexcat);
    
        for (i = 0; i < sqrt_p; i = i + 1)
            for (j = 0; j < sqrt_p; j = j + 1)
                for (k = 0; k < n_divide_ps; k = k + 1)
                    for (v = 0; v < n_divide_ps; v = v + 1)
                        FP_Adder x_adder(out_sum[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32], out_sum_temp[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32], out_sum_new_temp_final[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32], overflow, underflow, inexcat);
        for (i = 0; i < sqrt_p; i = i + 1)
            for (j = 0; j < sqrt_p; j = j + 1)
                for (k = 0; k < n_divide_ps; k = k + 1)
                    for (v = 0; v < n_divide_ps; v = v + 1)
                        always @(posedge enable_sum)
                            if (enable_sum)
                                //TODO recorrect this
                                begin
                                    out_sum[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32] = out_sum_new_temp_final[i][j][(k * n_divide_ps + v)*32 + 31: (k * n_divide_ps + v)*32];
                                    
                                    
                                end
    endgenerate
    
    
    //multipling procedure
    generate 
        for (i = 0; i < sqrt_p; i = i + 1)
            for (j = 0; j < sqrt_p; j = j + 1)
            begin
                mul_matrix #(n_divide_ps) i_j_AB(tmp_A[i][j], tmp_B[i][i], out_sum_temp[j][i]);
            end
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
                                    if(enable_shift1)
                                        tmp_AA[0][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll)*32] <= tmp_A[ii][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll) * 32];
        
            for (ii = 0; ii < sqrt_p; ii = ii + 1)
                for(jj = 0; jj < sqrt_p; jj = jj + 1)
                    for(kk = 0; kk < n_divide_ps; kk = kk + 1)
                        for(ll = 0; ll < n_divide_ps; ll = ll + 1)
                            if (ii != sqrt_p - 1)
                                always @(posedge clk)
                                    if(enable_shift1)
                                        tmp_AA[ii + 1][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll)*32] <= tmp_A[ii][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll)*32];
                                
            
            //shift B to down
            
            for (ii = 0; ii < sqrt_p; ii = ii + 1)
                for(jj = 0; jj < sqrt_p; jj = jj + 1)
                    for(kk = 0; kk < n_divide_ps; kk = kk + 1)
                        for(ll = 0; ll < n_divide_ps; ll = ll + 1)
                            if (jj == sqrt_p - 1)
                                //tmp_A[i][0][k][l] <= tmp_A[i][j][k][l];
                                always @(posedge clk)
                                    if(enable_shift1)
                                        tmp_BB[ii][0][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll) * 32] = tmp_B[ii][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll)*32];
    
            for (ii = 0; ii < sqrt_p; ii = ii + 1)
                for(jj = 0; jj < sqrt_p; jj = jj + 1)
                    for(kk = 0; kk < n_divide_ps; kk = kk + 1)
                        for(ll = 0; ll < n_divide_ps; ll = ll + 1)
                            if (jj != sqrt_p - 1)
                                always @(posedge clk)
                                    if(enable_shift1)
                                //tmp_A[i][j + 1]][k][l] <= tmp_A[i][j][k][l];
                                        tmp_BB[ii][jj + 1][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll)*32] = tmp_B[ii][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll)*32];



            for (ii = 0; ii < sqrt_p; ii = ii + 1)
                for(jj = 0; jj < sqrt_p; jj = jj + 1)
                    for(kk = 0; kk < n_divide_ps; kk = kk + 1)
                        for(ll = 0; ll < n_divide_ps; ll = ll + 1)
                            always @(posedge clk)
                                if(enable_shift2)
                                    tmp_A[ii][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll) * 32] = tmp_AA[ii][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll) * 32];
            
            for (ii = 0; ii < sqrt_p; ii = ii + 1)
                for(jj = 0; jj < sqrt_p; jj = jj + 1)
                    for(kk = 0; kk < n_divide_ps; kk = kk + 1)
                        for(ll = 0; ll < n_divide_ps; ll = ll + 1)
                            always @(posedge clk)
                                if(enable_shift2)
                                    tmp_B[ii][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll) * 32] = tmp_BB[ii][jj][(kk * n_divide_ps + ll) * 32 + 31 : (kk * n_divide_ps + ll) * 32];
    
    endgenerate
    

endmodule



//----------------------------------------------------------------------------------------------------------------------------------------------------------------

module mul_matrix
#(parameter n = 2)
(input [32 * n * n - 1: 0] mat_A, input [32 * n * n  - 1: 0] mat_B, output [32 * n * n - 1 : 0] mat_out);

    wire [31: 0] mul_res [n - 1 : 0][n - 1 : 0][n - 1 : 0]; 
    wire [31: 0] acc_res [n - 1 : 0][n - 1 : 0][n - 1: 0];
    genvar i, j, k, l;
    wire overflow;
    wire underflow;
    wire inexcat;

    generate 
        
        for (i = 0; i < n; i = i + 1)
            for (j = 0; j < n; j = j + 1)
                for (k = 0; k < n; k = k + 1)
                begin
                    //mul i_j_k(mat_A[i][j], mat_B[j][k], mul_res[i][k][j]);
                    FP_Multiplicator i_j_k(mat_A[(i +  n * j) * 32 + 31 : (i + n *  j) * 32], mat_B[(j + n * k) * 32 + 31 : (j + n * k) * 32],  mul_res[i][k][j][31 : 0], overflow, underflow);
                    //$display("in matrix mul", mat_A[(i * n +  j) * 32 + 31 : (i * n +  j) * 32]);
                end
        
        for (i = 0; i < n; i = i + 1)
            for (j = n - 1; j < n; j = j + 1)
                for (k = 0; k < n; k = k + 1)
                    assign acc_res[i][k][j][31 : 0] = mul_res[i][k][j][31: 0];
                
        for (i = 0; i < n; i = i + 1)
            for (j = 1; j < n; j = j + 1)
                for (k = 0; k < n; k = k + 1)
                    FP_Adder i_j_k(acc_res[i][k][j][31 : 0], mul_res[i][k][j - 1][31 : 0], acc_res[i][k][j - 1][31 : 0], overflow, underflow, inexcat);
        
        for (i = 0; i < n; i = i + 1)
            for (k = 0; k < n; k = k + 1)
                //assign mat_out[i][k] = acc_res[i][k][0];
                if (n > 1)
                    assign mat_out[(i + n * k)*32 + 31 : (i + n * k)*32] = acc_res[i][k][0][31 : 0];
                else
                    assign mat_out[(i + n * k)*32 + 31 : (i + n * k)*32] = mul_res[i][k][0][31 : 0];
    endgenerate

endmodule



//------------------------------------------------------------------
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
always @(*) begin
    underflow = 0;
    overflow = 0;
    result_exp_mul = 0;
    result_mnts_mul = 0;
    // case: a = zero
    if (a == `ZERO) begin
        // case: b is either NAN or infinity
            result = `ZERO;
    // case: b = 0
    end else if (b == `ZERO) begin
            result = `ZERO;
    // Infinity check
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


module FP_Adder (
    input wire [31:0] a,
    input wire [31:0] b,
    output reg [31:0] result,
    output reg underflow,
    output reg overflow,
    output reg inexcat
);
    // Registers needed in normalizing the exponents
    reg [2+22:0] a_fraction, b_fraction; // one more bit for real number
    reg [7:0] result_exponent, counter;
    wire [7:0] a_exponent = a[30:23];
    wire [7:0] b_exponent = b[30:23];
    wire same_signs = b[31] == a[31];

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

    always @(*)begin
        // Reset everything
        {underflow, overflow, inexcat} = 0;
        {a_fraction, b_fraction, result_exponent} = 0;
        counter = 0;
        // If one of them is NaN the result is NaN
        if (b == 0) begin // If b is zero then a is the result!
            result = a;
        end else if (a == 0) begin
            result = b;
        // Infinity checks
        end else begin // Now we are talking real numbers...
            // Set the registers
            a_fraction = {2'b1, a[22:0]};
            b_fraction = {2'b1, b[22:0]};
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
        end
    end
endmodule
