`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module aes_combined_eqinv(
    input wire [127:0] key_in, data_in,
    input wire clkin, reset, enable, mode,
    output reg [127:0] out,
    output reg busy
);
reg [127:0] enc_res, dec_res;
wire busy_e, busy_d;
//encryption and decryption done together output muxed
aes_encrypt_iterative MOD_ENC(
    .in(data_in),
    .key(key_in),
    .out(enc_res),
    .clkin(clkin),
    .reset(reset),
    .enable(enable),
    .busy(busy_e)
);
aes_eqdec_iterative MOD_EQDEC(
    .cipher(data_in),
    .key(key_in),
    .out(dec_res),
    .clkin(clkin),
    .reset(reset),
    .enable(enable),
    .busy(busy_d)
);
always@(*)begin
    busy = busy_e|busy_e;
    if(mode) out = enc_res;
    else out = dec_res;
end
endmodule
