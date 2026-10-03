# WSA1 prom_a 0xFD6132..0xFD686B (prom_b imports by .set): the CPU 1 tone-message sender and its twenty
# builders (wsa1/notes/FINDINGS-l7a1429-parameter-names.md 2c, FINDINGS-l7a1429-editor-pages.md 4a).
# ToneMsg<class>_Id<byte2>: byte[0] = class, byte[2] = id; _SendParam: byte[2] from an argument.
s/\bsub_FD6132\b/ToneMsg_Send/g
s/\bsub_FD6917\b/ToneMsg_ApplySelector/g
s/\bsub_FD616A\b/ToneMsg_SendParam/g
s/\bsub_FD61CF\b/ToneMsg80_SendParam/g
s/\bsub_FD622B\b/ToneMsg80_Id01/g
s/\bsub_FD62B4\b/ToneMsg80_Id12/g
s/\bsub_FD6316\b/ToneMsg80_Id13/g
s/\bsub_FD638B\b/ToneMsg80_Id10/g
s/\bsub_FD63D7\b/ToneMsg85_SendParam/g
s/\bsub_FD6447\b/ToneMsg80_Id00/g
s/\bsub_FD648D\b/ToneMsg80_Id04/g
s/\bsub_FD64D1\b/ToneMsg80_Id15_Part0/g
s/\bsub_FD6513\b/ToneMsg80_Id16/g
s/\bsub_FD655D\b/ToneMsg88_Id15/g
s/\bsub_FD65D8\b/ToneMsg88_Id16/g
s/\bsub_FD6669\b/ToneMsg88_Id13/g
s/\bsub_FD66A6\b/ToneMsg88_Id14/g
s/\bsub_FD6704\b/ToneMsg8D_SendParam/g
s/\bsub_FD677F\b/ToneMsg88_Id00/g
s/\bsub_FD67C9\b/ToneMsg88_Id0D/g
s/\bsub_FD6811\b/ToneMsg88_Id1A/g
s/\bsub_FD686B\b/ToneMsg80_Id0B_Part0/g
