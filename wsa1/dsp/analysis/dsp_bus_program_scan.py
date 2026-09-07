#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_bus_program_scan.py -- does the WSA1R ever put a DSP PROGRAM on the bus after boot?

The decisive test for whether runtime effect selection re-uploads I-RAM microcode. It
scans a LOG_DSPUP capture (the driver's dsp_capture stream) for cmd-0x01 records and
reports each one's destination, address, and byte position, separating a PROGRAM upload
(cmd 0x01 + a program I-RAM address such as 0x0030 or 0x006E) from a coefficient POKE
(cmd 0x01 + address 0x0160, the poke port). Post-boot program uploads are what the goal
"exercise more of the 918-word corpus at runtime" requires.

MEASURED 2026-09-07 (30 s boot + two effect changes, u0->20 and u1->9):
  * the ONLY cmd-0x01 program upload on the whole bus is to 0x0030 on dest2 (IC30) --
    the boot kernel (bytes #1 and #436). There is NO cmd-0x01 to 0x006E ever.
  * the effect changes produced 1923 (dest0) / 26 (dest1) POST-boot bytes, and de-framing
    them shows ONLY coefficient/descriptor groups (0A value, 08 01 address, 00 00 D-RAM) --
    no cmd-0x01 program record.
  => DIRECTLY PROVEN: the firmware never emits a per-effect I-RAM body at runtime; the
  program is uploaded once at boot, and effect changes stream coefficients only. So
  sub_FA3A3C's field+12 op3 emit is gated (the boot program is treated as resident), and
  the goal is not reachable via effect selection. This confirms the write-tap result
  (0 I-RAM writes on a change) at the bus level.

HOW TO REGENERATE THE CAPTURE (the log is volatile/large -- this is the recipe):
  1. In kn7000_mame/src/mame/matsushita/wsa1.cpp set  #define VERBOSE (LOG_LINKLOST|LOG_DSPUP)
  2. TEMP: in src/devices/cpu/upd6383/upd6383.cpp iram_map, map the full 11-bit space --
     `map(0x000, 0x7ff).ram();` -- otherwise the device's per-sample read past the 384-word
     iram floods error.log with "unmapped iram memory read" (>1 GB / 16 M lines) and the
     sim never reaches the change frame.
  3. Build with CPPFLAGS=-DWSA1R_ENABLE_DSP=1, run wsa1r with an autoboot lua that pokes an
     effect change after boot (poke live 0x856E+0x1A*unit + twin 0x7E7E+.. + flag 0x7ECC),
     `-log`; then revert both source edits.
  4. python3 dsp_bus_program_scan.py <path/to/error.log>

stdlib only, read-only.
"""
import collections
import re
import sys

LINE = re.compile(r'dspup: dest(\d) (CMD|DAT) ([0-9A-Fa-f]{2})  \(#(\d+)\)')
POKE_PORT = 0x0160


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    st = {}
    hi = {}
    recs = []                         # (dest, byte#, addr)
    for raw in open(sys.argv[1], 'rb'):
        m = LINE.search(raw.decode('latin1'))
        if not m:
            continue
        d, typ, val, n = m.group(1), m.group(2), m.group(3), int(m.group(4))
        if typ == 'CMD':
            st[d] = ('hi', n) if val == '01' else None
            hi[d] = None
        else:
            if st.get(d) and st[d][0] == 'hi':
                if hi[d] is None:
                    hi[d] = val
                else:
                    recs.append((d, st[d][1], (int(hi[d], 16) << 8) | int(val, 16)))
                    st[d] = None

    prog = [r for r in recs if r[2] != POKE_PORT]
    poke = [r for r in recs if r[2] == POKE_PORT]
    print("cmd-0x01 records: %d program-address, %d poke-port(0x0160)" % (len(prog), len(poke)))
    print("\nPROGRAM uploads (cmd 0x01 -> a program I-RAM address):")
    if not prog:
        print("  NONE.")
    for d, n, a in prog:
        print("  dest%s  byte#%-6d addr 0x%04X" % (d, n, a))
    by = collections.Counter((d, a) for d, n, a in prog)
    print("\ndistinct (dest, program-addr):", dict(by))
    print("\n=> post-boot program uploads = the count of the above with byte# beyond the "
          "boot window (dest0~10830 / dest1~6173 / dest2~856). If zero, effect selection "
          "uploads no I-RAM at runtime.")


if __name__ == "__main__":
    sys.exit(main())
