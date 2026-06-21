`timescale 1 ns/1 ps
`default_nettype none

module test_mixcols;
//mixcols fxn
reg [31:0] in = 32'h01020304;
reg [31:0] out = 32'h00000000; 
reg [31:0] res = 32'h0304090a;
reg flag;
//flag will be raised if output is correct
//function for mixcolumns
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
//since this function relies on xtimes
function [7:0]xtimes(
    input [7:0] num
);
    xtimes = (num[7])?((num<<1)^8'h1b):(num<<1);
endfunction

initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0,test_mixcols);
    #100;
    out = mixcolumns(in);
    #100;
    flag = out&&res; //precomputed result
    #100;
    $finish;
end
endmodule
