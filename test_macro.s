.macro aligned_string str:vararg
    .asciz \str
    .p2align 1, 0xff
.endm

    .text
    aligned_string "LCD PANEL TEST"
