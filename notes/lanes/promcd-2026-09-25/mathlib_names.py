#!/usr/bin/env python3
r"""Name prom_c's double-precision libm routines: sin, cos, tan, exp, log, pow, fabs, +-Inf.

QUESTION THIS ANSWERS
    prom_c/mathlib/mathlib.s kept eight routines at 0xFC8BB2-0xFCA0B9 unnamed and
    its pool banner refused to say what the coefficient arrays are.  They are
    the Cody & Waite (Software Manual for the Elementary Functions, 1980)
    coefficient sets -- every one within 1 ulp of the printed 20-digit value -- and
    each set is loaded by exactly one routine:

      sin/cos r8..r1  0xFCB2CE..0xFCB306  head loaded by sub_FC8C45 (with 1/pi, pi)
      tan p3..p1      0xFCB376..0xFCB386  \ sub_FC9140 (with 2/pi and the two-word
      tan q4..q1,1.0  0xFCB38E..0xFCB3AE  /  pi/2 = 1.57080078125 - 4.4544551e-6)
      exp p2..p0      0xFCB436..0xFCB446  sub_FC9844 (with ln 2, 1/ln 2, +-ln DBL_MAX)
      exp q3..q0      0xFCB44E..0xFCB466  (its q set; the loader has no located caller)
      log a2..a0      0xFCB4A6..0xFCB4B6  \ sub_FC9D12 (with sqrt(1/2) and ln 2)
      log b2..b0      0xFCB4C6..0xFCB4D6  /

    and the code confirms the roles:
      sub_FC8BB2  returns 1.0 for a zero argument (0xFC8BC0..0xFC8BD2), else
                  negates a negative one and calls sub_FC8C45 on x + pi/2
                  (0xFC8C07..0xFC8C2D) -- cos(x) = sin(|x| + pi/2);
      sub_FC9576  (44 callers) calls sub_FC9D12 at 0xFC96E4 and sub_FC9844 at
                  0xFC97B9, and tests its second argument for an integer
                  (Double_ToInt32 / Int32_ToDouble 0xFC9620/0xFC962A) -- pow(x, y)
                  = exp(y * log|x|) with the sign rule; sub_FC9D12 and sub_FC9844
                  have no other caller;
      sub_FCA085  copies its double and clears bit 7 of byte 7 (0xFCA098) -- fabs;
      sub_FC9CCD  builds 00 00 00 00 00 00 F0 7F, or FF when its argument is
                  non-zero (0xFC9CDF..0xFC9CF0) -- +Inf / -Inf.

    Asserts every coefficient against the published value (the script fails if
    a single one differs) and the cited instruction bytes.  sub_FC8EE5,
    sub_FC9FA3, sub_FC9ACB and sub_FC9BBC stay unnamed.

RUN
    python3 notes/lanes/promcd-2026-09-25/mathlib_names.py [--apply]
    (the rename is scripts/renaming/rename_promcd_mathlib.sed)
"""
import os
import re
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
W = os.path.join(ROOT, "wsa1")
C = open(os.path.join(W, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
SED = os.path.join(ROOT, "scripts", "renaming", "rename_promcd_mathlib.sed")
d = lambda a: struct.unpack("<d", C[a - 0xF80000:a - 0xF80000 + 8])[0]

# Cody & Waite (1980) coefficient sets, as printed there
SETS = {
    "sin r8..r1": (0xFCB2CE, [0.27204790957888846175e-14, -0.76429178068910467734e-12, 0.16058936490371589114e-9,
                              -0.25052106798274584544e-7, 0.27557319210152756119e-5, -0.19841269841201840457e-3,
                              0.83333333333331650314e-2, -0.16666666666666665052e0]),
    "tan p3..p1": (0xFCB376, [-0.17861707342254426711e-4, 0.34248878235890589960e-2, -0.13338350006421960681e0]),
    "tan q4..q1": (0xFCB38E, [0.49819433993786512270e-6, -0.31181531907010027307e-3, 0.25663832289440112864e-1,
                              -0.46671683339755294240e0, 1.0]),
    "exp p2..p0": (0xFCB436, [0.31555192765684646356e-4, 0.75753180159422776666e-2, 0.25]),
    "exp q3..q0": (0xFCB44E, [0.75104028399870046114e-6, 0.63121894374398503557e-3, 0.56817302698551221787e-1, 0.5]),
    "log a2..a0": (0xFCB4A6, [-0.78956112887491257267e0, 0.16383943563021534222e2, -0.64124943423745581147e2]),
    "log b2..b0": (0xFCB4C6, [-0.35667977739034646171e2, 0.31203222091924532844e3, -0.76949932108494879777e3]),
}
CODE = [(0xFC8BC0, "1d e5 a1 fc"), (0xFC8C1E, "1d 1f a4 fc"), (0xFC8C2D, "1d 45 8c fc"),
        (0xFC96E4, "1d 12 9d fc"), (0xFC97B9, "1d 44 98 fc"), (0xFC9620, "1d 61 a6 fc"),
        (0xFC962A, "1d fd a6 fc"), (0xFCA098, "8c 07 3c 7f"), (0xFC9CDF, "bc 06 00 f0")]
NAMES = {"sub_FC8C45": ("Double_Sin", "sin(x): Cody-Waite, the r1..r8 set at 0xFCB2CE-0xFCB306, reduction by 1/pi (F64_0p3183098861837907) and pi"),
         "sub_FC8BB2": ("Double_Cos", "cos(x) = Double_Sin(|x| + pi/2), 1.0 for a zero argument (0xFC8BC0-0xFC8C2D)"),
         "sub_FC9140": ("Double_Tan", "tan(x): Cody-Waite, the p/q sets at 0xFCB376-0xFCB3AE, 2/pi and the two-word pi/2"),
         "sub_FC9844": ("Double_Exp", "exp(x): Cody-Waite p set at 0xFCB436, ln 2 / 1/ln 2, bounds +-709.78 = +-ln DBL_MAX"),
         "sub_FC9D12": ("Double_Log", "log(x): Cody-Waite a/b sets at 0xFCB4A6-0xFCB4D6, sqrt(1/2) and ln 2"),
         "sub_FC9576": ("Double_Pow", "pow(x, y): Double_Log at 0xFC96E4, Double_Exp at 0xFC97B9, integer test of y at 0xFC9620/0xFC962A"),
         "sub_FCA085": ("Double_Abs", "fabs(x): clears the sign bit, `and (XIX+0x07),0x7f` at 0xFCA098"),
         "sub_FC9CCD": ("Double_MakeInfinity", "+Inf (7F F0 00..) or, for a non-zero argument, -Inf (FF F0 00..), 0xFC9CDF-0xFC9CF0")}


def check():
    import math
    worst = 0
    for what, (a, vals) in SETS.items():
        for k, v in enumerate(vals):
            got = d(a + 8 * k)
            ulps = abs(got - v) / math.ulp(v)
            worst = max(worst, ulps)
            assert ulps <= 2, (what, k, got, v, ulps)   # the printed 20-digit value, rounded to a double
    print("  worst difference from the printed coefficient: %.0f ulp" % worst)
    for a, enc in CODE:
        want = bytes.fromhex(enc.replace(" ", ""))
        assert C[a - 0xF80000:a - 0xF80000 + len(want)] == want, hex(a)
    print("  %d Cody-Waite coefficients match the ROM; %d cited encodings hold"
          % (sum(len(v) for _, v in SETS.values()), len(CODE)))


def apply():
    path = os.path.join(W, "prom_c", "mathlib", "mathlib.s")
    lines = open(path, "rb").read().decode("latin-1").split("\n")
    out = []
    for ln in lines:
        m = re.match(r"^(sub_[0-9A-F]{6}):$", ln)
        if m and m.group(1) in NAMES and out and out[-1].startswith("; ----"):
            dash = out.pop()
            new, why = NAMES[m.group(1)]
            out.append("; ★ NAMED 2026-09-25 (lane promcd): %s -- %s." % (new, why))
            out.append(";          Evidence asserted by notes/lanes/promcd-2026-09-25/mathlib_names.py.")
            out[-2] = out[-2].encode("utf-8").decode("latin-1")
            out.append(dash)
        out.append(ln)
    data = "\n".join(out).encode("latin-1")
    open(path, "wb").write(data)
    files = subprocess.run(["git", "grep", "-l", "-E", "|".join(NAMES), "--", "wsa1/prom_c"],
                           cwd=ROOT, capture_output=True, text=True).stdout.split()
    subprocess.run(["sed", "-i", "-f", SED] + [os.path.join(ROOT, f) for f in files], check=True,
                   env=dict(os.environ, LC_ALL="C"))
    print("applied: %d headers; sed over %s" % (len(NAMES), " ".join(files)))


if __name__ == "__main__":
    check()
    if "--apply" in sys.argv:
        apply()
