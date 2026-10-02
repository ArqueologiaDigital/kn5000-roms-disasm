# Data decoded as instructions, back to bytes (2026-10-02)

Tool: `scripts/converters/data_as_code_to_bytes.py --image <v> [--apply] [--report OUT]`;
`report_<tree>.json` lists each span, its label, how the label is used, and the markers.

Applied: v10 12 spans, v9 13, v7 14 -- the four AccPart_VoiceParamOffsets_* tables and the
eight TempoScale_* tables (sequencer/accompaniment_engine.s), reached only through `.long`
pointer tables, whose decode held normal / max / halt / swi.

Two drafts were narrower than they looked and were tightened before applying:
* operand uses were first allowed: `lda xix, (ExtData_ToneParam_AltBody_Code:24)` heads a
  table of real `jr` / `jrl` vectors, so an operand-only label is not data;
* reti / ei / di were first markers: INT0_HANDLER, INT5_HANDLER, INTT2_HANDLER and
  Empty_Handler are reached only through the vector table and end in reti.
