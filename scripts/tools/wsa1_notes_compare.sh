#!/bin/bash
# wsa1_notes_compare.sh -- do the wsa1/notes scripts say the same thing with and without the
# working tree's uncommitted change?
#
# QUESTION IT ANSWERS: a source edit (a respelling pass, a rename) can change what a checker that
# parses the source text reports, without moving a ROM byte.  This runs each wsa1/notes/*.py whose
# text matches PATTERN, with its default arguments, in two throwaway worktrees: BASE, and BASE plus
# `git diff BASE` of the working tree.  It then compares output and exit status.  Both runs happen
# in worktrees, so a script that writes files cannot touch the working tree.  rc!=0 on both sides
# is a pre-existing state, not a regression.
#
#   scripts/tools/wsa1_notes_compare.sh <base-commit> <grep-pattern> [timeout-seconds]
#   e.g. scripts/tools/wsa1_notes_compare.sh HEAD 'prom_c' 300
set -u
BASE="${1:?base commit}"
PAT="${2:?pattern}"
TMO="${3:-300}"
REPO="$(git rev-parse --show-toplevel)"
WORK="${TMPDIR:-$HOME/compartilhado/tmp}/wsa1-notescmp-$$"
OUT="${WORK:?}-out"
mkdir -p "${OUT:?}/before" "${OUT:?}/after"
git -C "$REPO" worktree add --detach "${WORK:?}/before" "$BASE" > /dev/null 2>&1
git -C "$REPO" worktree add --detach "${WORK:?}/after" "$BASE" > /dev/null 2>&1
git -C "$REPO" diff --binary "$BASE" > "${OUT:?}/change.patch"
git -C "${WORK:?}/after" apply --whitespace=nowarn "${OUT:?}/change.patch"
# the rebuilt ELFs some scripts read are not tracked: build both sides
for side in before after; do
    make -C "${WORK:?}/$side" wsa1 > "${OUT:?}/$side-build.log" 2>&1 || echo "build failed on $side"
done
SCRIPTS=$(cd "$REPO/wsa1/notes" && command grep -l -- "$PAT" *.py | sort)
diffs=0; n=0
for s in $SCRIPTS; do
    n=$((n + 1))
    for side in before after; do
        (cd "${WORK:?}/$side/wsa1" && timeout "$TMO" python3 "notes/$s" > "${OUT:?}/$side/$s.out" 2>&1; echo "rc=$?" >> "${OUT:?}/$side/$s.out")
        sed -i "s#${WORK:?}/$side#REPO#g" "${OUT:?}/$side/$s.out"
    done
    if cmp -s "${OUT:?}/before/$s.out" "${OUT:?}/after/$s.out"; then
        echo "SAME $s $(tail -1 "${OUT:?}/after/$s.out")"
    else
        echo "DIFF $s"; diffs=$((diffs + 1))
        diff "${OUT:?}/before/$s.out" "${OUT:?}/after/$s.out" | head -8 | sed 's/^/    /'
    fi
done
git -C "$REPO" worktree remove --force "${WORK:?}/before"
git -C "$REPO" worktree remove --force "${WORK:?}/after"
git -C "$REPO" worktree prune
rmdir -- "${WORK:?}" 2>/dev/null   # the now-empty parent of the two worktrees
echo "$diffs of $n script(s) changed; outputs kept in ${OUT:?}"
[ "$diffs" -eq 0 ]
