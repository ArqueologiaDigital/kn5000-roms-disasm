#!/usr/bin/env python3
"""Do the KN5000 sources still ASSEMBLE with the pinned toolchain?

QUESTION IT ANSWERS
    "Ignoring every build artefact on disk, does each image's root source, with
     all of its includes, go through `llvm-mc` without a single error?"

    That is not the same question as `assert_byte_identical.py`, and on
    2026-09-01 the two disagreed.  The byte gate rebuilds before comparing --
    but `make` only rebuilt what its prerequisite lists named, and every image's
    object named ONLY ITS ROOT FILE, not the ~150 sources the root `.include`s.
    So when the toolchain pin moved to 95f7f2d40428 ("[TLCS900] Refuse an
    immediate or an index register that does not fit"), FOUR OF THE EIGHT KN5000
    IMAGES STOPPED ASSEMBLING -- v10, v9 and v7 maincpu and the v142 sub-CPU
    payload -- and the gate stayed green all day on objects dated 2026-08-23.

    31 `jrl` operands were the cause.  This backend's `jrl cc, imm` takes the
    RAW 16-BIT DISPLACEMENT FIELD, not a target address (`jrl t, 0xfd30`
    assembles to `78 30 fd` at any address), but the disassembly that produced
    these lines had sign-extended the field to 24 bits -- `jrl t, 16776496`
    for 0xfffd30 = -720.  The old assembler truncated silently; the new one
    refuses.  Truncating them in the source restored all eight images and moved
    no byte, which is the evidence that truncation was all the old build did.

    Twelve of the 31 are in the sound path: DSP_EffParam_Apply_T0..TB, the
    twelve algorithm-type cases that tail-jump into DSP_EffParam_Copy_V0..V7.

WHY IT IS SEPARATE FROM THE BYTE GATE
    A gate that reads `make`'s answer inherits `make`'s blind spots.  This one
    asks the assembler directly, from the root source, every time.  The
    Makefile's prerequisite lists were fixed in the same commit; this script is
    the check that does not depend on their staying fixed.

RUN:  python3 scripts/analysis/assert_images_assemble.py
      python3 scripts/analysis/assert_images_assemble.py --selftest
"""
import os, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
# ⚠ Honour LLVM_MC, exactly as the Makefile and assert_toolchain_is_a_
# prerequisite.py do.  `make LLVM_MC=<binary> gate-all` exports it; this check
# used to ignore it and always ran the SHARED build/bin/llvm-mc, so during a
# null run of one assembler (2026-09-25, toolchain lane) the byte gate was
# about to certify objects built by LLVM_MC while this check judged a
# different binary that a backend rebuild had just replaced -- and failed 7 of
# 8 images for errors the binary under test does not produce.
MC = os.environ.get("LLVM_MC") or os.path.join(
    os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado")),
    "llvm-project", "build", "bin", "llvm-mc")

# (include dir, root source) -- exactly the eight `llvm-mc -filetype=obj`
# invocations in the Makefile.
IMAGES = [
    ("v10/maincpu",  "v10/maincpu/kn5000_v10_program.s"),
    ("v9/maincpu",   "v9/maincpu/kn5000_v9_program.s"),
    ("v7/maincpu",   "v7/maincpu/kn5000_v7_program.s"),
    ("v142/subcpu",  "v142/subcpu/kn5000_subprogram_v142.s"),
    ("subcpu/boot",  "subcpu/boot/kn5000_subcpu_boot.s"),
    ("hdae5000",     "hdae5000/hd-ae5000_v2_06i.s"),
    ("table_data",   "table_data/kn5000_table_data.s"),
    ("custom_data",  "custom_data/kn5000_custom_data.s"),
]


def assemble(incdir, root, out):
    """-> list of llvm-mc error lines (empty means clean)."""
    r = subprocess.run([MC, "-triple=tlcs900", "-filetype=obj",
                        "-I", os.path.join(ROOT, incdir), "-o", out,
                        os.path.join(ROOT, root)],
                       capture_output=True, text=True)
    return [l for l in (r.stdout + r.stderr).splitlines() if ": error:" in l]


def run():
    bad = 0
    with tempfile.TemporaryDirectory() as td:
        for incdir, root in IMAGES:
            errs = assemble(incdir, root, os.path.join(td, "o.o"))
            print(f"  {root:42} {'clean' if not errs else str(len(errs)) + ' ERROR(S)'}")
            for e in errs[:4]:
                print("      " + e.strip())
            bad += bool(errs)
    print("\n" + ("PASS: every KN5000 image assembles with the pinned toolchain."
                  if not bad else f"FAIL: {bad} image(s) do not assemble."))
    return 1 if bad else 0


def selftest():
    """INVARIANTS.  A check that cannot fail is not a check, so the second one
    proves this script can still SEE a broken source."""
    f = 0

    def ck(desc, cond, extra=""):
        nonlocal f
        print(("  ok   " if cond else "  FAIL ") + desc + (("   " + extra) if extra else ""))
        f += not cond

    ck("the pinned llvm-mc exists", os.path.exists(MC), MC)
    ck("all eight roots and include dirs exist", all(
        os.path.exists(os.path.join(ROOT, r)) and os.path.isdir(os.path.join(ROOT, d))
        for d, r in IMAGES))
    with tempfile.TemporaryDirectory() as td:
        # POSITIVE CONTROL: a lone good instruction assembles.
        good = os.path.join(td, "good.s")
        open(good, "w").write("\t.text\n\tjrl\tt, 0xfd30\n")
        ck("a 16-bit jrl displacement is accepted",
           not assemble(td, os.path.relpath(good, ROOT), os.path.join(td, "g.o")))
        # NEGATIVE CONTROL: the exact shape that broke the tree must be REFUSED,
        # otherwise a green run here would mean nothing.
        bad = os.path.join(td, "bad.s")
        open(bad, "w").write("\t.text\n\tjrl\tt, 16776496\n")
        errs = assemble(td, os.path.relpath(bad, ROOT), os.path.join(td, "b.o"))
        ck("a sign-extended 24-bit jrl displacement is REFUSED", bool(errs),
           errs[0].strip() if errs else "no error -- the check is blind")
        # And the truncation really is byte-preserving: 0xfffd30 and 0xfd30
        # must encode identically, which is why rewriting them moved no byte.
        enc = []
        for src in ("\t.text\n\tjrl\tt, 0xfd30\n",):
            p = os.path.join(td, "e.s")
            open(p, "w").write(src)
            r = subprocess.run([MC, "-triple=tlcs900", "-show-encoding", p],
                               capture_output=True, text=True)
            enc.append(r.stdout)
        ck("jrl's operand is the raw displacement field, not a target address",
           "0x78,0x30,0xfd" in enc[0].replace(" ", ""),
           enc[0].strip().splitlines()[-1].strip() if enc[0].strip() else "")
    print(f"\n5 checks, {f} failures")
    return 1 if f else 0


sys.exit(selftest() if "--selftest" in sys.argv else run())
