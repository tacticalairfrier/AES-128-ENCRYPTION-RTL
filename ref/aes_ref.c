#include<stdio.h>
#include<stdint.h>
#include<stdlib.h>
#include<string.h>
//mathermatical definitions for aes
#define NB 4 //number of bytes in a column
#define NK 4 // number of 32 bit or 4 byte words in the key i.e the key is 16 bytes long
#define NR 10 //number of rounds is 10 for aes128
//declaring all function prototypes here
uint8_t xtimes(uint8_t num);
void subbytes(uint8_t* state);
void invsubbytes(uint8_t* state);
void shiftrows(uint8_t* state);
void invshiftrows(uint8_t* state);
void mixcolumns(uint8_t* state);
void invmixcolumns(uint8_t* state);
void swap(uint8_t* a, uint8_t* b);
void addroundkey(uint8_t* state, uint32_t* w);
void keyexpansion(uint32_t key[4], uint32_t* w);
void keyexpansioneic(uint32_t key[4], uint32_t* dw);
void cipher(uint32_t* in, uint32_t* out, uint32_t* w);
void invcipher(uint32_t* in, uint32_t* out, uint32_t* w);
void eqinvcipher(uint32_t* in, uint32_t* out, uint32_t* dw);
uint32_t rotword(uint32_t word);
uint32_t subword(uint32_t word);
//this is the reference c program/code for the aes128 encryption algorithm
//take uint8_t[16] instead of uint8_t[4][4] as it is easier to compute and easier to optimise?
//defining the s-box here
static uint8_t sbox[16][16] = {
    {0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76},
    {0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0},
    {0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15},
    {0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75},
    {0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84},
    {0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf},
    {0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8},
    {0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2},
    {0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73},
    {0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb},
    {0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79},
    {0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08},
    {0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a},
    {0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e},
    {0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf},
    {0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16},
};
//defining the inverse s-box here
static uint8_t invsbox[16][16] = {
    {0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb},
    {0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb},
    {0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e},
    {0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25},
    {0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92},
    {0x6c, 0x70	,0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84},
    {0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06},
    {0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b},
    {0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73},
    {0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e},
    {0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b},
    {0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4},
    {0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f},
    {0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef},
    {0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61},
    {0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d},
};
//rcon look up table
static uint32_t rcon[10] = { 0x01000000, 0x02000000, 0x04000000, 0x08000000, 0x10000000, 0x20000000, 0x40000000, 0x80000000, 0x1b000000, 0x36000000 };
//implementation of the xtimes function
void cipher(uint32_t* in, uint32_t* out, uint32_t* w) {
    uint8_t state[16];
    for (int i = 0;i < 4; i++) {
        state[4 * i] = in[i] >> 24;
        state[4 * i + 1] = in[i] >> 16;
        state[4 * i + 2] = in[i] >> 8;
        state[4 * i + 3] = in[i];
    }
    addroundkey(state, w);
    for (int i = 1; i <= NR - 1; i++) {
        subbytes(state);
        shiftrows(state);
        mixcolumns(state);
        addroundkey(state, w + i * 4);
    }
    subbytes(state);
    shiftrows(state);
    addroundkey(state, w + NR * 4);
    for (int i = 0; i < 4;i++) {
        out[i] = state[4 * i] << 24 | state[4 * i + 1] << 16 | state[4 * i + 2] << 8 | state[4 * i + 3];
    }
}
void invcipher(uint32_t* in, uint32_t* out, uint32_t* w) {
    uint8_t state[16];
    for (int i = 0;i < 4; i++) {
        state[4 * i] = in[i] >> 24;
        state[4 * i + 1] = in[i] >> 16;
        state[4 * i + 2] = in[i] >> 8;
        state[4 * i + 3] = in[i];
    }
    addroundkey(state, w + 4 * NR);
    for (int i = NR - 1; i >= 1; i--) {
        invsubbytes(state);
        invshiftrows(state);
        addroundkey(state, w + i * 4);
        invmixcolumns(state);
    }
    invsubbytes(state);
    invshiftrows(state);
    addroundkey(state, w);
    for (int i = 0; i < 4;i++) {
        out[i] = state[4 * i] << 24 | state[4 * i + 1] << 16 | state[4 * i + 2] << 8 | state[4 * i + 3];
    }
}
//the eqinvcipher here
void eqinvcipher(uint32_t* in, uint32_t* out, uint32_t* dw) {
    uint8_t state[16];
    for (int i = 0;i < 4; i++) {
        state[4 * i] = in[i] >> 24;
        state[4 * i + 1] = in[i] >> 16;
        state[4 * i + 2] = in[i] >> 8;
        state[4 * i + 3] = in[i];
    }
    addroundkey(state, dw + 4 * NR);
    for (int i = NR - 1; i >= 1; i--) {
        invsubbytes(state);
        invshiftrows(state);
        invmixcolumns(state);
        addroundkey(state, dw + i * 4);
    }
    invsubbytes(state);
    invshiftrows(state);
    addroundkey(state, dw);
    for (int i = 0; i < 4;i++) {
        out[i] = state[4 * i] << 24 | state[4 * i + 1] << 16 | state[4 * i + 2] << 8 | state[4 * i + 3];
    }
}
uint8_t xtimes(uint8_t num) {
    return (num & 0x80) ? ((num << 1) ^ 0x1b) : (num << 1);
}

//implementation of the subbytes or substitute bytes function
void subbytes(uint8_t* state) {
    for (int i = 0; i < 16; i++) {
        state[i] = sbox[((state[i] & 0xf0) / 0x10)][state[i] & 0x0f];
    }
}
//inverse subbytes using the invsbox lut
void invsubbytes(uint8_t* state) {
    for (int i = 0; i < 16; i++) {
        state[i] = invsbox[((state[i] & 0xf0) / 0x10)][state[i] & 0x0f];
    }
}
//shiftrows
void shiftrows(uint8_t* state) {
    //row 0 doesnt have any swappings
    //swappings for the row 1
    swap(&state[1], &state[13]);
    swap(&state[1], &state[5]);
    swap(&state[5], &state[9]);
    //swappings for the row 2
    swap(&state[2], &state[10]);
    swap(&state[6], &state[14]);
    //swappings for the row 3
    swap(&state[3], &state[7]);
    swap(&state[3], &state[11]);
    swap(&state[3], &state[15]);
}
//invshiftrows
void invshiftrows(uint8_t* state) {
    //row 0 doesnt have any swappings
    //swappings for the row 1
    swap(&state[1], &state[13]);
    swap(&state[9], &state[13]);
    swap(&state[5], &state[9]);
    //swappings for row 2
    swap(&state[2], &state[10]);
    swap(&state[6], &state[14]);
    //swappings for row 3
    swap(&state[3], &state[7]);
    swap(&state[7], &state[11]);
    swap(&state[11], &state[15]);
}
//implementing the mixcolumns function
void mixcolumns(uint8_t* state) {
    uint8_t b0, b1, b2, b3;
    for (int i = 0; i < 4; i++) {
        //copying over the current state in a temporary register
        b0 = state[4 * i];
        b1 = state[4 * i + 1];
        b2 = state[4 * i + 2];
        b3 = state[4 * i + 3];
        //multiplying according to the matrix
        state[4 * i] = xtimes(b0) ^ (xtimes(b1) ^ b1) ^ b2 ^ b3;
        state[4 * i + 1] = b0 ^ xtimes(b1) ^ (xtimes(b2) ^ b2) ^ b3;
        state[4 * i + 2] = b0 ^ b1 ^ xtimes(b2) ^ (xtimes(b3) ^ b3);
        state[4 * i + 3] = (xtimes(b0) ^ b0) ^ b1 ^ b2 ^ xtimes(b3);
    }
}

//inverse of mixcolumns
void invmixcolumns(uint8_t* state) {
    uint8_t b0, b1, b2, b3;
    for (int i = 0;i < 4;i++) {
        b0 = state[4 * i];
        b1 = state[4 * i + 1];
        b2 = state[4 * i + 2];
        b3 = state[4 * i + 3];
        state[4 * i] = xtimes(xtimes(xtimes(b0))) ^ xtimes(xtimes(b0)) ^ xtimes(b0) ^ xtimes(xtimes(xtimes(b1))) ^ xtimes(b1) ^ b1 ^ xtimes(xtimes(xtimes(b2))) ^ xtimes(xtimes(b2)) ^ b2 ^ xtimes(xtimes(xtimes(b3))) ^ b3;
        state[4 * i + 1] = xtimes(xtimes(xtimes(b0))) ^ b0 ^ xtimes(xtimes(xtimes(b1))) ^ xtimes(xtimes(b1)) ^ xtimes(b1) ^ xtimes(xtimes(xtimes(b2))) ^ xtimes(b2) ^ b2 ^ xtimes(xtimes(xtimes(b3))) ^ xtimes(xtimes(b3)) ^ b3;
        state[4 * i + 2] = xtimes(xtimes(xtimes(b0))) ^ xtimes(xtimes(b0)) ^ b0 ^ xtimes(xtimes(xtimes(b1))) ^ b1 ^ xtimes(xtimes(xtimes(b2))) ^ xtimes(xtimes(b2)) ^ xtimes(b2) ^ xtimes(xtimes(xtimes(b3))) ^ xtimes(b3) ^ b3;
        state[4 * i + 3] = xtimes(xtimes(xtimes(b0))) ^ xtimes(b0) ^ b0 ^ xtimes(xtimes(xtimes(b1))) ^ xtimes(xtimes(b1)) ^ b1 ^ xtimes(xtimes(xtimes(b2))) ^ b2 ^ xtimes(xtimes(xtimes(b3))) ^ xtimes(xtimes(b3)) ^ xtimes(b3);
    }
}

//implementing the swap function
void swap(uint8_t* a, uint8_t* b) {
    uint8_t temp;
    temp = *a;
    *a = *b;
    *b = temp;
}

//making the addroundkey function here
void addroundkey(uint8_t* state, uint32_t* w) {
    for (int i = 0;i < 4;i++) {
        state[4 * i] ^= w[i] >> 24;
        state[4 * i + 1] ^= w[i] >> 16;
        state[4 * i + 2] ^= w[i] >> 8;
        state[4 * i + 3] ^= w[i];
    }
}

//keyexpansion
void keyexpansion(uint32_t key[4], uint32_t* w) {
    //first puttin all the initial key vals in w
    for (int i = 0; i < NK; i++) {
        w[i] = key[i];
    }
    //expanding with the second part
    for (int i = 4; i < 44; i++) {
        if (i % 4 == 0) {
            w[i] = subword(rotword(w[i - 1])) ^ rcon[i / NK - 1] ^ w[i - NK];
        }
        else {
            w[i] = w[i - NK] ^ w[i - 1];
        }
    }
}
//keyexpansion for eqinvcipher key schedule
void keyexpansioneic(uint32_t key[4], uint32_t* dw) {
    //first puttin all the initial key vals in w
    uint8_t dw_byte[16];
    for (int i = 0; i < NK; i++) {
        dw[i] = key[i];
    }
    //expanding with the second part
    for (int i = 4; i < 44; i++) {
        if (i % 4 == 0) {
            dw[i] = subword(rotword(dw[i - 1])) ^ rcon[i / NK - 1] ^ dw[i - NK];
        }
        else {
            dw[i] = dw[i - NK] ^ dw[i - 1];
        }
    }
    for (int i = 1;i < NR;i++) {
        for (int j = 0;j < 4;j++) {
            dw_byte[4 * j] = dw[4 * i + j] >> 24;
            dw_byte[4 * j + 1] = dw[4 * i + j] >> 16;
            dw_byte[4 * j + 2] = dw[4 * i + j] >> 8;
            dw_byte[4 * j + 3] = dw[4 * i + j];
        }
        invmixcolumns(dw_byte);
        for (int j = 0; j < 4;j++) {
            dw[4 * i + j] = (dw_byte[4 * j] << 24 | dw_byte[4 * j + 1] << 16 | dw_byte[4 * j + 2] << 8 | dw_byte[4 * j + 3]);
        }
    }
}
//rotword
uint32_t rotword(uint32_t word) {
    //lets take a thing i.e a collection of 4 8 bit int
    uint8_t word_8[4];
    word_8[0] = word;
    word_8[1] = word >> 8;
    word_8[2] = word >> 16;
    word_8[3] = word >> 24;
    swap(&word_8[0], &word_8[3]);
    swap(&word_8[2], &word_8[3]);
    swap(&word_8[1], &word_8[2]);
    word = (word_8[3] << 24 | word_8[2] << 16 | word_8[1] << 8 | word_8[0]);
    return word;
}

//subword
uint32_t subword(uint32_t word) {
    //lets take a thing i.e a collection of 4 8 bit int
    uint8_t word_8[4];
    word_8[0] = word;
    word_8[1] = word >> 8;
    word_8[2] = word >> 16;
    word_8[3] = word >> 24;
    for (int i = 0; i < 4; i++) {
        word_8[i] = sbox[((word_8[i] & 0xf0) / 0x10)][word_8[i] & 0x0f];
    }
    word = (word_8[3] << 24 | word_8[2] << 16 | word_8[1] << 8 | word_8[0]);
    return word;
}
int main(int argc, char* argv[]) {
    uint32_t in[4];
    uint32_t key[4];
    uint32_t out[3];
    uint32_t w[44], dw[44];
    char* endptr_pt;
    char* endptr_key;
    if (argc > 4) {
        fprintf(stderr, "ERR: too many arguments\n");
        return -1;
    }
    else if (argc < 4) {
        fprintf(stderr, "ERR: less arguments applied\n");
        return -2;
    }
    else {
        //parsing through the plaintext and key
        in[0] = strtoul(argv[2], &endptr_pt, 16);
        key[0] = strtoul(argv[3], &endptr_key, 16);
        for (int i = 1;i < 4;i++) {
            in[i] = strtoul(endptr_pt + 1, &endptr_pt, 16);
            key[i] = strtoul(endptr_key + 1, &endptr_key, 16);
        }
        keyexpansion(key, w);
        keyexpansioneic(key, dw);
        //enc for encryption using cipher fxn
        if (!strcmp(argv[1], "enc")) {
            cipher(in, out, w);
            for (int i = 0;i < 4;i++) {
                printf("%08x", out[i]);
            }
            printf("\n");
        }
        //dec for decryption using the inv fxn
        else if (!strcmp(argv[1], "dec")) {
            invcipher(in, out, w);
            for (int i = 0;i < 4;i++) {
                printf("%08x", out[i]);
            }
            printf("\n");
        }
        //eqdec for using the eqivalent decrypt fxn
        else if (!strcmp(argv[1], "eqdec")) {
            eqinvcipher(in, out, dw);
            for (int i = 0;i < 4;i++) {
                printf("%08x", out[i]);
            }
            printf("\n");
        }
        else {
            //if unc doesnt even know the basic commands how lame lmao
            fprintf(stderr, "ERR: not the correct command\nenter only\n");
            fprintf(stderr, "enc for encryption\ndec for decryption\neqdec for equivalent decryption\n");
        }
    }
    return 0;
}