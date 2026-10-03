# v7's island at 0xFCCE4A (kn5000_v7_program.s, ported by scripts/lanes/sys/port_islands.py) holds v10's
# SndParam_RW_* code; its labels carried a _v7 suffix only because the drifted audio/sndparam_routines.s
# also defined the plain names.  The 2026-10-03 port (notes/v7-port-sndser-2026-10-03/) removed those.
s/\bSndParam_RW_ChainCheckFirst_v7\b/SndParam_RW_ChainCheckFirst/g
s/\bSndParam_RW_FoundCallback_v7\b/SndParam_RW_FoundCallback/g
s/\bSndParam_RW_ChainContinue_v7\b/SndParam_RW_ChainContinue/g
s/\bSndParam_RW_ProcessResult_v7\b/SndParam_RW_ProcessResult/g
