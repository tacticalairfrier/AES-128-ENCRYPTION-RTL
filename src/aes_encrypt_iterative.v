`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module aes_encrypt_iterative(
    input wire [127:0] in, key,
    //reset is active low, enable is active high
    input wire clkin, reset, enable,
    output reg [127:0] out ,
    output reg busy
);
//comments for linter
/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off CASEINCOMPLETE */
/* verilator lint_off WIDTHEXPAND */
//since this is aes 128, the rounds are 10
localparam ROUNDS = 4'd10;
localparam SETUP = 2'b00, ENCRYPT = 2'b01, UPDATE = 2'b10;
//setup is sort of like idle situation and the thing is important
//encrypt is the main cycle and will consume 10 clock cycles
//update updates all setup values i.e updates the out
//making state a a 16 byte wide register no make it 128 bits wide
reg [127:0] state, nextstate, key_arr, nextkey_arr;
//the functions are supposed to be the same
reg [3:0] roundcounter; 
reg [1:0] state_fsm, nextstate_fsm;
//this guy stores the sbox
wire [7:0] sbox_lut [0:255];
wire [7:0] rcon_lut [1:10];
//here state fsm is the state for the fsm which is a 2 bit counter
always@(posedge clkin, negedge reset)begin
    if(!reset)begin
        roundcounter <= ROUNDS;
        state_fsm <= SETUP;
        out<=128'h0;
        key_arr <= nextkey_arr;
        state <= nextstate; 
    end
    else begin
        key_arr<=nextkey_arr;
        state<=nextstate;
        state_fsm<=nextstate_fsm;
        case(state_fsm)
            SETUP:begin
                roundcounter <= ROUNDS;
            end
            ENCRYPT:begin
                roundcounter <= roundcounter-1;
            end
            UPDATE:begin
                roundcounter <= 4'h0;
                out <= state;
            end
        endcase
    end
end
//xtimes function is implemented this way in order to be cheaper on hardware
always@(*)begin
    nextstate_fsm = state_fsm;
    nextstate = state;
    nextkey_arr = key_arr;
    busy = `FALSE;
    if(!reset)begin
        nextstate_fsm = SETUP;
        nextstate = 128'h0;
        nextkey_arr = 128'h0;
    end
    else begin
        case(state_fsm)
            SETUP:begin
                if(enable)begin
                    nextstate_fsm = ENCRYPT;
                    nextstate = in;
                    nextkey_arr = key;
                    busy =`TRUE;
                end
                else begin
                    nextstate_fsm = SETUP;
                    busy = `FALSE;
                end 
            end
            //here busy is a mooore output as its only strobed in setup, when it enters
            //all the cipher action happens in the encrypt state instead of making a separate cipher fxn
            ENCRYPT:begin
                // {nextkey_arr[i],nextkey_arr[i+1],nextkey_arr[i+2],nextkey_arr[i+3]}
                ///key scheduling here
                busy =  `TRUE;
                //rotword is shiftrows at 1 th mode
                nextkey_arr[127:96] = shiftrows(key_arr[31:0], 1);
                //subword is as it is
                // nextkey_arr[127:96] =  subword(nextkey_arr[127:96]);
                nextkey_arr[127:96] = {sbox(nextkey_arr[127:120]), sbox(nextkey_arr[119:112]), sbox(nextkey_arr[111:104]), sbox(nextkey_arr[103:96])};
                //this is for rcon
                nextkey_arr[127:96] = nextkey_arr[127:96] ^ {rcon((ROUNDS-roundcounter)+4'h1), 24'h000000} ^ key_arr[127:96];
                //loop for the other 3 words
                nextkey_arr[95:64] = nextkey_arr[127:96] ^ key_arr[95:64];
                nextkey_arr[63:32] = nextkey_arr[95:64] ^ key_arr[63:32];
                nextkey_arr[31:0] = nextkey_arr[63:32] ^ key_arr[31:0];
                //key scheduling ends here
                if(roundcounter==ROUNDS)begin
                    //initial addroundkey
                    nextstate = key_arr^state;
                    nextstate_fsm = ENCRYPT;
                end
                else if(roundcounter>0)begin
                    nextstate = subword(state);
                    //shiftrows gonn be tough without the array appraoach
                    //not even calling shiftrows at 0
                    {nextstate[119:112], nextstate[87:80],nextstate[55:48],nextstate[23:16]} = shiftrows({nextstate[119:112], nextstate[87:80],nextstate[55:48],nextstate[23:16]},1);
                    {nextstate[111:104], nextstate[79:72],nextstate[47:40],nextstate[15:8]} = shiftrows({nextstate[111:104], nextstate[79:72],nextstate[47:40],nextstate[15:8]},2);
                    {nextstate[103:96], nextstate[71:64],nextstate[39:32],nextstate[7:0]} = shiftrows({nextstate[103:96], nextstate[71:64],nextstate[39:32],nextstate[7:0]} ,3);
                    //shiftrows ends 
                    //mixcolumns here
                    nextstate[127:96] = mixcolumns(nextstate[127:96]);
                    nextstate[95:64] = mixcolumns(nextstate[95:64]);
                    nextstate[63:32] = mixcolumns(nextstate[63:32]);
                    nextstate[31:0] = mixcolumns(nextstate[31:0]);
                    //mixcolumns ends
                    nextstate = key_arr^nextstate;
                    //addroundkey
                    nextstate_fsm = ENCRYPT;
                end
                else begin
                    nextstate = subword(state);
                    //shiftrows
                    {nextstate[119:112], nextstate[87:80],nextstate[55:48],nextstate[23:16]} = shiftrows({nextstate[119:112], nextstate[87:80],nextstate[55:48],nextstate[23:16]},1);
                    {nextstate[111:104], nextstate[79:72],nextstate[47:40],nextstate[15:8]} = shiftrows({nextstate[111:104], nextstate[79:72],nextstate[47:40],nextstate[15:8]},2);
                    {nextstate[103:96], nextstate[71:64],nextstate[39:32],nextstate[7:0]} = shiftrows({nextstate[103:96], nextstate[71:64],nextstate[39:32],nextstate[7:0]} ,3);
                    //addroundkey
                    nextstate = key_arr^nextstate;
                    nextstate_fsm = UPDATE;
                end
            end
            UPDATE: begin
                nextstate_fsm = SETUP;
                busy = `TRUE;
            end
        endcase
    end      
end
function [7:0]xtimes(
    input [7:0] num
);
    xtimes = (num[7])?((num<<1)^8'h1b):(num<<1);
endfunction
//function for shiftrows
function[31:0]shiftrows(
    input[31:0] row,
    input integer i_sr
);
begin
    case(i_sr)
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
            shiftrows[7:0] = row[15:8];
        end
        default:begin
            shiftrows = row;
        end
    endcase 
end
endfunction
//function for mixcolumns;
function [31:0] mixcolumns(
    input [31:0] column
);
begin
    reg[7:0]temp[0:3];
    reg[7:0]temp_column[0:3];
    temp[0] = xtimes(column[31:24]);
    temp[1] = xtimes(column[23:16]);
    temp[2] = xtimes(column[15:8]);
    temp[3] = xtimes(column[7:0]);
    temp_column[0] = column[31:24];
    temp_column[1] = column[23:16];
    temp_column[2] = column[15:8];
    temp_column[3] = column[7:0];
    //now the assignment of the mixcolumns output
    //31-0 is hte range for b-0 through b-4 and on
    //2311
    mixcolumns[31:24] = temp[0]^temp[1]^temp_column[1]^temp_column[2]^temp_column[3];
    //1231
    mixcolumns[23:16] = temp_column[0]^temp[1]^temp[2]^temp_column[2]^temp_column[3];
    //1123
    mixcolumns[15:8] = temp_column[0]^temp_column[1]^temp[2]^temp[3]^temp_column[3];
    //3112
    mixcolumns[7:0] = temp_column[0]^temp[0]^temp_column[1]^temp_column[2]^temp[3];
end
endfunction
//since everyone is 32 bytes wide, for simplicities sake subword is also 32 bit wide
//subbytes will be 128 widee cos why the hell not and ill need to call subword once onlu
function [127:0] subword(
    input [127:0] word
);
    begin
        integer j;
        for(j=0;j<16;j=j+1)begin
            //this is reverse order but who cares
            subword[(j*8)+:8] = sbox(word[(j*8)+:8]);
        end
        // subword[31:24] = sbox(word[31:24]);
        // subword[23:16] = sbox(word[23:16]);
        // subword[15:8] = sbox(word[15:8]);
        // subword[7:0] = sbox(word[7:0]);
    end
endfunction
//all the look up tables below this
//sbox function for subbytes
function [7:0]sbox(
    input [7:0] inbyte
);//behold the fruits of my manual labour
begin
    sbox = sbox_lut[inbyte];
end
endfunction
//look up table for the round constant
//use the concat operator here //{output of rcon, 24'h0000000}
function [7:0] rcon(
    input [7:0] round_val
);
begin
    rcon = rcon_lut[round_val];
end
endfunction
//assign block for sbox look up table
assign sbox_lut[8'h00] = 8'h63;
assign sbox_lut[8'h01] = 8'h7c;
assign sbox_lut[8'h02] = 8'h77;
assign sbox_lut[8'h03] = 8'h7b;
assign sbox_lut[8'h04] = 8'hf2;
assign sbox_lut[8'h05] = 8'h6b;
assign sbox_lut[8'h06] = 8'h6f;
assign sbox_lut[8'h07] = 8'hc5;
assign sbox_lut[8'h08] = 8'h30;
assign sbox_lut[8'h09] = 8'h01;
assign sbox_lut[8'h0a] = 8'h67;
assign sbox_lut[8'h0b] = 8'h2b;
assign sbox_lut[8'h0c] = 8'hfe;
assign sbox_lut[8'h0d] = 8'hd7;
assign sbox_lut[8'h0e] = 8'hab;
assign sbox_lut[8'h0f] = 8'h76;
assign sbox_lut[8'h10] = 8'hca;
assign sbox_lut[8'h11] = 8'h82;
assign sbox_lut[8'h12] = 8'hc9;
assign sbox_lut[8'h13] = 8'h7d;
assign sbox_lut[8'h14] = 8'hfa;
assign sbox_lut[8'h15] = 8'h59;
assign sbox_lut[8'h16] = 8'h47;
assign sbox_lut[8'h17] = 8'hf0;
assign sbox_lut[8'h18] = 8'had;
assign sbox_lut[8'h19] = 8'hd4;
assign sbox_lut[8'h1a] = 8'ha2;
assign sbox_lut[8'h1b] = 8'haf;
assign sbox_lut[8'h1c] = 8'h9c;
assign sbox_lut[8'h1d] = 8'ha4;
assign sbox_lut[8'h1e] = 8'h72;
assign sbox_lut[8'h1f] = 8'hc0;
assign sbox_lut[8'h20] = 8'hb7;
assign sbox_lut[8'h21] = 8'hfd;
assign sbox_lut[8'h22] = 8'h93;
assign sbox_lut[8'h23] = 8'h26;
assign sbox_lut[8'h24] = 8'h36;
assign sbox_lut[8'h25] = 8'h3f;
assign sbox_lut[8'h26] = 8'hf7;
assign sbox_lut[8'h27] = 8'hcc;
assign sbox_lut[8'h28] = 8'h34;
assign sbox_lut[8'h29] = 8'ha5;
assign sbox_lut[8'h2a] = 8'he5;
assign sbox_lut[8'h2b] = 8'hf1;
assign sbox_lut[8'h2c] = 8'h71;
assign sbox_lut[8'h2d] = 8'hd8;
assign sbox_lut[8'h2e] = 8'h31;
assign sbox_lut[8'h2f] = 8'h15;
assign sbox_lut[8'h30] = 8'h04;
assign sbox_lut[8'h31] = 8'hc7;
assign sbox_lut[8'h32] = 8'h23;
assign sbox_lut[8'h33] = 8'hc3;
assign sbox_lut[8'h34] = 8'h18;
assign sbox_lut[8'h35] = 8'h96;
assign sbox_lut[8'h36] = 8'h05;
assign sbox_lut[8'h37] = 8'h9a;
assign sbox_lut[8'h38] = 8'h07;
assign sbox_lut[8'h39] = 8'h12;
assign sbox_lut[8'h3a] = 8'h80;
assign sbox_lut[8'h3b] = 8'he2;
assign sbox_lut[8'h3c] = 8'heb;
assign sbox_lut[8'h3d] = 8'h27;
assign sbox_lut[8'h3e] = 8'hb2;
assign sbox_lut[8'h3f] = 8'h75;
assign sbox_lut[8'h40] = 8'h09;
assign sbox_lut[8'h41] = 8'h83;
assign sbox_lut[8'h42] = 8'h2c;
assign sbox_lut[8'h43] = 8'h1a;
assign sbox_lut[8'h44] = 8'h1b;
assign sbox_lut[8'h45] = 8'h6e;
assign sbox_lut[8'h46] = 8'h5a;
assign sbox_lut[8'h47] = 8'ha0;
assign sbox_lut[8'h48] = 8'h52;
assign sbox_lut[8'h49] = 8'h3b;
assign sbox_lut[8'h4a] = 8'hd6;
assign sbox_lut[8'h4b] = 8'hb3;
assign sbox_lut[8'h4c] = 8'h29;
assign sbox_lut[8'h4d] = 8'he3;
assign sbox_lut[8'h4e] = 8'h2f;
assign sbox_lut[8'h4f] = 8'h84;
assign sbox_lut[8'h50] = 8'h53;
assign sbox_lut[8'h51] = 8'hd1;
assign sbox_lut[8'h52] = 8'h00;
assign sbox_lut[8'h53] = 8'hed;
assign sbox_lut[8'h54] = 8'h20;
assign sbox_lut[8'h55] = 8'hfc;
assign sbox_lut[8'h56] = 8'hb1;
assign sbox_lut[8'h57] = 8'h5b;
assign sbox_lut[8'h58] = 8'h6a;
assign sbox_lut[8'h59] = 8'hcb;
assign sbox_lut[8'h5a] = 8'hbe;
assign sbox_lut[8'h5b] = 8'h39;
assign sbox_lut[8'h5c] = 8'h4a;
assign sbox_lut[8'h5d] = 8'h4c;
assign sbox_lut[8'h5e] = 8'h58;
assign sbox_lut[8'h5f] = 8'hcf;
assign sbox_lut[8'h60] = 8'hd0;
assign sbox_lut[8'h61] = 8'hef;
assign sbox_lut[8'h62] = 8'haa;
assign sbox_lut[8'h63] = 8'hfb;
assign sbox_lut[8'h64] = 8'h43;
assign sbox_lut[8'h65] = 8'h4d;
assign sbox_lut[8'h66] = 8'h33;
assign sbox_lut[8'h67] = 8'h85;
assign sbox_lut[8'h68] = 8'h45;
assign sbox_lut[8'h69] = 8'hf9;
assign sbox_lut[8'h6a] = 8'h02;
assign sbox_lut[8'h6b] = 8'h7f;
assign sbox_lut[8'h6c] = 8'h50;
assign sbox_lut[8'h6d] = 8'h3c;
assign sbox_lut[8'h6e] = 8'h9f;
assign sbox_lut[8'h6f] = 8'ha8;
assign sbox_lut[8'h70] = 8'h51;
assign sbox_lut[8'h71] = 8'ha3;
assign sbox_lut[8'h72] = 8'h40;
assign sbox_lut[8'h73] = 8'h8f;
assign sbox_lut[8'h74] = 8'h92;
assign sbox_lut[8'h75] = 8'h9d;
assign sbox_lut[8'h76] = 8'h38;
assign sbox_lut[8'h77] = 8'hf5;
assign sbox_lut[8'h78] = 8'hbc;
assign sbox_lut[8'h79] = 8'hb6;
assign sbox_lut[8'h7a] = 8'hda;
assign sbox_lut[8'h7b] = 8'h21;
assign sbox_lut[8'h7c] = 8'h10;
assign sbox_lut[8'h7d] = 8'hff;
assign sbox_lut[8'h7e] = 8'hf3;
assign sbox_lut[8'h7f] = 8'hd2;
assign sbox_lut[8'h80] = 8'hcd;
assign sbox_lut[8'h81] = 8'h0c;
assign sbox_lut[8'h82] = 8'h13;
assign sbox_lut[8'h83] = 8'hec;
assign sbox_lut[8'h84] = 8'h5f;
assign sbox_lut[8'h85] = 8'h97;
assign sbox_lut[8'h86] = 8'h44;
assign sbox_lut[8'h87] = 8'h17;
assign sbox_lut[8'h88] = 8'hc4;
assign sbox_lut[8'h89] = 8'ha7;
assign sbox_lut[8'h8a] = 8'h7e;
assign sbox_lut[8'h8b] = 8'h3d;
assign sbox_lut[8'h8c] = 8'h64;
assign sbox_lut[8'h8d] = 8'h5d;
assign sbox_lut[8'h8e] = 8'h19;
assign sbox_lut[8'h8f] = 8'h73;
assign sbox_lut[8'h90] = 8'h60;
assign sbox_lut[8'h91] = 8'h81;
assign sbox_lut[8'h92] = 8'h4f;
assign sbox_lut[8'h93] = 8'hdc;
assign sbox_lut[8'h94] = 8'h22;
assign sbox_lut[8'h95] = 8'h2a;
assign sbox_lut[8'h96] = 8'h90;
assign sbox_lut[8'h97] = 8'h88;
assign sbox_lut[8'h98] = 8'h46;
assign sbox_lut[8'h99] = 8'hee;
assign sbox_lut[8'h9a] = 8'hb8;
assign sbox_lut[8'h9b] = 8'h14;
assign sbox_lut[8'h9c] = 8'hde;
assign sbox_lut[8'h9d] = 8'h5e;
assign sbox_lut[8'h9e] = 8'h0b;
assign sbox_lut[8'h9f] = 8'hdb;
assign sbox_lut[8'ha0] = 8'he0;
assign sbox_lut[8'ha1] = 8'h32;
assign sbox_lut[8'ha2] = 8'h3a;
assign sbox_lut[8'ha3] = 8'h0a;
assign sbox_lut[8'ha4] = 8'h49;
assign sbox_lut[8'ha5] = 8'h06;
assign sbox_lut[8'ha6] = 8'h24;
assign sbox_lut[8'ha7] = 8'h5c;
assign sbox_lut[8'ha8] = 8'hc2;
assign sbox_lut[8'ha9] = 8'hd3;
assign sbox_lut[8'haa] = 8'hac;
assign sbox_lut[8'hab] = 8'h62;
assign sbox_lut[8'hac] = 8'h91;
assign sbox_lut[8'had] = 8'h95;
assign sbox_lut[8'hae] = 8'he4;
assign sbox_lut[8'haf] = 8'h79;
assign sbox_lut[8'hb0] = 8'he7;
assign sbox_lut[8'hb1] = 8'hc8;
assign sbox_lut[8'hb2] = 8'h37;
assign sbox_lut[8'hb3] = 8'h6d;
assign sbox_lut[8'hb4] = 8'h8d;
assign sbox_lut[8'hb5] = 8'hd5;
assign sbox_lut[8'hb6] = 8'h4e;
assign sbox_lut[8'hb7] = 8'ha9;
assign sbox_lut[8'hb8] = 8'h6c;
assign sbox_lut[8'hb9] = 8'h56;
assign sbox_lut[8'hba] = 8'hf4;
assign sbox_lut[8'hbb] = 8'hea;
assign sbox_lut[8'hbc] = 8'h65;
assign sbox_lut[8'hbd] = 8'h7a;
assign sbox_lut[8'hbe] = 8'hae;
assign sbox_lut[8'hbf] = 8'h08;
assign sbox_lut[8'hc0] = 8'hba;
assign sbox_lut[8'hc1] = 8'h78;
assign sbox_lut[8'hc2] = 8'h25;
assign sbox_lut[8'hc3] = 8'h2e;
assign sbox_lut[8'hc4] = 8'h1c;
assign sbox_lut[8'hc5] = 8'ha6;
assign sbox_lut[8'hc6] = 8'hb4;
assign sbox_lut[8'hc7] = 8'hc6;
assign sbox_lut[8'hc8] = 8'he8;
assign sbox_lut[8'hc9] = 8'hdd;
assign sbox_lut[8'hca] = 8'h74;
assign sbox_lut[8'hcb] = 8'h1f;
assign sbox_lut[8'hcc] = 8'h4b;
assign sbox_lut[8'hcd] = 8'hbd;
assign sbox_lut[8'hce] = 8'h8b;
assign sbox_lut[8'hcf] = 8'h8a;
assign sbox_lut[8'hd0] = 8'h70;
assign sbox_lut[8'hd1] = 8'h3e;
assign sbox_lut[8'hd2] = 8'hb5;
assign sbox_lut[8'hd3] = 8'h66;
assign sbox_lut[8'hd4] = 8'h48;
assign sbox_lut[8'hd5] = 8'h03;
assign sbox_lut[8'hd6] = 8'hf6;
assign sbox_lut[8'hd7] = 8'h0e;
assign sbox_lut[8'hd8] = 8'h61;
assign sbox_lut[8'hd9] = 8'h35;
assign sbox_lut[8'hda] = 8'h57;
assign sbox_lut[8'hdb] = 8'hb9;
assign sbox_lut[8'hdc] = 8'h86;
assign sbox_lut[8'hdd] = 8'hc1;
assign sbox_lut[8'hde] = 8'h1d;
assign sbox_lut[8'hdf] = 8'h9e;
assign sbox_lut[8'he0] = 8'he1;
assign sbox_lut[8'he1] = 8'hf8;
assign sbox_lut[8'he2] = 8'h98;
assign sbox_lut[8'he3] = 8'h11;
assign sbox_lut[8'he4] = 8'h69;
assign sbox_lut[8'he5] = 8'hd9;
assign sbox_lut[8'he6] = 8'h8e;
assign sbox_lut[8'he7] = 8'h94;
assign sbox_lut[8'he8] = 8'h9b;
assign sbox_lut[8'he9] = 8'h1e;
assign sbox_lut[8'hea] = 8'h87;
assign sbox_lut[8'heb] = 8'he9;
assign sbox_lut[8'hec] = 8'hce;
assign sbox_lut[8'hed] = 8'h55;
assign sbox_lut[8'hee] = 8'h28;
assign sbox_lut[8'hef] = 8'hdf;
assign sbox_lut[8'hf0] = 8'h8c;
assign sbox_lut[8'hf1] = 8'ha1;
assign sbox_lut[8'hf2] = 8'h89;
assign sbox_lut[8'hf3] = 8'h0d;
assign sbox_lut[8'hf4] = 8'hbf;
assign sbox_lut[8'hf5] = 8'he6;
assign sbox_lut[8'hf6] = 8'h42;
assign sbox_lut[8'hf7] = 8'h68;
assign sbox_lut[8'hf8] = 8'h41;
assign sbox_lut[8'hf9] = 8'h99;
assign sbox_lut[8'hfa] = 8'h2d;
assign sbox_lut[8'hfb] = 8'h0f;
assign sbox_lut[8'hfc] = 8'hb0;
assign sbox_lut[8'hfd] = 8'h54;
assign sbox_lut[8'hfe] = 8'hbb;
assign sbox_lut[8'hff] = 8'h16;
//assign block for rcon look up table
assign rcon_lut[1] = 8'h01;
assign rcon_lut[2] = 8'h02;
assign rcon_lut[3] = 8'h04;
assign rcon_lut[4] = 8'h08;
assign rcon_lut[5] = 8'h10;
assign rcon_lut[6] = 8'h20;
assign rcon_lut[7] = 8'h40;
assign rcon_lut[8] = 8'h80;
assign rcon_lut[9] = 8'h1b;
assign rcon_lut[10] = 8'h36;
endmodule
