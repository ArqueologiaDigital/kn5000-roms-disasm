# dsp/tools

Scripts behind the KN5000 effects-DSP (uPD6383 / IC311) analysis. One line each: the question it
answers, and how to run it. Run from the repo root.

⚠ Three of these were rescued on 2026-08-14 from `KN7000/tmp-dir/`, an untracked scratch directory,
where they were the only copies of themselves despite being the stated evidence for published
claims. They are listed first, with their status **as re-run on the day of the rescue**.

| script | question it answers | status |
|---|---|---|
| `sqcensus.py` | which class-A multiplies **square their own coefficient**? (coef port = C-RAM[cursor] *and* operand L = C-RAM[cursor], i.e. `SRC == 0x08`) | ✅ runs — `f31 of non-sq classA: {1: 523, 0: 202, 4: 16, 2: 21}`, `f98 of squarers: {0: 79, 2: 2}` |
| `sq_ladder_226.py` | the fixed-point arithmetic of the kernel ladder and its dependence on the cursor base, computed **from disk** (no emulator run) | ✅ runs — e.g. `C-RAM[0x00] = 000072 = 114` (CHORUS LFO increment) |
| `h0_verify_effectchipmap.py` | the **gate-H0 table**: UI effect name → slot → chip → image hash, with a self-test. Produced the "12 of 12 named effects are stubs" confirmation | ❌ **ROTTED — see below** |

## h0_verify_effectchipmap.py is currently broken

It parses `v10/maincpu/ui_widgets/naka_widget_descriptors.c` for a `.ptrs_0` array to recover the
widget-name ordering:

```python
ORDER = [int(x) for x in re.findall(r"SELF\(str_(\d+)\)",
         re.search(r"\.ptrs_0\s*=\s*\{(.*?)\}", src, re.S).group(1))]
```

That field **no longer exists** — the descriptor file's arrays now start at `.ptrs_1`
(`grep -c 'ptrs_0'` returns 0), so `re.search` returns `None` and the script dies with
`AttributeError` before producing anything.

**It has deliberately not been "fixed" by nudging the index**, because which array it reads decides
the whole name→slot mapping, and a silently wrong mapping would produce a plausible but wrong
gate-H0 table — worse than no table. Whoever repairs it must establish *from the descriptor
structure* which array is the widget-name pointer list, and re-run the script's own self-test.

**Consequence to state plainly: the gate-H0 table and the "12 of 12 effects are stubs" figure are
currently unreproducible.** The claim may well be right — it was measured once — but nothing on
disk can re-derive it today.
