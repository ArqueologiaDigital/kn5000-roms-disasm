# Rename maincpu FDC_SeekRecalibrate -> FDC_CmdRecalibrate (match the
# bootloader twin's name established by table_data/boot_fdc_driver.s).
# Verified: the routine at 0xF97652 is the byte-level twin of the boot
# FDC_CmdRecalibrate (recalibrate to track 0 via a track-5 settling seek,
# then RECALIBRATE 0x07); the old name is kept as a comment alias at the
# definition sites.
#
# Apply to:
#   v10/maincpu/storage/fdc_routines.s
#   v9/maincpu/storage/fdc_routines.s
#   v7/maincpu/storage/fdc_routines.s   (also renames the transplant incbin path)
#   v7/maincpu/transplant_manifest.txt  (bin name + label columns)
#   table_data/kn5000_table_data.s      (dispatch-table twin comment)
#   table_data/boot_fdc_driver.s        (Twin: header comment)
s/FDC_SeekRecalibrate/FDC_CmdRecalibrate/g

# Apply to symbols/maincpu_symbols_reference.txt only: the file still held the
# pre-rename placeholder name for 0xF97652 (stale since rename_fdc_labels.py).
s/^LABEL_F97652 0xF97652$/FDC_CmdRecalibrate 0xF97652/
