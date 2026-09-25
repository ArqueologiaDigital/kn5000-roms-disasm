#!/usr/bin/env python3
r"""Re-express address ranges of ONE maincpu source file as labelled, typed data.

QUESTION ANSWERED
    Given a spec that says, for each object, WHERE it is (lo..hi), WHAT to call
    it and WHY (a header that cites the reader), and how its bytes are shaped
    (byte / short / long / asciz / keep), rewrite exactly those source lines --
    and prove the rewrite changes no ROM byte.

    The tool never decides what an object IS.  The spec author does, from the
    reader; the tool renders and guards.

SPEC (JSON list, one object each)
    {"lo": "0xEE8C7E", "hi": "0xEE8CCE",
     "label": "VoiceInit_HandlerTablePtrs",
     "header": ["line 1", "line 2"],             # written as `; ` comments
     "type": "long" | "short" | "byte" | "asciz" | "keep",
     "per_line": 8,                              # elements per line (default 8/8/1)
     "comments": {"0xEE8C7E": "text"}}           # optional end-of-line comments
    type "keep" leaves the existing lines alone and only inserts label+header
    before `lo` (lo must be the first address of a line).
    type "struct": "fields": [4, 4, 4, 1] (byte sizes), "count": N -- one line
    per record, consecutive same-size fields share a directive; 4-byte fields
    resolve to labels like type "long".
    "tail": N renders the last N bytes as `.byte` (pads after records).
    "alias": {"LegacyName": 4} emits `.set LegacyName, <label> + 4` -- for a
    name other files still load (positional_labels.s bases etc.).
    "signed": true prints short/byte values as signed (switch offsets, steps).
    "row_index": "0x%02X" comments each line with the index of its first element.
    Top-level: the spec may be {"renames": {"old": "new"}, "objects": [...]};
    renames apply to every label name the tool writes (so a `.long` of a
    label renamed in the same run is written with the new name).
    type "long" keeps the symbolic operand an existing `.long` line at the same
    address already had (the rebuild proves it has the same value); otherwise
    it resolves the value to a label of THIS image (exact address,
    non-positional names first); a value with no exact label stays hex.

GUARDS
    * lo/hi must be line starts in the file's line map (file_line_addresses.py,
      which itself refuses a map of a tree that does not build the ROM);
    * every label defined on a replaced line is re-emitted at its address
      (so nothing that references it breaks), unless the spec lists it in
      "retire" -- then it must have no reference anywhere in <image>/maincpu;
    * a re-emitted label that falls inside an element aborts (split the object);
    * comments on replaced lines abort unless the spec sets "drop_comments"
      to the exact list of comment texts it replaces;
    * --apply rebuilds the image and compares it with the original ROM; on any
      difference the file is restored and the run fails.

RUN
    python3 scripts/converters/retype_data_objects.py --image v10 --file ui_widgets/widget_dispatch.s --spec S.json            # dry run: prints the render
    python3 scripts/converters/retype_data_objects.py --image v10 --file ui_widgets/widget_dispatch.s --spec S.json --apply
"""
import argparse
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "analysis"))
import file_line_addresses as fla  # noqa: E402

ROOT = fla.ROOT
B = 0xE00000
LABEL_RE = re.compile(r'^([A-Za-z_.$][\w.$]*):')
POSITIONAL = re.compile(r"_0x[0-9A-Fa-f]+$")


def symbols(image):
    elf = os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % image)
    out = subprocess.run([os.path.join(fla.LLVM, "llvm-nm"), "--defined-only", elf],
                         capture_output=True, text=True, check=True).stdout
    by, absn = {}, set()
    for ln in out.splitlines():
        p = ln.split()
        if len(p) != 3:
            continue
        v = int(p[0], 16)
        if p[1] in "tT" or (p[1] in "aA" and 0xE00000 <= v <= 0xFFFFFF):
            by.setdefault(v, []).append(p[2])
            if p[1] in "aA":
                absn.add(p[2])       # absolute ROM-address equates (.set X, 0xNNNNNN)
    for a in by:
        by[a].sort(key=lambda n: (bool(POSITIONAL.search(n)), n in absn, n.startswith("."), len(n)))
    return by


def referenced(image, name):
    r = subprocess.run(["git", "grep", "-l", "-a", "-w", name, "--", "%s/maincpu" % image],
                       cwd=ROOT, capture_output=True, text=True)
    files = r.stdout.split()
    if not files:
        return False
    # the defining line itself does not count
    n = 0
    for f in files:
        for ln in open(os.path.join(ROOT, f), encoding="latin-1"):
            code = ln.split(";")[0]
            if re.search(r'(?<![\w.$])%s(?![\w.$])' % re.escape(name), code) and \
                    not re.match(r'^\s*%s:' % re.escape(name), code):
                n += 1
    return n > 0


RENAMES = {}
NEAREST = {"on": False, "addrs": None, "v10": None}


def symname(v, syms, at=None):
    """Exact label; else (with --nearest, for ROM code/data addresses)
    `Nearest + N` plus a note, the form the v7 tree already used for pointers
    whose target has no label; else hex."""
    if v in syms and v:
        n = syms[v][0]
        return RENAMES.get(n, n)
    if NEAREST["on"] and 0xE00000 <= v <= 0xFFFFFF:
        if NEAREST["addrs"] is None:
            NEAREST["addrs"] = sorted(a for a in syms
                                      if any(not POSITIONAL.search(n) for n in syms[a]))
        import bisect
        addrs = NEAREST["addrs"]
        i = bisect.bisect_right(addrs, v) - 1
        base = next(n for n in syms[addrs[i]] if not POSITIONAL.search(n))
        NOTES.append((at, v))
        return "%s + %d" % (RENAMES.get(base, base), v - addrs[i])
    return "0x%08x" % v


NOTES = []
OLD_LONG = {}   # address -> symbolic operand text of an existing `.long` line there


def asm_escape(b):
    """String-literal body: escape quote/backslash and every control byte
    (a raw newline inside a literal once slipped through here)."""
    out = []
    for c in b:
        if c == 0x22:
            out.append('\\"')
        elif c == 0x5C:
            out.append('\\\\')
        elif c == 0x0A:
            out.append('\\n')
        elif c == 0x0D:
            out.append('\\r')
        elif c == 0x09:
            out.append('\\t')
        elif c < 0x20 or c == 0x7F:
            out.append('\\%03o' % c)
        else:
            out.append(chr(c))
    return "".join(out)


def render(obj, data, lo, syms, keep_labels):
    """keep_labels: {addr: [names]} to re-emit inside the object."""
    t = obj["type"]
    tail = obj.get("tail", 0)
    if t == "struct":
        return render_struct(obj, data, lo, syms, keep_labels)
    if tail:
        body = render(dict(obj, tail=0), data[:-tail], lo, syms, keep_labels)
        body.append("\t.byte " + ", ".join("0x%02x" % b for b in data[-tail:]) +
                    ("\t; " + obj["tail_comment"] if obj.get("tail_comment") else ""))
        return body
    size = {"byte": 1, "short": 2, "long": 4, "asciz": 1}[t]
    per = obj.get("per_line", {"byte": 8, "short": 8, "long": 1, "asciz": 1}[t])
    cm = {int(k, 0): v for k, v in obj.get("comments", {}).items()}
    out = []
    for h in obj.get("header", []):
        out.append(("; " + h).rstrip())
    out.append("%s:" % obj["label"])
    for leg, off in obj.get("alias", {}).items():
        out.append("\t.set %s, %s + %d" % (leg, obj["label"], off) if off else
                   "\t.set %s, %s" % (leg, obj["label"]))
    i = 0
    n = len(data)
    if n % size:
        sys.exit("%s: size %d is not a multiple of %d" % (obj["label"], n, size))
    row = []
    row_start = [0]

    ri = obj.get("row_index")

    def flush():
        if row:
            vals = ", ".join(v for v, _ in row)
            c = "; ".join(x for _, x in row if x)
            if ri:
                c = (ri % row_start[0]) + ("; " + c if c else "")
            directive = {"byte": ".byte", "short": ".short", "long": ".long"}[t]
            out.append("\t%s %s" % (directive, vals) + ("\t; " + c if c else ""))
            row.clear()
    if t == "asciz":
        s = data
        parts = s.split(b"\x00")
        a = lo
        for k, ptxt in enumerate(parts[:-1]):
            if a in keep_labels and a != lo:
                for nm in keep_labels[a]:
                    out.append("%s:" % nm)
            out.append('\t.asciz "%s"' % asm_escape(ptxt))
            a += len(ptxt) + 1
        if parts[-1]:
            sys.exit("%s: asciz object does not end in NUL" % obj["label"])
        return out
    while i < n:
        a = lo + i
        for k in range(1, size):
            if a + k in keep_labels:
                sys.exit("label %s falls inside an element of %s at 0x%X" %
                         (keep_labels[a + k], obj["label"], a))
        if a in keep_labels and a != lo:
            flush()
            for nm in keep_labels[a]:
                out.append("%s:" % nm)
        v = int.from_bytes(data[i:i + size], "little")
        if t == "long" and a in OLD_LONG:
            txt = OLD_LONG[a]           # keep the operand the source already used
            txt = RENAMES.get(txt, txt)
        elif t == "long":
            n0 = len(NOTES)
            txt = symname(v, syms, a)
            if len(NOTES) > n0:
                note = "no label at this target yet"
                if NEAREST["v10"] is not None and a in NEAREST["v10"]:
                    note += "; v10: %s" % NEAREST["v10"][a]
                cm[a] = (cm.get(a) + "; " if cm.get(a) else "") + note
        elif t == "short":
            if obj.get("signed") and v >= 0x8000:
                v -= 0x10000
            txt = obj.get("fmt_short", "0x%04x") % v
        else:
            if obj.get("signed") and v >= 0x80:
                v -= 0x100
            txt = obj.get("fmt_byte", "0x%02x") % v
        if not row:
            row_start[0] = i // size
        row.append((txt, cm.get(a)))
        if len(row) >= per or cm.get(a):
            flush()
        i += size
    flush()
    return out


def render_struct(obj, data, lo, syms, keep_labels):
    fields = obj["fields"]
    rs = sum(fields)
    cnt = obj["count"]
    tail = obj.get("tail", 0)
    if rs * cnt + tail != len(data):
        sys.exit("%s: %d x %d + %d != %d" % (obj["label"], cnt, rs, tail, len(data)))
    out = [("; " + h).rstrip() for h in obj.get("header", [])]
    out.append("%s:" % obj["label"])
    for leg, off in obj.get("alias", {}).items():
        out.append("\t.set %s, %s + %d" % (leg, obj["label"], off) if off else
                   "\t.set %s, %s" % (leg, obj["label"]))
    for r in range(cnt):
        base = r * rs
        if lo + base in keep_labels and base:
            for nm in keep_labels[lo + base]:
                out.append("%s:" % nm)
        for k in range(1, rs):
            if lo + base + k in keep_labels:
                sys.exit("label %s inside record %d of %s" % (keep_labels[lo + base + k], r, obj["label"]))
        groups, off = [], 0
        for f in fields:
            v = int.from_bytes(data[base + off:base + off + f], "little")
            txt = symname(v, syms) if f == 4 else ("0x%04x" % v if f == 2 else "0x%02x" % v)
            if groups and groups[-1][0] == f:
                groups[-1][1].append(txt)
            else:
                groups.append((f, [txt]))
            off += f
        rc = obj.get("record_comment")
        for gi, (f, vals) in enumerate(groups):
            d = {1: ".byte", 2: ".short", 4: ".long"}[f]
            line = "\t%s %s" % (d, ", ".join(vals))
            if gi == 0 and rc:
                line += "\t; " + rc % r
            out.append(line)
    if tail:
        out.append("\t.byte " + ", ".join("0x%02x" % b for b in data[-tail:]) +
                   ("\t; " + obj["tail_comment"] if obj.get("tail_comment") else ""))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--spec", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--nearest", action="store_true",
                    help="write unlabelled ROM pointers as `Nearest + N` with a comment")
    ap.add_argument("--v10-names", action="store_true",
                    help="(v9/v7) name the v10 label of the same slot in that comment;"
                         " requires the spec range to share v10's layout")
    a = ap.parse_args()
    NEAREST["on"] = a.nearest
    spec = json.load(open(a.spec))
    if isinstance(spec, dict):
        RENAMES.update(spec.get("renames", {}))
        spec = spec["objects"]
    path = os.path.join(ROOT, a.image, "maincpu", a.file)
    ent = fla.build(a.image, a.file)
    rom = open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % a.image), "rb").read()
    syms = symbols(a.image)
    if a.v10_names and a.image != "v10":
        s10 = symbols("v10")
        r10 = open(os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
        NEAREST["v10"] = {}
        for o in (spec["objects"] if isinstance(spec, dict) else spec):
            if o["type"] in ("long", "struct"):
                lo_, hi_ = int(o["lo"], 0), int(o["hi"], 0)
                for x in range(lo_, hi_ - 3):
                    v = int.from_bytes(r10[x - B:x - B + 4], "little")
                    if v in s10:
                        NEAREST["v10"][x] = s10[v][0]
    raw = open(path, "rb").read()
    lines = raw.decode("latin-1").split("\n")
    # line -> addr (first byte); also labels per line
    addr_of_line = {e["line"]: e["addr"] for e in ent}
    first_line_at = {}
    for e in ent:
        first_line_at.setdefault(e["addr"], e["line"])
    edits = []          # (first_line, last_line, new_lines)
    objs = sorted(spec, key=lambda o: int(o["lo"], 0))
    # group adjacent objects into runs: only run ends must be line starts
    runs = []
    for o in objs:
        if runs and int(runs[-1][-1]["hi"], 0) == int(o["lo"], 0) and o["type"] != "keep" \
                and runs[-1][-1]["type"] != "keep":
            runs[-1].append(o)
        else:
            runs.append([o])
    for run in runs:
        lo, hi = int(run[0]["lo"], 0), int(run[-1]["hi"], 0)
        first = run[0]
        if lo not in first_line_at:
            sys.exit("%s: run start 0x%X is not the start of a line" % (first["label"], lo))
        if hi not in first_line_at:
            sys.exit("%s: run end 0x%X is not the start of a line" % (run[-1]["label"], hi))
        fl = first_line_at[lo]
        ll = first_line_at[hi] - 1
        # comment / blank lines right above the next object belong to it
        while ll >= fl and (not lines[ll - 1].strip() or lines[ll - 1].lstrip().startswith(";")):
            ll -= 1
        old = lines[fl - 1:ll]
        if first["type"] == "keep":
            new = [("; " + h).rstrip() for h in first.get("header", [])] + ["%s:" % first["label"]]
            edits.append((fl, fl - 1, new))
            continue
        comments = [ln.split(";", 1)[1].strip() for ln in old if ";" in ln
                    and not re.match(r'^\s*\.(ascii|asciz|string)\b', ln)]
        allowed = sum((o.get("drop_comments", []) for o in run), [])
        bad = [c for c in comments if c not in allowed]
        if bad:
            sys.exit("%s: replaced lines hold comments %r (list them in drop_comments)" %
                     (first["label"], bad[:3]))
        keep = {}
        retire = set(sum((o.get("retire", []) for o in run), []))
        own = {o["label"] for o in run}
        aliased = set(sum((list(o.get("alias", {})) for o in spec), []))
        for k in range(fl, ll + 1):
            m = LABEL_RE.match(lines[k - 1])
            if not m:
                continue
            nm = m.group(1)
            if nm in own or nm in RENAMES or nm in aliased:
                continue
            if nm in retire:
                if referenced(a.image, nm):
                    sys.exit("cannot retire %s: it is referenced" % nm)
                continue
            ad = addr_of_line.get(k)
            if ad is None:
                sys.exit("label %s on line %d has no address" % (nm, k))
            keep.setdefault(ad, []).append(nm)
        OLD_LONG.clear()
        for k in range(fl, ll + 1):
            m = re.match(r'^\s*\.long\s+([A-Za-z_.$][\w.$]*(?:\s*[-+]\s*\w+)?)\s*(;.*)?$',
                         lines[k - 1])
            if m and k in addr_of_line:
                OLD_LONG[addr_of_line[k]] = m.group(1)
        new = []
        for o in run:
            olo, ohi = int(o["lo"], 0), int(o["hi"], 0)
            if olo in keep:
                sys.exit("%s: label(s) %s already name 0x%X -- retire, rename or alias them"
                         % (o["label"], keep[olo], olo))
            sub = {ad: n for ad, n in keep.items() if olo < ad < ohi}
            new += render(o, rom[olo - B:ohi - B], olo, syms, sub)
        edits.append((fl, ll, new))
    out = list(lines)
    for fl, ll, new in sorted(edits, key=lambda e: -e[0]):
        out[fl - 1:ll] = new
    text = "\n".join(out)
    if not a.apply:
        for fl, ll, new in sorted(edits):
            print("---- lines %d..%d -> %d lines" % (fl, ll, len(new)))
            print("\n".join(new[:60]))
            if len(new) > 60:
                print("  ... (%d more)" % (len(new) - 60))
        return 0
    backup = raw
    open(path, "wb").write(text.encode("latin-1"))
    r = subprocess.run(["make", "rebuilt_ROMs/kn5000_%s_program.llvm.rom" % a.image],
                       cwd=ROOT, capture_output=True, text=True)
    got = open(os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.rom" % a.image), "rb").read() \
        if r.returncode == 0 else b""
    if r.returncode != 0 or got != rom:
        open(path, "wb").write(backup)
        print(r.stderr[-3000:])
        sys.exit("REBUILD %s -- file restored" % ("FAILED" if r.returncode else "DIFFERS"))
    print("%s: %d objects rewritten; %s rebuilds byte-identical" % (path, len(edits), a.image))
    return 0


if __name__ == "__main__":
    sys.exit(main())
