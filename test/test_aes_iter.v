`timescale 1 ns/1 ps
`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module test_aes_iter;
    //this testbench only tests for 1 test vector (now)
    //input reg variables
    reg [127:0] in_tb;
    reg [127:0] key_tb; 
    reg clkin, reset, enable;
    //output wire variables
    wire [127:0] out_tb;
    wire busy;
    //in and key should get the test vector values before sim starts
    aes_encrypt_iterative DUT_ENC_0(
        .in(in_tb),
        .key(key_tb),
        .out(out_tb),
        .clkin(clkin),
        .reset(reset),
        .enable(enable),
        .busy(busy)
    );
    //initialing clock, enable and reset variables to 0

    initial begin
        reset = `TRUE;
        clkin = `FALSE;
        enable = `FALSE;
        //initialising the value of key and in
        //in
        in_tb= 128'h3243_f6a8_885a_308d_3131_98a2_e037_0734;
        //key
        key_tb = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    end
    //clock to begin toggling
    always #5 clkin = ~clkin;
    //calling reset
    initial begin
        reset = `FALSE;
        #10 reset = `TRUE;
        #10 enable = `TRUE;
    end
    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(0,test_aes_iter);
        #150;
        enable = `FALSE;
        #150;
        $finish;
    end
endmodule
