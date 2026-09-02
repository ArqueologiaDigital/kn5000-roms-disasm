# The "grep returns 0 on these sources" hazard: REPRODUCED, with the mechanism

`notes/lanes/BRIEF-2026-09-01.md` carries an addendum marked
**⚠ UNCONFIRMED: the "plain grep returns 0 on latin-1 sources" claim**, which
records that the effect "does not reproduce" and suggests the general claim is
unsupported.

It reproduces. Lane V10AUDIO hit it on 2026-09-02 and this note records the
exact file, the exact byte, and the mechanism, so the hazard can be stated
precisely instead of being either believed or dismissed wholesale.

## Reproduction

    $ cd v10/maincpu/audio
    $ grep  -c '\.byte' dsp_config_sysex.s      # ->  (empty, no count printed)
    $ grep -ac '\.byte' dsp_config_sysex.s      # -> 223
    $ command grep -c '\.byte' dsp_config_sysex.s   # GNU grep -> 223

The plain form prints **nothing at all** — not "0", not a warning — and exits
as though the pattern were absent.

## Mechanism

In this environment `grep` is a **shell function**, not GNU grep. It execs the
Claude Code binary under `ARGV0=ugrep` with a fixed prefix of flags:

    -G --ignore-files --hidden -I --exclude-dir=.git ...

The load-bearing flag is **`-I`** — *ignore binary files*. ugrep's binary
heuristic is UTF-8 validity, not the presence of NUL bytes.

`v10/maincpu/audio/dsp_config_sysex.s` contains **exactly one** byte >= 0x80:
offset 69,024, value **0x81**, inside an `.ascii` literal —

    jr	z, 59
    	.byte 0x8f, 0x06
    	.ascii "?df5\x81"
    	ldb	l, 219

0x81 is a UTF-8 *continuation* byte with no lead byte, so the file is invalid
UTF-8, so ugrep calls it binary, so `-I` drops it silently. `file(1)` still
reports "assembler source, ASCII text", which is why the earlier check with
`file` concluded the claim was unsupported — `file` and ugrep disagree, and it
is ugrep's verdict that decides what the search returns.

This also explains why the earlier A/B on `hdae5000_data_tables.s` found `grep
-c` and `grep -a -c` **identical**: whether a given high byte forms a valid
UTF-8 sequence with its neighbours is per-file. A file whose high bytes happen
to be well-formed UTF-8 is searched normally. One stray lone continuation byte
is enough to hide a whole file.

## Practical rule

`grep -a` for anything under a disassembly tree, always. A zero result from a
plain `grep` over these sources is not evidence of absence, and the failure is
**silent** — there is no "Binary file matches" line to notice.
