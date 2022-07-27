module controller
    #(parameter n = 4, parameter sqrt_p = 2, parameter n_divide_ps = 2, parameter p = 4)
    (input [32 * n * n : 0] matrix_A, input [32 * n * n : 0] matrix_B, input clk, input enable, input reset, output [32 * n * n : 0] out, output reg out_put_ready);
    reg [3 : 0] state;
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
                            out_put_ready = 1;
                            //get ready the output
                        end
                
                endcase
            else
                state <= state;
        end
        else
            state = 0;
    end
endmodule
