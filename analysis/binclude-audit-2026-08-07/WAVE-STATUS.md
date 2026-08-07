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
| 2026-08-07 04:11 | Wave 1 COMPLETE: 6/7 landed, build 100.00% x15 (now incl. the new v142 update-image section). Commits 22ecfb5 (hdae boot-flash tail), 670077e (boot clib: malloc/free w/ coalescing, div runtime), 72242c0 (disk probe + boot CP-serial), 65c79cb (boot FDC driver, 84 labels, uPD72068/IC208), 2fb8a95 (v142 update image compress rule + --with-header flag; v140 payload PRESERVED sha256 a39025fe...), 2011518 (SLIDE8K help DBs source-built, make verify-help-databases 6/6 OK), 1228b72 (kn5000-docs Help System rework). Issue kn5000-v41 filed. a4-serial-pair WORKER DIED (API stall, no work delivered) -> retried in Wave 2. Deferred follow-ups for later: FDC_Seek repo-wide rename, fdc-subsystem.md PIO +2 quirk, cross-ROM 0x986000/0x987000 symbolic refs, TOOLCHAIN_VERSION mismatch note. Beads-daemon caveat moot (beads decommissioned 2026-07-27; issues.jsonl is edited directly). |
| 2026-08-07 04:12 | Wave 2 launching: table_data conversion (fonts, style records, TG config + 0x9C0000 region, preset banks left half, wallpaper/icons, gap trivia) + a4-serial-pair RETRY. Help index/strings + tone DB already landed in Waves 0/1 - skipped. |
| 2026-08-07 04:38 | Wave 2 INTERRUPTED by session usage limit (reset 06:40 London): w2-fonts, w2-preset-banks, w2-trivia ready in scratch; w2-style-records, w2-tgconfig-tail, w2-wallpaper-icons, w2-followups, a4-serial-pair-retry and the MANAGER never ran. Nothing integrated, repo untouched since Wave 1. |
| 2026-08-07 06:51 | Wave 2 RESUMED (resumeFromRunId wf_97096d8d-f57): 3 ready workers replay from cache, 5 workers + manager run live. |
