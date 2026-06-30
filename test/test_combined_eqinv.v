`default_nettype none
`define FILE_DEC "vec/aes_test_vectors_dec.csv"
`define FILE_ENC "vec/aes_test_vectors_enc.csv"
`define TRUE 1'b1
`define FALSE 1'b0
module test_combined_eqinv; 
//LINE BUFFER
reg [799:0] line;
reg [127:0] key_in, data_in, out_expected;
//file inputs from csv
reg clkin, reset, enable, mode;
//output wire variables
wire [127:0] out_tb;
wire busy;
integer i, j, failed, passed;
aes_combined_eqinv DUT_COM_1(
    .key_in(key_in),
    .data_in(data_in),
    .out(out_tb),
    .clkin(clkin),
    .reset(reset),
    .enable(enable),
    .busy(busy),
    .mode(mode)
);
initial begin
    //reset logic
    reset = `TRUE;
    clkin = `FALSE;
    enable = `FALSE;
    failed = 0;
    passed = 0;
end
always #5 clkin = ~clkin;
initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0, test_combined_eqinv);
    //Opening the file handles
    reset = `FALSE;
    #10 reset = `TRUE;
    #10 enable = `TRUE;
    i = $fopen(`FILE_ENC, "r");
    j = $fopen(`FILE_DEC, "r");
    $fgets(line, i);
    $fgets(line, j);
    mode = `TRUE;
    while(!$feof(i))begin
        $fgets(line, i);
        $sscanf(line, "%h, %h, %h",key_in, data_in, out_expected);
        enable = `TRUE;
         #130 enable = `FALSE;
        if(out_expected==out_tb)begin
            passed = passed +1;
        end
        else begin
            failed = failed+1;
            $display("%h, %h, for keys and plaintexts -> for output %h expected was = %h", key_in, data_in, out_tb, out_expected);
        end
    end
    mode = `FALSE;
    while(!$feof(j))begin
        $fgets(line, j);
        $sscanf(line, "%h, %h, %h", key_in, data_in, out_expected);
        enable = `TRUE;
        #130 enable = `FALSE;
        if(out_expected==out_tb)begin
            passed = passed +1;
        end
        else begin
            failed = failed+1;
            $display("%h, %h, for keys and cipher -> for output %h expected was = %h", key_in, data_in, out_tb, out_expected);
        end 
    end
    $display("====METRICS FOR THE TEST====");
    $display("tests passed = %d", passed);
    $display("tests failed = %d", failed);
    $fclose(i);
    $fclose(j);
    $finish;
end
endmodule