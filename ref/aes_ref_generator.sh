#!/usr/bin/env bash
# This reference Bash Script was made using an llm(claude) to go with my aes_ref.c code in order to validate many test ve
set -euo pipefail

SRC="aes_ref.c"
BIN="./aes_ref"

gcc -O2 -Wall -o "$BIN" "$SRC"
echo "Compiled OK"
echo "---"

# Format: "plaintext key expected_ct"
# Words separated by _ within each argument
VECTORS=(
    "3243f6a8_885a308d_313198a2_e0370734 2b7e1516_28aed2a6_abf71588_09cf4f3c 3925841d02dc09fbdc118597196a0b32"
    "6bc1bee2_2e409f96_e93d7e11_7393172a 2b7e1516_28aed2a6_abf71588_09cf4f3c 3ad77bb40d7a3660a89ecaf32466ef97"
    "ae2d8a57_1e03ac9c_9eb76fac_45af8e51 2b7e1516_28aed2a6_abf71588_09cf4f3c f5d3d58503b9699de785895a96fdbaaf"
    "30c81c46_a35ce411_e5fbc119_1a0a52ef 2b7e1516_28aed2a6_abf71588_09cf4f3c 43b1cd7f598ece23881b00e3ed030688"
    "f69f2445_df4f9b17_ad2b417b_e66c3710 2b7e1516_28aed2a6_abf71588_09cf4f3c 7b0c785e27e8ad3f8223207104725dd4"
)

PASS=0
FAIL=0

for vec in "${VECTORS[@]}"; do
    read -r pt key expected <<< "$vec"

    got=$("$BIN" enc "$pt" "$key")

    if [[ "$got" == "$expected" ]]; then
        echo "PASS: $pt -> $got"
        PASS=$((PASS+1))
    else
        echo "FAIL: $pt"
        echo "  Expected: $expected"
        echo "  Got:      $got"
        FAIL=$((FAIL+1))
    fi
done

echo "---"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1