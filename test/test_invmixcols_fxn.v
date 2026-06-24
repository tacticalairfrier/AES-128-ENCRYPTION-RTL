`timescale 1 ns/1 ps 
`default_nettype none

module test_mixcols_fxn;
reg [31:0] in;
reg [31:0] out;
initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0,test_mixcols_fxn);
    in = 31'h01020304;
    #10;
    out = invmixcolumns(in);
    #10;
    out = mixcolumns(out);
    #10;
    if(out == in)begin
        $display("basic test passed");
    end
    else begin
        $display("basic test failedw");
    end
    $finish;
end
function [31:0] invmixcolumns(
    input [31:0] column
);
begin
    reg [31:0] temp_4;
    reg [31:0] temp_2;
    reg [31:0] temp;
    {temp_4[31:24],temp_4[23:16], temp_4[15:8], temp_4[7:0]} = {xtimes_4(column[31:24]),xtimes_4(column[23:16]),xtimes_4(column[15:8]),xtimes_4(column[7:0])};
    {temp_2[31:24],temp_2[23:16], temp_2[15:8], temp_2[7:0]} = {xtimes_2(column[31:24]),xtimes_2(column[23:16]),xtimes_2(column[15:8]),xtimes_2(column[7:0])};
    {temp[31:24],temp[23:16], temp[15:8], temp[7:0]} = {xtimes(column[31:24]),xtimes(column[23:16]),xtimes(column[15:8]),xtimes(column[7:0])};
    invmixcolumns[31:24] = temp_4[31:24]^temp_2[31:24]^temp[31:24]^temp_4[23:16]^temp[23:16]^column[23:16]^temp_4[15:8]^temp_2[15:8]^column[15:8]^temp_4[7:0]^column[7:0];
    invmixcolumns[23:16] = temp_4[31:24]^column[31:24]^temp_4[23:16]^temp_2[23:16]^temp[23:16]^temp_4[15:8]^temp[15:8]^column[15:8]^temp_4[7:0]^temp_2[7:0]^column[7:0];
    invmixcolumns[15:8] = temp_4[31:24]^temp_2[31:24]^column[31:24]^temp_4[23:16]^column[23:16]^temp_4[15:8]^temp_2[15:8]^temp[15:8]^temp_4[7:0]^temp[7:0]^column[7:0];
    invmixcolumns[7:0] = temp_4[31:24]^temp[31:24]^column[31:24]^temp_4[23:16]^temp_2[23:16]^column[23:16]^temp_4[15:8]^column[15:8]^temp_4[7:0]^temp_2[7:0]^temp[7:0];
end
endfunction
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
   2'd0: xtimes_2 = num<<2;
   2'd1: xtimes_2 = (num<<2)^8'h1b;
   2'd2: xtimes_2 = (num<<2)^8'h36;
   2'd3: xtimes_2 = (num<<2)^8'h2d;
   endcase 
end
endfunction
//since mixcols is verified, ill use that for the verification
function [31:0] mixcolumns(
    input [31:0] column
);
begin
    reg[7:0]temp[0:3];
    reg[7:0]temp_column[0:3];
    //removed the int logic
    //making temporary regs which hold the values of all 4 bytes after the xtimes operation
    //and also making temp_column which stores b0 through b3
    temp[0] = xtimes(column[31:24]);
    temp[1] = xtimes(column[23:16]);
    temp[2] = xtimes(column[15:8]);
    temp[3] = xtimes(column[7:0]);
    temp_column[0] = column[31:24];
    temp_column[1] = column[23:16];
    temp_column[2] = column[15:8];
    temp_column[3] = column[7:0];
    //now the assignment of the mixcolumns output
    //31-0 is hte range for b-0 through b-4 and on
    //2311
    mixcolumns[31:24] = temp[0]^temp[1]^temp_column[1]^temp_column[2]^temp_column[3];
    //1231
    mixcolumns[23:16] = temp_column[0]^temp[1]^temp[2]^temp_column[2]^temp_column[3];
    //1123
    mixcolumns[15:8] = temp_column[0]^temp_column[1]^temp[2]^temp[3]^temp_column[3];
    //3112
    mixcolumns[7:0] = temp_column[0]^temp[0]^temp_column[1]^temp_column[2]^temp[3];
end
endfunction
endmodule