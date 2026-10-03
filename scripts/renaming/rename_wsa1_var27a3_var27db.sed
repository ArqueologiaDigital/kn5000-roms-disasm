# WSA1 prom_a, imported by prom_b by .set.  (0x27A3) is the 1..4 selector of Var27A3_GetValidSlot;
# (0x27DB) is a byte counter (Var27DB_Clear / Var27DB_Get already named).
s/\bsub_FD6B2E\b/Var27A3_SetSlot/g
s/\bsub_FD74AE\b/Var27A3_ChangeSlot/g
s/\bsub_FD7719\b/Var27DB_Increment/g
