#!/usr/bin/env python3
"""Name the Msg0716 module's message builders from the MIDI-shaped message each one posts to CPU 2.

QUESTION IT ANSWERS
  FINDINGS-prom_a-msg0716-module.md: every handler builds a short message at RAM 0x0716 and posts it to
  CPU 2 (Msg0716_Post_Trampoline -> Msg0716_Post), and "what any handler does is not established".
  The builders at 0xFC151B-0xFC19FF write a MIDI-SHAPED message: byte 0 a status, byte 1 the object /
  part number the caller stored (a handler does `ld A,(XIZ+0x06) / ld (XIX+0x01),A`; record +6 = n),
  byte 2 a controller number, byte 3 the value from the UI event, then BC = 4 and post:
      ld (XIX),0xB0 / ld (XIX+0x02),cc / ld c,limit / calr <tail> / ret
  so each builder is "post controller cc for this part" and is named by the MIDI 1.0 controller number:
  0x01 Modulation, 0x02 Breath, 0x04 Foot, 0x07 Volume, 0x0B Expression, 0x10-0x13 GeneralPurpose1-4,
  0x40 Sustain, 0x5B Effect1Depth, 0x5D Effect3Depth (MIDI's names); numbers 0x80 and above are not
  MIDI controllers -- this firmware's own -- and keep only the number: Msg0716_PostCtrlInt<cc>, the
  spelling of the receiver's arms.  ★ THE RECEIVER CONFIRMS THE READING: prom_c's MidiCtrl_Dispatch
  (prom_c/midi/midi_controllers.s, round 7) takes packet byte [1] as the part, [2] as the controller
  NUMBER and [3] as its value; its seventeen numbers below 0x80 are "the standard MIDI allocation, with
  no number that is not in it" (notes/prom_c_dev10c_meaning_checks.py), and it names the ones >= 0x80
  MidiCtrl_IntXX.  That answers the round-10 refusal of 0xFC151B (notes/prom_c_inventory_round8.py
  REFUSALS10: "0x97 is 151 ... so field +2 is not a controller number"): the extensions sit beside the
  MIDI numbers, they do not make the MIDI ones something else.
  Status 0xD0 is Channel Pressure.  `F0 50 cmd` is a system-exclusive message with manufacturer ID 0x50
  (Matsushita): Msg0716_PostSysEx50_<cmd>, the command meaning not established here.
  The three tails, read from their bodies:
      0xFC18CC  value = UiEvent_Byte2 AND limit                     Msg0716_PostValueMasked
      0xFC18DC  value = 0x7F if UiEvent_Byte2 AND limit, else 0      Msg0716_PostValueAsSwitch
      0xFC18F7  value = min(UiEvent_Byte2, limit)                    Msg0716_PostValueClamped
  A handler-table entry whose whole body is `ld A,(XIZ+0x06) / ld (XIX+0x01),A / calr <builder> / ret` is
  Msg0716_PartPost<what the builder posts>.  REFUSED: any routine of another shape, and a name taken.

RUN
  python3 notes/prom_a_msg0716_message_names.py          # the plan
  python3 notes/prom_a_msg0716_message_names.py --args   # 'old=new|header' for the rename helper
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1")
CC = {0x01: "Modulation", 0x02: "Breath", 0x04: "Foot", 0x07: "Volume", 0x0B: "Expression",
      0x10: "GeneralPurpose1", 0x11: "GeneralPurpose2", 0x12: "GeneralPurpose3", 0x13: "GeneralPurpose4",
      0x40: "Sustain", 0x5B: "Effect1Depth", 0x5D: "Effect3Depth"}
TAILS = {"Msg0716_PostValueMasked": "Msg0716_PostValueMasked", "Msg0716_PostValueAsSwitch": "Msg0716_PostValueAsSwitch",
         "Msg0716_PostValueClamped": "Msg0716_PostValueClamped"}
TAILDOC = {"Msg0716_PostValueMasked": "value = UiEvent_Byte2 AND C", "Msg0716_PostValueAsSwitch": "value = 0x7F if UiEvent_Byte2 AND C, else 0",
           "Msg0716_PostValueClamped": "value = min(UiEvent_Byte2, C)"}


def bodies():
    L = A.split("\n")
    st = [(i, m.group(1)) for i, l in enumerate(L) for m in [re.match(r'^([A-Za-z_][\w$]*):', l)] if m]
    for k, (i, n) in enumerate(st):
        j = st[k + 1][0] if k + 1 < len(st) else len(L)
        b = [re.sub(r'\s+', ' ', l.split(";")[0]).strip() for l in L[i + 1:j]]
        yield n, [x for x in b if x and not x.startswith(".L")]


def tailname(t):
    return TAILS.get(t, t)


def plan():
    rows, built = [], {}
    labels = dict(bodies())
    for old, new in TAILS.items():
        if old in labels:
            rows.append((old, new, "%s: the shared tail of the Msg0716 builders -- %s, byte 3 of the message at 0x0716, BC = 4,\\n"
                         "  Msg0716_Post_Trampoline (notes/prom_a_msg0716_message_names.py)." % (new, TAILDOC[new])))
    for n, b in labels.items():
        if not re.match(r'^sub_FC1[0-9A-F]{3}$', n):
            continue
        t = " | ".join(b)
        m = re.match(r'^ld \(XIX\),0xb0 \| ld \(XIX\+0x02\),0x([0-9a-f]{2}) \| ld c, 0x([0-9a-f]{2}):opc \| calr (\w+) \| ret', t)
        if m and (m.group(3) in TAILS or m.group(3) in TAILS.values()):
            cc, lim = int(m.group(1), 16), int(m.group(2), 16)
            new = ("Msg0716_PostCC%02X_%s" % (cc, CC[cc])) if cc in CC else "Msg0716_PostCtrlInt%02X" % cc
            built[n] = new[len("Msg0716_"):]
            rows.append((n, new, "%s: posts B0 <part> %02X <value> to CPU 2 -- controller 0x%02X%s, value through %s with limit 0x%02X\\n"
                         "  (notes/prom_a_msg0716_message_names.py)." % (new, cc, cc, " (MIDI %s)" % CC[cc] if cc in CC else " (not a MIDI number; the receiver's MidiCtrl_Int%02X)" % cc, tailname(m.group(3)), lim)))
            continue
        m = re.match(r'^ld \(XIX\),0xd0 \| ld \(XIX\+0x02\),0x00 \| ld c, 0x([0-9a-f]{2}):opc \| calr (\w+) \| ret', t)
        if m and m.group(2) in TAILS:
            built[n] = "PostChannelPressure"
            rows.append((n, "Msg0716_PostChannelPressure", "Msg0716_PostChannelPressure: posts D0 <part> 00 <value> (MIDI Channel Pressure) to CPU 2, value through %s\\n"
                         "  (notes/prom_a_msg0716_message_names.py)." % tailname(m.group(2))))
            continue
        m = re.match(r'^(?:ld XIX,0x00000716 \| )?ld \(XIX\),0xf0 \| ld \(XIX\+0x01\),0x50 \| ld \(XIX\+0x02\),0x([0-9a-f]{2})', t)
        if m:
            cmd = int(m.group(1), 16)
            new = "Msg0716_PostSysEx50_%02X" % cmd
            built[n] = new[len("Msg0716_"):]
            rows.append((n, new, "%s: posts F0 50 %02X ... to CPU 2 -- a system-exclusive message, manufacturer ID 0x50 (Matsushita),\\n"
                         "  command 0x%02X, whose meaning is not established here (notes/prom_a_msg0716_message_names.py)." % (new, cmd, cmd)))
    for n, b in labels.items():
        if not re.match(r'^sub_FC0[0-9A-F]{3}$', n):
            continue
        t = " | ".join(b)
        m = re.match(r'^ld A,\(XIZ\+0x06\) \| ld \(XIX\+0x01\),A \| calr (\w+) \| ret$', t)
        if m and m.group(1) in built:
            new = "Msg0716_Part" + built[m.group(1)]
            rows.append((n, new, "%s: a Msg0716 handler-table entry -- byte 1 = the object record's +6 (its number), then\\n"
                         "  Msg0716_%s (notes/prom_a_msg0716_message_names.py)." % (new, built[m.group(1)])))
    return rows


def main():
    rows = plan()
    names = [n for _o, n, _h in rows]
    taken = set(re.findall(r'[A-Za-z_][\w$]*', A))
    for o, n, h in rows:
        bad = names.count(n) > 1 or n in taken
        if "--args" in sys.argv:
            if not bad:
                print("%s=%s|%s" % (o, n, h))
        else:
            print("%-11s -> %s%s" % (o, n, "  WITHHELD" if bad else ""))
    if "--args" not in sys.argv:
        print("rename %d" % sum(1 for _o, n, _h in rows if not (names.count(n) > 1 or n in taken)))


if __name__ == "__main__":
    main()
