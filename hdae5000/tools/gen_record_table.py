#!/usr/bin/env python3
"""gen_record_table.py -- Generate the typed-data replacement for HDAE5000_RECORD_TABLE (0x29C0AA-0x29D97D).

⚠ THIS SPAN IS THE LARGEST CONFIRMED data-framed-as-code CASE IN THE TREE:
  6,356 bytes written as ~6,150 lines of instruction mnemonics. The evidence
  that it is DATA is external, not textual -- its only references LOAD IT AS AN
  ADDRESS, and there are zero call or jump sites anywhere in the tree, while the
  tree's own comments describe 13 records x 24 bytes with fields at +0x00/+0x14.

⚠ THE BYTE GATE CANNOT VALIDATE THIS IN EITHER DIRECTION. It passes whether
  the bytes are spelled as instructions or as data -- which is exactly why this
  category went unmeasured for so long. Typing real code as data is equally
  available and equally invisible. Read the bytes before converting any part.

RUN
    python3 hdae5000/tools/gen_record_table.py

PROVENANCE
  Lane HDAERECORD, 2026-09-02; recovered from session scratch.
"""
import struct

ROM = "original_ROMs/hd-ae5000_v2_06i.ic4"
BASE = 0x280000
TBL = 0x29C0AA
END = 0x29D97E  # HDAE5000_RECORD_COUNT

CLASS_NAMES = ["SelectList", "DbMemoCl", "TtlScreenR", "AcHddNamingWindow",
               "IvHddNaming", "HDTitleMenu", "TtlScreenR2", "TtlScreenR3",
               "AcWindowPage1", "IvScreenR2", "AcLanguageText1", "LyricBox",
               "FDFileSelect"]

data = open(ROM, "rb").read()
print("rom len", len(data))


def cstr_at(addr):
    off = addr - BASE
    end = data.index(b"\x00", off)
    return data[off:end], off, end


out = []
out.append("HDAE5000_RECORD_TABLE:\t; 0x29C0AA")
out.append("\t; Record/entry data table -- CONFIRMED DATA, not code.")
out.append("; ============================================================================")
out.append("; HDAE5000_RECORD_TABLE  (0x29C0AA - 0x29D97D, 6,356 bytes)")
out.append("; ============================================================================")
out.append("; This span was previously disassembled as ~6,150 lines of TLCS-900 instruction")
out.append("; mnemonics.  It is DATA.  The only reference to this address")
out.append("; (hd-ae5000_v2_06i.s:312, `lda_24 xwa, (0x29c0aa)`) loads it as an ADDRESS for the")
out.append('; "DISK MENU / UI" handler registration (see the Handler Registration Table just')
out.append("; above HDAE5000_Handler_Registration in hd-ae5000_v2_06i.s); there is no call or")
out.append("; jump site anywhere in the tree.  hdae5000_init_data.s:23 already documents the")
out.append("; record layout below from the RAM-image side; this header confirms it against the")
out.append("; raw ROM bytes and extends it to the full 6,356-byte span.")
out.append(";")
out.append("; DECOMPOSITION (confirmed byte-exact, see EVIDENCE below):")
out.append(";   0x29C0AA-0x29C1E1   312 B   the 13 x 24-byte record array itself")
out.append(";   0x29C1E2-0x29D8A9 5,832 B   all-zero reserved gap (verified, every byte 0x00)")
out.append(";   0x29D8AA-0x29D97D   212 B   packed pool of the 26 NUL-terminated strings the")
out.append(";                              records above point at (13 class names + 13")
out.append(";                              parameter type-signature strings, in reverse record")
out.append(";                              order, several signatures empty)")
out.append(";")
out.append("; RECORD LAYOUT (24 bytes), matching hdae5000_init_data.s:23-28:")
out.append(";   +0x00  .long  ProcPtr        class procedure entry point (ROM); matches an")
out.append(";                                already-named *Proc routine in this tree for all")
out.append(";                                13 records (e.g. record 7 -> HDAE5000_TtlScreenR3Proc")
out.append(";                                at 0x280645, byte-identical address)")
out.append(";   +0x04  .short Field_04       varies per record (0x11-0x6a); UNDECODED")
out.append(";   +0x06  .short Field_06       0x0160 in all 13 records; UNDECODED.  [INFERENCE]")
out.append(";                                matches the high half of port 0x01600004, the PPI")
out.append(";                                port this whole table is registered under in")
out.append(";                                HDAE5000_Handler_Registration -- not traced further")
out.append(";   +0x08  .short Field_08       varies per record (0x1a-0x3c); UNDECODED")
out.append(";   +0x0A  .short Field_0A       varies per record (0x00-0x20); UNDECODED")
out.append(";   +0x0C  .long  NamePtr        -> class name string, in the pool below")
out.append(";   +0x10  .long  SigPtr         -> parameter type-signature string (may be empty);")
out.append(";                                signature length == parameter count, matching")
out.append(";                                hdae5000_init_data.s:26-28 exactly for all 13")
out.append(";                                records (11,2,0,0,1,0,0,0,0,0,0,6,3)")
out.append(";   +0x14  .long  ParamListPtr   RAM address of this class's parameter-name list,")
out.append(";                                confirmed against hdae5000_init_data.s's own table:")
out.append(";                                record 0's 0x23975A == the documented")
out.append(';                                "0x2f96e2 -> 0x23975a, 13 lists" first entry')
out.append(";")
out.append("; EVIDENCE.  Every claim above is checked by the committed probe")
out.append("; hdae5000/tools/verify_record_table.py, run from the repo root; it reads")
out.append("; original_ROMs/hd-ae5000_v2_06i.ic4 at load base 0x280000 and nothing else:")
out.append(";  * all 13 ProcPtr values land exactly on an already-named *Proc label's address")
out.append(";  * the reserved gap (0x29C1E2-0x29D8A9) is 5,832 bytes of 0x00, no exception")
out.append(";  * the string pool (0x29D8AA-0x29D97D) decomposes into exactly 26 NUL-terminated")
out.append(";    runs with zero leftover bytes, and every NamePtr/SigPtr in the record array")
out.append(";    resolves to the start of one of those runs")
out.append(";  * SigPtr string length equals the parameter count already published in")
out.append(";    hdae5000_init_data.s, for all 13 records with no exception")
out.append("; ============================================================================")
out.append("")

for i, cname in enumerate(CLASS_NAMES):
    addr = TBL + i * 24
    off = addr - BASE
    proc, f04, f06, f08, f0a, namep, sigp, listp = struct.unpack_from("<IHHHHIII", data, off)
    lbl = "HDAE5000_Record_" + cname
    out.append("%s:\t; 0x%06X  class %r" % (lbl, addr, cname))
    out.append("\t.long 0x%x                     ; +0x00 ProcPtr (== named routine in this tree)" % proc)
    out.append("\t.short 0x%x, 0x%x                 ; +0x04 Field_04, +0x06 Field_06 (UNDECODED, see header)" % (f04, f06))
    out.append("\t.short 0x%x, 0x%x                 ; +0x08 Field_08, +0x0A Field_0A (UNDECODED, see header)" % (f08, f0a))
    out.append("\t.long 0x%x                     ; +0x0C NamePtr  -> %r" % (namep, cname))
    sig_bytes = cstr_at(sigp)[0] if sigp else b""
    out.append("\t.long 0x%x                     ; +0x10 SigPtr   -> %r (%d params)" % (sigp, sig_bytes.decode("latin1"), len(sig_bytes)))
    out.append("\t.long 0x%x                     ; +0x14 ParamListPtr (RAM)" % listp)
    out.append("")

recs_end = TBL + 13 * 24
gap = data[recs_end - BASE: 0x29D8AA - BASE]
assert gap == b"\x00" * (0x29D8AA - recs_end), "gap not all-zero!"
out.append("; ---------------------------------------------------------------------------")
out.append("; reserved gap: %d bytes, all 0x00 (verified above)" % (0x29D8AA - recs_end))
out.append("; ---------------------------------------------------------------------------")
out.append(".zero %d" % (0x29D8AA - recs_end))
out.append("")

out.append("; ---------------------------------------------------------------------------")
out.append("; string pool referenced by NamePtr/SigPtr above, in reverse record order")
out.append("; ---------------------------------------------------------------------------")
# Which addresses in the pool are actual SigPtr targets pointing at a bare
# NUL (an empty, 0-parameter signature)? Used only to make the comment on
# that one byte say what it is, instead of "empty string" for every filler
# NUL -- it does not change any byte emitted.
sig_targets = {}
for i, cname in enumerate(CLASS_NAMES):
    addr = TBL + i * 24
    aoff = addr - BASE
    _p, _f04, _f06, _f08, _f0a, _namep, sigp, _listp = struct.unpack_from("<IHHHHIII", data, aoff)
    if sigp and data[sigp - BASE] == 0:
        sig_targets[sigp] = cname

off = 0x29D8AA - BASE
off_end = END - BASE
count = 0
pad_run = 0
pad_run_start = None


def flush_pad():
    global pad_run, pad_run_start
    if pad_run:
        out.append("\t.zero %d\t\t\t; 0x%06X (unreferenced pad)" % (pad_run, pad_run_start))
        pad_run = 0
        pad_run_start = None


while off < off_end:
    nul = data.index(b"\x00", off)
    s = data[off:nul]
    addr = off + BASE
    if s:
        flush_pad()
        esc = s.decode("latin1").replace("\\", "\\\\").replace('"', '\\"')
        out.append('\t.asciz "%s"\t\t\t; 0x%06X' % (esc, addr))
    elif addr in sig_targets:
        flush_pad()
        out.append("\t.byte 0x00\t\t\t; 0x%06X (SigPtr target of %s, empty signature)" % (addr, sig_targets[addr]))
    else:
        if pad_run == 0:
            pad_run_start = addr
        pad_run += 1
    off = nul + 1
    count += 1

flush_pad()
assert off == off_end, (off, off_end)
print("pool strings:", count)

text = "\n".join(out) + "\n"
outp = "/tmp/claude-1000/-home-fsanches-compartilhado-KN7000/af5fe695-af5e-4caf-a2c2-2624dd161081/scratchpad/record_table_replacement.s"
open(outp, "w").write(text)
print("wrote replacement, lines:", len(out))
print("recs_end", hex(recs_end), "zero gap", 0x29D8AA - recs_end)
