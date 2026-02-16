# Sed script for batch renaming address-based labels to semantic names
# Generated during investigation of 0x60 command handler and EFF routines

# === 0x60 Command Handler Related ===
# Ring buffer write loop - enqueues bytes into DSP command queue
s/LABEL_035910/DSP_RingBuf_Enqueue/g
# Extract 14-bit payload size from bytes at offsets +5/+6
s/LABEL_035936/Extract_14Bit_PayloadSize/g
# Extract 14-bit value from bytes at offsets +2/+3
s/LABEL_03597D/Extract_14Bit_VoiceParam/g
# Dequeue 7-byte DSP command header from ring buffer into 0x4369-0x436F
s/LABEL_035997/DSP_Cmd_DequeueHeader/g
# Process 290-byte effect preset bundle (8-byte header + 5*56 effect slots + 2 footer)
s/LABEL_0359DB/DSP_Cmd_LoadEffectPreset/g

# === DSP Configuration Routines ===
# Apply DSP configuration based on effect type (WA=0-4)
s/LABEL_03616A/DSP_ApplyConfig/g
# Apply config and read DSP status with fallback reconfig
s/LABEL_0361C5/DSP_ReconfigAndStatus/g
# Get DSP config buffer pointer (returns 448Eh)
s/LABEL_0361D4/DSP_GetConfigBuffer/g
# Get EFF slot buffer pointer (4496h + slot*0x38), validates slot 0-4
s/LABEL_0361D9/EFF_GetSlotBuffer/g
# Schedule DSP processing delay
s/LABEL_038392/DSP_ScheduleDelay/g
# Wait for scheduled DSP delay using microsecond timer (1040h)
s/LABEL_036305/DSP_WaitForDelay/g

# === EFF Processing Pipeline ===
# Prepare EFF state for processing (calls three setup routines)
s/LABEL_03774E/EFF_StateLoad_Prepare/g
# Return MAX(BC, WA) - unsigned comparison for delay selection
s/LABEL_037848/Unsigned_Max_Select/g
# Iterate through EFF parameters, call EFF_ParamEdit_WithDebug for dirty params
s/LABEL_037851/EFF_ParamIterator_Process/g
# Check EFF volume change flag (4960h+EFF*0x32+0x10), call param iterator if set
s/LABEL_03798B/EFF_VolumeChange_Check/g
# Handle disconnect, config change, and data change for single EFF channel
s/LABEL_0379A7/EFF_Change_Handler/g
# Write disconnect configuration to DSP for an EFF channel
s/LABEL_037F4F/EFF_Disconnect/g
# Write link configuration to DSP for an EFF channel
s/LABEL_037FAE/EFF_Link/g
# Print "EFF %d vol %d" and update volume parameter
s/LABEL_03826E/EFF_VolumeUpdate_WithDebug/g
