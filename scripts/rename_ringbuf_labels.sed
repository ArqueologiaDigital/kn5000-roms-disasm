# Rename sequencer ring buffer core routines
s/LABEL_EF2F69/Seq_RingBuf_Init_256/g
s/LABEL_EF2F83/Seq_RingBuf_ReadByte/g
s/LABEL_EF2FD7/Seq_RingBuf_WriteByte_Small/g
s/LABEL_EF2FF8/Seq_RingBuf_Init_512/g
s/LABEL_EF3087/Seq_RingBuf_Init_1024/g
s/LABEL_EF30BF/Seq_RingBuf_ReadData/g
s/LABEL_EF30F5/Seq_RingBuf_WriteByte/g
s/LABEL_EF3116/Seq_RingBuf_Init_2048/g

# Rename Seq_Main wrappers (buffer at 0x01F37B)
s/LABEL_EF276D/SeqMain_WriteByte/g
s/LABEL_EF2783/SeqMain_WriteBytes/g
s/LABEL_EF27B7/SeqMain_GetTimingValue/g
s/LABEL_EF27BD/SeqMain_InitBuffer/g
s/LABEL_EF27CB/SeqMain_SaveWritePos/g
s/LABEL_EF27D8/SeqMain_ReadData/g

# Rename Seq_Alt1 wrappers (buffer at 0x01F785)
s/LABEL_EF280E/SeqAlt1_ReadByte/g

# Rename Seq_Alt2 wrappers (buffer at 0x01FCA3)
s/LABEL_EF2A25/SeqAlt2_WriteByte/g
s/LABEL_EF2A3B/SeqAlt2_WriteBytes/g
s/LABEL_EF2A75/SeqAlt2_InitBuffer/g
s/LABEL_EF2A5D/SeqAlt2_CheckSongEnd/g

# Rename Seq_Alt3 wrappers (buffer at 0x0201C1)
s/LABEL_EF2C22/SeqAlt3_ReadByte/g

# Rename Seq_Alt4 wrappers (buffer at 0x0204DF)
s/LABEL_EF2E2C/SeqAlt4_ReadByte/g
s/LABEL_EF2E71/SeqAlt4_CheckSongEnd/g
