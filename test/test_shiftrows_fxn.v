`timescale 1ns/1ps
`default_nettype none

module test_shiftrows;
    //regular testing params
    reg [31:0] row = 32'h01020304;
    reg [31:0] shifted = 32'h00000000;
    //int 
    integer pos = 0;
    function[31:0]shiftrows(
    input[31:0] row,
    input integer i
    );
    begin
        case(i)
            0:begin
                //the 0th row experiences no change
                shiftrows = row;
            end
            1:begin
                //the first row is shifted to the right by 1
                shiftrows[31:24] = row[23:16];
                shiftrows[23:16] = row[15:8];
                shiftrows[15:8] = row[7:0];
                shiftrows[7:0] = row[31:24];
            end
            2:begin
               //second row is shifted to the right by 2
                shiftrows[31:24] = row[15:8];
                shiftrows[23:16] = row[7:0];
                shiftrows[15:8] = row[31:24];
                shiftrows[7:0] = row[23:16];
            end
            3:begin
                //the third row is shfited to the right by 3
                shiftrows[31:24] = row[7:0];
                shiftrows[23:16] = row[31:24];
                shiftrows[15:8] = row[23:16];
                shiftrows[7:0] = row[16:8];
            end
            default:begin
                shiftrows = row;
            end
        endcase 
    end
    endfunction
    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(0,test_shiftrows);
        //testing for the mode 0 or in 0th row mode
        shifted = shiftrows(row, pos);
        #100 pos = pos+1;
        //in 1st row mode
        shifted = shiftrows(row, pos);
        #100 pos = pos+1;
        //2nd row mode
        shifted = shiftrows(row, pos);
        #100 pos = pos+1;
        shifted = shiftrows(row, pos);
        #100;
        $finish;
    end
endmodule