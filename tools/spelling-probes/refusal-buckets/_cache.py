#!/usr/bin/env python3
"""Decode caches for the refusal-bucket probe.

QUESTION ANSWERED: none on its own. It is the piece `classify.py` needs.

Two caches, both keyed by TARGET ADDRESS, both TOPPED UP rather than rebuilt
(so switching between the seed and the closure target list costs only the
addresses not seen yet), and both FINGERPRINTED against the tree they describe:

  `load()`      what the CONVERTER sees -- `crr.decode_range()`'s output, which
                stops at the first `db` or terminator.
  `load_raw()`  the FULL unidasm listing of each target's run, `db` lines
                included, plus the run length. The converter's decode cannot say
                WHY it stopped; this can.

⚠ EVERY INPUT HERE MOVES, and it moved twice while this probe was being written.
`v7_branch_closure_targets.json` went 1,131 -> 1,109 entries in ten minutes;
then an `--apply` round landed and `v7_call_targets.json` went 687 -> 659, which
took bucket B1 from 200 ranges to 169 with no script changing. So:
  * `fingerprint()` hashes the ROM and the territory map; a cache built against
    a different fingerprint is DISCARDED, never silently reused;
  * `targets()` returns the file's sha256 and entry count, which `classify.py`
    prints in its header. A count in this probe's README without that triple
    beside it is a count about an unknown tree.

Both pickles are disposable (see `.gitignore`): delete to force a rebuild, about
20 s for the seed list and 40 s for the closure list -- one unidasm per target.
"""
import hashlib, json, os, pickle, subprocess, sys

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(HERE, "decodes.pkl")
RAW = os.path.join(HERE, "raw_listings.pkl")
FILES = {"seed": os.path.join(REPO, "analysis/v7-reachability/v7_call_targets.json"),
         "closure": os.path.join(REPO,
                                 "analysis/v7-reachability/v7_branch_closure_targets.json")}


def targets(which="seed"):
    """Return (sorted target list, provenance dict) for "seed" or "closure"."""
    path = FILES[which]
    raw = open(path, "rb").read()
    return (sorted(json.loads(raw)["targets"]),
            {"which": which, "file": os.path.relpath(path, REPO),
             "sha256": hashlib.sha256(raw).hexdigest()[:16],
             "count": len(json.loads(raw)["targets"])})


_TERR = None


def _terr(crr=None):
    global _TERR
    if _TERR is None:
        import importlib.util
        spec = importlib.util.spec_from_file_location(
            "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
        spans = importlib.util.module_from_spec(spec); spec.loader.exec_module(spans)
        _TERR = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
    return _TERR


def fingerprint():
    """What a cached decode DEPENDS ON: the ROM and the territory map.

    ⚠ THE TERRITORY MAP MOVES. It is derived from `v7/maincpu/*.s`, and every
    `--apply` round of the converter turns .byte runs into instructions, which
    changes both the run lengths `decode_range()` walks and the set of call
    targets that still land in DATA. Between two runs of this probe on
    2026-08-23 the seed list went 687 -> 659 entries and bucket B1 went 200 ->
    169 ranges, with no change to any script.

    A cache that quietly served the older decodes would make this probe report
    numbers about a tree that no longer exists -- so both pickles carry this
    fingerprint and are DISCARDED, not reused, when it moves. That is the
    difference between "measured, and the answer is X" and "could not measure".
    """
    t = _terr()
    rom = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
    h = hashlib.sha256()
    h.update(rom)
    h.update(bytes(t) if isinstance(t, (bytes, bytearray)) else bytes(bytearray(t)))
    code = sum(1 for x in t if x == 1)
    data = sum(1 for x in t if x == 2)
    return {"sha256": h.hexdigest()[:16], "code_bytes": code, "data_bytes": data,
            "head": subprocess.run(["git", "-C", REPO, "rev-parse", "--short", "HEAD"],
                                   capture_output=True, text=True).stdout.strip()}


def _open(path, fp):
    """Load `path` only if it was built against the same fingerprint."""
    if not os.path.exists(path):
        return {}
    blob = pickle.load(open(path, "rb"))
    if not isinstance(blob, dict) or blob.get("fp", {}).get("sha256") != fp["sha256"]:
        print(f"  cache {os.path.basename(path)} was built against a different tree "
              f"-- discarding", file=sys.stderr)
        return {}
    return blob["decodes"]


def load(crr, want, verbose=True):
    """{target: [(addr, nbytes, text), ...]} exactly as the converter decodes it.

    ⚠ The class-A sweep's committed `decodes.pkl` is NOT reused. It carries no
    fingerprint, so there is no way to tell which territory map it was built
    against, and it is now known to predate several `--apply` rounds. Reusing it
    would save 20 seconds and cost the ability to say what the numbers describe.
    """
    fp = fingerprint()
    have = _open(CACHE, fp)
    missing = [t for t in want if t not in have]
    if missing:
        rom = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
        terr = _terr(crr)
        for i, t in enumerate(missing):
            have[t] = crr.decode_range(rom, terr, t)
            if verbose and i % 200 == 0:
                print(f"  decoding {i}/{len(missing)}", file=sys.stderr)
        pickle.dump({"fp": fp, "decodes": have}, open(CACHE, "wb"))
    return have


def load_raw(crr, want, verbose=True):
    """{target: {"run": N, "lines": [(addr, nbytes, text), ...], "raw": str}}.

    `lines` is EVERY line unidasm printed for the run, `db` lines included
    (`nbytes` counts the bytes shown on the line). `run` is the length of the
    undisassembled-territory run starting at the target, capped at the
    converter's own 16,384-byte limit, so `run == 16384` means "capped".
    """
    import re, tempfile
    fp = fingerprint()
    have = _open(RAW, fp)
    missing = [t for t in want if t not in have]
    if missing:
        rom = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
        terr = _terr(crr)
        scratch = tempfile.mkdtemp(prefix="kn5000_raw_")
        tmp = os.path.join(scratch, "r.bin")
        LINE = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')
        for i, t in enumerate(missing):
            off = t - crr.BASE
            end = off
            while end < len(terr) and terr[end] == 2 and end - off < 16384:
                end += 1
            open(tmp, "wb").write(rom[off:end])
            txt = subprocess.run([crr.UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(t)],
                                 capture_output=True, text=True, timeout=120).stdout
            lines = [(int(m.group(1), 16), len(m.group(2).split()), m.group(3).strip())
                     for m in (LINE.match(ln) for ln in txt.split("\n")) if m]
            have[t] = {"run": end - off, "lines": lines, "raw": txt}
            if verbose and i % 200 == 0:
                print(f"  raw listing {i}/{len(missing)}", file=sys.stderr)
        pickle.dump({"fp": fp, "decodes": have}, open(RAW, "wb"))
    return have
