# symbolize_numeric_branches.py

Replaces numeric `jr`/`jrl`/`calr`/`call`/`jp` operands with labels, inserting a
structurally-named label at each target.  Spec and guards: the script's
docstring.  Verification evidence: `notes/branch-symbolization-2026-09-25/`.

## The counting one-liner quoted in the docstring

    export LC_ALL=C
    for t in v10/maincpu v9/maincpu v7/maincpu v142/subcpu hdae5000 table_data \
             wsa1/prom_a wsa1/prom_b wsa1/prom_c; do
      n=$(git ls-files "$t/*.s" | xargs cat | grep -aEc \
        '^\s*(\S+:)?\s*(jr|jrl|calr|call|jp|djnz)\s+([a-z]+,\s*)?(-?[0-9]+|0x[0-9a-fA-F]+)\s*(;.*)?$')
      echo "$t $n"
    done

(It does not count the `calr (0xTGT - 0xNEXT)` spelling, which the tool also
converts when 0xNEXT is provably the next instruction's address.)

## Typical use

    python3 scripts/converters/symbolize_numeric_branches.py --image v10 --report out.json   # dry run
    python3 scripts/converters/symbolize_numeric_branches.py --image v10 --apply --verify
    python3 scripts/converters/symbolize_numeric_branches.py --image v10 --only sequencer/accompaniment_engine.s --apply --verify
    make gate-all

`--report` lists every refused site by reason (R1..R6, never-taken) and every
target that lands MID-instruction or mid-data-line: that list is misframe
evidence -- either the branch or the target region is decoded wrongly.
