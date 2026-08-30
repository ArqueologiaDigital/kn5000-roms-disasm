#!/usr/bin/env python3
"""Is the WSA1's shared kernel ALSO in the KN5000? A three-way byte comparison.

QUESTION IT ANSWERS
    "prom_a and prom_c run the same kernel -- 36 routine pairs, 35 structurally
     identical to the byte. Do those same bytes appear in the KN5000's images?"

    If yes, one body of code is shared by THREE processors across TWO instruments,
    and it is the natural first place to make the two disassembly trees converge:
    a single source included by all three, rather than three transcriptions that
    happen to agree.

METHOD, and why it is a byte test and not a name test
    Take each kernel routine's bytes straight from WSA1 prom_c, and search every
    KN5000 image for that exact run. No labels, no heuristics, no address
    arithmetic -- the failure mode this project has repeatedly paid for is a
    cross-tree claim resting on a name or an offset constant, so this rests on
    neither.
    ⚠ A short run can match by chance. Runs under MIN_RUN are reported separately
    and are not counted as evidence.

RUN
    python3 notes/kernel_three_way.py
    python3 notes/kernel_three_way.py --selftest
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KN = "/home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs"
MIN_RUN = 24          # below this a match is not evidence


def wsa1_prom_c():
    return open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()


def kn_images():
    out = {}
    for f in sorted(os.listdir(KN)):
        p = os.path.join(KN, f)
        if os.path.isfile(p) and os.path.getsize(p) > 4096:
            out[f] = open(p, "rb").read()
    return out


# ⚠⚠ REPOINTED 2026-08-30, AND IT FIXES A DEFECT THAT WAS BEING READ AS A RESULT.
# These three helpers used to read prom_c/wsa1_prom_c.s.  Two things changed:
#
#   1. prom_c no longer writes the kernel out -- it `.include`s kernel/kernel.s,
#      the ONE source both CPUs share -- so reading prom_c found 35 marked
#      routines where it used to find 93.
#   2. ★ MORE IMPORTANTLY, extent() below wants the instruction's HEX BYTES after
#      the address, and PROM_C NEVER WROTE ANY.  Its line shape is
#      `<asm> ; ADDR <MAME text>`; only prom_a carries hex.  So extent() returned
#      None for nearly every routine, which is why this tool reported "32 too
#      short to count (<24 B)" and its own docstring calls the test underpowered.
#      The shared file carries BOTH addresses AND the bytes, so the extents are
#      real now.  The `<24 B` misses that remain are genuinely short routines.
#
# ⚠ The line shape here is a THIRD one: `; AAAAAA/CCCCCC  <bytes>` for a slot the
#   two CPUs agree on and `; AAAAAA/CCCCCC  a=<bytes> c=<bytes>` for one they do
#   not.  A is prom_a's address, C is prom_c's, and this file works in prom_c's.
KSRC = os.path.join("kernel", "kernel.s")
KADDR = r';\s*[0-9A-F]{6}/([0-9A-F]{6})\s+(?:a=)?((?:[0-9a-f]{2} )*[0-9a-f]{2})'


def kernel_routines():
    """The kernel block's routines, read from the SHARED kernel source: every
    label whose header this tree marked as a kernel pair."""
    src = open(os.path.join(ROOT, KSRC)).read()
    out = []
    for m in re.finditer(r'^([A-Za-z_][A-Za-z0-9_]*):.*?\n', src, re.M):
        name = m.group(1)
        if name.startswith("Kernel_") or name.startswith("INTT") or "_Kernel" in name:
            out.append(name)
    return sorted(set(out))


def addr_of(name):
    src = open(os.path.join(ROOT, KSRC)).read()
    m = re.search(r'^%s:.*\n(?:.*\n)*?\t\S.*?;\s*[0-9A-F]{6}/([0-9A-F]{6})\s'
                  % re.escape(name), src, re.M)
    return int(m.group(1), 16) if m else None


def extent(name):
    """[start, end) of the routine: from its label's first instruction to the
    next top-level label."""
    lines = open(os.path.join(ROOT, KSRC)).read().split("\n")
    i = next((k for k, l in enumerate(lines) if l.startswith(name + ":")), None)
    if i is None:
        return None
    lo = hi = None
    for l in lines[i + 1:]:
        # ⚠ a label here does NOT always start the next routine: the shared file
        # emits prom_c's name and prom_a's name for the same address on
        # consecutive lines.  Stop only once this routine has produced a byte.
        if re.match(r'^[A-Za-z_.][A-Za-z0-9_.]*:', l):
            if lo is not None:
                break
            continue
        m = re.search(KADDR, l)
        if m:
            a = int(m.group(1), 16)
            n = len(m.group(2).split())
            if lo is None:
                lo = a
            hi = a + n
    return (lo, hi) if lo is not None else None


def main():
    d = wsa1_prom_c()
    imgs = kn_images()
    names = kernel_routines()
    print("KN5000 images searched: %s" % ", ".join(sorted(imgs)))
    print("WSA1 prom_c kernel-marked routines found: %d\n" % len(names))
    hit = miss = short = 0
    for name in names:
        e = extent(name)
        if not e or e[1] is None:
            continue
        lo, hi = e
        blob = d[lo - 0xF80000:hi - 0xF80000]
        if len(blob) < MIN_RUN:
            short += 1
            continue
        where = [(f, im.find(blob)) for f, im in imgs.items() if im.find(blob) >= 0]
        if where:
            hit += 1
            print("  ★ %-38s %4d B  -> %s @ 0x%05X"
                  % (name, len(blob), where[0][0], where[0][1]))
        else:
            miss += 1
    print("\n%d kernel routines found in a KN5000 image, %d not, %d too short to count (<%d B)"
          % (hit, miss, short, MIN_RUN))
    if hit:
        print("★ A body of code shared by THREE processors across TWO instruments.")
    else:
        print("★ NO kernel routine appears in any KN5000 image. The trees share the")
        print("  sub-CPU payload but NOT this kernel, and that is a real answer.")


def selftest():
    ok = fail = 0

    def check(desc, cond, extra=""):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc + (("   " + extra) if extra else ""))
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    imgs = kn_images()
    check("KN5000 images are readable", len(imgs) > 0, "%d" % len(imgs))
    d = wsa1_prom_c()
    check("WSA1 prom_c is 512 KiB", len(d) == 0x80000)
    # a NEGATIVE CONTROL: a random 32-byte run should not appear in KN5000
    import hashlib
    probe = hashlib.sha256(b"negative-control").digest()[:32]
    check("a synthetic 32-byte run appears in NO KN5000 image",
          not any(probe in im for im in imgs.values()))
    # and a POSITIVE control: the shared payload the tree already measured
    shared = d[0xFDE32B - 0xF80000:0xFDE32B - 0xF80000 + 64]
    found = any(shared in im for im in imgs.values())
    check("the ALREADY-MEASURED shared run at 0xFDE32B is found in a KN5000 image",
          found, "this is what makes a miss elsewhere meaningful")
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv else (main() or 0))
