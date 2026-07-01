# AES-128 (Encrypt / InvCipher / EqInvCipher) — Iterative RTL Core

Iterative (non-pipelined) AES-128 implementation in Verilog, covering the
forward cipher, the straight inverse cipher, and the equivalent inverse
cipher (EqInvCipher), plus combined wrapper modules that mux between
encrypt/decrypt on a shared interface.

## Repo Structure

```
src/
  aes_encrypt_iterative.v   - AES-128 forward cipher
  aes_decrypt_iterative.v   - AES-128 InvCipher (straight inverse)
  aes_eqdec_iterative.v     - AES-128 EqInvCipher (equivalent inverse)
  aes_combined_inv.v        - encrypt + InvCipher, muxed on `mode`
  aes_combined_eqinv.v      - encrypt + EqInvCipher, muxed on `mode`
test/
  test_*_fxn.v               - unit tests for individual transform functions
                                (SBox, ShiftRows, MixColumns, InvShiftRows,
                                InvMixColumns)
  test_*_exaustive.v         - exhaustive/vector-driven tests per cipher path
  test_combined_inv.v
  test_combined_eqinv.v
ref/
  aes_ref.c                  - C golden model (FIPS 197 reference)
  aes_ref_generator.sh        - sanity check against published NIST vectors
  gen_aes_vectors_enc.sh      - generates randomized encrypt test vectors
  gen_aes_vector_dec.sh       - generates randomized decrypt test vectors
```

## Architecture

All three cipher modules share the same iterative FSM shape: a 3-state
machine (`SETUP` → `{ENCRYPT|DECRYPT}` → `UPDATE`) built around a 4-bit
round counter, with `ROUNDS = 10` for AES-128. One round is processed per
clock cycle through the main loop, with one cycle for setup and one for
output update.

- `state` / `nextstate`: 128-bit cipher state register (column-major).
- Key handling: `aes_encrypt_iterative` carries a 128-bit `key_arr` /
  `nextkey_arr` pair; `aes_decrypt_iterative` and `aes_eqdec_iterative`
  carry a full 1280-bit `key_schedule` / `nextkey_schedule` (all 11 round
  keys), since the inverse paths need the schedule available out of
  round-order.
- `busy`: asserted while a cipher operation is in flight.
- `reset`: active-low, asynchronous assert / synchronous deassert.
- `enable`: active-high.

`aes_combined_inv` and `aes_combined_eqinv` instantiate the encrypt core
alongside the respective decrypt core in parallel and mux the output on
`mode` (the unused path's result is simply discarded each cycle — this
trades area for a fixed, simple interface rather than time-sharing a
single datapath).

### Design notes (from project decisions log)

- **Encrypt path** uses a `case`-statement implementation by design choice
  for clarity/readability over a generate-loop approach, targeting under
  12 clock cycles for a full encrypt. Because AES-128's key schedule is
  generated and consumed a round at a time, the encrypt core does not need
  to materialize the full 1280-bit schedule up front — only the current
  128-bit round key.
- **Decrypt path (InvCipher)** implements the GF(2^8) `xtimes` chain as
  explicit `xtimes_4`/`xtimes_2` helper functions for InvMixColumns,
  combined into a single `case` statement that computes the result in one
  step. Note: the naming is intentionally not pedantically accurate —
  `xtimes_4` is `xtimes(xtimes(xtimes(a)))` (×8 in GF terms by repeated
  doubling, used as part of the ×14/×11/×13/×9 InvMixColumns
  coefficients) and `xtimes_2` is `xtimes(xtimes(b))`; the names describe
  the call depth, not the GF multiplier value.
- **EqInvCipher path** introduces a third intermediate register to hold
  the last 32 bits of the relevant key-schedule word *before* it goes
  through InvMixColumns, since the equivalent inverse cipher needs that
  pre-transform value available separately from the transformed round key
  used elsewhere in the round.

## Verification

- Golden model: `aes_ref.c`, a standalone C implementation of FIPS 197
  AES-128 (encrypt + decrypt), used as the source of truth for all RTL
  validation.
- Vector generation: bash scripts around `aes_ref.c` generate ~2000
  randomized plaintext/key/ciphertext (and decrypt-direction) vectors into
  CSV form, in addition to the published FIPS 197 example vectors.
- RTL is exercised against these CSVs with self-checking testbenches
  (`test_*_exaustive.v`) per cipher direction, plus standalone function
  tests for SBox/InvSBox, ShiftRows/InvShiftRows, and MixColumns/
  InvMixColumns in isolation.
- **Bug found during validation:** the official FIPS 197 test vectors
  passed cleanly on first pass, but `InvCipher`/`EqInvCipher` failed
  roughly half of the randomized vectors — traced to a single incorrect
  entry in the InvSBox table. The official vectors happened not to
  exercise that table index; random inputs did, at roughly 50/50 odds per
  vector given the byte distribution.

All current cipher paths pass the full ~2000-vector regression against the
C golden model.

## Synthesis

Targeted at Xilinx 7-series (Basys3, Artix-7 XC7A35T) via Vivado, and
previously brought up on Lattice iCE40UP5K (VSDSquadron FM) via the
open-source Yosys/nextpnr flow before moving to Basys3 due to LUT/BRAM
constraints on the iCE40 part.

- SBox/InvSBox lookup tables synthesize as inferred ROM (`RTL_ROM30` in
  Vivado's elaboration view) rather than expanding into combinational
  logic, when targeting a part with adequate block RAM.
- No DSP usage expected — AES has no multiply/MAC operations; MixColumns/
  InvMixColumns GF(2^8) multiplication by fixed constants resolves to
  XOR/shift logic.

GDS2 hardening via OpenLane/Sky130 — results and findings to follow below.

## AI Use Disclosure

The RTL (cipher modules, FSMs, function implementations) and the C golden
model are hand-written. AI (Claude) was used to generate the bash tooling
scripts in `ref/` (`aes_ref_generator.sh`, `gen_aes_vectors_enc.sh`,
`gen_aes_vector_dec.sh`) that compile `aes_ref.c` and drive randomized
vector generation into CSV form for regression testing — not for the
core design or verification logic itself. This README was also drafted
with AI assistance, based on the project's actual source files and a
design-decisions log written by the author.

---

## GDS2 / OpenLane Results

*(to be added)*
