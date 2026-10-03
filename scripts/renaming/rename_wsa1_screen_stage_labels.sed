# The screen objects' button maps and their key handlers carried the RAM address of the byte that
# picks them: ButtonTable_<screen>_207EZero / _207ENonZero.  (0x207E) is UI_ScreenStage since
# 4167723f (wsa1/notes/FINDINGS-prom_ab-screen-stage-and-flags.md): stage 0 is the parameter page,
# non-zero the "Are You Sure ?" page.
s/207ENonZero/StageNonZero/g
s/207EZero/StageZero/g
