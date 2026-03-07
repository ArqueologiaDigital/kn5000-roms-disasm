# Rename toshi_data.s note name and multilingual string tables
# Note name tables (chromatic scale display strings, different key signatures)
s/LABEL_ED02A0/NoteNameStr_Table_0/g
s/LABEL_ED0326/NoteNameStr_Table_1/g
s/LABEL_ED03B0/NoteNameStr_Table_2/g
s/LABEL_ED043A/NoteNameStr_Table_3/g

# Multilingual UI message tables (5 entries = 5 languages: EN, DE, FR, ES, ID)
s/LABEL_ED04C8/Str_Attention_Multilingual/g
s/LABEL_ED07BE/Str_FactoryResetDesc_Multilingual/g
s/LABEL_ED0A78/Str_StoreSoundBalance_Multilingual/g
s/LABEL_ED0B80/Str_StoreTotalSetting_Multilingual/g

# Multilingual attention warning strings (targets of Str_Attention_Multilingual)
s/LABEL_ED04DC/Str_Attention_ID/g
s/LABEL_ED04E8/Str_Attention_IT/g
s/LABEL_ED04F0/Str_Attention_ES/g
s/LABEL_ED04FC/Str_Attention_FR/g
s/LABEL_ED0508/Str_Attention_DE/g
s/LABEL_ED0512/Str_Attention_EN/g
