`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b

module aes_encrypt_iterative(

);
//spi slave for communication with the aes encryption core as it utilises 128 bit things
//cant afford that for obv reasons on real hardwar
endmodule
module aes_encrypt_block_iterative(
    input wire [127:0] in, key,
    input wire clkin, reset, enable,
    output reg [127:0] out,
    output reg busy
);
//since this is aes 128, the rounds are 128
localparam ROUNDS = 4'd10;
localparam SETUP = 2'b00, ENCRYPT = 2'b01, UPDATE = 2'b10;
//setup is sort of like idle situation and the thing is important
//encrypt is the main cycle and will consume 10 clock cycles
//update updates all setup values i.e updates the out
integer i;
//making state a a 16 byte wide register
reg [7:0] state [0:16];
reg [7:0] key_arr [0:16];
reg [3:0] roundcounter; 
reg [1:0] state;
always@(posedge clkin, negedge reset)begin
    if(!reset)begin
        roundcounter = ROUNDS;
        
    end
    else begin
        if(roundcounter == 4'd10)begin
            
        end
        roundcounter = roundcounter-1;
    end
end
//xtimes function is implemented this way in order to be cheaper on hardware
task xtimes(
    input [7:0] in_xt
    output [7:0] out_xt;
);
    out_xt = (num[7])?((num<<1)^8'h1b):(num<<1);
endtask
endmodule