/* naka_sequencer_exit_link.ld — Linker script for naka_sequencer_exit.c */

ENTRY(0)

SECTIONS {
    .text : { *(.text*) *(.rodata*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}

/* Linked widget descriptors */
NakaDesc_FuncTtlNo_B     = 0x00E270A6;
NakaDesc_Empty_C          = 0x00E270C2;
NakaDesc_Empty_D          = 0x00E270C8;
NakaDesc_FuncIndex        = 0x00E270CE;
NakaDesc_Mode             = 0x00E270F0;
NakaDesc_ColorFontPageFunc = 0x00E27100;
NakaDesc_SeqExitWidgets              = 0x00E2713C;
NakaDesc_Empty_E          = 0x00E27142;
NakaDesc_Empty_F          = 0x00E27148;
NakaDesc_Empty_G          = 0x00E2714E;
NakaDesc_Empty_H          = 0x00E27154;
NakaDesc_Empty_I          = 0x00E2715A;
NakaDesc_StyleFunc        = 0x00E27160;
NakaDesc_Empty_J          = 0x00E2717A;

/* Proc handler functions */
EqOnOffFuncToggleProc     = 0x00F345E4;
MsgToTtlProc              = 0x00F2EFFA;
AcIndexWideToggleProc     = 0x00F2ECF1;
IvPlayExitProc            = 0x00F2EB76;
HelpTtlProc               = 0x00F2E8A4;
IvPnlWrExitProc           = 0x00F309D7;
IvSdrevProc               = 0x00F2E97E;
IvSddspProc               = 0x00F2EA1D;
IvSdaccProc               = 0x00F2EAD8;
IvPunchExitProc           = 0x00F2EBFF;
IvAutoPunchExitProc       = 0x00F2EC74;
AcPanicEditSwProc         = 0x00F2E532;
IvRealRecExitProc         = 0x00F2E490;
