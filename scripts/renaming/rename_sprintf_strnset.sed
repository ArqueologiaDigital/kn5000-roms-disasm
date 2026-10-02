# Sprintf_DataBlock_28E9 is code, not data (re-framed 2026-10-03): strnset(s, c, n) --
# writes c into s[0..n) and stops at a NUL; returns s.
s/\bSprintf_DataBlock_28E9_Loop\b/Sprintf_StrNSet_Loop/g
s/\bSprintf_DataBlock_28E9_Join\b/Sprintf_StrNSet_Join/g
s/\bSprintf_DataBlock_28E9\b/Sprintf_StrNSet/g
