THE ANSWERS THE TOOL GAVE BEFORE THE WINDOW-TAIL GUARD.

  Frozen from notes/perf/baseline/ at commit a247c67, which is the last commit
  whose notes/reachability.py had no MAXLEN guard.  These five files are the
  PRE-GUARD side of the accounting: notes/perf/guard_accounting.py checks that
  its `MAXLEN = 0` walk reproduces them exactly, which is what makes it the same
  tool on both sides rather than a re-implementation.

  ⚠ DO NOT RE-RECORD THIS DIRECTORY.  notes/perf/baseline/ is the live one that
  prove_identical.py compares against and that moves with the tool.  This one is
  a historical record and only ever changes if it was copied wrong.

      prom_a reached 361,931 | .incbin 46,306 | reachable-and-unconverted 1,590
      prom_b reached 242,549 | .incbin 40,932 |                              80
      prom_c reached 216,419 | .incbin      0 |                               0
      TOTAL reachable-and-unconverted: STRONG 17 bytes, ANY 1,670, in 17 spans
