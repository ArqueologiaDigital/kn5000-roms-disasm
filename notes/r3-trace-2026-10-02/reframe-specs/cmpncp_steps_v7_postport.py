#!/usr/bin/env python3
"""After port_islands.py --whole put v10's CmpNcp_ItemStep0..3 stretch (v10 0xF659D1-0xF65D64) onto v7
0xF655CD-0xF65960: drop the duplicated [v10] comment block, restate the carried comments with v7's RAM
addresses, head the step routines as v10 does, and label CmpNcp_ItemStep4 (v7 0xF65960).
v7 RAM: v10 0x342D/0x342E/0x342F/0x34CD/0x34D6/0x34EF = v7 0x3391/0x3392/0x3393/0x3431/0x343A/0x3453."""
import os
p = "v7/maincpu/sequencer/accompaniment_engine.s"
L = open(p, "rb").read().decode("latin-1").split("\n")
# 1. the 15-tables: v7's own comment block stays (with v7's address); the [v10] copy goes
k = L.index("TimeSig_StepUpTable15:")
dup = L[k + 1:k + 5]
assert all(x.startswith("; [v10] ") for x in dup), dup
del L[k + 1:k + 5]
OLD15 = "; Two 12-entry step tables for (0x342D) when AccVoice_GetChannelCount_Direct returns 15: the routine above"
assert L[k - 4] == OLD15, L[k - 4]
L[k - 4] = OLD15.replace("(0x342D)", "(0x3391)")
# 2. the 26-tables
k = L.index("TimeSig_StepDownTable26:")
assert all(x.startswith("; [v10] ") for x in L[k + 1:k + 5]), L[k + 1:k + 5]
L[k + 1:k + 5] = [
 "\t; The two 33-entry remaps of (0x343A) used by CmpNcp_ItemStep2 when the position in (0x3453)",
 "\t; crosses 26: a down step below (0x3393) sets 26 and (0x343A) := TimeSig_StepDownTable26[(0x343A)];",
 "\t; an up step from 26 sets (0x3393) and (0x343A) := TimeSig_StepUpTable26[(0x343A)].  Were decoded",
 "\t; as `calr` / `max` / `ld (P2:8), 8` code."]
# 3. step headers above their labels
for n in range(4):
    lab = "CmpNcp_ItemStep%d:" % n
    i = L.index(lab)
    h = L[i + 1]
    assert h.startswith("; [v10] Called by CmpNcp_ItemHandler%d." % n), h
    del L[i + 1]
    L.insert(i, h.replace("; [v10] ", "; "))
# 4. CmpNcp_ItemStep4: v7 0xF65960, after DrumVoice_NotifyEE_Return4's ret
k = L.index("DrumVoice_NotifyEE_Return4:")
assert L[k + 1] == "\tret" and L[k + 2] == "\tld\ta, (13370:16)", L[k:k + 3]
L[k + 2:k + 2] = ["; Called by CmpNcp_ItemHandler4.  Steps (0x343A) through one of three helpers chosen by bits 4/5 of (0x3431).",
                  "CmpNcp_ItemStep4:"]
assert not any("[v10]" in x for x in L[L.index("CmpNcp_ItemStep0:") - 3:k + 4])
d = "\n".join(L).encode("latin-1")
with open(p + ".tmp", "wb") as fh:
    fh.write(d)
os.replace(p + ".tmp", p)
print("ok")
