# (superseded) — see FINDINGS-system-clock.md

This file was the first write-up of the 28 MHz derivation. Its **conclusion was
right and its supporting argument had four errors**, so it has been replaced
rather than patched, and the replacement carries the corrections explicitly:

* it called MAME's `tmp94c241_serial.cpp` "the real implementation" and the
  other two TLCS-900 files wrong. Those tap constants are this project's own
  earlier databook reading (MAME PR #13220), not an independent authority. The
  ROM adjudicates instead, through an fc-independent ratio;
* it credited the /16 end-to-end validation to "the KN5000 control-panel link".
  Wrong channel — that link is on the *main* CPU's SC1 and is not a 31250-baud
  UART. The cited registers are the *sub* CPU's, and that port really is MIDI,
  so the validation stands but the sentence did not;
* it said a ×2 error in the prescaler chain was "closed by the parts list". A
  parts list cannot exclude an internal clock doubler;
* it read the service manual as "agrees exactly, /1". The manual never ties any
  oscillator to either processor, it lists six of them, and one of the six is a
  24 MHz part of the same family that fits the ÷768 boot writes exactly.

It also under-weighted the tempo constant: that lever is primary, not a
tie-breaker, and there is now a stronger one still — prom_c's byte at 0xFFFFEF
states fc in MHz.

**Read `notes/FINDINGS-system-clock.md`.**
