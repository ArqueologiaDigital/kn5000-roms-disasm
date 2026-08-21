import re
f='/home/fsanches/compartilhado/kn5000-roms-disasm/v142/subcpu/kn5000_subprogram_v142.s'
L=open(f,encoding='latin-1').read().split('\n')
lab=re.compile(r'^([A-Za-z_][\w]*):')
def enc(n):
    for i in range(n-1,-1,-1):
        m=lab.match(L[i])
        if m: return m.group(1), i+1
    return None,None
for n in [4297,4372,4386,4751,19791,19802,20478,20539,38555,51744,51754,51796,51817,51847,51928,51955,51961,51964,37370,37345]:
    lb,ln=enc(n); print('%5d %-42s (label@%d)  %r'%(n,lb,ln,L[n-1][:78]))
print("=== label lines ===")
for name in ['CmdTable_InitEntry_Loop','ChanStruct_Init_Entry','ChanStruct_Init_Entry_AltPtr','Voice_Allocate_Nodes','Voice_Slot_ApplyPortamentoDelta','Voice_Slot_ApplyPortamentoDelta_BranchD','Voice_Poly_NoteOn_SlotFound','DSP_WriteEFFConfig','DSP_WriteGlobalConfig','DSP_WriteParameter','DSP_BytecodeInterpreter_Init','DSP_BytecodeInterpreter_Loop','MIDI_Dispatch','Audio_Process_Init']:
    for i,l in enumerate(L):
        if l==name+':': print('%-42s label@%d'%(name,i+1)); break
