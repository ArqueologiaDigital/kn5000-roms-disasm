.macro string16 str
    .asciz "\str"
    .p2align 1, 0xff
.endm

    .text
    string16 "LCD PANEL TEST"
    string16 "SHORT"
