# Disk-format probes (2026-08-21)

Asserting probes behind the disk-format findings in `docs/kn-disk-file-formats.md` and
`docs/accompaniment-style-format.md`. They were produced by a multi-agent investigation in which
every claim was attacked by an independent skeptic; **34 of 83 claims were refuted** and only the
survivors are documented. These are the probes for the survivors.

All take the directory of extracted floppies as their argument. Recreate it with:

    mkdir -p /tmp/disk && cd /tmp/disk
    for z in /home/fsanches/compartilhado/KN7000/floppy-archive/*.zip; do
        n=$(basename "$z" .zip); mkdir -p "$n"; unzip -o -q -d "$n" "$z"
    done

| probe | question it answers | headline |
|---|---|---|
| `disk_seq_chains.py` | Are the two u16 fields in a disk `.SEQ` cell a prev/next pair? | YES -- as ONE-BASED cell numbers. 1192 cells, 2188/2188 pointers resolve, **1094/1094 forward and backward links mutual**, 98 chains. |
| `disk_lsw_container.py` | What is a `.LSW` file? | A TLV container: 26 blocks of tag/len/payload records ending in `FF FF`, zero residue on all seven disks, plus a byte-exact mirror of the disk's own `.MSP` at 0x5480. |
| `disk_msp_container.py` | What is a `.MSP` file? | The IC19 cell container, with the directory geometry SELF-DESCRIBED in the header. |
| `disk_seq_tracks.py` | How do `.SEQ` chains map to tracks? | Seven chains per file, heads at blocks 0..6, plus a free list in four of the seven. |
| `demo_status_census.py` | Which statuses appear in the demo songs, and how often? | Backs the `0x80`/`0x85`/`0x86` findings. |
| `style_ctl_census.py` | Argument distributions of `0xD1`/`0xD2`/`0xD3`. | Backs the controller findings. |

## ⚠ Two traps these probes exist to survive

**Recursive `grep` skips 47% of this tree.** See the warning at the end of `CLAUDE.md`. Any probe
that searches the sources must use `command grep` or read bytes in Python.

**One-based cell numbers with asymmetric sentinels.** In `.SEQ`, a pointer value *v* addresses
block *v-1*; `+0x01` uses `0x0000` for "no predecessor" and `+0x03` uses `0xFFFF` for "no
successor". Reading them as zero-based, or assuming one sentinel serves both, makes the links look
like they do not agree -- which is exactly the wrong conclusion this project recorded before these
probes were written.
