module matrix_divider(input [31: 0] A [3:0][3:0], input [31: 0] B [3: 0][3: 0], output reg [31: 0] C[3: 0][3: 0], input clk);
    reg [2: 0] state;
    reg [2 : 0] next_state;
    integer out_delay = 0; 
    wire [31: 0] P1 [1: 0][1: 0];
    wire [31: 0] P2 [1: 0][1: 0];
    wire [31: 0] P3 [1: 0][1: 0];
    wire [31: 0] P4 [1: 0][1: 0];
    integer loop_counter = 0;
    initial begin
        
    end
    
    set_next_state sns(state, next_state, out_delay, loop_counter);
    
    action_state as(state, loop_counter, A, B, P1, P2, P3, P4);
    //TODO dividing by loop counter
    //TODO complete 2*2 matrix multiplier
    //TODO handle integer for passing arguement or change them to register type.
    
endmodule


module action_state(input state, input loop_counter, input [31: 0] A [3: 0][3: 0], input [31: 0] B [3: 0][3: 0],
    output [31: 0] P1 [1: 0][1: 0],
    output [31: 0] P2 [1: 0][1: 0],
    output [31: 0] P3 [1: 0][1: 0],
    output [31: 0] P4 [1: 0][1: 0]);
endmodule 


module set_next_state(input [2 : 0] state, output reg next_state, input out_delay, output o_delay, input loop_counter, output o_loop_counter);

    always @(*)
    begin
        case(state)
            0: next_state <= 1;
            1: next_state <= 2;
            2: next_state <= 3;
            3: next_state <= 4;
            4: next_state <= 5;
            5:  
            begin
               next_state <= loop_counter == 0 ? 6 : 2;
               out_delay <= 10;
            end
            default: 
                begin
                    next_state <= out_delay == 0 ? 0 : 6;
                    out_delay <= out_delay - 1;
                end
        endcase
    end
    
endmodule

module test_matrix();
    
endmodule

module rand_input();

endmodule
