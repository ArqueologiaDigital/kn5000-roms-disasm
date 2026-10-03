# The block at v10/v9 0xF6304A (v7 0xF62C46): on title 0xB6 (TITLE_CMSTEP) it prints six RAM bytes in hex at
# fixed screen positions -- a debug readout whose character output is a bare `ret`.  It was named as data.
s/\bAccPlayback_PartAssign_DataBlock\b/CmStep_DebugShowHexBytes/g
# v7/maincpu/transplant_manifest.txt: the bin-name column too (as rename_fdc_cmdrecalibrate.sed did)
s/\bv7_transplant_AccPlayback_PartAssign_DataBlock\.bin\b/v7_transplant_CmStep_DebugShowHexBytes.bin/g
