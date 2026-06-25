`timescale 1 ns/1 ps
`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module test_aes_dec;
    localparam EXPECTED = 128'h3243f6a8885a308d313198a2e0370734 ;
    //this testbench only tests for 1 test vector (now)
    //input reg variables
    reg [127:0] cipher_tb;
    reg [127:0] key_tb; 
    reg clkin, reset, enable;
    //output wire variables
    wire [127:0] out_tb;
    wire busy;
    //in and key should get the test vector values before sim starts
    aes_eqdec_iterative DUT_EQDEC_0(
        .cipher(cipher_tb),
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
        //ciphertexxt in
        cipher_tb= 128'h3925841d02dc09fbdc118597196a0b32;
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
        $dumpvars(0,test_aes_dec);
        #150;
        enable = `FALSE;
        #150;
        if(out_tb == EXPECTED)begin
            $display("test passed");
        end
        else begin
            $display("test failed");
        end
        $finish;
    end
endmodule