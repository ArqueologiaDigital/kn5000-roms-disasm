import re,sys
m={'AccPedal_CopyStyleMemBit0ToFlag13155':'AccPedal_LoadFlagFromStyleMem',
   'AccVoice_ResetRecords3246':'AccVoice_ResetFiveRecords',
   'Rhythm_DispatchHelperToFlag332B':'Rhythm_StoreDispatchHelperResult'}
for p in sys.argv[1:]:
    s=open(p,encoding='latin-1').read()
    for o,n in m.items():
        # prefix rename (covers _Done/_Rec0.. suffixes)
        s=re.sub(r'(?<![\w.$@])%s(?=[\w.$@]*)'%o,n,s)
    open(p,'w',encoding='latin-1').write(s)
