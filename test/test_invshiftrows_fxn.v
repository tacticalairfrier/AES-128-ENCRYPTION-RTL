`timescale 1 ns/1 ps 
`default_nettype none

module test_invshiftrows_fxn;
reg [31:0] in, out;
initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0,test_invshiftrows_fxn);
    out = 32'h0;
    in = 31'h01020304;
    #10 out = invshiftrows(in,0);
    #10 out = invshiftrows(in,1);
    #10 out = invshiftrows(in,2);
    #10 out = invshiftrows(in,3);
    #10;
    $finish;
end
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
endmodule