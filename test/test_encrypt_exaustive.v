`timescale 1 ns/1 ps
`default_nettype none
`define FILE "vec/aes_test_vectors_enc.csv"
`define TRUE 1'b1
`define FALSE 1'b0

module test_encrypt_exaustive;
//using 1000 test vectors list
//using ffscanf and fpopen
reg [799:0] line;
//800 bit buffer for storing each line
reg [127:0] key_in,plaintext_in,out_expected;
//file inputs from csv
reg clkin, reset, enable;
//output wire variables
wire [127:0] out_tb;
wire busy;
aes_encrypt_iterative DUT_AES_ENC(
    .key(key_in),
    .in(plaintext_in),
    .out(out_tb),
    .clkin(clkin),
    .reset(reset),
    .enable(enable),
    .busy(busy)
);
integer j, failed, passed;
initial begin
    //reset logic
    reset = `TRUE;
    clkin = `FALSE;
    enable = `FALSE;
    failed = 0;
    passed = 0;
end
//clock starts toggling here
always #5 clkin = ~clkin;
initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0,test_encrypt_exaustive);
    //invoking reset
    reset = `FALSE;
    #10 reset = `TRUE;
    #10 enable = `TRUE;
    //j is an integer that just keeps track of which file is which
    j  = $fopen(`FILE, "r");
    $fgets(line, j);
    while(!$feof(j))begin
        $fgets(line, j);
        $sscanf(line, "%h, %h, %h", key_in, plaintext_in, out_expected);
        enable = `TRUE;
        #130 enable = `FALSE;
        if(out_expected==out_tb)begin
            passed = passed +1;
        end
        else begin
            failed = failed+1;
            $display("%h, %h, for keys and plaintexts -> for output %h expected was = %h", key_in, plaintext_in, out_tb, out_expected);
        end
    end
    //display the passed and failed metrics
    $display("====METRICS FOR THE TEST====");
    $display("tests passed = %d", passed);
    $display("tests failed = %d", failed);
    $fclose(j);
    $finish;
end
endmodule
