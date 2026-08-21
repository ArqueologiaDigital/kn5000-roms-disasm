import os
R='/home/fsanches/compartilhado/kn5000-roms-disasm/'
A=[
(0,'v142/subcpu/kn5000_subprogram_v142.s',
"""; The four tables are exactly 10/9/9/10 entries and butt up against each other
; (0x00F786+0x14 = 0x00F79A, 0x00F79A+0x12 = 0x00F7AC, 0x00F7AC+0x12 = 0x00F7BE,
; 0x00F7BE+0x14 = 0x00F7D2), which is what pins COUNT to 0..9 and INDEX to 0..8."""),
(1,'v142/subcpu/kn5000_subprogram_v142.s',
""";        +0 = read pointer (16-bit)
;        +2 = write pointer (16-bit)"""),
(2,'v142/subcpu/subcpu_data_tables.s',
"""; --- 0x00F786-0x00F7E5  VOICE_SELECTOR_MIXWEIGHT_TABLES (outside this region)
; Four adjacent u16 tables consumed by Voice_Selector_ComputeMixWeights, sized exactly to
; their index ranges: 0x00F786 (10 entries, indexed by COUNT 0..9) -> part+0x10E;
; 0x00F79A (9 entries, indexed by INDEX 0..8) -> """),
(3,'v142/subcpu/subcpu_data_tables.s',
"""; The DSP bytecode interpreter's PRIMARY opcode dispatch. DSP_BytecodeInterpreter_Init takes the
; high nibble of the fetched byte (`srl wa,4`), special-cases 0x0E (SendCommand) and 0x0D
; (StateChange), rejects >5, then `add wa,wa / lda_24 xix,0x014739 / ldw_sri WA /
; lda_24 xix,0x03c32e / jp_ind`"""),
(4,'v142/subcpu/subcpu_data_tables.s',"; --- 0x014739-0x014744  DSP_Bytecode_HandlerOffsetTable"),
(5,'v142/subcpu/subcpu_data_tables.s',"; --- 0x014745-0x014776  DSP_Translator_OpcodeOffsetTable"),
(6,'v142/subcpu/subcpu_data_tables.s',"; --- 0x014777-0x0147B2  DSP_EFFBytecode_ProgramTable"),
(7,'v142/subcpu/kn5000_subprogram_v142.s',"; Called from Audio_Process_Init (0x032197) when the audio-tick phase byte at 0x041342 is 0,"),
(8,'v142/subcpu/kn5000_subprogram_v142.s',"; 0x27E7, the MIDI BACKLOG GAUGE.  Sole caller: MIDI_Dispatch (0x0374F5).  The value is"),
(9,'v142/subcpu/subcpu_data_tables.s',"; Both read by CmdTable_InitEntry_Loop (subcpu source ~line 3990): it walks i = 0..0x11 (18),"),
(10,'v142/subcpu/subcpu_data_tables.s',"; code, ChanStruct_Init_Entry / _AltPtr (subcpu source ~line 4066/4080): index = channel*4,"),
(11,'v142/subcpu/subcpu_data_tables.s',"; Indexing proved in Voice_Allocate_Nodes (subcpu source ~line 4405): it takes the byte at"),
(12,'v142/subcpu/subcpu_data_tables.s',"; `add wa,wa / lda_24 xbc,0x00f786 / ldw_sri WA / stw_dri` (subcpu source ~line 17230); the"),
(13,'v142/subcpu/subcpu_data_tables.s',"; 9 x s16 -> DRAM 0x04147A + part*0x11F (subcpu source ~line 17241), same idiom as 0x00F786."),
(14,'v142/subcpu/subcpu_data_tables.s',"; 0xFFF clamp, inside Voice_Slot_ApplyPortamentoDelta (subcpu source ~line 17835). The scaling"),
(15,'v142/subcpu/subcpu_data_tables.s',"; path (subcpu source ~line 33331). Entries: 0x0355AD, 0x035656, then 0x0355AD four more times."),
(16,'v142/subcpu/subcpu_data_tables.s',"; DSP_WriteParameter x2, subcpu source 44822/44863/44883/44912). It is DSP program+parameter"),
(17,'CLAUDE.md',
"""| maincpu | `maincpu/kn5000_v10_program.asm` | 100% |
| subcpu payload | `subcpu/kn5000_subprogram_v142.asm` | 100% |
| table_data | `table_data/kn5000_table_data.asm` | ~33% |
| hdae5000 | `hdae5000/hd-ae5000_v2_06i.asm` | ~5% |"""),
(18,'v142/subcpu/kn5000_subprogram_v142.s',"; Notes: Clears DSP2 control variables at 0x3B60-0x3B64"),
]
for idx,f,a in A:
    t=open(R+f,encoding='utf-8',errors='replace').read()
    n=t.count(a)
    line = t[:t.find(a)].count('\n')+1 if n else None
    # does the anchor end mid-line?
    mid=''
    if n:
        p=t.find(a)+len(a)
        rest=t[p:t.find('\n',p)] if t.find('\n',p)!=-1 else ''
        if rest.strip()!='' : mid='  MID-LINE-END leftover=%r'%rest
    print('[%2d] %-40s count=%d line=%s%s'%(idx,os.path.basename(f),n,line,mid))
