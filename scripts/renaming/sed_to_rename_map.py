#!/usr/bin/env python3
"""sed_to_rename_map.py -- turn a label-rename .sed script into an old=new map.

QUESTION ANSWERED: which label renames does a `scripts/renaming/*.sed` file
perform, in the `old=new` form that
`scripts/analysis/assert_comments_preserved.py --rename-map` accepts?

Understands exactly the rule shape the rename scripts use:
    s/\\bOLD\\b/NEW/g        s/\\.LOCAL\\b/NEW/g        s/\\bPREFIX__/NEWPREFIX__/g
(the last is emitted as-is and only matches whole prefixes).  Comment lines
(#) and blank lines are skipped.

RUN
    python3 scripts/renaming/sed_to_rename_map.py scripts/renaming/X.sed > /tmp/X.map
    python3 scripts/analysis/assert_comments_preserved.py --base HEAD \\
        --rename-map /tmp/X.map hdae5000/*.s
"""
import re
import sys

for path in sys.argv[1:]:
    for ln in open(path, encoding="utf-8"):
        m = re.match(r"^s/(.*?)/(.*?)/g\s*$", ln.strip())
        if not m:
            continue
        old = m.group(1).replace("\\b", "").replace("\\.", ".")
        print("%s=%s" % (old, m.group(2)))
