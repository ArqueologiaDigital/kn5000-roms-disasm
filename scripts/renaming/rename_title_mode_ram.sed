# 0x8D36 is the CURRENT TITLE id (EVT_CHANGE_TITLE -> SeqState_TransitionMode stores it), not a
# "master sequencer state": its skip range 0x10-0x16 is exactly the TT_STYLCNV* titles.  0x8D38/0x8D39
# are the ACTIVE title (also set by EVT_RETURN_TITLE / EVT_INTERRUPT_TITLE) and its previous value.
s/\bSEQ_MASTER_STATE\b/CURRENT_TITLE/g
s/\bMAIN_TITLE_CURRENT\b/ACTIVE_TITLE/g
s/\bMAIN_TITLE_PREVIOUS\b/ACTIVE_TITLE_PREVIOUS/g
