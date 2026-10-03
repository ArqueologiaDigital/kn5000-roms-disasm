#!/usr/bin/env python3
"""Give the SOUND EDIT screens (screen codes 0x80-0x9F and 0xCD) names from the text their pages draw.

QUESTION IT ANSWERS
  The tree spells these screens by number: ScreenEnter_SoundEditPitchTune, ScreenLeave_SoundEditPitchTune,
  ScreenButton_SoundEditPitchTune, SoftKeyCol1_ScreenCode87, ScreenCode87_Paint ...  A screen's code is both its
  PanelScreen_VtableTable ViewB index and the selector its paints go through (Dispatch_Code80 /
  _Bracketed; FINDINGS-l7a1429-editor-pages.md 2c: codes 0xC0+k reuse entry 0xA0+k).  So the text
  DispatchTable_F5B8F8[code] draws IS the screen's identity.  The strings below were read out of the
  display lists each full paint runs (header + page lists), and the shared PARTIAL-repaint routines
  (DispatchTable_F5B9F8) corroborate the groups:
    0x8A shares its field repaint with 0x8F and 0x99 (the AMPLITUDE and FILTER LFO pages) -> PITCH LFO;
    0x88 / 0x97 share one (envelope page 1), 0x89 / 0x98 another (envelope page 2), 0x8C / 0x96 a third
    (page 2/2, KEY FOLLOW).
  Renamed, for each code: ScreenCode<XX>_Handler -> ScreenEnter_<Name>, ScreenLeave_Code<XX> ->
  ScreenLeave_<Name>, ScreenButton_Code<XX> -> ScreenButton_<Name>, <Control>_ScreenCode<XX> ->
  <Control>_<Name>, ScreenCode<XX>_Paint / _RepaintField -> <Name>_Paint / _RepaintField; a repaint
  shared by several codes takes the group name in SHARED.  Codes not in SCREENS are left alone
  (0x81, 0x9C, 0xA0-0xBF, and 0xC0-0xCF except 0xCD).

RUN
  python3 notes/prom_ab_sound_edit_screen_names.py          # the plan
  python3 notes/prom_ab_sound_edit_screen_names.py --args   # 'old=new|header' for the rename helper
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# code -> (name, the strings that name it)
SCREENS = {
    0x80: ("SoundEditMenu", "SOUND EDIT / WRITE COPY; TONE LAYER, DSP EFFECT, PITCH, DIGITAL EFFECT, FILTER, CONTROLLER, AMPLITUDE"),
    0x82: ("SoundEditModelingToneTemplate", "M0DELING SOUND EDIT; TONE TEMPLATE / LEVEL / KEY / TUNE"),
    0x83: ("SoundEditToneLayerPanning", "T0NE LAYER SOUND EDIT (TRIGGER / KEY LAYER / VEL LAYER); PANNING"),
    0x84: ("SoundEditToneLayerKeyLayer", "T0NE LAYER SOUND EDIT; KEY LAYER 0..6"),
    0x85: ("SoundEditToneLayerVelocityLayer", "T0NE LAYER SOUND EDIT; VELOCITY LAYER 0 32 64 96 127"),
    0x86: ("SoundEditModelingDriverWaveform", "M0DELING SOUND EDIT; DRIVER WAVEFORM / VELOCITY / CURS0R"),
    0x87: ("SoundEditPitchTune", "PITCH SOUND EDIT (ENV / PITCH LF0); KEY DE-TONE, KEY SCALING, SHIFT, TUNE, SCALE, OCT-SHIFT"),
    0x88: ("SoundEditPitchEnvelope1", "PITCH SOUND EDIT; START PITCH, STOP PITCH, TOTAL DEPTH; PAGE1/2 ENVELOPE KEYOFF ATK"),
    0x89: ("SoundEditPitchEnvelope2", "PITCH SOUND EDIT; PAGE2/2 KEY FOLLOW"),
    0x8A: ("SoundEditPitchLfo", "PITCH SOUND EDIT header only; its field repaint is the LFO one 0x8F and 0x99 use"),
    0x8B: ("SoundEditAmpLevel1", "AMPLITUDE SOUND EDIT (ENV / AMP / LF0); PAGE1/2 LEVEL, TOUCH CURVE"),
    0x8C: ("SoundEditAmpLevel2", "AMPLITUDE SOUND EDIT; PAGE2/2 KEY FOLLOW"),
    0x8D: ("SoundEditAmpEnvelope1", "AMPLITUDE SOUND EDIT; ENVELOPE KEYOFF ATK PEAK DECAY1 SUST1 DECAY2 SUST2, PAGE1/2"),
    0x8E: ("SoundEditAmpEnvelope2", "AMPLITUDE SOUND EDIT; PAGE2/2 KEY FOLLOW ( ENVELOPE / TOUCH ATTACK )"),
    0x8F: ("SoundEditAmpLfo", "AMPLITUDE SOUND EDIT; LF01 LF02 LF03 LF04, LF0 WAVE, DELAY, SPEED"),
    0x90: ("SoundEditFilterLpf12", "FILTER SOUND EDIT; FILTER: CUTOFF / EQUALIZER FREQ; LOW PASS -12dB; PAGE1/2"),
    0x91: ("SoundEditFilterHpf12", "FILTER SOUND EDIT; HIGH PASS -12dB; PAGE1/2"),
    0x92: ("SoundEditFilterLpf24", "FILTER SOUND EDIT; FILTER CUTOFF / RESO / TOUCH CURVE; LOW PASS -24dB; PAGE1/2"),
    0x93: ("SoundEditFilterHpf24", "FILTER SOUND EDIT; HIGH PASS -24dB; PAGE1/2"),
    0x94: ("SoundEditFilterBpf", "FILTER SOUND EDIT; FILTER: BAND PASS, LOW ~ HIGH CUTOFF; PAGE1/2"),
    0x95: ("SoundEditFilterThrough", "FILTER SOUND EDIT; THROUGH; PAGE1/2"),
    0x96: ("SoundEditFilterKeyFollow", "FILTER SOUND EDIT; PAGE2/2 KEY FOLLOW, FILTER KEY FOLLOW"),
    0x97: ("SoundEditFilterEnvelope1", "FILTER SOUND EDIT; START POINT, STOP POINT, CUTOFF ADJUST"),
    0x98: ("SoundEditFilterEnvelope2", "FILTER SOUND EDIT header only; its field repaint is the envelope-page-2 one 0x89 uses"),
    0x99: ("SoundEditFilterLfo", "FILTER SOUND EDIT; LF01 LF02 LF03 LF04, LF0 WAVE, DELAY, SPEED"),
    0x9A: ("SoundEditDigitalEffect", "the DIGITAL EFFECT page (SoundEditDigitalEffect_Paint, already so named)"),
    0x9B: ("SoundEditControllerPage2", "C0NTR0LLER SOUND EDIT; PAGE2/2 AFTER TOUCH, CTRL PEDAL (SoundEditController_PaintPage2)"),
    0x9C: ("SoundEditDigitalEffectFromMenu", "no paint of its own (DispatchTable_F5B8F8[0x9C] is the default `ret`): its ENTER calls\n"
           "ScreenEnter_SoundEditDigitalEffect, which paints page 0x9A, then sends ToneMsg80_Id00(0x10); it shares 0x9A's button\n"
           "table PanelOpTable_FCFBFC and leave body; LcdKeyRow3_SoundEditMenu requests it (2026-10-04)"),
    0x9D: ("SoundEditCopy", "the COPY page (SoundEditCopy_Paint, already so named)"),
    0x9E: ("SoundEditMemoryWrite", "MEM0RY WRITE SOUND EDIT; NAME, MEMORY BANK"),
    0x9F: ("SoundEditNaming", "SOUND NAMING; WRITE"),
    0xCB: ("SoundEditDrumMenu", "SOUND EDIT / WRITE COPY; EFFECT SEND & OUTPUT, DSP EFFECT, KIT PARAMETER, FILTER, CONTROLLER, DRUM SOUND\n"
           "NAMING, NOTE (repaint entry 0xAB, SoundEditDrumMenu_Paint)"),
    0xCD: ("SoundEditControllerPage1", "C0NTR0LLER SOUND EDIT; PAGE1/2 (repaint entry 0xAD = SoundEditController_PaintPage1)"),
}
SHARED = {  # partial repaints several codes use
    "SoundEditLfo_RepaintField": "SoundEditLfo_RepaintField",
    "SoundEditEnvelope1_RepaintField": "SoundEditEnvelope1_RepaintField",
    "SoundEditEnvelope2_RepaintField": "SoundEditEnvelope2_RepaintField",
    "SoundEditKeyFollow_RepaintField": "SoundEditKeyFollow_RepaintField",
}
# screens 0xC0+k paint through entry 0xA0+k; prom_a already calls 0xC3-0xC7 ToneEditPage_A3..A7, so
# 0xC0/0xC1/0xC2/0xC8 join that family (entries A0 MODELING top, A1 TONE TEMPLATE, A2 DRIVER WAVEFORM,
# A8 SERIAL / PARALLEL), and the drum menu's entry-0xAB paints take its name (2026-10-04)
EXPLICIT = {
    "ToneEditPage_A0_ModelingTop": "ToneEditPage_A0_ModelingTop",
    "ToneEditPage_A0_Leave": "ToneEditPage_A0_Leave",
    "ToneEditPage_A1_Leave": "ToneEditPage_A1_Leave",
    "ToneEditPage_A2_Leave": "ToneEditPage_A2_Leave",
    "ToneEditPage_A8_SerialParallel": "ToneEditPage_A8_SerialParallel",
    "ToneEditPage_A8_Leave": "ToneEditPage_A8_Leave",
    "ToneEditPage_A8_RepaintField": "ToneEditPage_A8_RepaintField",
    "SoundEditDrumMenu_Paint": "SoundEditDrumMenu_Paint",
    "SoundEditDrumMenu_RepaintField": "SoundEditDrumMenu_RepaintField",
}
FILES = [os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")]


def plan():
    text = "\n".join(open(p, "rb").read().decode("latin-1") for p in FILES)
    labels = set(re.findall(r'^([A-Za-z_][\w$]*):', text, re.M))
    rows = []
    for lab in sorted(labels):
        new = SHARED.get(lab) or EXPLICIT.get(lab)
        m = (re.match(r'^ScreenCode([0-9A-F]{2})_Handler$', lab) or re.match(r'^ScreenLeave_Code([0-9A-F]{2})$', lab)
             or re.match(r'^ScreenButton_Code([0-9A-F]{2})$', lab) or re.match(r'^(\w+)_ScreenCode([0-9A-F]{2})$', lab)
             or re.match(r'^ScreenCode([0-9A-F]{2})_(Paint|RepaintField)$', lab))
        if new is None and m:
            g = m.groups()
            code = int(re.search(r'Code([0-9A-F]{2})', lab).group(1), 16)
            if code not in SCREENS:
                continue
            nm = SCREENS[code][0]
            if lab.endswith("_Handler"):
                new = "ScreenEnter_" + nm
            elif lab.startswith("ScreenLeave_"):
                new = "ScreenLeave_" + nm
            elif lab.startswith("ScreenButton_"):
                new = "ScreenButton_" + nm
            elif re.match(r'^\w+_ScreenCode[0-9A-F]{2}$', lab):
                new = "%s_%s" % (g[0], nm)
            else:
                new = "%s_%s" % (nm, g[1])
        if new and new != lab:
            rows.append((lab, new))
    return rows


def main():
    rows = plan()
    names = [n for _o, n in rows]
    dup = {n for n in names if names.count(n) > 1}
    for o, n in rows:
        if "--args" in sys.argv:
            if n not in dup:
                print("%s=%s" % (o, n))
        else:
            print("%-36s -> %s%s" % (o, n, "  DUPLICATE" if n in dup else ""))
    if "--args" not in sys.argv:
        print("renames %d, duplicates %d" % (len(rows), len(dup)))


if __name__ == "__main__":
    main()
