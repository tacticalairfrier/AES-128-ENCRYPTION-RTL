//this is for the inversecipher
`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module aes_decrypt_iterative(
    input [127:0] cipher, key,
    input wire clkin, reset, enable,
    output reg [127:0] out,
    output reg busy

);
//comments for linter
/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off CASEINCOMPLETE */
/* verilator lint_off WIDTHEXPAND */
//since this is aes 128, the rounds are 10
localparam ROUNDS = 4'd10;
localparam SETUP = 2'b00, DECRYPT = 2'b01, UPDATE = 2'b10;
//using similar state definitions to the encrypt fsm
//1 clock cycle for the setup, 10 for decrypt, 1 for update
//xtimes
reg [127:0] state, nextstate;
//nextkeyscheduel will be optimised away
reg [1279:0] key_schedule, nextkey_schedule;
//the functions are supposed to be the same
reg [3:0] roundcounter; 
reg [1:0] state_fsm, nextstate_fsm;
//here state fsm is the state for the fsm which is a 2 bit counter
always@(posedge clkin, negedge reset)begin
    if(!reset)begin
        roundcounter <= ROUNDS;
        state_fsm <= SETUP;
        out<=128'h0;
        state <= nextstate; 
        key_schedule = 1280'b0;
    end
    else begin
        state<=nextstate;
        state_fsm<=nextstate_fsm;
        key_schedule<=nextkey_schedule;
        case(state_fsm)
            SETUP:begin
                roundcounter <= ROUNDS;
            end
            DECRYPT:begin
                roundcounter <= roundcounter-1;
            end
            UPDATE:begin
                roundcounter <= 4'h0;
                out <= state;
            end
        endcase
    end
end
//combinational block
always@(*)begin
    nextstate_fsm = state_fsm;
    nextstate = state;
    nextkey_schedule = key_schedule;
    busy = `FALSE;
    if(!reset)begin
        nextstate_fsm = SETUP;
        nextstate = 128'h0;
    end
    else begin
        case(state_fsm)
            SETUP:begin
                if(enable)begin
                    nextstate_fsm = DECRYPT;
                    nextstate = cipher;
                    busy =`TRUE;
                    nextkey_schedule = keyscheduler(key);
                end
                else begin
                    nextstate_fsm = SETUP;
                    busy = `FALSE;
                end 
            end
            //here busy is a mooore output as its only strobed in setup, when it enters
            //all the cipher action happens in the encrypt state instead of making a separate cipher fxn
            DECRYPT:begin
                // {nextkey_arr[i],nextkey_arr[i+1],nextkey_arr[i+2],nextkey_arr[i+3]}
                ///key scheduling here
                // key scheduling has to be in reverse
                busy =  `TRUE;
                //key schedule stays the same for the inverse cipher thus i have kept the og fnxs
                //rotword is shiftrows at 1 th mode
                // nextkey_arr[127:96] = shiftrows(key_arr[31:0]);
                // //subword is as it is
                // nextkey_arr[127:96] = subword(nextkey_arr[127:96]);
                // //this is for rcon
                // nextkey_arr[127:96] = nextkey_arr[127:96] ^ {rcon((ROUNDS-roundcounter)+4'h1), 24'h000000} ^ key_arr[127:96];
                // //loop for the other 3 words
                // nextkey_arr[95:64] = nextkey_arr[127:96] ^ key_arr[95:64];
                // nextkey_arr[63:32] = nextkey_arr[95:64] ^ key_arr[63:32];
                // nextkey_arr[31:0] = nextkey_arr[63:32] ^ key_arr[31:0];
                // //key scheduling ends here
                if(roundcounter==ROUNDS)begin
                    //neeed to add all hte key scheduling logic here with a loop to generate all the 10 roundkeys which then can easily be left shifted out
                    //initial addroundkey
                    //
                    //placeholder for a function for generating the key
                    //
                    nextstate = key_schedule[127:0]^state;
                    nextkey_schedule = key_schedule>>128;
                    //
                    nextstate_fsm = DECRYPT;
                end
                else if(roundcounter>0)begin
                    nextstate = invsubword(state);
                    //shiftrows gonn be tough without the array appraoach
                    //not even calling shiftrows at 0
                    {nextstate[119:112], nextstate[87:80],nextstate[55:48],nextstate[23:16]} = invshiftrows({nextstate[119:112], nextstate[87:80],nextstate[55:48],nextstate[23:16]},1);
                    {nextstate[111:104], nextstate[79:72],nextstate[47:40],nextstate[15:8]} = invshiftrows({nextstate[111:104], nextstate[79:72],nextstate[47:40],nextstate[15:8]},2);
                    {nextstate[103:96], nextstate[71:64],nextstate[39:32],nextstate[7:0]} = invshiftrows({nextstate[103:96], nextstate[71:64],nextstate[39:32],nextstate[7:0]} ,3);
                    //shiftrows ends 
                    //
                    nextstate = key_schedule[127:0]^nextstate;
                    nextkey_schedule = key_schedule>>128;
                    //
                    //addroundkey
                    //mixcolumns here
                    nextstate[127:96] = invmixcolumns(nextstate[127:96]);
                    nextstate[95:64] = invmixcolumns(nextstate[95:64]);
                    nextstate[63:32] = invmixcolumns(nextstate[63:32]);
                    nextstate[31:0] = invmixcolumns(nextstate[31:0]);
                    //mixcolumns ends
                    nextstate_fsm = DECRYPT;
                end
                else begin
                    nextstate = invsubword(state);
                    //shiftrows
                    {nextstate[119:112], nextstate[87:80],nextstate[55:48],nextstate[23:16]} = invshiftrows({nextstate[119:112], nextstate[87:80],nextstate[55:48],nextstate[23:16]},1);
                    {nextstate[111:104], nextstate[79:72],nextstate[47:40],nextstate[15:8]} = invshiftrows({nextstate[111:104], nextstate[79:72],nextstate[47:40],nextstate[15:8]},2);
                    {nextstate[103:96], nextstate[71:64],nextstate[39:32],nextstate[7:0]} = invshiftrows({nextstate[103:96], nextstate[71:64],nextstate[39:32],nextstate[7:0]} ,3);
                    //addroundkey
                    // this is the only correct statement in the keyexpansion
                    nextkey_schedule = key_schedule;
                    nextstate = key^nextstate;
                    nextstate_fsm = UPDATE;
                end
            end
            UPDATE: begin
                nextstate_fsm = SETUP;
                busy = `FALSE;
            end
        endcase
    end      
end
function [7:0]xtimes(
    input [7:0] num
);
    xtimes = (num[7])?((num<<1)^8'h1b):(num<<1);
endfunction
//replacement for xtimes(xtimes(b))
function [7:0]xtimes_2(
    input [7:0] num
);
begin
   case(num[7:6])
   2'd0: xtimes_2 = num<<2;
   2'd1: xtimes_2 = (num<<2)^8'h1b;
   2'd2: xtimes_2 = (num<<2)^8'h36;
   2'd3: xtimes_2 = (num<<2)^8'h2d;
   endcase 
end
endfunction
//replacement for xtimes(xtimes(xtimes(b)))
function [7:0]xtimes_4(
    input [7:0] num
);
begin
    //precomputed results for the xor and logical things
    case(num[7:5])
    3'd0: xtimes_4 = num<<3;
    3'd1: xtimes_4 = (num<<3)^8'h1b;
    3'd2: xtimes_4 = (num<<3)^8'h36;
    3'd3: xtimes_4 = (num<<3)^8'h2d;
    3'd4: xtimes_4 = (num<<3)^8'h6c;
    3'd5: xtimes_4 = (num<<3)^8'h77;
    3'd6: xtimes_4 = (num<<3)^8'h5a;
    3'd7: xtimes_4 = (num<<3)^8'h41;
    endcase
end
endfunction
//invshiftrows
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
//function for invmixcolumns
function [31:0] invmixcolumns(
    input [31:0] column
);
begin
    reg [31:0] temp_4;
    reg [31:0] temp_2;
    reg [31:0] temp;
    {temp_4[31:24],temp_4[23:16], temp_4[15:8], temp_4[7:0]} = {xtimes_4(column[31:24]),xtimes_4(column[23:16]),xtimes_4(column[15:8]),xtimes_4(column[7:0])};
    {temp_2[31:24],temp_2[23:16], temp_2[15:8], temp_2[7:0]} = {xtimes_2(column[31:24]),xtimes_2(column[23:16]),xtimes_2(column[15:8]),xtimes_2(column[7:0])};
    {temp[31:24],temp[23:16], temp[15:8], temp[7:0]} = {xtimes(column[31:24]),xtimes(column[23:16]),xtimes(column[15:8]),xtimes(column[7:0])};
    invmixcolumns[31:24] = temp_4[31:24]^temp_2[31:24]^temp[31:24]^temp_4[23:16]^temp[23:16]^column[23:16]^temp_4[15:8]^temp_2[15:8]^column[15:8]^temp_4[7:0]^column[7:0];
    invmixcolumns[23:16] = temp_4[31:24]^column[31:24]^temp_4[23:16]^temp_2[23:16]^temp[23:16]^temp_4[15:8]^temp[15:8]^column[15:8]^temp_4[7:0]^temp_2[7:0]^column[7:0];
    invmixcolumns[15:8] = temp_4[31:24]^temp_2[31:24]^column[31:24]^temp_4[23:16]^column[23:16]^temp_4[15:8]^temp_2[15:8]^temp[15:8]^temp_4[7:0]^temp[7:0]^column[7:0];
    invmixcolumns[7:0] = temp_4[31:24]^temp[31:24]^column[31:24]^temp_4[23:16]^temp_2[23:16]^column[23:16]^temp_4[15:8]^column[15:8]^temp_4[7:0]^temp_2[7:0]^temp[7:0];
end
endfunction
//128 bit wide invsubword
function [127:0] invsubword(
    input [127:0] word
);
    begin
        integer j;
        for(j=0;j<16;j=j+1)begin
            //this is reverse order but who cares
            invsubword[(j*8)+:8] = invsbox(word[(j*8)+:8]);
        end
    end
endfunction
//here the shiftrows function is just rotword 
function[31:0]shiftrows(
    input[31:0] row
);
begin
    //the first row is shifted to the right by 1
    shiftrows[31:24] = row[23:16];
    shiftrows[23:16] = row[15:8];
    shiftrows[15:8] = row[7:0];
    shiftrows[7:0] = row[31:24];
end
endfunction
//key schedule generator
function [1279:0] keyscheduler(
    input[127:0] key_in
);
begin
    integer i;
    reg [127:0] temp;
    //
    //making the first entry manually ig
    //this is round 1
    temp[127:96] = shiftrows(key_in[31:0]);
    temp[127:96] = subword(temp[127:96]);
    temp[127:96] = temp[127:96] ^ {rcon(8'h01), 24'h000000} ^ key_in[127:96];
    temp[95:64] = temp[127:96] ^ key_in[95:64];
    temp[63:32] = temp[95:64] ^ key_in[63:32];
    temp[31:0] = temp[63:32] ^ key_in[31:0];
    //the lsb 128 bits hold the first key schedule
    keyscheduler[127:0] = temp;
    for(i=2;i<=10;i=i+1)begin
        //round 2 onwards
        temp[127:96] = shiftrows(keyscheduler[32:0]); //32 bit wide part select of keyschedule goes from 32 through 0
        temp[127:96] = subword(temp[127:96]);  //same logic
        temp[127:96] = temp[127:96] ^ {rcon(i), 24'h000000} ^ keyscheduler[127:96]; //key scheduler part select here to capture 127:96 here
        temp[95:64] = temp[127:96] ^ keyscheduler[95:64]; //keyscheduler here
        temp[63:32] = temp[95:64] ^ keyscheduler[63:32]; //ks here
        temp[31:0] = temp[63:32] ^ keyscheduler[31:0];//key in becomes hte keyscheduler variable
        //now keyscheduler can move on that is shifted by 128
        keyscheduler<<=128;
        keyscheduler[127:0] = temp; //this should be lower i.e closer to o'th value
    end
end
endfunction
//all look up tables below this
//this is the inverse-sbox 
function [7:0] invsbox(
    input[7:0] inbyte
);
begin
    case(inbyte)
        8'h00: invsbox = 8'h52;
        8'h01: invsbox = 8'h09;
        8'h02: invsbox = 8'h6a;
        8'h03: invsbox = 8'hd5;
        8'h04: invsbox = 8'h30;
        8'h05: invsbox = 8'h36;
        8'h06: invsbox = 8'ha5;
        8'h07: invsbox = 8'h38;
        8'h08: invsbox = 8'hbf;
        8'h09: invsbox = 8'h40;
        8'h0a: invsbox = 8'ha3;
        8'h0b: invsbox = 8'h93;
        8'h0c: invsbox = 8'h81;
        8'h0d: invsbox = 8'hf3;
        8'h0e: invsbox = 8'hd7;
        8'h0f: invsbox = 8'hfb;
        8'h10: invsbox = 8'h7c;
        8'h11: invsbox = 8'he3;
        8'h12: invsbox = 8'h39;
        8'h13: invsbox = 8'h82;
        8'h14: invsbox = 8'h9b;
        8'h15: invsbox = 8'h2f;
        8'h16: invsbox = 8'hff;
        8'h17: invsbox = 8'h87;
        8'h18: invsbox = 8'h34;
        8'h19: invsbox = 8'h8e;
        8'h1a: invsbox = 8'h43;
        8'h1b: invsbox = 8'h44;
        8'h1c: invsbox = 8'hc4;
        8'h1d: invsbox = 8'hde;
        8'h1e: invsbox = 8'he9;
        8'h1f: invsbox = 8'hcb;
        8'h20: invsbox = 8'h54;
        8'h21: invsbox = 8'h7b;
        8'h22: invsbox = 8'h94;
        8'h23: invsbox = 8'h32;
        8'h24: invsbox = 8'ha6;
        8'h25: invsbox = 8'hc2;
        8'h26: invsbox = 8'h23;
        8'h27: invsbox = 8'h3d;
        8'h28: invsbox = 8'hee;
        8'h29: invsbox = 8'h4c;
        8'h2a: invsbox = 8'h95;
        8'h2b: invsbox = 8'h0b;
        8'h2c: invsbox = 8'h42;
        8'h2d: invsbox = 8'hfa;
        8'h2e: invsbox = 8'hc3;
        8'h2f: invsbox = 8'h4e;
        8'h30: invsbox = 8'h08;
        8'h31: invsbox = 8'h2e;
        8'h32: invsbox = 8'ha1;
        8'h33: invsbox = 8'h66;
        8'h34: invsbox = 8'h28;
        8'h35: invsbox = 8'hd9;
        8'h36: invsbox = 8'h24;
        8'h37: invsbox = 8'hb2;
        8'h38: invsbox = 8'h76;
        8'h39: invsbox = 8'h5b;
        8'h3a: invsbox = 8'ha2;
        8'h3b: invsbox = 8'h49;
        8'h3c: invsbox = 8'h6d;
        8'h3d: invsbox = 8'h8b;
        8'h3e: invsbox = 8'hd1;
        8'h3f: invsbox = 8'h25;
        8'h40: invsbox = 8'h72;
        8'h41: invsbox = 8'hf8;
        8'h42: invsbox = 8'hf6;
        8'h43: invsbox = 8'h64;
        8'h44: invsbox = 8'h86;
        8'h45: invsbox = 8'h68;
        8'h46: invsbox = 8'h98;
        8'h47: invsbox = 8'h16;
        8'h48: invsbox = 8'hd4;
        8'h49: invsbox = 8'ha4;
        8'h4a: invsbox = 8'h5c;
        8'h4b: invsbox = 8'hcc;
        8'h4c: invsbox = 8'h5d;
        8'h4d: invsbox = 8'h65;
        8'h4e: invsbox = 8'hb6;
        8'h4f: invsbox = 8'h92;
        8'h50: invsbox = 8'h6c;
        8'h51: invsbox = 8'h70;
        8'h52: invsbox = 8'h48;
        8'h53: invsbox = 8'h50;
        8'h54: invsbox = 8'hfd;
        8'h55: invsbox = 8'hed;
        8'h56: invsbox = 8'hb9;
        8'h57: invsbox = 8'hda;
        8'h58: invsbox = 8'h5e;
        8'h59: invsbox = 8'h15;
        8'h5a: invsbox = 8'h46;
        8'h5b: invsbox = 8'h57;
        8'h5c: invsbox = 8'ha7;
        8'h5d: invsbox = 8'h8d;
        8'h5e: invsbox = 8'h9d;
        8'h5f: invsbox = 8'h84;
        8'h60: invsbox = 8'h90;
        8'h61: invsbox = 8'hd8;
        8'h62: invsbox = 8'hab;
        8'h63: invsbox = 8'h00;
        8'h64: invsbox = 8'h8c;
        8'h65: invsbox = 8'hbc;
        8'h66: invsbox = 8'hd3;
        8'h67: invsbox = 8'h0a;
        8'h68: invsbox = 8'hf7;
        8'h69: invsbox = 8'he4;
        8'h6a: invsbox = 8'h58;
        8'h6b: invsbox = 8'h05;
        8'h6c: invsbox = 8'hb8;
        8'h6d: invsbox = 8'hb3;
        8'h6e: invsbox = 8'h45;
        8'h6f: invsbox = 8'h06;
        8'h70: invsbox = 8'hd0;
        8'h71: invsbox = 8'h2c;
        8'h72: invsbox = 8'h1e;
        8'h73: invsbox = 8'h8f;
        8'h74: invsbox = 8'hca;
        8'h75: invsbox = 8'h3f;
        8'h76: invsbox = 8'h0f;
        8'h77: invsbox = 8'h02;
        8'h78: invsbox = 8'hc1;
        8'h79: invsbox = 8'haf;
        8'h7a: invsbox = 8'hbd;
        8'h7b: invsbox = 8'h03;
        8'h7c: invsbox = 8'h01;
        8'h7d: invsbox = 8'h13;
        8'h7e: invsbox = 8'h8a;
        8'h7f: invsbox = 8'h6b;
        8'h80: invsbox = 8'h3a;
        8'h81: invsbox = 8'h91;
        8'h82: invsbox = 8'h11;
        8'h83: invsbox = 8'h41;
        8'h84: invsbox = 8'h4f;
        8'h85: invsbox = 8'h67;
        8'h86: invsbox = 8'hdc;
        8'h87: invsbox = 8'hea;
        8'h88: invsbox = 8'h97;
        8'h89: invsbox = 8'hf2;
        8'h8a: invsbox = 8'hcf;
        8'h8b: invsbox = 8'hce;
        8'h8c: invsbox = 8'hf0;
        8'h8d: invsbox = 8'hb4;
        8'h8e: invsbox = 8'he6;
        8'h8f: invsbox = 8'h73;
        8'h90: invsbox = 8'h96;
        8'h91: invsbox = 8'hac;
        8'h92: invsbox = 8'h74;
        8'h93: invsbox = 8'h22;
        8'h94: invsbox = 8'he7;
        8'h95: invsbox = 8'had;
        8'h96: invsbox = 8'h35;
        8'h97: invsbox = 8'h85;
        8'h98: invsbox = 8'he2;
        8'h99: invsbox = 8'hf9;
        8'h9a: invsbox = 8'h37;
        8'h9b: invsbox = 8'he8;
        8'h9c: invsbox = 8'h1c;
        8'h9d: invsbox = 8'h75;
        8'h9e: invsbox = 8'hdf;
        8'h9f: invsbox = 8'h6e;
        8'ha0: invsbox = 8'h47;
        8'ha1: invsbox = 8'hf1;
        8'ha2: invsbox = 8'h1a;
        8'ha3: invsbox = 8'h71;
        8'ha4: invsbox = 8'h1d;
        8'ha5: invsbox = 8'h29;
        8'ha6: invsbox = 8'hc5;
        8'ha7: invsbox = 8'h89;
        8'ha8: invsbox = 8'h6f;
        8'ha9: invsbox = 8'hb7;
        8'haa: invsbox = 8'h62;
        8'hab: invsbox = 8'h0e;
        8'hac: invsbox = 8'haa;
        8'had: invsbox = 8'h18;
        8'hae: invsbox = 8'hbe;
        8'haf: invsbox = 8'h1b;
        8'hb0: invsbox = 8'hfc;
        8'hb1: invsbox = 8'h56;
        8'hb2: invsbox = 8'h3e;
        8'hb3: invsbox = 8'h4b;
        8'hb4: invsbox = 8'hc6;
        8'hb5: invsbox = 8'hd2;
        8'hb6: invsbox = 8'h79;
        8'hb7: invsbox = 8'h20;
        8'hb8: invsbox = 8'h9a;
        8'hb9: invsbox = 8'hdb;
        8'hba: invsbox = 8'hc0;
        8'hbb: invsbox = 8'hfe;
        8'hbc: invsbox = 8'h78;
        8'hbd: invsbox = 8'hcd;
        8'hbe: invsbox = 8'h5a;
        8'hbf: invsbox = 8'hf4;
        8'hc0: invsbox = 8'h1f;
        8'hc1: invsbox = 8'hdd;
        8'hc2: invsbox = 8'ha8;
        8'hc3: invsbox = 8'h33;
        8'hc4: invsbox = 8'h88;
        8'hc5: invsbox = 8'h07;
        8'hc6: invsbox = 8'hc7;
        8'hc7: invsbox = 8'h31;
        8'hc8: invsbox = 8'hb1;
        8'hc9: invsbox = 8'h12;
        8'hca: invsbox = 8'h10;
        8'hcb: invsbox = 8'h59;
        8'hcc: invsbox = 8'h27;
        8'hcd: invsbox = 8'h80;
        8'hce: invsbox = 8'hec;
        8'hcf: invsbox = 8'h5f;
        8'hd0: invsbox = 8'h60;
        8'hd1: invsbox = 8'h51;
        8'hd2: invsbox = 8'h7f;
        8'hd3: invsbox = 8'ha9;
        8'hd4: invsbox = 8'h19;
        8'hd5: invsbox = 8'hb5;
        8'hd6: invsbox = 8'h4a;
        8'hd7: invsbox = 8'h0d;
        8'hd8: invsbox = 8'h2d;
        8'hd9: invsbox = 8'he5;
        8'hda: invsbox = 8'h7a;
        8'hdb: invsbox = 8'h9f;
        8'hdc: invsbox = 8'h93;
        8'hdd: invsbox = 8'hc9;
        8'hde: invsbox = 8'h9c;
        8'hdf: invsbox = 8'hef;
        8'he0: invsbox = 8'ha0;
        8'he1: invsbox = 8'he0;
        8'he2: invsbox = 8'h3b;
        8'he3: invsbox = 8'h4d;
        8'he4: invsbox = 8'hae;
        8'he5: invsbox = 8'h2a;
        8'he6: invsbox = 8'hf5;
        8'he7: invsbox = 8'hb0;
        8'he8: invsbox = 8'hc8;
        8'he9: invsbox = 8'heb;
        8'hea: invsbox = 8'hbb;
        8'heb: invsbox = 8'h3c;
        8'hec: invsbox = 8'h83;
        8'hed: invsbox = 8'h53;
        8'hee: invsbox = 8'h99;
        8'hef: invsbox = 8'h61;
        8'hf0: invsbox = 8'h17;
        8'hf1: invsbox = 8'h2b;
        8'hf2: invsbox = 8'h04;
        8'hf3: invsbox = 8'h7e;
        8'hf4: invsbox = 8'hba;
        8'hf5: invsbox = 8'h77;
        8'hf6: invsbox = 8'hd6;
        8'hf7: invsbox = 8'h26;
        8'hf8: invsbox = 8'he1;
        8'hf9: invsbox = 8'h69;
        8'hfa: invsbox = 8'h14;
        8'hfb: invsbox = 8'h63;
        8'hfc: invsbox = 8'h55;
        8'hfd: invsbox = 8'h21;
        8'hfe: invsbox = 8'h0c;
        8'hff: invsbox = 8'h7d;
    endcase
end
endfunction
//look up table for the round constant
//use the concat operator here //{output of rcon, 24'h0000000}
function [7:0] rcon(
    [7:0] round_val
);
begin
    case(round_val)
    8'h01: rcon = 8'h01; 
    8'h02: rcon = 8'h02;
    8'h03: rcon = 8'h04;
    8'h04: rcon = 8'h08;
    8'h05: rcon = 8'h10;
    8'h06: rcon = 8'h20;
    8'h07: rcon = 8'h40;
    8'h08: rcon = 8'h80;
    8'h09: rcon = 8'h1b;
    8'h0a: rcon = 8'h36;
    endcase
end
endfunction
//subword needed for keyschedule
function [127:0] subword(
    input [127:0] word
);
    begin
        integer j;
        for(j=0;j<16;j=j+1)begin
            //this is reverse order but who cares
            subword[(j*8)+:8] = sbox(word[(j*8)+:8]);
        end
    end
endfunction
//sbox fxn needed for subbytes in keyschedule
function [7:0]sbox(
    input [7:0] inbyte
);//behold the fruits of my manual labour
begin
case(inbyte)
    8'h00: sbox = 8'h63;
    8'h01: sbox = 8'h7c;
    8'h02: sbox = 8'h77;
    8'h03: sbox = 8'h7b;
    8'h04: sbox = 8'hf2;
    8'h05: sbox = 8'h6b;
    8'h06: sbox = 8'h6f;
    8'h07: sbox = 8'hc5;
    8'h08: sbox = 8'h30;
    8'h09: sbox = 8'h01;
    8'h0a: sbox = 8'h67;
    8'h0b: sbox = 8'h2b;
    8'h0c: sbox = 8'hfe;
    8'h0d: sbox = 8'hd7;
    8'h0e: sbox = 8'hab;
    8'h0f: sbox = 8'h76;
    8'h10: sbox = 8'hca;
    8'h11: sbox = 8'h82;
    8'h12: sbox = 8'hc9;
    8'h13: sbox = 8'h7d;
    8'h14: sbox = 8'hfa;
    8'h15: sbox = 8'h59;
    8'h16: sbox = 8'h47;
    8'h17: sbox = 8'hf0;
    8'h18: sbox = 8'had;
    8'h19: sbox = 8'hd4;
    8'h1a: sbox = 8'ha2;
    8'h1b: sbox = 8'haf;
    8'h1c: sbox = 8'h9c;
    8'h1d: sbox = 8'ha4;
    8'h1e: sbox = 8'h72;
    8'h1f: sbox = 8'hc0;
    8'h20: sbox = 8'hb7;
    8'h21: sbox = 8'hfd;
    8'h22: sbox = 8'h93;
    8'h23: sbox = 8'h26;
    8'h24: sbox = 8'h36;
    8'h25: sbox = 8'h3f;
    8'h26: sbox = 8'hf7;
    8'h27: sbox = 8'hcc;
    8'h28: sbox = 8'h34;
    8'h29: sbox = 8'ha5;
    8'h2a: sbox = 8'he5;
    8'h2b: sbox = 8'hf1;
    8'h2c: sbox = 8'h71;
    8'h2d: sbox = 8'hd8;
    8'h2e: sbox = 8'h31;
    8'h2f: sbox = 8'h15;
    8'h30: sbox = 8'h04;
    8'h31: sbox = 8'hc7;
    8'h32: sbox = 8'h23;
    8'h33: sbox = 8'hc3;
    8'h34: sbox = 8'h18;
    8'h35: sbox = 8'h96;
    8'h36: sbox = 8'h05;
    8'h37: sbox = 8'h9a;
    8'h38: sbox = 8'h07;
    8'h39: sbox = 8'h12;
    8'h3a: sbox = 8'h80;
    8'h3b: sbox = 8'he2;
    8'h3c: sbox = 8'heb;
    8'h3d: sbox = 8'h27;
    8'h3e: sbox = 8'hb2;
    8'h3f: sbox = 8'h75;
    8'h40: sbox = 8'h09;
    8'h41: sbox = 8'h83;
    8'h42: sbox = 8'h2c;
    8'h43: sbox = 8'h1a;
    8'h44: sbox = 8'h1b;
    8'h45: sbox = 8'h6e;
    8'h46: sbox = 8'h5a;
    8'h47: sbox = 8'ha0;
    8'h48: sbox = 8'h52;
    8'h49: sbox = 8'h3b;
    8'h4a: sbox = 8'hd6;
    8'h4b: sbox = 8'hb3;
    8'h4c: sbox = 8'h29;
    8'h4d: sbox = 8'he3;
    8'h4e: sbox = 8'h2f;
    8'h4f: sbox = 8'h84;
    8'h50: sbox = 8'h53;
    8'h51: sbox = 8'hd1;
    8'h52: sbox = 8'h00;
    8'h53: sbox = 8'hed;
    8'h54: sbox = 8'h20;
    8'h55: sbox = 8'hfc;
    8'h56: sbox = 8'hb1;
    8'h57: sbox = 8'h5b;
    8'h58: sbox = 8'h6a;
    8'h59: sbox = 8'hcb;
    8'h5a: sbox = 8'hbe;
    8'h5b: sbox = 8'h39;
    8'h5c: sbox = 8'h4a;
    8'h5d: sbox = 8'h4c;
    8'h5e: sbox = 8'h58;
    8'h5f: sbox = 8'hcf;
    8'h60: sbox = 8'hd0;
    8'h61: sbox = 8'hef;
    8'h62: sbox = 8'haa;
    8'h63: sbox = 8'hfb;
    8'h64: sbox = 8'h43;
    8'h65: sbox = 8'h4d;
    8'h66: sbox = 8'h33;
    8'h67: sbox = 8'h85;
    8'h68: sbox = 8'h45;
    8'h69: sbox = 8'hf9;
    8'h6a: sbox = 8'h02;
    8'h6b: sbox = 8'h7f;
    8'h6c: sbox = 8'h50;
    8'h6d: sbox = 8'h3c;
    8'h6e: sbox = 8'h9f;
    8'h6f: sbox = 8'ha8;
    8'h70: sbox = 8'h51;
    8'h71: sbox = 8'ha3;
    8'h72: sbox = 8'h40;
    8'h73: sbox = 8'h8f;
    8'h74: sbox = 8'h92;
    8'h75: sbox = 8'h9d;
    8'h76: sbox = 8'h38;
    8'h77: sbox = 8'hf5;
    8'h78: sbox = 8'hbc;
    8'h79: sbox = 8'hb6;
    8'h7a: sbox = 8'hda;
    8'h7b: sbox = 8'h21;
    8'h7c: sbox = 8'h10;
    8'h7d: sbox = 8'hff;
    8'h7e: sbox = 8'hf3;
    8'h7f: sbox = 8'hd2;
    8'h80: sbox = 8'hcd;
    8'h81: sbox = 8'h0c;
    8'h82: sbox = 8'h13;
    8'h83: sbox = 8'hec;
    8'h84: sbox = 8'h5f;
    8'h85: sbox = 8'h97;
    8'h86: sbox = 8'h44;
    8'h87: sbox = 8'h17;
    8'h88: sbox = 8'hc4;
    8'h89: sbox = 8'ha7;
    8'h8a: sbox = 8'h7e;
    8'h8b: sbox = 8'h3d;
    8'h8c: sbox = 8'h64;
    8'h8d: sbox = 8'h5d;
    8'h8e: sbox = 8'h19;
    8'h8f: sbox = 8'h73;
    8'h90: sbox = 8'h60;
    8'h91: sbox = 8'h81;
    8'h92: sbox = 8'h4f;
    8'h93: sbox = 8'hdc;
    8'h94: sbox = 8'h22;
    8'h95: sbox = 8'h2a;
    8'h96: sbox = 8'h90;
    8'h97: sbox = 8'h88;
    8'h98: sbox = 8'h46;
    8'h99: sbox = 8'hee;
    8'h9a: sbox = 8'hb8;
    8'h9b: sbox = 8'h14;
    8'h9c: sbox = 8'hde;
    8'h9d: sbox = 8'h5e;
    8'h9e: sbox = 8'h0b;
    8'h9f: sbox = 8'hdb;
    8'ha0: sbox = 8'he0;
    8'ha1: sbox = 8'h32;
    8'ha2: sbox = 8'h3a;
    8'ha3: sbox = 8'h0a;
    8'ha4: sbox = 8'h49;
    8'ha5: sbox = 8'h06;
    8'ha6: sbox = 8'h24;
    8'ha7: sbox = 8'h5c;
    8'ha8: sbox = 8'hc2;
    8'ha9: sbox = 8'hd3;
    8'haa: sbox = 8'hac;
    8'hab: sbox = 8'h62;
    8'hac: sbox = 8'h91;
    8'had: sbox = 8'h95;
    8'hae: sbox = 8'he4;
    8'haf: sbox = 8'h79;
    8'hb0: sbox = 8'he7;
    8'hb1: sbox = 8'hc8;
    8'hb2: sbox = 8'h37;
    8'hb3: sbox = 8'h6d;
    8'hb4: sbox = 8'h8d;
    8'hb5: sbox = 8'hd5;
    8'hb6: sbox = 8'h4e;
    8'hb7: sbox = 8'ha9;
    8'hb8: sbox = 8'h6c;
    8'hb9: sbox = 8'h56;
    8'hba: sbox = 8'hf4;
    8'hbb: sbox = 8'hea;
    8'hbc: sbox = 8'h65;
    8'hbd: sbox = 8'h7a;
    8'hbe: sbox = 8'hae;
    8'hbf: sbox = 8'h08;
    8'hc0: sbox = 8'hba;
    8'hc1: sbox = 8'h78;
    8'hc2: sbox = 8'h25;
    8'hc3: sbox = 8'h2e;
    8'hc4: sbox = 8'h1c;
    8'hc5: sbox = 8'ha6;
    8'hc6: sbox = 8'hb4;
    8'hc7: sbox = 8'hc6;
    8'hc8: sbox = 8'he8;
    8'hc9: sbox = 8'hdd;
    8'hca: sbox = 8'h74;
    8'hcb: sbox = 8'h1f;
    8'hcc: sbox = 8'h4b;
    8'hcd: sbox = 8'hbd;
    8'hce: sbox = 8'h8b;
    8'hcf: sbox = 8'h8a;
    8'hd0: sbox = 8'h70;
    8'hd1: sbox = 8'h3e;
    8'hd2: sbox = 8'hb5;
    8'hd3: sbox = 8'h66;
    8'hd4: sbox = 8'h48;
    8'hd5: sbox = 8'h03;
    8'hd6: sbox = 8'hf6;
    8'hd7: sbox = 8'h0e;
    8'hd8: sbox = 8'h61;
    8'hd9: sbox = 8'h35;
    8'hda: sbox = 8'h57;
    8'hdb: sbox = 8'hb9;
    8'hdc: sbox = 8'h86;
    8'hdd: sbox = 8'hc1;
    8'hde: sbox = 8'h1d;
    8'hdf: sbox = 8'h9e;
    8'he0: sbox = 8'he1;
    8'he1: sbox = 8'hf8;
    8'he2: sbox = 8'h98;
    8'he3: sbox = 8'h11;
    8'he4: sbox = 8'h69;
    8'he5: sbox = 8'hd9;
    8'he6: sbox = 8'h8e;
    8'he7: sbox = 8'h94;
    8'he8: sbox = 8'h9b;
    8'he9: sbox = 8'h1e;
    8'hea: sbox = 8'h87;
    8'heb: sbox = 8'he9;
    8'hec: sbox = 8'hce;
    8'hed: sbox = 8'h55;
    8'hee: sbox = 8'h28;
    8'hef: sbox = 8'hdf;
    8'hf0: sbox = 8'h8c;
    8'hf1: sbox = 8'ha1;
    8'hf2: sbox = 8'h89;
    8'hf3: sbox = 8'h0d;
    8'hf4: sbox = 8'hbf;
    8'hf5: sbox = 8'he6;
    8'hf6: sbox = 8'h42;
    8'hf7: sbox = 8'h68;
    8'hf8: sbox = 8'h41;
    8'hf9: sbox = 8'h99;
    8'hfa: sbox = 8'h2d;
    8'hfb: sbox = 8'h0f;
    8'hfc: sbox = 8'hb0;
    8'hfd: sbox = 8'h54;
    8'hfe: sbox = 8'hbb;
    8'hff: sbox = 8'h16;       
endcase
end
endfunction
endmodule
