import json, sys
D = sys.argv[1]
b = {r["script"]: r for r in json.load(open(D + "/trace-before.json"))}
a = {r["script"]: r for r in json.load(open(D + "/trace-after.json"))}
out = []
out.append("# The numbers\n")
out.append("*BEFORE = a worktree of 3947944a, the last commit before this lane.")
out.append("AFTER = the fixed tree. Same tool, same invocations (SAFE_ARGV in")
out.append("notes/git_path_audit.py).*\n")
out.append("| script | before reads/bad | after reads/bad |")
out.append("|---|---:|---:|")
for k in sorted(set(b) | set(a)):
    fb = "%d/%d" % (b[k]["reads"], b[k]["bad"]) if k in b else "-"
    fa = "%d/%d" % (a[k]["reads"], a[k]["bad"]) if k in a else "-"
    mark = " *" if (k in b and b[k]["bad"]) and (k in a and not a[k]["bad"]) else ""
    out.append("| `%s`%s | %s | %s |" % (k, mark, fb, fa))
nb = sum(1 for r in b.values() if r["bad"])
na = sum(1 for r in a.values() if r["bad"])
out.append("")
out.append("**BEFORE: %d scripts traced, %d issued a failing or misspelled git "
           "read, %d bad reads.**" % (len(b), nb, sum(r["bad"] for r in b.values())))
out.append("")
out.append("**AFTER: %d scripts traced, %d issued a failing or misspelled git "
           "read, %d bad reads.**" % (len(a), na, sum(r["bad"] for r in a.values())))
out.append("")
out.append("`*` marks a script that had at least one bad read and now has none.")
out.append("")
out.append("The AFTER sweep covers TWO MORE scripts than BEFORE, which is the")
out.append("point of the discovery rule in git_scripts(): a script migrated off a")
out.append("raw git call must STAY in the sweep, or the instrument stops")
out.append("measuring exactly what it just fixed.  The two are")
out.append("notes/prom_c_round3_frontier_delta.py and")
out.append("notes/promb_macro_preservation.py, which read a revision only through")
out.append("asm_source and so had no raw call site to be discovered by.")
open(D + "/RESULT.md", "w").write("\n".join(out) + "\n")
print("\n".join(out[:6]))
print("...")
print("\n".join(out[-14:]))
