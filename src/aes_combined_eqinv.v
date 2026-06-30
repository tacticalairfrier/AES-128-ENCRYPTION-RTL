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
//encryption and decryption done together output muxed
aes_encrypt_iterative MOD_ENC(
    .in(data_in),
    .key(key_in),
    .out(enc_res),
    .clkin(clkin),
    .reset(reset),
    .enable(enable),
    .busy(busy)
);
aes_eqdec_iterative MOD_EQDEC(
    .cipher(data_in),
    .key(key_in),
    .out(dec_res),
    .clkin(clkin),
    .reset(reset),
    .enable(enable),
    .busy(busy)
);
always@(*)begin
    if(!reset)begin
        enc_res = 128'd0;
        dec_res = 128'd0;
    end
    else begin
        if(mode) out = enc_res;
        else out = dec_res;
    end
end
endmodule
