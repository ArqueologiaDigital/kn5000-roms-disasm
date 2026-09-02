#!/usr/bin/env python3
"""v142_decode_region.py -- Decode one blocked region via unidasm and re-assemble it, to see whether it survives a round trip.

RUN
    python3 scripts/analysis/v142_decode_region.py

⚠ A round trip is NECESSARY but NOT SUFFICIENT. The byte gate cannot catch
  data framed as code: re-assembling a wrong interpretation reproduces the
  same bytes. Corroborate with call targets landing on routines already named
  in the tree before converting anything this reports.

⚠ A decoder FAILING is not evidence the bytes are data. The disassembler has
  no case at all for the register-indexed SriRR family and decodeERPPrefix is
  a stub, so silence here means "unknown", never "not code".
"""
"""Self-verifying byte->instruction decoder for a raw byte stream.

Strategy: at each position, try KNOWN forced-mnemonic special cases first
(explicit-displacement / bit-mem forms whose generic short spelling is
AMBIGUOUS and reassembles to fewer bytes than truly present). Otherwise fall
back to llvm-mc's own decode of the FIRST instruction in the remaining
stream, but verify true consumed length by reassembling THAT INSTRUCTION
ALONE and checking it reproduces the exact byte slice -- never trust
--show-encoding's length blindly (it can be a RE-ENCODE, not the true
consumed length; proven via 0xbb 0x00 0x50 <-> 0xb3 0x50 collision and the
0x9c 0x00 0x20 <-> 0x94 0x20 zero-displacement collision).
"""
import re, subprocess, sys
from pathlib import Path

MC = str(Path.home() / 'compartilhado/llvm-project/build/bin/llvm-mc')

R8 = ["w", "a", "b", "c", "d", "e", "h", "l"]
R16 = ["wa", "bc", "de", "hl", "ix", "iy", "iz", "sp"]
R32 = ["xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp"]

ENC_RE = re.compile(rb'encoding: \[([^\]]+)\]')

def asm_one(text):
    r = subprocess.run([MC, '--triple=tlcs900', '--show-encoding', '-'],
                        input=(text+'\n').encode(), capture_output=True, timeout=30)
    m = ENC_RE.search(r.stdout)
    if not m:
        return None
    return bytes(int(x,16) for x in m.group(1).decode().split(','))

def special(raw, i):
    """Try forced-mnemonic explicit-displacement / bit-mem forms.
    Returns (text, length, comment_or_None) or None."""
    n = len(raw) - i
    b0 = raw[i] if n > 0 else None
    # ld8_src_rid8 / ld16_src_rid8: prefix 0x88-0x8F (byte) / 0x98-0x9F (word),
    # + disp byte + subop 0x20-0x27 (reg encoded in low 3 bits)
    if n >= 3 and 0x88 <= b0 <= 0x8F and 0x20 <= raw[i+2] <= 0x27:
        base, disp, sub = R32[b0-0x88], raw[i+1], raw[i+2]
        reg = R8[sub-0x20]
        return (f"ld8_src_rid8\t{base}, {disp:#04x}, {reg}", 3,
                f"ld {reg},({base.upper()}+{disp:#04x})")
    if n >= 3 and 0x98 <= b0 <= 0x9F and 0x20 <= raw[i+2] <= 0x27:
        base, disp, sub = R32[b0-0x98], raw[i+1], raw[i+2]
        reg = R16[sub-0x20]
        return (f"ld16_src_rid8\t{base}, {disp:#04x}, {reg}", 3,
                f"ld {reg},({base.upper()}+{disp:#04x})")
    # ld_dst16_rid8: prefix 0xB8-0xBF + disp + subop 0x50-0x57
    if n >= 3 and 0xB8 <= b0 <= 0xBF and 0x50 <= raw[i+2] <= 0x57:
        base, disp, sub = R32[b0-0xB8], raw[i+1], raw[i+2]
        reg = R16[sub-0x50]
        return (f"ld_dst16_rid8\t{base}, {disp:#04x}, {reg}", 3,
                f"ld ({base.upper()}+{disp:#04x}),{reg}")
    # lda_rid8: prefix 0xB8-0xBF + disp + subop 0x20-0x27 (32-bit dest reg)
    if n >= 3 and 0xB8 <= b0 <= 0xBF and 0x20 <= raw[i+2] <= 0x27:
        base, disp, sub = R32[b0-0xB8], raw[i+1], raw[i+2]
        reg = R32[sub-0x20]
        return (f"lda_rid8\t{base}, {disp:#04x}, {reg}", 3,
                f"lda {reg},({base.upper()}+{disp:#04x})")
    # resm/setm/bitm bit,(mem): prefix 0xB0-0xB7 (no disp) + subop
    # 0xB0-0xB7 (res) / 0xB8-0xBF (set) / 0xC8-0xCF (bit)
    if n >= 2 and 0xB0 <= b0 <= 0xB7:
        sub = raw[i+1]
        base = R32[b0-0xB0]
        if 0xB0 <= sub <= 0xB7:
            return f"resm\t{sub-0xB0}, ({base})", 2, None
        if 0xB8 <= sub <= 0xBF:
            return f"setm\t{sub-0xB8}, ({base})", 2, None
        if 0xC8 <= sub <= 0xCF:
            return f"bitm\t{sub-0xC8}, ({base})", 2, None
    # and8_imm_rid8 / cp8_imm_rid8: prefix 0x88-0x8F + disp + subop (0x3C/0x3F) + imm8
    if n >= 4 and 0x88 <= b0 <= 0x8F:
        who = {0x3C: "and8_imm_rid8", 0x3F: "cp8_imm_rid8"}.get(raw[i+2])
        if who:
            base, disp, imm = R32[b0-0x88], raw[i+1], raw[i+3]
            mnem = who.split('8_')[0]
            return (f"{who}\t{base}, {disp:#04x}, {imm:#04x}", 4,
                    f"{mnem} ({base.upper()}+{disp:#04x}),{imm:#04x}")
    # ldc_cr16: prefix 0xD8-0xDF (16-bit reg, WA..IY/IZ; SP has no encoding) + 0x2E + cr_byte
    if n >= 3 and 0xD8 <= b0 <= 0xDE and raw[i+1] == 0x2E:
        return f"ldc_cr16\t{R16[b0-0xD8]}, {raw[i+2]:#04x}", 3, None
    return None

def decode_stream(raw):
    """Returns (list of (text, length, bytes)), or raises on unresolved byte."""
    out = []
    i = 0
    n = len(raw)
    while i < n:
        sp = special(raw, i)
        if sp:
            text, length, comment = sp
            enc = asm_one(text)
            if enc == bytes(raw[i:i+length]):
                out.append((text, length, enc, comment))
                i += length
                continue
            else:
                raise ValueError(f"special-case {text!r} at offset {i} did not "
                                  f"verify: got {enc}, want {raw[i:i+length]!r}")
        # generic fallback: decode first instruction of the remaining stream
        hex_str = ' '.join(f'0x{b:02x}' for b in raw[i:]) + '\n'
        r = subprocess.run([MC, '--triple=tlcs900', '--disassemble', '--show-encoding', '-'],
                            input=hex_str.encode(), capture_output=True, timeout=30)
        err = r.stderr.decode(errors='replace')
        out_txt = r.stdout.decode(errors='replace').strip().splitlines()
        WARN_RE = re.compile(r'^<stdin>:1:(\d+): warning: invalid instruction encoding$')
        fails_at_0 = any((int(m.group(1)) - 1) // 5 == 0
                          for l in err.splitlines() if (m := WARN_RE.match(l.strip())))
        if not out_txt or fails_at_0:
            # hard failure right here (position 0 of the remaining slice)
            raise ValueError(f"HARD DECODE FAILURE at offset {i}: byte 0x{raw[i]:02x}, "
                              f"context {bytes(raw[i:i+8]).hex(' ')}")
        first = out_txt[0].strip()
        m = ENC_RE.search(first.encode())
        text = first.split(';', 1)[0].strip()
        enc = asm_one(text)
        if enc is None:
            raise ValueError(f"cannot reassemble decoded text {text!r} at offset {i}")
        if bytes(raw[i:i+len(enc)]) == enc:
            out.append((text, len(enc), enc, None))
            i += len(enc)
            continue
        # length mismatch / silent-miscompile family: try growing window up to 8
        raise ValueError(f"SILENT MISCOMPILE / unresolved ambiguity at offset {i}: "
                          f"decoded {text!r} claims {enc.hex(' ')} but stream has "
                          f"{bytes(raw[i:i+8]).hex(' ')}")
    return out
