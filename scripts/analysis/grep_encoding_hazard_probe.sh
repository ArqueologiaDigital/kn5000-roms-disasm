#!/usr/bin/env bash
# grep_encoding_hazard_probe.sh -- does a `grep` census over these sources
# silently under-report, and under exactly what condition?
#
# QUESTION THIS ANSWERS
# ---------------------
# The lane brief warned that grepping these disassembly sources can silently
# miss matches. On 2026-09-02 I tested it, saw no discrepancy, and committed a
# note saying the hazard "does not reproduce" (commit 80e16190). Lane promB1
# then hit it for real. Both of us were right about what we ran, and the truth
# is more specific than either claim.
#
# THE MECHANISM -- IT IS NOT GNU grep, IT IS THE AGENT'S SHELL
# -------------------------------------------------------------
# In a Claude Code agent shell, `grep` is a shell FUNCTION that routes to
# `ugrep` with the `-I` flag, i.e. SKIP FILES IT CONSIDERS BINARY. A source
# file containing a byte sequence that is not valid UTF-8 is judged binary, so
# it is skipped ENTIRELY -- no matches, exit status 1, and NOTHING on stderr:
#
#     grep -c 'f00c' bad.s        -> (no output)  exit 1     <- the wrapper
#     grep -ac 'f00c' bad.s       -> 2            exit 0     <- -a defeats it
#     command grep -c 'f00c' bad.s-> 2            exit 0     <- real GNU grep
#
# So the hazard is REAL for anyone working in an agent shell and INVISIBLE to
# any script, because Python's subprocess and `bash script.sh` both invoke
# /usr/bin/grep directly and never see the function. That is why my earlier
# test could not reproduce it: I was measuring a different program than the one
# my own command line was running.
#
# ⚠ THE TRIGGER IS INVALID ENCODING, NOT "NON-ASCII". These sources are full of
# proper UTF-8 (⚠ and ★ in comments) and are fine. What triggers it is a
# MALFORMED sequence -- most easily produced by writing UTF-8 text through a
# latin-1 encoder, which yields double-encoded mojibake, or by a tool emitting a
# lone lead byte. promB1 hit it right after its own edit introduced exactly that.
#
# THE RULE
#     Use `grep -a` for every census over the disassembly sources. It costs
#     nothing and removes the failure mode. `command grep` also works.
#
# ⚠ HOW TO RUN IT SO IT CAN ACTUALLY FAIL
#     source scripts/analysis/grep_encoding_hazard_probe.sh
#
#     SOURCING IS REQUIRED. Run as `bash grep_encoding_hazard_probe.sh` the
#     wrapper function does not exist, the probe cannot see the hazard, and it
#     will say so and refuse to report a pass. A criterion that cannot fail is
#     not evidence -- which is the same mistake that produced the wrong note in
#     the first place, so this script refuses to repeat it.
#
# THE CONTROL
#     Three files, which must NOT behave alike:
#       ok.bin    valid UTF-8            -> wrapper and -a agree
#       moji.bin  double-encoded, valid  -> wrapper and -a agree  (mojibake
#                                            alone is NOT the trigger)
#       bad.bin   invalid UTF-8          -> wrapper finds NOTHING, -a finds all
#     If ok/moji ever disagree, the probe is broken, not grep.

_d=$(mktemp -d) || return 1 2>/dev/null || exit 1
printf '; \xe2\x9a\xa0 warn\nld xwa,0x00f00c4d\nf00c99\n'                 > "$_d/ok.bin"
printf '; \xc3\xa2\xc2\x9a\xc2\xa0 warn\nld xwa,0x00f00c4d\nf00c99\n'     > "$_d/moji.bin"
printf '; \xe2 warn\nld xwa,0x00f00c4d\nf00c99\n'                         > "$_d/bad.bin"

echo "grep is: $(type -t grep 2>/dev/null || echo file)"
if [ "$(type -t grep 2>/dev/null)" != "function" ]; then
    echo "⚠ NOT RUNNING UNDER THE AGENT'S grep WRAPPER."
    echo "  This probe can only observe the hazard when \`grep\` is the shell"
    echo "  function that routes to ugrep -I. You are invoking /usr/bin/grep"
    echo "  directly, where the hazard does not exist."
    echo "  Re-run as:  source scripts/analysis/grep_encoding_hazard_probe.sh"
    echo "  NO CONCLUSION DRAWN."
    rm -rf "$_d"
    return 2 2>/dev/null || exit 2
fi

_fail=0
for _f in ok.bin moji.bin bad.bin; do
    _plain=$(grep -c 'f00c' "$_d/$_f" 2>/dev/null); _prc=$?
    _anyb=$(grep -ac 'f00c' "$_d/$_f" 2>/dev/null); _arc=$?
    [ -z "$_plain" ] && _plain="(none)"
    case "$_f" in
        bad.bin) _want="differ" ;;
        *)       _want="agree"  ;;
    esac
    if [ "$_plain" = "$_anyb" ]; then _got="agree"; else _got="differ"; fi
    if [ "$_got" = "$_want" ]; then _st="OK"; else _st="PROBE BROKEN"; _fail=1; fi
    printf '  %-9s plain=%-7s(rc %d)  -a=%-7s(rc %d)  expect %-6s  %s\n' \
           "$_f" "$_plain" "$_prc" "$_anyb" "$_arc" "$_want" "$_st"
done
rm -rf "$_d"

echo
if [ "$_fail" -ne 0 ]; then
    echo "⚠ CONTROL FAILED. Do not draw a conclusion from this run."
else
    echo "CONFIRMED: under the agent's grep wrapper, a file containing INVALID"
    echo "UTF-8 yields NO MATCHES with no diagnostic, while -a finds them all."
    echo "Valid UTF-8, including double-encoded mojibake, is unaffected."
    echo "RULE: use \`grep -a\` for any census over these sources."
fi
unset _d _f _plain _anyb _prc _arc _want _got _st
