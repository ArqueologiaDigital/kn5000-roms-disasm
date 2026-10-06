#!/usr/bin/env python3
"""regenerate_v7_c_divergence.py -- recompute v7_c_divergence.json after the v7 C or link scripts change.

QUESTION IT ANSWERS
  v7_c_divergence.json records, per compiled-C bin, what the committed C does not yet reproduce of v7: pointer
  relocations (offset, delta) and raw bytes.  When the C or a link script becomes more v7-aware (for example
  generate_v7_naka_link_scripts.py), entries become wrong -- a relocation would now be applied to a pointer that
  is already right.  This script recomputes every entry:
    1. it copies the current FINAL v7 bins (the patched build products the byte gate certifies) aside;
    2. it recompiles each bin from its C (`make -B` on that bin's target only, which does not patch);
    3. per bin, an old relocation offset whose compiled word still differs keeps a relocation with the delta
       recomputed; one that now matches is dropped; every other differing byte becomes a raw byte;
    4. it writes the json, runs apply_v7_c_divergence.py, and asserts every bin equals its saved final copy.
  The ROM is never read: the reference is the build's own certified output, so the json only ever SHRINKS by
  what the source now explains.

RUN (repository root, built tree)
  python3 scripts/build/regenerate_v7_c_divergence.py            # report what would change
  python3 scripts/build/regenerate_v7_c_divergence.py --apply    # rewrite the json, re-patch, verify
"""
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GEN = os.path.join(REPO, "v7", "maincpu", "includes", "generated")
JSON = os.path.join(REPO, "v7", "maincpu", "includes", "v7_c_divergence.json")


def le32(b, o):
    return int.from_bytes(b[o:o + 4], "little")


def main():
    apply = "--apply" in sys.argv
    patch = json.load(open(JSON))
    with tempfile.TemporaryDirectory(dir=os.environ.get("TMPDIR")) as ref:
        for name in patch:
            shutil.copy2(os.path.join(GEN, name), os.path.join(ref, name))
        targets = ["v7/maincpu/includes/generated/" + n for n in patch]
        subprocess.run(["make", "-s", "-B"] + targets, cwd=REPO, check=True, stdout=subprocess.DEVNULL)
        new_patch, before, after = {}, 0, 0
        for name, ent in patch.items():
            final = open(os.path.join(ref, name), "rb").read()
            comp = bytearray(open(os.path.join(GEN, name), "rb").read())
            size = ent["size"]
            assert len(final) == size, (name, len(final), size)
            if len(comp) < size:
                comp.extend(b"\x00" * (size - len(comp)))
            del comp[size:]
            reloc, covered = [], set()
            for off, _ in ent.get("reloc", []):
                d = (le32(final, off) - le32(comp, off)) & 0xFFFFFFFF
                if d:
                    d = d - 0x100000000 if d & 0x80000000 else d
                    reloc.append([off, d])
                    covered.update(range(off, off + 4))
                    comp[off:off + 4] = le32(final, off).to_bytes(4, "little")
            raw = {str(i): final[i] for i in range(size) if comp[i] != final[i] and i not in covered}
            new_patch[name] = {"raw": raw, "reloc": reloc, "size": size}
            before += len(ent.get("reloc", [])) * 4 + len(ent.get("raw", {}))
            after += len(reloc) * 4 + len(raw)
            print("%-36s reloc %4d -> %4d   raw %4d -> %4d" % (name, len(ent.get("reloc", [])), len(reloc),
                                                             len(ent.get("raw", {})), len(raw)))
        print("patch bytes %d -> %d" % (before, after))
        if not apply:
            for name in patch:      # put the certified finals back
                shutil.copy2(os.path.join(ref, name), os.path.join(GEN, name))
            return
        tmp = JSON + ".tmp"
        open(tmp, "w").write(json.dumps(new_patch, separators=(",", ":"), sort_keys=True))   # the file's own format
        os.replace(tmp, JSON)
        subprocess.run([sys.executable, os.path.join(REPO, "scripts", "build", "apply_v7_c_divergence.py")],
                       cwd=REPO, check=True)
        bad = [n for n in patch if open(os.path.join(GEN, n), "rb").read() != open(os.path.join(ref, n), "rb").read()]
        assert not bad, "patched bins differ from the certified finals: %s" % bad
        for n in patch:
            assert open(os.path.join(GEN, n + ".patched")).read().strip() == \
                hashlib.sha256(open(os.path.join(GEN, n), "rb").read()).hexdigest()
        print("rewrote %s; every patched bin equals its certified final" % os.path.relpath(JSON, REPO))


if __name__ == "__main__":
    main()
