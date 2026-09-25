import sys, subprocess
img, p = sys.argv[1], sys.argv[2]
import os
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
nm = subprocess.run([os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-nm'), '--defined-only',
                     ROOT + '/rebuilt_ROMs/kn5000_%s_program.llvm.elf' % img], capture_output=True, text=True).stdout
SYM = {}
for ln in nm.split('\n'):
    x = ln.split()
    if len(x) == 3:
        SYM.setdefault(x[2], int(x[0], 16))
ROM = open(ROOT + '/original_ROMs/kn5000_%s_program.rom' % img, 'rb').read()
a = SYM['SMF_ChannelTranslationTable']
b = ROM[a - 0xE00000:a - 0xE00000 + 64]
assert SYM['SMF_ConfigSlot'] == a + 64
s = open(p, encoding='latin-1').read()
i = s.index('\nSMF_ChannelTranslationTable:\n') + 1
j = s.index('\nSMF_ConfigSlot:\n', i) + 1
old = s[i:j]
assert old.count('.fill 8, 1, 0xff') == 1
body = "\n".join("\t.byte %s\t; inputs 0x%02x-0x%02x" % (", ".join("0x%02x" % x for x in b[k:k + 8]), k, k + 7)
                 for k in range(0, 64, 8))
new = '''; -----------------------------------------------------------------------------
; SMF_ChannelTranslationTable -- 64 bytes, indexed by the value in A.
; Reader: SMF_TranslateChannel (0x%06X): `ld xix, SMF_ChannelTranslationTable`,
; `ldb_sri W, 0x07, 0xf0, 0xec` (W := table[A]).  0xFF leaves A unchanged;
; otherwise A := W, except that with RAM byte 0x112A == 3 the inputs 0x0E and
; 0x10 give 0x17 and 0x18 instead.  Its callers (the SMF_SlotParam_* handlers)
; pass the (XIY+2) byte of a slot record, treat bit 7 of the result as a flag
; (`and a, 0x7f; or (xiy), 4`) and store the low 7 bits back into (XIY+2).
; 64 entries (inputs 0x00-0x3F), to SMF_ConfigSlot (code); the last 8 were a
; `.fill 8, 1, 0xff` until 2026-09-25.
; -----------------------------------------------------------------------------
SMF_ChannelTranslationTable:
%s

''' % (SYM['SMF_TranslateChannel'], body)
s = s[:i] + new + s[j:]
open(p, 'w', encoding='latin-1').write(s)
print('ok')
