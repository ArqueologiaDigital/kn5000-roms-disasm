# hdae5000/tools/

Scripts scoped to the single HD-AE5000 image (`hd-ae5000_v2_06i.ic4`). Each answers one question;
run each with no arguments (or `-h`-shaped usage on error) to see it, or read its own docstring.

- **`measure_debt.py`** -- how many bytes of the 524,288 B ROM are NOT reproduced by real source
  (raw `.incbin`, or bare undocumented `.byte`/`.word`), vs. documented-but-untyped, vs. real
  source? This is the lane's headline debt number.
  ```
  python3 hdae5000/tools/measure_debt.py
  python3 hdae5000/tools/measure_debt.py --list-debt   # also print every debt line
  ```

- **`get_lprobe_addrs.py`** -- what is the REAL, linked ROM address of line N of a given
  `hdae5000/*.s` file? Clones `hdae5000/`, labels every source line, rebuilds, confirms the build
  is still byte-identical to the original dump, and reads the addresses back from the ELF symbol
  table -- ground truth from the pinned assembler itself, not a hand-rolled parser.
  ```
  python3 hdae5000/tools/get_lprobe_addrs.py > /tmp/lprobe.txt                        # data_tables
  python3 hdae5000/tools/get_lprobe_addrs.py hdae5000_utilities.s > /tmp/lprobe_u.txt # another file
  ```

- **`alignment_evidence.py`** -- is a lone `.byte 0x00` at an odd address before a string really
  word-alignment padding, or could it be a coincidental zero-valued field? Prints the file-wide
  `.asciz`/`.ascii`/`.long`/`.zero` alignment statistics, classifies every odd-address bare
  `.byte 0x00` by what follows it, and independently cross-checks two pre-existing offset anchors
  (added by an earlier pass for an unrelated reason) against the real assembled address, tens of
  thousands of bytes apart. Read-only; every count/anchor asserts it examined something real
  (guards against a vacuous pass). See
  `notes/hdae5000-lane-2026-09-02-alignment-padding.md` for the argument this evidence supports.
  ```
  python3 hdae5000/tools/get_lprobe_addrs.py > /tmp/lprobe.txt
  python3 hdae5000/tools/alignment_evidence.py /tmp/lprobe.txt
  ```

- **`convert_align_pads.py`** -- applies the claim `alignment_evidence.py` supports: converts a
  bare, undocumented `.byte 0x00` at a proven odd address, immediately before an `.asciz`/`.ascii`,
  into an explicit `.balign 2, 0x00`. Deliberately narrower than the evidence would statistically
  allow (skips bytes before `.zero`, which is not reliably aligned, and bytes before another bare
  `.byte`, which could be a genuine field). Mutates the file only with `--apply`.
  ```
  python3 hdae5000/tools/get_lprobe_addrs.py > /tmp/lprobe.txt
  python3 hdae5000/tools/convert_align_pads.py /tmp/lprobe.txt hdae5000/hdae5000_data_tables.s            # dry run
  python3 hdae5000/tools/convert_align_pads.py /tmp/lprobe.txt hdae5000/hdae5000_data_tables.s --apply    # write
  ```
  After running with `--apply`, always rebuild and diff against the dump before trusting the
  result:
  ```
  make rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom
  cmp rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom original_ROMs/hd-ae5000_v2_06i.ic4
  ```
