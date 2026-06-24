//this is for the inversecipher
`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module aes_decrypt_iterative(
    input [127:0] cipher, key,
    input wire clkin, reset, enable,
    output reg [127:0] out,
    output reg busy

);
localparam ROUNDS = 4'd10;
localparam SETUP = 2'b00, DECRYPT = 2'b01, UPDATE = 2'b10;
//using similar state definitions to the encrypt fsm
//1 clock cycle for the setup, 10 for decrypt, 1 for update
//xtimes
function [7:0]xtimes(
    input [7:0] num
);
    xtimes = (num[7])?((num<<1)^8'h1b):(num<<1);
endfunction
//replacement for xtimes(xtimes(b))
function [7:0]xtimes_2(
    input [7:0] num
);
begin
   case(num[7:6])
   2'd0: xtimes_2 = num<<2
   2'd1: xtimes_2 = (num<<2)^8'h1b;
   2'd2: xtimes_2 = (num<<2)^8'h36;
   2'd3: xtimes_2 = (num<<2)^8'h2d;
   endcase 
end
endfunction
//replacement for xtimes(xtimes(xtimes(b)))
function [7:0]xtimes_4(
    input [7:0] num
);
begin
    //precomputed results for the xor and logical things
    case(num[7:5])
    3'd0: xtimes_4 = num<<3;
    3'd1: xtimes_4 = (num<<3)^8'h1b;
    3'd2: xtimes_4 = (num<<3)^8'h36;
    3'd3: xtimes_4 = (num<<3)^8'h2d;
    3'd4: xtimes_4 = (num<<3)^8'h6c;
    3'd5: xtimes_4 = (num<<3)^8'h77;
    3'd6: xtimes_4 = (num<<3)^8'h5a;
    3'd7: xtimes_4 = (num<<3)^8'h41;
    endcase
end
endfunction
//invshiftrows
function [31:0] invshiftrows(
    input [31:0] row, 
    input integer i
);
begin
    case(i)
        0:begin
            invshiftrows = row;
        end
        1:begin
            invshiftrows[31:24] = row[7:0];
            invshiftrows[23:16] = row[31:24];
            invshiftrows[15:8] = row[23:16];
            invshiftrows[7:0] = row[15:8];
        end
        2:begin
            invshiftrows[31:24] = row[15:8];
            invshiftrows[23:16] = row[7:0];
            invshiftrows[15:8] = row[31:24];
            invshiftrows[7:0] = row[23:16];
        end
        3:begin
            invshiftrows[31:24] = row [23:16];
            invshiftrows[23:16] = row[15:8];
            invshiftrows[15:8] = row[7:0];
            invshiftrows[7:0] = row[31:24];
        end
    endcase
end
endfunction
//function for invmixcolumns
function [31:0] mixcolumns(
    input [31:0] column
);
begin
    reg [31:0] temp_4;
    reg [31:0] temp_2;
    reg [31:0] temp;
    {temp_4[31:24],temp_4[23:16], temp_4[15:8], temp_4[7:0]} = {xtimes_4(column[31:24]),xtimes_4(column[23:16]),xtimes_4(column[15:8]),xtimes_4(column[7:0])};
end
endfunction
//128 bit wide invsubword
function [127:0] invsubword(
    input [127:0] word
);
    begin
        integer j;
        for(j=0;j<16;j=j+1)begin
            //this is reverse order but who cares
            invsubword[(j*8)+:8] = invsbox(word[(j*8)+:8]);
        end
    end
endfunction
//all look up tables below this
//this is the inverse-sbox 
function [7:0] invsbox(
    input[7:0] inbyte
);
begin
    case(inbyte)
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
        8'h00: invsbox = 8'h00;
    endcase
end
endfunction
//look up table for the round constant
//use the concat operator here //{output of rcon, 24'h0000000}
function [7:0] rcon(
    [7:0] round_val
);
begin
    case(round_val)
    8'h01: rcon = 8'h01; 
    8'h02: rcon = 8'h02;
    8'h03: rcon = 8'h04;
    8'h04: rcon = 8'h08;
    8'h05: rcon = 8'h10;
    8'h06: rcon = 8'h20;
    8'h07: rcon = 8'h40;
    8'h08: rcon = 8'h80;
    8'h09: rcon = 8'h1b;
    8'h0a: rcon = 8'h36;
    endcase
end
endfunction
endmodule
