#!/usr/bin/env python3
"""
Replace screendata .s files with .incbin directives pointing to C-compiled binaries.
"""

import os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INCLUDES = os.path.join(REPO, 'maincpu', 'includes')

NAMES = {
    'ctlonly':     ('CtlOnly',     551),
    'main':        ('Main',        3531),
    'meascursor':  ('MeasCursor',  184),
    'yesctl':      ('YesCtl',      228),
}

for key, (display, total) in sorted(NAMES.items()):
    s_file = os.path.join(INCLUDES, f'style_ui_screendata_{key}.s')

    # Read existing source tag
    source = ''
    with open(s_file, 'rb') as f:
        for line in f:
            line_str = line.decode('latin-1', errors='replace').strip()
            if line_str.startswith('; Source:'):
                source = line_str.split('Source:')[1].strip()
                break

    content = f"""; StyleUI_ScreenData_{display}: Style UI screen data ({display})
; Total: {total} bytes
; Source: {source}
;
; Canonical source: maincpu/c_src/style_ui_screendata_{key}.c
; Built by: make screendata (clang -> llvm-objcopy -> .bin)
\t.incbin "includes/generated/style_ui_screendata_{key}.bin"
"""

    with open(s_file, 'wb') as f:
        f.write(content.encode('latin-1'))

    print(f"  {key}: {s_file} -> .incbin generated/{key}.bin")

print(f"\nDone. {len(NAMES)} files updated.")
