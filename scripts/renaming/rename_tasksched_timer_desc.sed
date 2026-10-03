# boot/system_handlers.s: the descriptor TaskSched_InitMsgQueues passes to TaskTimer_Register in XWA
# (v10/v9 0xEF1A7E, v7 0xEF1A54); was decoded as `normal / nop / normal / nop / jr pe, 25 ...`.
s/\bTaskSched_InitMsgQueues_Code\b/TaskSched_TimerDesc_Slot1/g
