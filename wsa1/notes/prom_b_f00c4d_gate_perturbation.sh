#!/bin/bash
# Would the byte gate NOTICE if 0xF00C4D-0xF017FF were converted wrongly?
#
# QUESTION IT ANSWERS
#   `make gate-wsa1` is green after notes/gen_prom_b_f00c4d_module.py --apply.
#   A green gate proves nothing unless it has been SHOWN to go red on this
#   particular edit -- an object built from a stale prerequisite certifies
#   nothing, and this tree has been burned by exactly that.
#
#   So: flip one byte in EACH of the four sub-regions the module emits, one at a
#   time, and require the gate to fail AT THAT ADDRESS.  A region where the gate
#   stays green is a region whose source is not actually reaching the ROM.
#
# RESULT, 2026-09-02 (worktree disasm-lanes/promB1, wsa1 gate, 4 images):
#   .long 0x00FD8E21 -> ...22  at F00C4E   DIFFERS, first at 0xC4E    head array
#   ldb c, 4 -> ldb c, 5       at F00CC8   DIFFERS, first at 0xCC9    code
#   .long 0x00FDD45D -> ...5C  at F014EE   DIFFERS, first at 0x14EE   tail array
#   .byte 0xD5, 0xED -> ...EC  at F017FE   DIFFERS, first at 0x17FF   refused 2 B
#   restored                               PASS: every rebuilt ROM is identical
#
# RUN (from the repository root, one level above wsa1/):
#   bash wsa1/notes/prom_b_f00c4d_gate_perturbation.sh
#
# It restores the file after every step, including on failure.
set -u
SRC=wsa1/prom_b/wsa1_prom_b.s
[ -f "$SRC" ] || { echo "run me from the repository root (the dir with wsa1/)"; exit 2; }
KEEP=$(mktemp); cp "$SRC" "$KEEP"
trap 'cp "$KEEP" "$SRC"; rm -f -- "${KEEP:?}"' EXIT

flip () {   # flip <exact old line> <exact new line>
  python3 - "$1" "$2" "$SRC" <<'PY'
import sys
p = sys.argv[3]
s = open(p, 'rb').read()
o, n = sys.argv[1].encode(), sys.argv[2].encode()
assert s.count(o) == 1, "expected exactly one %r, found %d" % (sys.argv[1], s.count(o))
open(p, 'wb').write(s.replace(o, n))
PY
}

run () {    # run <label> <old> <new>
  flip "$2" "$3" || return 1
  echo "--- $1"
  make gate-wsa1 2>&1 | grep -E "DIFFERS|^FAIL|^PASS" | head -3
  cp "$KEEP" "$SRC"
}

run "head array  0xF00C4E" "$(printf '\t.long\t0x00FD8E21\t; F00C4E')" "$(printf '\t.long\t0x00FD8E22\t; F00C4E')"
run "code        0xF00CC8" "$(printf '\tldb\tc, 4\t; F00CC8  ld C,0x04')" "$(printf '\tldb\tc, 5\t; F00CC8  ld C,0x04')"
run "tail array  0xF014EE" "$(printf '\t.long\t0x00FDD45D\t; F014EE')" "$(printf '\t.long\t0x00FDD45C\t; F014EE')"
run "refused 2 B 0xF017FE" "$(printf '\t.byte\t0xD5, 0xED\t; F017FE')" "$(printf '\t.byte\t0xD5, 0xEC\t; F017FE')"
echo "--- restored"
make gate-wsa1 2>&1 | tail -2
