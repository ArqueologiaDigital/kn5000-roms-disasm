# Wave 3a T1 fix round: probes (2026-10-02)

The tools behind TOOLCHAIN_VERSION UPDATE 18: what the V1 verifier panel used to find
the defects of stage T1, and what verified each fix.  Most were written by the panel's
ENCODING-TRUTH verifier (V1a) and CERTIFICATION verifier (V1c) in
`~/compartilhado/disasm-lanes/wave3a-scratch/verify-V1{a,c}/` and are promoted here
with their scratch paths replaced: outputs go to `$OUTDIR` (default
`$TMPDIR/wave3a-fixround-out`), never into this tree.

Every script decodes with MAME's unidasm (`~/compartilhado/tools/unidasm`, the
reference for what bytes MEAN) and picks the build under test with `MC=` / `OBJDUMP=`
(default `~/compartilhado/llvm-project/build/bin`).  Quote the binary's sha256 with any
figure (TOOLCHAIN_VERSION "NAME THE BINARY").

| script | question it answers | command |
|---|---|---|
| `v1a_sweep.py` | Over the WHOLE register / mode / displacement / sub-opcode field of each family T1 touched (`direct`, `autoinc`, `disp`, `disp16full`, `sri`, `muldiv`, `erp`, `ei`), does llvm's decoder print the operation and every operand MAME reads, and does the printed text re-assemble to the same bytes (ASYM)? | `python3 v1a_sweep.py direct autoinc disp sri muldiv erp ei` |
| `asm_sweep.py` | The ASSEMBLER side: for every MC def and InstAlias (from `llvm-tblgen --dump-json`, `$RECORDS`), representative operand instances assembled alone and read by unidasm -- ENC_DB (bytes MAME calls db), ENC_LEN, MNEM / OPERAND (real mnemonics that disagree), REGSET (pseudos whose register names differ). | `RECORDS=... python3 asm_sweep.py` |
| `size_lies.py` | From `asm_sweep.tsv`: the defs whose written register names differ from MAME's ONLY IN WIDTH (`xbc` written, BC encoded) -- the class UPDATE 17 fixed for MUL/DIV and the direct-address pseudos. | `python3 size_lies.py` (after asm_sweep) |
| `pseudo_ops.py` | Pseudo mnemonics whose bytes are a different OPERATION than their name (`incdd8` = ld, `sla_erpw` = add).  Heuristic name->operation map, and raw-operand pseudos are probed with out-of-range values too, so read `../out/pseudo_ops_baseline.txt` for what is a known false positive. | `python3 pseudo_ops.py` |
| `lying_pseudo_check.py` | The regression check the panel asked for: runs asm_sweep + size_lies + pseudo_ops and fails if a def is flagged that is not in `../out/size_lies_baseline.txt` (EMPTY) or `../out/pseudo_ops_baseline.txt` (known false positives, each explained there). | `RECORDS=... python3 lying_pseudo_check.py` |
| `sp_asm_check.py` | With SP accepted where a GR16 operand is expected (6836c2807026), does every def / alias with a GR16 operand encode SP where MAME reads SP?  `REG=sp` and `REG=wa` give twin runs over the same operand instances, so a defect of SP alone shows as good-with-WA, bad-with-SP. | `REG=sp python3 sp_asm_check.py; REG=wa python3 sp_asm_check.py` |
| `per_commit_gate.sh` | Does the tree AT a given disasm commit rebuild byte-identically with a given llvm-mc?  (Is a commit's `LLVM:` trailer the binary its own tree builds with?)  `git archive` into a slot, `make LLVM_MC=<bin> gate-all`.  Signal: `EXIT=0` and two `PASS: every rebuilt ROM is byte-identical.` | `per_commit_gate.sh <slotdir> <commit> <llvm-mc> [label]` |

`../two_decoder_sweep.py --all-reg-fields` (T1's sweep, extended in the fix round)
repeats its register rows for every register field 0..7 -- T1's figures used field 1
only, which could not see a defect of one register (SP, field 7).

`scripts/analysis/check_encoding_examples.py` (tree root) checks every
`text` -> `bytes` example in CLAUDE.md's encoding-quirks section.

The records.json the assembler sweeps read:

    LLVM=~/compartilhado/llvm-project
    $LLVM/build/bin/llvm-tblgen --dump-json -I $LLVM/llvm/include \
        -I $LLVM/llvm/lib/Target/TLCS900 $LLVM/llvm/lib/Target/TLCS900/TLCS900.td \
        -o $TMPDIR/records.json        # 25 MB, regenerable, not committed

The figures each one produced at the fix-round pin are in TOOLCHAIN_VERSION UPDATE 18
and `../out/*_<commit>.txt`.
