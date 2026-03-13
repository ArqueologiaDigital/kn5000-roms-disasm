#!/usr/bin/env python3
"""
Replace paramblock .s files with .incbin directives pointing to C-compiled binaries.

Each .s file becomes a thin wrapper that .incbin's the corresponding generated .bin file.
The C source in c_src/ is now the canonical source for the data.
"""

import os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INCLUDES = os.path.join(REPO, 'maincpu', 'includes')

NAMES = {
    'alta':     ('AltA',     39),
    'altb':     ('AltB',     41),
    'altc':     ('AltC',     111),
    'altd':     ('AltD',     80),
    'alte':     ('AltE',     115),
    'bal':      ('BAL',      250),
    'common':   ('Common',   152),
    'extended': ('Extended', 183),
    'meas':     ('MEAS',     155),
    'medium':   ('Medium',   191),
    'short':    ('Short',    39),
    'value':    ('VALUE',    39),
}

for key, (display, total) in sorted(NAMES.items()):
    s_file = os.path.join(INCLUDES, f'style_ui_paramblock_{key}.s')

    # Read existing source tag
    source = ''
    with open(s_file, 'rb') as f:
        for line in f:
            line_str = line.decode('latin-1', errors='replace').strip()
            if line_str.startswith('; Source:'):
                source = line_str.split('Source:')[1].strip()
                break

    content = f"""; StyleUI_ParamBlock_{display}: Style UI parameter block ({display})
; Total: {total} bytes
; Source: {source}
;
; Canonical source: maincpu/c_src/style_ui_paramblock_{key}.c
; Built by: make paramblocks (clang -> llvm-objcopy -> .bin)
\t.incbin "includes/generated/style_ui_paramblock_{key}.bin"
"""

    with open(s_file, 'wb') as f:
        f.write(content.encode('latin-1'))

    print(f"  {key}: {s_file} -> .incbin generated/{key}.bin")

print(f"\nDone. {len(NAMES)} files updated.")
