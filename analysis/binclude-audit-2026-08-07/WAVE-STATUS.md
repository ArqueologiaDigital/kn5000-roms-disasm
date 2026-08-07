# Wave status — autonomous run ledger

Standing authorization (Felipe, 2026-08-07): when a wave completes, start the
next one automatically; he is away for many hours. Scope: the disassembly and
documentation work of PLAN.md, heavily parallelized workflows, manager-integrated,
100% byte-match gate after every merge. Do not push any repo.

Update this file whenever a wave starts or finishes (one line each, newest last).

| when (UTC-3) | event |
|---|---|
| 2026-08-07 ~00:30 | Wave 0 launched (run wf_04bd6fdd-f77): p1 incbin boundary, p2 FDC dispatch tables, p3 SLIDE8K tooling, p4 docs errata, p5/p6/p7 tone database |
| 2026-08-07 03:09 | Wave 0 COMPLETE: 7/7 ready, 0 rejected. Commits 0494f44 (FDC dispatch tables), f79fcb1 (mid-instruction incbin fix), f95975b (tone database 0x830000-0x87FFEF symbolic, 2263 new symbols), f40a93d (SLIDE8K tooling), f7c34d9 + aad54ce (docs errata, both repos). Build 100.00% x15 incl. ASL. Notes: initial_data.bin kept whole on disk (ASL mirror needs it); llvm side uses offset,length incbin. SLIDE8K block 0 = stale corrupt German duplicate (preserved byte-exact). |
| 2026-08-07 03:10 | Wave 1 launching: A1-A5 bootcode disassembly (FDC driver + boot CP-serial + serial ISRs + malloc), B2 help-DB SLIDE8K round-trip + Makefile wiring + table-data-rom.md HELP rework, B3 subprogram compressed images (v142 rule, v140 preservation, v141 issue). |
