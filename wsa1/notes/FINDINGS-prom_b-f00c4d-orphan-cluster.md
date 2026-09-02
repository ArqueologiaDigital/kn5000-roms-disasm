# prom_b 0xF00C4D-0xF017FF — a module that is in the image but not in the machine

Status: the CONVERSION is certified (the byte gate rebuilds prom_b exactly); the
INTERPRETATION below is graded, and the part that is not established says so.

Reproduce:

    cd wsa1
    python3 notes/gen_prom_b_f00c4d_module.py --layout     # the four regions
    python3 notes/gen_prom_b_f00c4d_module.py --selftest   # 20 checks
    python3 notes/prom_b_f00c4d_xrefs.py                   # the reference census
    python3 notes/prom_b_incbin_debt.py                    # 10,664 -> 7,669 B
    cd .. && make gate-wsa1                                # 4 images, PASS
    bash wsa1/notes/prom_b_f00c4d_gate_perturbation.sh     # and it goes RED on a flip

---

## 1. What the span is

| range | bytes | what | grade |
|---|---|---|---|
| 0xF00C4D-0xF00CA1 | 85 | tail of a 4-byte pointer array starting 0xF00C46 | strong |
| 0xF00CA2-0xF014ED | 2,124 | code, 828 instructions | strong |
| 0xF014EE-0xF017FD | 784 | a 196-entry pointer array, 18-slot records | strong |
| 0xF017FE-0xF017FF | 2 | refused, see §5 | — |

The code is four copies of one 15-instruction dispatch stub (0xF00CA2, 0xF00CE3,
0xF00D24, 0xF00D65), each selecting through one of four consecutive 0x48-byte
(18-slot) tables at 0xF002AC, 0xF002F4, 0xF0033C, 0xF00384, then ~50 further
routines. Every routine is compiler output: `link XIZ,imm16` … `unlk XIZ` /
`ret`, 54 pairs, arguments pushed and the stack popped with `inc n,XSP`.

## 2. Why the code reading is not "data that decodes"

That hazard is invisible to the byte gate, so the reading rests on five
properties of the bytes, all re-measured by `--selftest`:

1. a linear MAME-unidasm decode from 0xF00CA2 tiles the region **exactly**, ending
   on 0xF014EE with no straddle and no resynchronisation;
2. **0** `db` markers inside it, against **26** in the 786 bytes immediately after
   it — which is what a linear decode of a pointer array looks like;
3. all **54** internal branch targets land on instruction starts of that decode;
4. **26 pointers held OUTSIDE the span**, in 0xF0033C-0xF003C7, name addresses
   inside it and all 26 land on instruction starts;
5. 54 `link` / 54 `unlk`, region opens with the first and ends with the second.

Check 4 is the one that cannot be arranged by choosing a framing: the table was
not consulted until after check 1 held.

## 3. ★ The finding — the cluster is orphaned, and its calls do not fit prom_a

**N1. Nothing reaches it.** `notes/prom_b_f00c4d_xrefs.py`, with a positive
control for each instrument:

* converted source of all four images: **0** references to 0xF00C00-0xF017FF;
* raw bytes of prom_a and prom_b: 4 byte sequences read as `jp`/`call` imm24
  into the range and **all four are coincidences inside data** — two inside a
  `.byte` bitmap row in prom_b's font area, two spanning the immediate of
  `ld (XIX+0x01),0x1b` and the first three bytes of the next instruction in
  prom_a. **0** are on an instruction line of the converted source.

The only thing naming any of the range is the 0xF0033C table, and that table is
named only by the four routines *inside* the span. It is a closed loop.

⚠ The control is not decoration. `grep -ao 'f00c..'` returns **0** matches on
files a Python `encoding='latin-1'` read shows **32** in — this environment
resolves `grep` to ugrep. A bare grep would have "confirmed" N1 while returning
zero for everything.

**N2. Its call targets are not prom_a entry points.** The code makes 24-bit
absolute calls to 34 distinct addresses in 0xFDA6FC-0xFDDA7B (prom_a's window on
CPU 1's CS2, confirmed in `FINDINGS-memory-map.md`); the two arrays name 155 more
in 0xFC4480-0xFDED77. prom_a has 2,542 bytes of `.incbin` left in the whole
image, and the window these targets fall in — 0xFDA000-0xFDEFFF — is **20,372 of
20,480 bytes on instruction lines** and 101 on data lines, so its boundaries
there are framed and not guessed. And:

* **14 of 34** call targets and **58 of 155** array targets land on one;
* no constant offset in -2048..+2048 fixes it — the best is 79/155 at +1936,
  barely above the 58 that offset 0 already gives;
* and where a target can be checked by hand it is not merely unaligned but
  **impossible**:
  * `0xFDA6FC` is four instructions from the end of a **loop body** in prom_a
    (`sub_FDA6FC` there is an orphan label no prom_a line references — very
    likely planted by an earlier pass that seeded from these same bytes);
  * `0xFDBD28` is the **last byte** of `cp (XIZ-12),0x01` (`8e f4 3f 01`);
  * `0xFDA7CE`, the tail array's repeated stub value in **51 of its 196 slots**,
    is the **second byte** of `extz BC` (`d9 12`).

Neither prom_c nor any other base makes them fit: at prom_c's own 0xF80000 the
same addresses are `nop`/`db` noise.

**Reading, GRADED "strong, not proven":** this is a module correctly linked for
where it sits — its own dispatch tables and its `lda XIY,0xf00cdf` return
addresses are right for 0xF00xxx — that calls **a prom_a which is not the prom_a
next to it**. A leftover from a different build of the pair is the obvious
candidate. No claim is made about which, and none is needed: checks 1-5 are
properties of the bytes and do not depend on where the calls land.

⚠ **Consequence for naming.** Do NOT name a routine here after what its call
target does in the prom_a we have. That is the specific mistake N2 makes
available and it would invent a whole module of semantics.

## 4. What the round-1 banner said, and what survives of it

`wsa1_prom_b.s` recorded these bytes as "NOT reachable and stays `.incbin`".
The first half is still true and is kept verbatim in the file. The second half
does not follow from it: **unreachable is a fact about the call graph, never a
fact about the bytes.** §3 now also explains *why* it is unreachable, which the
round-1 note could not.

## 5. The two bytes refused

0xF017FE-0xF017FF are `D5 ED`. The three array entries before them are
0x00FDECBB, 0x00FDED19, 0x00FDED77 — a +0x5E progression whose next term
0x00FDEDD5 has exactly these two bytes as its low half. Completing the entry
needs 0xF01800-0xF01801, and those belong to the display list at 0xF01800:
`1C 10` is op 0x1C length 16, and 6 header bytes + the 10 characters of
"SOUND EDIT" is exactly 16. The rival framing dies at once — starting that list
at 0xF01802 gives `6E 00`, a record of length 0, a non-terminating walk. So the
entry cannot be completed, and it is not invented: the two bytes stay `.byte`
with this note at the site.

## 6. A toolchain note worth keeping

Of the 828 instructions, 152 are shapes llvm-mc's *disassembler* prints and its
*assembler* rejects. All 152 already have a spelling in prom_a and are emitted
as real instructions, so the code region contains **no** `.byte`. One of them is
a trap:

    cp (XIZ+0xfc),0x00     accepted by llvm-mc, assembles to c3 f9 fc 00 3f 00
    m_cp_mi8 MBD+r6, 0xfc, 0x00                            8e fc 3f 00  ← the ROM

The macro is not a style preference; the native spelling silently picks the
wrong encoding. This is exactly the class of error the byte gate exists for.
