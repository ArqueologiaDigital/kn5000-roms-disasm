import sys, re
img, p = sys.argv[1], sys.argv[2]
import os
ROM = open(os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))), 'original_ROMs/kn5000_%s_program.rom' % img), 'rb').read()
B = 0xE00000
s = open(p, encoding='latin-1').read()

def rows(addr, n, per=16, fmt="0x%02x"):
    b = ROM[addr - B:addr - B + n]
    out = []
    for i in range(0, n, per):
        out.append("\t.byte " + ", ".join(fmt % x for x in b[i:i + per]))
    return out

def variants(addr, nvar, notes):
    notes = [remap(n) for n in notes]
    out = []
    for v in range(nvar):
        a = addr + 49 * v
        out.append("\t; +0x%02X: %s" % (49 * v, notes[v]))
        b = ROM[a - B:a - B + 49]
        for i in range(0, 48, 16):
            out.append("\t.byte " + ", ".join("%d" % x for x in b[i:i + 16]))
        out.append("\t.byte %d\t; entry 48: past the 0..0x2F index clamp, never read" % b[48])
    return out

RAM = {}
def remap(text):
    if not RAM:
        return text
    pat = re.compile("|".join(re.escape(k) for k in sorted(RAM, key=len, reverse=True)))
    return pat.sub(lambda m: RAM[m.group(0)], text)

def replace_block(label, nextlabel, header, body):
    global s
    header = remap(header)
    i = s.index("\n" + label + ":\n") + 1
    j = s.index("\n" + nextlabel + ":\n", i) + 1
    s = s[:i] + header + label + ":\n" + "\n".join(body) + "\n\n" + s[j:]

A = {}
for x in sys.argv[3:]:
    k, v = x.split("=")
    if k.startswith("ram:"):
        RAM[k[4:]] = v
    else:
        A[k] = int(v, 16)

replace_block("Rhythm_InstrMapTable_Default", "Rhythm_TransposeNote", '''; -----------------------------------------------------------------------------
; Rhythm_InstrMapTable_Default -- 3 variants x 49 bytes.  Each maps the RAM
; byte 0x32D8 (index clamped to 0..0x2F, anything larger reads entry 0) to a
; ROW NUMBER of the 16-byte-row table at Display_FontPalette_Table_0x136A.
; Readers (all the same pattern): Rhythm_VelocityLookup_A, Rhythm_VoiceMapLookup
; (second half) and Rhythm_TranspMod_BaseApply:
;     ld xiy, <variant> / ldb_sri L, ..., 0xf4, 0xec     ; L := variant[L]
;     sla hl, 4 / ld xiy, Display_FontPalette_Table_0x136A
;     lda_dri XIY, ...  ; xiy += row*16  /  ldb_sri A, ... ; A := row[A]
;     add w, a                                           ; note += row[col]
; where the column A came from Rhythm_InstrBaseLookup (a byte of
; Display_FontPalette_Table_0x12EA indexed by the note).
; Variant choice: bit 2 of RAM 0x32F4 selects +0x31 (the positional alias
; Rhythm_InstrMapTable_Default_0x31), bit 3 selects +0x62 (..._0x62);
; Rhythm_TranspMod_BaseApply always uses +0x31.  Stride 0x31 = 49 is pinned by
; those two aliases; the tables end exactly at Rhythm_TransposeNote (147 B).
; Values 0..20 = row numbers.  What the rows mean musically is not established.
; -----------------------------------------------------------------------------
''', variants(A["instr"], 3, ["default (bits 2 and 3 of 0x32F4 clear)",
                              "bit 2 of 0x32F4 set; always used by Rhythm_TranspMod_BaseApply",
                              "bit 3 of 0x32F4 set"]))

replace_block("Rhythm_PitchShiftTable_Default", "Rhythm_VelocityCompute", '''; -----------------------------------------------------------------------------
; Rhythm_PitchShiftTable_Default -- 2 variants x 49 bytes of SHIFT SELECTORS,
; indexed like Rhythm_InstrMapTable_Default by RAM 0x32D8 (clamped 0..0x2F).
; Reader: Rhythm_VoiceMapLookup, first half: `ld xiy, <variant>`,
; `ldb_sri L, ..., 0xf4, 0xec` (L := variant[L]); then
;     0 -> no shift;  1 -> shift byte RAM 0x3433;  2 -> shift byte RAM 0x3434,
; where a shift byte with bit 5 set returns 0 (muted), bit 4 set subtracts and
; clear adds its low nibble to A.  Rhythm_NoteRangeCheck clears both bytes.
; Variant: bit 3 of RAM 0x32F4 selects +0x31 (alias
; Rhythm_PitchShiftTable_Default_0x31).  98 bytes = 2 x 49, to
; Rhythm_VelocityCompute.  Was framed as `nop` / `normal` / `push sr`
; (0x00 / 0x01 / 0x02) until 2026-09-25.
; -----------------------------------------------------------------------------
''', variants(A["pitch"], 2, ["default (bit 3 of 0x32F4 clear)", "bit 3 of 0x32F4 set"]))

replace_block("Rhythm_VelocityTable_A", "Rhythm_FourChannelDispatch", '''; -----------------------------------------------------------------------------
; Rhythm_VelocityTable_A -- 2 variants x 49 bytes, the same kind of table as
; Rhythm_InstrMapTable_Default (row numbers into the 16-byte rows at
; Display_FontPalette_Table_0x136A), for a different reader.
; Reader: Rhythm_VelocityCompute -- `ld xiy, <variant>`, L := variant[L]
; (L = RAM 0x32D8 clamped 0..0x2F), `sla hl, 4`, row lookup, `add w, a`,
; `calr Rhythm_TransposeNote`: identical to Rhythm_VelocityLookup_A.
; Variant: bit 2 of RAM 0x32F4 selects +0x31 (alias Rhythm_VelocityTable_A_0x31).
; 98 bytes = 2 x 49, to Rhythm_FourChannelDispatch.  The two variants differ
; from Rhythm_InstrMapTable_Default's first two only at entry 7 (0 here, 9
; there).  The "Velocity" in the name is not supported by the reader, which
; adds the row value to the NOTE in W.
; -----------------------------------------------------------------------------
''', variants(A["vel"], 2, ["default (bit 2 of 0x32F4 clear)", "bit 2 of 0x32F4 set"]))

def longs(addr, n):
    b = ROM[addr - B:addr - B + 4 * n]
    return ["\t.long 0x%08x\t; [%d]" % (int.from_bytes(b[4 * i:4 * i + 4], "little"), i) for i in range(n)]

_b = ROM[A["seqreset"] - B:A["seqreset"] - B + 68]
_nz = ["[%d] 0x%04X" % (i, int.from_bytes(_b[4*i:4*i+4], "little")) for i in range(17) if int.from_bytes(_b[4*i:4*i+4], "little")]
replace_block("Rhythm_SeqResetTable", "Rhythm_TransposeWithMod", '''; -----------------------------------------------------------------------------
; Rhythm_SeqResetTable -- 17 x 32-bit RAM pointers (or 0), indexed by RAM byte
; 0x379B.
; Reader: Rhythm_SeqResetCheck -- when bit 2 of RAM 0x34CF is set and bit 4
; clear: L := (0x379B), `sla l, 2`, `ld xiy, Rhythm_SeqResetTable`,
; `ld_sril3 XIX, 0x07, 0xf4, 0xec` (xix := table[L]); if non-zero, with
; interrupts masked (`ei 6` .. `ei 0`) the word at (xix+6) is copied to
; (xix+4).  Stride 4 from `sla l, 2`; 17 entries = 68 bytes, to
; Rhythm_TransposeWithMod.  Non-zero entries: NONZERO.  What those RAM
; structures are is not established.
; -----------------------------------------------------------------------------
'''.replace("NONZERO", ", ".join(_nz)), longs(A["seqreset"], 17))

old = '''Rhythm_NoteRangeData:
	nop
	nop
''' if "Rhythm_NoteRangeData:\n\tnop\n" in s else '''Rhythm_NoteRangeData:
	.byte 0x00, 0x00
'''
new = '''; Two zero bytes between Rhythm_NoteRangeCheck's `ret` and the called routine
; Rhythm_VelocityLookup_A.  No reference found (scripts/analysis/
; sequi_find_refs.py %s 0x%06X 0x%06X -> none); inter-routine padding by
; position, nothing established beyond that.  Was `nop / nop` until 2026-09-25.
Rhythm_NoteRangeData:
	.byte 0x00, 0x00
''' % (img, A["noterange"], A["noterange"] + 1)
assert s.count(old) == 1
s = s.replace(old, new)
open(p, "w", encoding="latin-1").write(s)
print("ok")
