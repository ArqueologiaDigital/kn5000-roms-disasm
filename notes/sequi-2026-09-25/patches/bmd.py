import sys, re, subprocess
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
A = lambda n: "0x%06X" % SYM[n]
s = open(p, encoding='latin-1').read()
def rep(old, new, cnt=1):
    global s
    assert s.count(old) == cnt, (old[:80], s.count(old))
    s = s.replace(old, new)
nc = SYM['BmDrEdit_ByteData_NoteCoordTable']
# the ram addresses are read from the file itself (v7 differs)
m = re.search(r'BmDrEdit_ByteData_NoteCoordTable:\n((?:\tldmm\S+ .*\n){4})\tret\n((?:\tldmm\S+ .*\n){4})\tret\n', s)
assert m, 'block shape'
save = [re.match(r'\tldmm(\d+) (0x[0-9a-f]+), (0x[0-9a-f]+)', l).groups() for l in m.group(1).splitlines()]
desc = ", ".join("%s%s" % (src, " (byte)" if w == "8" else "") for w, dst, src in save)
dsts = ", ".join(dst for w, dst, src in save)
rep(m.group(0), '''; -----------------------------------------------------------------------------
; Four unreferenced routines, `.byte` until 2026-09-25 (both decoders agree:
; notes/sequi-2026-09-25/reframe-%s-bmdredit_routines.log).  NO CALLER FOUND
; for any of the four entry points: scripts/analysis/sequi_find_refs.py %s
; %s %s %s %s -> no hit at an instruction start.
;
; BmDrEdit_SavePositionVars / BmDrEdit_RestorePositionVars: copy the four
; variables %s
; to %s and back.  (The first two are the
; beat position BmDrEdit_CalcBeatFromGridPos writes.)
; -----------------------------------------------------------------------------
BmDrEdit_SavePositionVars:
%s\tret
BmDrEdit_RestorePositionVars:
%s\tret
''' % (img, img, A('BmDrEdit_ByteData_NoteCoordTable'), "0x%06X" % (nc + 25), "0x%06X" % (nc + 50),
       "0x%06X" % (nc + 76), desc, dsts, m.group(1), m.group(2)))
# the two scroll duplicates: insert labels before the two `bit 7, (0x295c:16)` right after
_k = s.index('\nBmDrEdit_RestorePositionVars:\n')
_head, s = s[:_k], s[_k:]
s = re.sub(r'\tret\n(\tbit 7, \(0x295c:16\)\n\tret[\t ]nz\n)', lambda m: '''\tret

; Unreferenced near-duplicate of BmDrEdit_ModeScrollUp (same test of bit 7 of
; RAM 0x295C, same 0x60 ceiling, same tail jump).
BmDrEdit_ModeScrollUp_Dup:
''' + m.group(1), s, count=1)
s = re.sub(r'(\tjp[\t ]NoteEditSy_SendModeScrollCmd\n)(\tbit 7, \(0x295c:16\)\n\tret[\t ]nz\n)', lambda m: m.group(1) + '''
; Unreferenced near-duplicate of BmDrEdit_ModeScrollDown (0 -> 48, else
; decrement down to 1); ends in `call ...; ret` where the live one has `jp`.
BmDrEdit_ModeScrollDown_Dup:
''' + m.group(2), s, count=1)
assert 'BmDrEdit_ModeScrollUp_Dup:' in s[:400] and 'BmDrEdit_ModeScrollDown_Dup:' in s[:1200], 'dup labels misplaced'
s = _head + s
s = re.sub(r'(?<![\w.$@])BmDrEdit_ByteData_NoteCoordTable_Code_Skip(?![\w.$@])', 'BmDrEdit_ModeScrollDown_Dup_Clamp', s)
s = re.sub(r'(?<![\w.$@])BmDrEdit_ByteData_NoteCoordTable_Code_Join(?![\w.$@])', 'BmDrEdit_ModeScrollDown_Dup_Send', s)
assert 'BmDrEdit_ByteData_NoteCoordTable' not in s
# ScrollParams
rep('\nBmDrEdit_ByteData_ScrollParams:\n', '''
; -----------------------------------------------------------------------------
; BmDrEdit_TestPartTableEntry -- A := RAM 0x2965 (a MIDI channel), code :=
; RAM 0xF1A0[A] (the channel's part-type code, cf. SMF_HeaderConstants),
; XWA := the 32-bit pointer at 0xE4448E + code*4; returns HL = 0 when the byte
; that pointer addresses is >= 0xF0, else HL = 0xFFFF.
; NO CALLER FOUND: scripts/analysis/sequi_find_refs.py %s %s -> none.
; Was `.byte` (named ByteData_ScrollParams) until 2026-09-25.  What the
; pointer table at 0xE4448E is, is not established here.
; -----------------------------------------------------------------------------
BmDrEdit_TestPartTableEntry:
''' % (img, A('BmDrEdit_ByteData_ScrollParams')))
open(p, 'w', encoding='latin-1').write(s)
print('ok')
