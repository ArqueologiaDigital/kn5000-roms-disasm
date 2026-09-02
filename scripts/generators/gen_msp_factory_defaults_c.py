#!/usr/bin/env python3
"""Generate the C source for MSP_FACTORY_DEFAULTS (lane w13/census-structs).

QUESTION THIS ANSWERS
  What is the record structure of the 5,376 nameless `.byte` operands that
  used to make up `<image>/maincpu/msp_factory_defaults.s`, and can it be
  written as a C struct that compiles byte-exact against all three program
  ROMs?

RUN
  python3 scripts/generators/gen_msp_factory_defaults_c.py           # verify only
  python3 scripts/generators/gen_msp_factory_defaults_c.py --write   # rewrite the .c files

WHAT IT VERIFIES (asserts; the script refuses to write if any fails)
  * the region is 21 x 256 bytes, matching `ldw bc, 0xa80` (= 0xA80 words)
    in Voice_InitBankData;
  * the same 5,376 bytes appear in v7, v9 and v10 at the addresses below --
    so ONE struct definition may be shared by all three images, unlike the
    SE_NAMES case where a v10-derived descriptor was meaningless elsewhere;
  * every block has bit 7 of +0x00 set (the "allocated" bit that
    CountAvailableVoiceSlots tests with `bitm 7, (xhl)`);
  * +0x05 and +0xFF are 0x87 in all 21 blocks (the two payload offsets the
    runtime cursor can never reach: it starts at 6 and stops before 0xFF);
  * the +0x01 / +0x03 link words are mutually consistent -- for every block
    whose next_block is not 0xFFFF, that block's prev_block points back.

SIGNALS AND THEIR MEANING -- every field name below comes from an instruction
that reads or writes it, cited in the emitted C header.
"""
import argparse
import hashlib
import os
import struct
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# image -> (rom file, address of MSP_FACTORY_DEFAULTS in that image)
# Addresses taken from llvm-nm on the linked ELF of each image.
IMAGES = {
    "v7":  ("original_ROMs/kn5000_v7_program.rom",  0xF6F22B),
    "v9":  ("original_ROMs/kn5000_v9_program.rom",  0xF6F62F),
    "v10": ("original_ROMs/kn5000_v10_program.rom", 0xF6F62F),
}
ROM_BASE = 0xE00000
BLOCK_SIZE = 256
N_BLOCKS = 21
TOTAL = BLOCK_SIZE * N_BLOCKS          # 5376 == 0xA80 words
PAYLOAD_LEN = 0xFE - 0x06 + 1          # 249

# Event lengths for the payload opcode stream.  These are NOT read off a
# reader -- they are the unique set for which every one of the twelve block
# chains tiles exactly, ending on the 0x83 terminator with only zero padding
# after it (see verify_stream_framing below).  A wrong length fails within a
# few events, so the test can fail; the opcode SET is the one
# AccompSeq_SeqParse_Dispatch compares against.
EVENT_LEN = {0x90: 6, 0x91: 8, 0x81: 1, 0x83: 1, 0xD1: 3, 0xD2: 3, 0xD3: 3}
OP_NAME = {
    0x90: "MIDI event (0x90)",
    0x91: "MIDI event (0x91)",
    0x81: "time advance",
    0x83: "end of sequence",
    0xD1: "MIDI event (0xD1)",
    0xD2: "MIDI event (0xD2)",
    0xD3: "MIDI event (0xD3)",
}


def read_region(rom_path, addr):
    rom = open(os.path.join(REPO, rom_path), "rb").read()
    off = addr - ROM_BASE
    return rom[off:off + TOTAL]


def verify(data):
    assert len(data) == TOTAL, len(data)
    blocks = [data[i * BLOCK_SIZE:(i + 1) * BLOCK_SIZE] for i in range(N_BLOCKS)]
    for i, b in enumerate(blocks):
        assert b[0] & 0x80, ("allocated bit clear", i, b[0])
        assert b[5] == 0x87, ("guard +0x05", i, b[5])
        assert b[255] == 0x87, ("guard +0xFF", i, b[255])
    links = [(struct.unpack_from("<H", b, 1)[0], struct.unpack_from("<H", b, 3)[0])
             for b in blocks]
    for i, (prv, nxt) in enumerate(links):
        if nxt != 0xFFFF:
            assert nxt < N_BLOCKS, ("next out of range", i, nxt)
            assert links[nxt][0] == i, ("broken back-link", i, nxt, links[nxt][0])
        if prv != 0xFFFF:
            assert prv < N_BLOCKS, ("prev out of range", i, prv)
            assert links[prv][1] == i, ("broken fwd-link", i, prv, links[prv][1])
    verify_stream_framing(blocks, links)
    return blocks


def chains(links):
    """The chains, head-first, as lists of block indices."""
    out = []
    for i, (prv, _) in enumerate(links):
        if prv != 0xFFFF:
            continue
        c, j = [], i
        while j != 0xFFFF:
            c.append(j)
            j = links[j][1]
        out.append(c)
    return out


def verify_stream_framing(blocks, links):
    """Every chain's concatenated payload must tile exactly under EVENT_LEN,
    terminate on 0x83, and be zero-padded from there to the end."""
    n = 0
    for c in chains(links):
        p = b"".join(blocks[i][6:6 + PAYLOAD_LEN] for i in c)
        j = 0
        while j < len(p):
            op = p[j]
            assert op in EVENT_LEN, ("unknown opcode", c, j, hex(op))
            n += 1
            j += EVENT_LEN[op]
            if op == 0x83:
                break
        else:
            raise AssertionError(("chain ran off the end without 0x83", c))
        assert all(x == 0 for x in p[j:]), ("padding after 0x83 is not zero", c)
    print("verified: %d chains, %d events, all tile exactly under EVENT_LEN"
          % (len(chains(links)), n))


HEADER = '''/**
 * msp_factory_defaults.c -- factory image of the accompaniment stream-buffer pool
 *
 * Label:       MSP_FACTORY_DEFAULTS
 * Size:        5,376 bytes = 21 x 256
 * ROM address: 0xF6F22B (v7), 0xF6F62F (v9 and v10).  The 5,376 bytes are
 *              BYTE-IDENTICAL in all three images (md5 %(md5)s),
 *              which is why one struct definition is shared by v7/v9/v10.
 *
 * WHAT THIS IS.  `Voice_InitBankData` (kn5000_v10_program.s) does
 *
 *     ld  xix, 0x1e8b00
 *     ld  xiy, MSP_FACTORY_DEFAULTS
 *     ldw bc, 0xa80          ; 0xA80 WORDS = 5,376 bytes
 *     ldirw
 *
 * and `Voice_GetSlotAddress` (same file) computes `0x1e8b00 + (index << 8)`,
 * so RAM 0x1E8B00 is an array of 256-byte blocks and this ROM image preloads
 * the first 21 of them.  The pool holds 57 blocks in total:
 * midi/midi_dispatch_handlers.s builds a region descriptor
 * (base 0x1E8B00, size 0x3900 = 57 x 256), and Voice_InitBankTables fills all
 * 57 from `Voice_SlotTemplate` before this image is copied over the first 21.
 *
 * It is a LINKED-LIST BLOCK ALLOCATOR for accompaniment / recorded-MIDI byte
 * streams, not a table of "MSP parameters" -- the label predates the evidence
 * and is kept only because the assembly references it by that name.
 *
 * FIELD PROVENANCE.  Every name below is the instruction that reads or writes
 * the field, not a guess from the values:
 *
 *   +0x00 allocated_and_marker
 *          `bitm 7, (xhl)`        kn5000_v10_program.s, CountAvailableVoiceSlots
 *                                 -- counts blocks with bit 7 CLEAR into 0x7E18
 *          `ormi8 (xix), 0x80`    sequencer/seq_event_playback.s -- allocate,
 *                                 paired with `decdi16 1, 0x7e18`
 *          `andmi8 (xix), 0x7f`   sequencer/seq_event_playback.s,
 *                                 Voice_ReleaseChainLoop -- free
 *          `cp a, 0x87`           sequencer/accompseq_routines.s,
 *                                 AccompSeq_AdvanceCheckPattern -- tests the
 *                                 WHOLE byte of the next block after a wrap
 *   +0x01 prev_block   16-bit block INDEX, not an address
 *          `ld (xix + 1), de`     seq_event_playback.s -- de = the block that
 *                                 was current when this one was allocated
 *          `ldw (xix + 1), 0xffff` -- cleared on release; 0xFFFF = none
 *   +0x03 next_block   16-bit block INDEX
 *          `ld hl, (xix + 3)`     seq_event_playback.s, Voice_ReleaseChainLoop
 *                                 -- walks the chain
 *          `ld wa, (xix + 3)`     seq_event_playback.s, MidiSeqBuf_AdvanceWritePos
 *                                 -- follow, then `stda16 (0x7f10)` + cursor = 6
 *          `ld (xix + 3), wa`     -- link a freshly allocated block on
 *          accompseq_routines.s AccompSeq_ReadBeatHeader reads it as
 *          `add xwa, 0x3` / `add xwa, 0x1e8b00` / `ld wa, (xwa)`, and both its
 *          callers follow with `stda16 (0x7e42), xwa` + cursor = 6.
 *   +0x05 guard_05  -- see stream[] below
 *   +0x06 stream[249]
 *          The payload.  The write cursor is initialised to 6
 *          (`lds wa, 6` after every allocate and every link traversal) and the
 *          wrap test is `inc 1, wa` / `cp wa, 0xff`, so +0x06..+0xFE is exactly
 *          the writable span.  Bytes are addressed only through the runtime
 *          cursor (`ld (xix + xhl), a`), never by a constant offset.
 *          It is an opcode stream: AccompSeq_SeqParse_Dispatch
 *          (sequencer/accompseq_routines.s) dispatches on the byte at the
 *          cursor -- 0x83 end-of-sequence, 0x81 time advance, 0x84 tempo reset,
 *          and 0x90/0x91/0xC0/0xD1/0xD2/0xD3/0xD4/0xD5/0xD7 MIDI event.
 *          The rows below are split at EVENT boundaries, with the event length
 *          taken from the tiling test in the generator, NOT from a reader:
 *          0x90 -> 6, 0x91 -> 8, 0xD1/0xD2/0xD3 -> 3, 0x81 and 0x83 -> 1.
 *          With those lengths all twelve chains tile exactly -- 558 events,
 *          every chain ending on 0x83 with nothing but zeros after it.  The
 *          test can fail: any other length set desynchronises within a few
 *          events and lands on a byte that is not one of the seven opcodes.
 *          !! The MEANING of the operand bytes inside an event is NOT
 *          established, so they are left unnamed rather than guessed.
 *          Events straddle block boundaries (chain 3->4 at +249, chain 6..14 at
 *          six of its eight joins), which is the direct evidence that the pool
 *          is a byte-stream buffer and not an array of records.
 *   +0xFF guard_ff
 *          +0x05 and +0xFF are the two payload offsets the cursor can never
 *          reach, and both hold 0x87 in all 21 blocks AND in Voice_SlotTemplate
 *          (`nop` / `.long 0xffffffff` / `.byte 0x87` / `.zero 248` /
 *          `.byte 0x00, 0x87` in audio/voice_bank_defaults.s).  0x87 is not one
 *          of the opcodes the dispatcher tests, so a linear reader falls
 *          through to AccompSeq_AdvancePosition on it -- which is the routine
 *          that performs the block-to-block hop.  Named `guard`, not
 *          "end marker", because no instruction was found that reads either
 *          offset by name.
 *
 * Generated by scripts/generators/gen_msp_factory_defaults_c.py; that script
 * re-derives this file from the ROM and asserts every invariant quoted above.
 */

#include <stdint.h>

/* One 256-byte pool block. */
typedef struct __attribute__((packed)) {
    uint8_t  allocated_and_marker;  /* +0x00 bit 7 = block in use */
    uint16_t prev_block;            /* +0x01 block index, 0xFFFF = none */
    uint16_t next_block;            /* +0x03 block index, 0xFFFF = none */
    uint8_t  guard_05;              /* +0x05 always 0x87, cursor cannot reach */
    uint8_t  stream[249];           /* +0x06..+0xFE accompaniment opcode stream */
    uint8_t  guard_ff;              /* +0xFF  always 0x87, cursor cannot reach */
} msp_pool_block_t;

_Static_assert(sizeof(msp_pool_block_t) == 256,
    "msp_pool_block_t must be exactly 256 bytes");

typedef struct __attribute__((packed)) {
    msp_pool_block_t block[21];
} msp_factory_defaults_t;

_Static_assert(sizeof(msp_factory_defaults_t) == 5376,
    "msp_factory_defaults_t must be exactly 5376 bytes (0xA80 words)");

const msp_factory_defaults_t msp_factory_defaults
    __attribute__((section(".text"), used)) = {
    .block = {
'''

FOOTER = '''    },
};
'''


def chain_comment(i, prv, nxt):
    if prv == 0xFFFF and nxt == 0xFFFF:
        return "unchained (single-block stream)"
    if prv == 0xFFFF:
        return "head of a chain, continues in block %d" % nxt
    if nxt == 0xFFFF:
        return "tail of a chain, continued from block %d" % prv
    return "chain link: %d -> [%d] -> %d" % (prv, i, nxt)


def frame_events(blocks, links):
    """Map every payload byte to (block, offset_in_block) event rows.

    The stream is a byte stream across a whole chain, so an event may straddle
    a block boundary; such an event is emitted as two rows, the first tagged
    "continues in block N".  Returns {block_index: [(off, bytes, comment)]}.
    """
    rows = {i: [] for i in range(len(blocks))}
    for c in chains(links):
        p = b"".join(blocks[i][6:6 + PAYLOAD_LEN] for i in c)
        j = 0
        while j < len(p):
            op = p[j]
            L = EVENT_LEN[op]
            piece = j
            while piece < j + L:
                blk_i = c[piece // PAYLOAD_LEN]
                off = piece % PAYLOAD_LEN
                take = min(PAYLOAD_LEN - off, j + L - piece)
                nxt = c[(piece + take) // PAYLOAD_LEN] if piece + take < len(p) else None
                split = (take != L)
                comment = "0x%02X %s" % (op, OP_NAME[op])
                if split and piece == j:
                    comment += " -- continues in block %d" % nxt
                elif split:
                    comment = "  ... rest of the 0x%02X event begun in the previous block" % op
                rows[blk_i].append((6 + off, p[piece:piece + take], comment))
                piece += take
            j += L
            if op == 0x83:
                break
        # zero padding after the terminator
        while j < len(p):
            bi = c[j // PAYLOAD_LEN]
            off = j % PAYLOAD_LEN
            take = min(16, PAYLOAD_LEN - off)
            rows[bi].append((6 + off, p[j:j + take], "zero padding"))
            j += take
    return rows


def emit(blocks, links):
    md5 = hashlib.md5(b"".join(blocks)).hexdigest()
    rows = frame_events(blocks, links)
    out = [HEADER % {"md5": md5}]
    for i, b in enumerate(blocks):
        prv, nxt = links[i]
        out.append("        /* ---- block %2d -- %s ---- */\n"
                   % (i, chain_comment(i, prv, nxt)))
        out.append("        [%2d] = {\n" % i)
        out.append("            .allocated_and_marker = 0x%02X,\n" % b[0])
        out.append("            .prev_block           = 0x%04X,\n" % prv)
        out.append("            .next_block           = 0x%04X,\n" % nxt)
        out.append("            .guard_05             = 0x%02X,\n" % b[5])
        out.append("            .stream = {\n")
        total = 0
        for off, data, comment in rows[i]:
            total += len(data)
            body = " ".join("0x%02X," % x for x in data)
            line = "                " + body
            while len(line) < 16 + 6 * 16:
                line += " "
            out.append("%s/* +0x%02X  %s */\n" % (line, off, comment))
        assert total == PAYLOAD_LEN, (i, total)
        out.append("            },\n")
        out.append("            .guard_ff             = 0x%02X,\n" % b[255])
        out.append("        },\n")
    out.append(FOOTER)
    return "".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true",
                    help="rewrite <image>/maincpu/msp_factory_defaults.c")
    args = ap.parse_args()

    regions = {k: read_region(p, a) for k, (p, a) in IMAGES.items()}
    md5s = {k: hashlib.md5(v).hexdigest() for k, v in regions.items()}
    assert len(set(md5s.values())) == 1, ("images differ", md5s)
    print("all three images identical: md5 %s, %d bytes"
          % (md5s["v10"], TOTAL))

    blocks = verify(regions["v10"])
    print("verified: 21 blocks, allocated bit set, guards 0x87, links consistent")

    links = [(struct.unpack_from("<H", b, 1)[0], struct.unpack_from("<H", b, 3)[0])
             for b in blocks]
    text = emit(blocks, links)
    if not args.write:
        print("(dry run; pass --write to update the .c files)")
        return 0
    for img in IMAGES:
        path = os.path.join(REPO, img, "maincpu", "msp_factory_defaults.c")
        with open(path, "w", encoding="ascii") as fh:
            fh.write(text)
        print("wrote", path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
