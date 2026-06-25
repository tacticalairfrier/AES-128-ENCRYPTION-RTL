`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module top_module_fpga(

);
SB_HFOSC u_SB_HFOSC (
    .CLKHFPU(1'b1), 
    .CLKHFEN(1'b1), 
    .CLKHF(clkin)
);
endmodule