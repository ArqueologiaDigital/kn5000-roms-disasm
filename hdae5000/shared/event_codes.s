; =============================================================================
; Event Code Constants
; See https://arqueologiadigital.github.io/technics-docs/event-codes/ for details
; =============================================================================

; ClassProc getter events (handled by jump table at 0xEAA8F8)
.equ EVT_GET_CLASS_SP, 0x1e00000	; MT_GetClassSp. Asks an object table's proc for the class id of the object. SendEvent asks this of every target
.equ EVT_GET_PARENT_CLASS_SP, 0x1e00001	; MT_GetParentClassSp. Class-level query that returns the parent class id (Class record +4 'parent').
.equ EVT_GET_PROCEDURE_SP, 0x1e00002	; MT_GetProcedureSp. Returns the class procedure pointer (Class record +0 'proc').
.equ EVT_GET_INSTANCE_SIZE_SP, 0x1e00003	; MT_GetInstanceSizeSp. Returns the instance size of the class (WORD at Class record +8 'allsize'). Not *(XHL+0x

; ClassProc special events
.equ EVT_GET_PROP_DATA_SP, 0x1e0000d	; MT_GetPropDataSp. Returns entry #n of an ID-typed property's value domain: FontIDProc returns the n-th font fr
.equ EVT_GET_PROP_DATA_COUNT_SP, 0x1e0000e	; MT_GetPropDataCountSp. Number of entries in an ID-typed property's value domain; FontIDProc returns the font c
.equ EVT_GET_INSTANCE, 0x1e0000f	; MT_GetInstance. Returns a pointer to the object's instance record: the class record for a class, the mode or t
.equ EVT_GET_NAME, 0x1e00015	; MT_GetName. Returns the object's name string pointer. For a class this is record+12; for Function, ApFunction,

; ObjectProc lifecycle events (handled by jump table at 0xEAA8A4)
.equ EVT_CHECK_CLASS, 0x1e00014	; MT_CheckClass. Object-level is-a test: returns 1 if the object's class is, or derives from, the class id in th

; Request/action events (reach record function directly)
.equ EVT_SHOW, 0x1c00001	; View shown (firmware EV_SHOW). Sent to a title's view after it becomes current; ViewableProc broadcasts it dow
.equ EVT_HIDE, 0x1c00002	; View hidden/closed (firmware EV_HIDE); broadcast down the view tree like EV_SHOW.
.equ EVT_SW_ON, 0x1c00008	; Panel switch pressed (firmware EV_SWON), param = switch number. Not specific to DISK MENU.
.equ EVT_DRAW, 0x1c0000d	; Draw this view only (firmware EV_DRAW); EV_PAINT and EV_REPAINT send it to self.
.equ EVT_PARA_DRAW, 0x1c0000f	; Draw the parameter/value text (firmware EV_PARADRAW); param = string pointer, or 0 to fetch the text with 0x1E
.equ EVT_ACTIVATE_STATE, 0x1c00013	; Activation-state notification to a mode or title object (firmware EV_ACTIVATE). The param is a phase: 0 = mode
.equ EVT_INTERRUPT_TITLE, 0x1c00016	; Show a title temporarily on top of the current one (firmware EV_INTERRUPT_TITLE), e.g. a message, error, welco
.equ EVT_NEW_TITLE, 0x1c00039	; Broadcast to the current view tree that a title has just become the new current title (firmware EV_NEW_TITLE).

; Activation events
.equ EVT_SET_VISIBLE, 0x1e0009c	; Firmware method MT_SetVisible. It shows or hides a view: parameter 0 sets bit 0 of the view flags at instance+

; Display/memory allocation events
.equ EVT_GET_BITMAP_DATA, 0x1e000a1	; Firmware method MT_GetBitmapData. A bitmap resource answers it with the ROM address of its pixel data.
.equ EVT_GET_BITMAP_WIDTH, 0x1e000a2	; Firmware method MT_GetBitmapWidth. A bitmap resource answers it with its width in pixels.
.equ EVT_GET_BITMAP_HEIGHT, 0x1e000a3	; Firmware method MT_GetBitmapHeight. A bitmap resource answers it with its height in pixels.

; Display callback identifiers
.equ EVT_HDAE_SEQ_STOP, 0x1ca0000	; The sequencer stopped while HD-AE5000 song-list (FLS) playback is active. FlsLoadScreen reacts by arming a 0x5
.equ EVT_HDAE_TICKS, 0x1ca0004	; Song-position tick for the open lyric box. The parameter points to HDAE5000_RAM_LyricPosEvt (sqbtof, step, pos

; Grid/Check widget events
.equ EVT_PAN_UP, 0x1e40008	; Firmware method MT_PanUp: composer-set grid: increment the pan byte (record +2, max 127) of part XDE, then MT_
.equ EVT_RLMT_UP, 0x1e4000a	; Firmware method MT_RLmtUp: composer-set grid: increment the range-limit byte (record +5, max 11) of part XDE
.equ EVT_GET_SELECTED_CEL, 0x1e0008f	; Firmware method MT_GetSelectedCel. It returns the selected cell packed as (col<<16)|row.

; Named from the event-code catalog of 2026-10-02 (notes/event-codes-2026-10-02/; evidence per value there)
.equ TITLE_PS, 0x1a00000	; Not an event. This is title id 0, entry 0 of object table 0x1A0. InitializeObjectTable registers that table as
.equ TITLE_NORMAL, 0x1a00001	; Title id 1, "TT_NORMAL": the normal play screen. It is the home title of mode 1, MD_NORMAL (0x01800001).
.equ TITLE_SDMENU, 0x1a00002	; Title id 2, "TT_SDMENU": the SOUND menu. It is the home title of mode 2, MD_SOUND (0x01800002).
.equ TITLE_CTMENU, 0x1a00040	; Title id 0x40, "TT_CTMENU": the CONTROL menu. It is the home title of mode 4, MD_CONTROL. Control sub-pages re
.equ TITLE_CTINIT, 0x1a00041	; Title id 0x41, "TT_CTINIT": the CONTROL > initialize page. The 'No' answer of the initialize confirmation retu
.equ TITLE_CTWALLSET, 0x1a00048	; Title id 0x48, "TT_CTWALLSET": the CONTROL > wallpaper-setting page.
.equ TITLE_DKSV, 0x1a00067	; Title id 0x67, "TT_DKSV": the disk SAVE page. The file-naming window returns to it.
.equ TITLE_DKSVSMF, 0x1a0006b	; Title id 0x6B, "TT_DKSVSMF": the disk save-as-SMF page.
.equ TITLE_DPSMFLYR, 0x1a00072	; Title id 0x72, "TT_DPSMFLYR": the disk direct-play SMF page with lyrics.
.equ TITLE_DPMDLYSMFLYR, 0x1a00076	; Title id 0x76, "TT_DPMDLYSMFLYR": the direct-play medley SMF page with lyrics.
.equ TITLE_HDDEXT, 0x1a0007f	; Title id 0x7F, "TT_HDDEXT": the hard-disk / extension title. The main CPU registers it in InitializeHama, and 
.equ TITLE_SQMENU, 0x1a00080	; Title id 0x80, "TT_SQMENU": the SEQUENCER menu. It is the home title of mode 8, MD_SEQ.
.equ TITLE_SQPLAY, 0x1a00081	; Title id 0x81, "TT_SQPLAY": the sequencer play page. It is the home title of mode 0xA, MD_SEQ_PLAY.
.equ TITLE_SQEASYREC, 0x1a00083	; Title id 0x83, "TT_SQEASYREC": the sequencer easy-record page. It is the home title of mode 9, MD_SEQ_EREC.
.equ TITLE_SQCMENU, 0x1a00084	; Title id 0x84, "TT_SQCMENU": a sequencer sub-menu. The record, punch, track-select, panel-write and song-copy 
.equ TITLE_SQPUNCH, 0x1a00087	; Title id 0x87, "TT_SQPUNCH": the sequencer punch-in record page.
.equ TITLE_SQPUNCHM, 0x1a00088	; Title id 0x88, "TT_SQPUNCHM": the auto-punch variant of the punch-in page.
.equ TITLE_SQPNLWR, 0x1a0008d	; Title id 0x8D, "TT_SQPNLWR": the sequencer panel-write page. Its exit returns to TT_SQCMENU.
.equ TITLE_SQSNGSEL, 0x1a0008e	; Title id 0x8E, "TT_SQSNGSEL": the sequencer song-select page.
.equ TITLE_SQSNGNAME, 0x1a0008f	; Title id 0x8F, "TT_SQSNGNAME": the sequencer song-name page.
.equ TITLE_SQSNGCLR, 0x1a00090	; Title id 0x90, "TT_SQSNGCLR": the sequencer song-clear page.
.equ TITLE_SQSNGCP, 0x1a00091	; Title id 0x91, "TT_SQSNGCP": the sequencer song-copy page, as entered from the edit menu. Its exit returns to 
.equ TITLE_SQEMENU, 0x1a00093	; Title id 0x93, "TT_SQEMENU": the sequencer EDIT menu. It is the home title of mode 0xC, MD_SEQ_EDIT.
.equ TITLE_SQNOTEEDT, 0x1a00095	; Title id 0x95, "TT_SQNOTEEDT": the sequencer note-edit page. Grid and box code shared with another edit title 
.equ TITLE_SQTRKCLR, 0x1a0009a	; Title id 0x9A, "TT_SQTRKCLR": the sequencer track-clear page. It is also the first of the 15 titles 0x9A..0xA8
.equ TITLE_SQMIXER, 0x1a000a5	; Title id 0xA5, "TT_SQMIXER": the sequencer track-mixer page.
.equ TITLE_SQEASYNAME, 0x1a000a7	; Title id 0xA7, "TT_SQEASYNAME": the song-name page reached from easy record. It reuses TT_SQSNGNAME's view 0x0
.equ TITLE_SQSNGCPC, 0x1a000a8	; Title id 0xA8, "TT_SQSNGCPC": the song-copy page reached from TT_SQCMENU. It reuses TT_SQSNGCP's view 0x009100
.equ TITLE_SQPNLWRM, 0x1a000aa	; Title id 0xAA, "TT_SQPNLWRM": the panel-write page reached from TT_SQMENU. It reuses TT_SQPNLWR's view 0x008D0
.equ TITLE_CMREAL, 0x1a000b5	; Title id 0xB5, "TT_CMREAL": the Composer (mode 0xE, MD_CMP) real-time page.
.equ TITLE_CMPNCP, 0x1a000b8	; Title id 0xB8, "TT_CMPNCP": a Composer copy page. Three box procs fill different notify data while on it.
.equ TITLE_MUSICSTYL, 0x1a000c1	; Title id 0xC1, "TT_MUSICSTYL": the music-style page in the One-Touch-Play (MD_OTP) title group.
.equ TITLE_PMBKSEL, 0x1a000d0	; Title id 0xD0, "TT_PMBKSEL": the panel-memory bank-select page.
.equ TITLE_PMVIEW, 0x1a000d1	; Title id 0xD1, "TT_PMVIEW": the panel-memory view page. The panel-memory naming and save/delete flows return t
.equ TITLE_PMNAME, 0x1a000d2	; Title id 0xD2, "TT_PMNAME": the panel-memory name page.
.equ TITLE_PMBKNAME, 0x1a000d3	; Title id 0xD3, "TT_PMBKNAME": the panel-memory bank-name page.
.equ TITLE_ETMENU, 0x1a000d6	; Title id 0xD6, "TT_ETMENU": the Entertainer menu. It is the home title of mode 7, MD_ENTERTAINER (0x01800007).
.equ TITLE_SNDARG, 0x1a000dc	; Title id 0xDC, "TT_SNDARG": the Sound Arranger page. It is the home title of mode 0x11, MD_SND_ARG.
.equ TITLE_DEMOMENU, 0x1a000e0	; Title id 0xE0, "TT_DEMOMENU": the demo menu. It is the home title of mode 0x13, MD_DEMO.
.equ TITLE_SWHELP, 0x1a000e7	; Title id 0xE7, "TT_SWHELP": the help screen. It is the home title of mode 0x14, MD_HELP.
.equ TITLE_SVARI, 0x1a000e8	; Title id 0xE8, "TT_SVARI". It is opened from a panel handler when the sound category byte (0xC07E) is neither 
.equ TITLE_RVARI, 0x1a000e9	; Title id 0xE9, "TT_RVARI". It is the companion of TT_SVARI. What the screen shows is not established beyond th
.equ TITLE_DRAWBAR, 0x1a000ea	; Title id 0xEA, "TT_DRAWBAR": the drawbar-organ screen. It is opened when the sound category byte (0xC07E) is 1
.equ TITLE_ACCORDION, 0x1a000eb	; Title id 0xEB, "TT_ACCORDION": the accordion screen. It is opened when the sound category byte (0xC07E) is 13.
.equ TITLE_MESAGE, 0x1a000ee	; Title id 0xEE, "TT_MESAGE" (the firmware's own spelling): the message / confirmation-box title. About 30 call 
.equ TITLE_WELCOM, 0x1a000ef	; Title id 0xEF, "TT_WELCOM": the welcome (boot) screen. It is requested once at boot.
.equ TITLE_SOFTVER, 0x1a000f0	; Title id 0xF0, "TT_SOFTVER": the software-version screen, requested by a control-panel switch chord.
.equ TITLE_TEST1, 0x1a000f4	; Title id 0xF4, "TT_TEST1": the first self-test screen. It is shown when the SRAM test or the panel-detection c
.equ TITLE_TEST3, 0x1a000f6	; Title id 0xF6, "TT_TEST3": a self-test screen. While it is up, some panel handlers stand down and one is activ
.equ EVT_ACCORDION_TAB, 0x1c10000	; Accordion tab selected. Firmware name EV_ACCORDIONTAB: entry 0 of the Murai ResEvent table, slot 0x1C1, table 
.equ EVT_READ_PRESENTATION, 0x1c10001	; The presentation (Feature Demo) file has been read. The parameter is the loader's result (sign-extended; negat
.equ EVT_READ_ACTION, 0x1c10002	; The presentation's action file has been read. The parameter is the result. Firmware name EV_READACTION, slot 0
.equ EVT_READ_SONG, 0x1c10003	; The presentation's song file has been read. The parameter is the result. Firmware name EV_READSONG, slot 0x1C1
.equ EVT_ALL_INITIAL, 0x1c10004	; Opens the "AllInitial" screen, i.e. view 0x00EF0004 (ResName slot 0x3EF entry 4). The welcome screen posts it 
.equ EVT_START_SONG, 0x1c10005	; A presentation/demo song has started. The parameter is the demo song index, byte 0x28A4. Firmware name EV_STAR
.equ EVT_END_SONG, 0x1c10006	; A presentation/demo song has ended. The parameter is the demo song index, byte 0x28A4. Firmware name EV_ENDSON
.equ EVT_EXEC_PRESENTATION, 0x1c10007	; Run a presentation. The parameter is a pointer to the presentation name: 0x00EA009E, which holds "FEATURE ". F
.equ EVT_TONE_MODE, 0x1c10008	; Reports a part's tone mode. Parameter = (part << 16) + the mode from FDemoText_CheckVoiceState (0, 1 or 2). Fi
.equ EVT_MP_VERSION, 0x1c10009	; Opens the "MPVersion" screen, i.e. view 0x00EF0007. The welcome screen posts it when the boot button-combo cod
.equ EVT_CHORD_SHOW, 0x1c20000	; Show or redraw the chord box. AcChordBox handles it exactly like EV_SHOW. Firmware name EV_CHORDSHOW: Toshi Re
.equ EVT_CHORD_DSP, 0x1c20001	; Display a new chord name. The parameter is the chord-name string the sender just built. Firmware name EV_CHORD
.equ EVT_PMBK_NAME, 0x1c20002	; Panel-memory bank name changed. The parameter is an 18-byte Malloc'd block holding the bank number and name; i
.equ EVT_PM_NAME, 0x1c20003	; Panel-memory name changed. The parameter is a Malloc'd block with the name, SndParam 0x300 and a display widge
.equ EVT_FRT_PAGE_CHANGE, 0x1c20004	; Page change for the window-page control. The parameter is the new page index (1 or 3). Firmware name EV_FRTPAG
.equ EVT_SUBCT_SHOW, 0x1c20005	; Show the sub-category grid for the music-style item now selected. Firmware name EV_SUBCTSHOW, slot 0x1C2 entry
.equ EVT_PAGE_SET, 0x1c20006	; Set the window page. The parameter is the page number (1, 3, 5 or 6). Firmware name EV_PAGESET, slot 0x1C2 ent
.equ EVT_TVARI_PAINT, 0x1c20007	; Repaint the Variation screen. Firmware name EV_TVARIPAINT, slot 0x1C2 entry 7. What the 'T' prefix means is no
.equ EVT_NOT_PARA_DRAW, 0x1c50000	; Suspend (param 1) or resume (param 0) parameter drawing. Each receiving view sets its draw-enable word to (par
.equ EVT_NOT_POST_AIC, 0x1c50001	; Suspend (param 1) or resume (param 0) the forwarding of the index-switch auto-repeat (AIC) events 0x01C00019/0
.equ EVT_INDEXSW_UP_DIAL, 0x1c50002	; Index-switch step coming from the data dial, which is bound to the control with SetDialUp/SetDialDown. The con
.equ EVT_INDEXSW_DOWN_DIAL, 0x1c50003	; The dial-bound counterpart of 0x01C50002, re-sent as EV_INDEXSW_DOWN (0x01C00018). Firmware name EV_INDEXSW_DO
.equ EVT_WAKEUP_PASSWORD, 0x1c50004	; Start the password check before a protected load, save or play. The parameter is the operation/slot byte at 0x
.equ EVT_CUR_SONG_NAME, 0x1c70000	; The current-song name string has been fetched into RAM (0x1C50); redraw it. Firmware name EV_CURSONGNAME: Yoko
.equ EVT_DISK_FILE_NAME, 0x1c70001	; The disk file name has been fetched; redraw it. Firmware name EV_DISKFILENAME, slot 0x1C7 entry 1.
.equ EVT_SMF_FILE_NAME, 0x1c70002	; The SMF file name has been fetched; redraw it. Firmware name EV_SMFFILENAME, slot 0x1C7 entry 2.
.equ EVT_SMF_SONG_NAME, 0x1c70003	; The SMF song name has been fetched; redraw it. Firmware name EV_SMFSONGNAME, slot 0x1C7 entry 3.
.equ EVT_DOC_SONG_NAME, 0x1c70005	; The song name of a document file (DOC) has been fetched; redraw it. Firmware name EV_DOCSONGNAME, slot 0x1C7 e
.equ EVT_DOC_FILE_NO, 0x1c70006	; The file number of a document file (DOC) has been formatted; redraw it. Firmware name EV_DOCFILENO, slot 0x1C7
.equ EVT_PD_SONG_NAME, 0x1c70007	; The song name for 'PD' has been fetched; redraw it. Firmware name EV_PDSONGNAME, slot 0x1C7 entry 7. What 'PD'
.equ EVT_PD_FILE_NO, 0x1c70008	; The 'PD' file number has been formatted; redraw it. Firmware name EV_PDFILENO, slot 0x1C7 entry 8.
.equ EVT_LYRICS_ALL_CLEAR, 0x1c70009	; Clear the lyric display when song playback is aborted. The lyric box blanks its line buffers at 0x020CBE and, 
.equ EVT_LYRICS_ALL_DRAW, 0x1c7000a	; Redraw every lyric line in the lyric box. Firmware name EV_ALLDRAW, slot 0x1C7 entry 10. It is distinct from t
.equ EVT_LYRICS_RENEW, 0x1c7000b	; Draw the lyric text that has just been added (cursor range 0x020E46-0x020E4A) after a character or newline is 
.equ EVT_LYRICS_REVERSE, 0x1c7000c	; Redraw the highlighted lyric span (cursor range 0x020E3E-0x020E42) in reverse video. Firmware name EV_REVERSE,
.equ EVT_LYRICS_SCROLL_UP, 0x1c7000d	; Scroll the lyric box up by one 18-pixel (0x12) line. Firmware name EV_SCROLLUP, slot 0x1C7 entry 13.
.equ EVT_COMPOSER_WRITE, 0x1c7000e	; The composer name has been fetched (to RAM 0x021064); draw it. Firmware name EV_COMPORSERWRITE, with the firmw
.equ EVT_SONG_WRITE, 0x1c7000f	; The lyrics song name has been fetched; draw it, centred. Firmware name EV_SONGWRITE, slot 0x1C7 entry 15.
.equ EVT_LYRICS_PLAY_START_INI, 0x1c70010	; Initialise the lyric player at song start: reset the four lyric cursors (0x020E3E/42/46/4A) and the text buffe
.equ EVT_LYRICS_PLAY_REQUEST, 0x1c70011	; Lyric text arrived during playback and needs processing. LyricsFunc answers by sending itself EV_GetEvent (0x0
.equ EVT_LYRICS_GET_EVENT, 0x1c70012	; Read the pending lyric text at 0x020E4E and apply it: newline, CR or characters, which in turn send EV_RENEW, 
.equ EVT_LYRICS_CHANGE_COLOR, 0x1c70013	; Lyric colour-change (highlight) data arrived: validate the lyric record at 0x020F4E and insert it. Firmware na
.equ EVT_EFF_FIX_DRAW, 0x1c80000	; Draw the fixed (non-parameter) area of an effect editor box. Firmware name EV_EFFFIXDRAW: Kubo ResEvent slot 0
.equ EVT_EFF_PARA_DRAW, 0x1c80001	; Draw effect parameter row N. The parameter is the row, 0-7. Firmware name EV_EFFPARADRAW, slot 0x1C8 entry 1.
.equ EVT_EQ_LINE_DRAW, 0x1c80002	; Draw the EQ curve/graph area (design box 0x20,0x24-0xF8,0x78). Firmware name EV_EQLINEDRAW, slot 0x1C8 entry 2
.equ EVT_EQ_STR_DRAW, 0x1c80003	; Draw the value string of EQ band N. The parameter is the band, 0-7. Firmware name EV_EQSTRDRAW, slot 0x1C8 ent
.equ EVT_GRAPH_DRAW, 0x1c80004	; Redraw part N (0-14) of the note-edit graph. The parameter selects the part. Firmware name EV_GRAPHDRAW, slot 
.equ EVT_HDAE_AFTER_LOAD, 0x1ca0001	; Timer-delivered follow-up to EV_SeqStop. If FLS playback is still active (0x22AD9A == 1), FlsLoadScreen moves 
.equ EVT_HDAE_TIMER_BACK, 0x1ca0002	; The error/attention message timer has expired; return to the screen that raised it. The catch object posts EV_
.equ EVT_HDAE_INIT_LYRIC_PARAM, 0x1ca0003	; One-time layout set-up of the lyric box. The first time (flag 0x23A19A) it fetches the client box into 0x22A08
.equ EVT_HDAE_BEAT_MESSAGE, 0x1ca0005	; Advance the beat/measure counters (beat 0x2307AC, measure 0x2307AA) and redraw the "%i/%i" beat display, via E
.equ EVT_HDAE_INIT_LYRICS, 0x1ca0007	; (Re)initialise the lyrics player for the loaded file. The parameter is 0 or 1. It runs HDAE5000_Lyrics_ResetSt
.equ EVT_HDAE_LYRIC_ALL_DRAW, 0x1ca0008	; Redraw all six lyric lines of the HD-AE5000 lyric box. Firmware name EV_Alldraw, slot 0x1CA entry 8. It is dis
.equ EVT_HDAE_DRAW_SYLLABLE, 0x1ca0009	; Partial lyric-box redraw. The parameter (0-4) chooses the area: the sung syllable, the info line, the beat dis
.equ EVT_HDAE_DRAW_FD_TEXT, 0x1ca000c	; Draw the text of the floppy (FD) file-select box. Firmware name EV_DrawFDText, slot 0x1CA entry 12.
.equ EVT_NONE, 0x1c00000	; Null event (firmware EV_NONE). DeleteEvent cancels a queued event by overwriting its event field with this val
.equ EVT_ACTION, 0x1c00006	; Perform action N (firmware EV_ACTION); the param is an action/script index.
.equ EVT_SW_IN, 0x1c00007	; Panel switch input (firmware EV_SWIN): the general press event for a switch, param = switch number (bit 7 = se
.equ EVT_SW_OFF, 0x1c00009	; Panel switch released (firmware EV_SWOFF), param = switch number.
.equ EVT_ALL_PAINT, 0x1c0000a	; Repaint the whole screen (firmware EV_ALLPAINT), posted to the current target after a dialog or progress windo
.equ EVT_PAINT, 0x1c0000b	; Paint a view and its subviews (firmware EV_PAINT): if visible, send EV_DRAW to self, then propagate EV_PAINT t
.equ EVT_REPAINT, 0x1c0000c	; Repaint self after a data change (firmware EV_REPAINT): EV_DRAW to self, then EV_PAINT to subviews. Widgets re
.equ EVT_SELE_DRAW, 0x1c0000e	; Draw the selection highlight (firmware EV_SELEDRAW), param = the selected index.
.equ EVT_CHANGE_PROPERTY, 0x1c00011	; A property of the view changed (firmware EV_CHANGEPROPERTY); the receiver re-reads the changed property and up
.equ EVT_CHANGE_MODE, 0x1c00014	; Request a change of the current mode (firmware EV_CHANGE_MODE); param = mode id 0x0180nnnn.
.equ EVT_CHANGE_TITLE, 0x1c00015	; Request a change of the current title/screen (firmware EV_CHANGE_TITLE); param = title id 0x01A0nnnn.
.equ EVT_INDEXSW_UP, 0x1c00017	; Index/cursor up (firmware EV_INDEXSW_UP); the dial is bound to it with SetDialUp, and the panel index switches
.equ EVT_INDEXSW_DOWN, 0x1c00018	; Index/cursor down (firmware EV_INDEXSW_DOWN); the dial-down counterpart of EV_INDEXSW_UP.
.equ EVT_INDEXSW_UP_AIC, 0x1c00019	; Auto-repeat (AIC = auto-increment) version of EV_INDEXSW_UP, re-sent while the switch is held.
.equ EVT_INDEXSW_DOWN_AIC, 0x1c0001a	; Auto-repeat version of EV_INDEXSW_DOWN.
.equ EVT_INDEX_SELECT, 0x1c0001b	; An index/choice was selected (firmware EV_INDEXSELECT); param = the selected index, sent to the target/linked 
.equ EVT_LSW_DATA, 0x1c0001c	; Delivery of a panel-setting (LSW) value record (firmware EV_LSWDATA); param = pointer to a 12-byte {lsw id, pa
.equ EVT_RAM_DATA, 0x1c0001d	; Delivery of a RAM-parameter value (firmware EV_RAMDATA), the RAM counterpart of EV_LSW_DATA; param = value rec
.equ EVT_PAGE_CHANGE, 0x1c0001e	; Switch the displayed page (firmware EV_PAGECHANGE); param = page number.
.equ EVT_DIAL, 0x1c0001f	; Dial (rotary encoder) turned (firmware EV_DIAL); param = signed step. The root translates it into the currentl
.equ EVT_SOUND_NAME, 0x1c00020	; Sound (voice) name result delivered to the sound-name display (firmware EV_SOUNDNAME).
.equ EVT_RHYTHM_NAME, 0x1c00021	; Rhythm (style) name result delivered to the rhythm-name display (firmware EV_RHYTHMNAME).
.equ EVT_PMEM_NAME, 0x1c00022	; Panel-memory name result delivered to the panel-memory name display (firmware EV_PMEMNAME).
.equ EVT_SOUND_SW_NO, 0x1c00023	; Sound-group switch number selected/changed (firmware EV_SOUNDSWNO); param = switch/category number.
.equ EVT_BIT_DATA, 0x1c00024	; Delivery of a bit (on/off flag) parameter value (firmware EV_BITDATA).
.equ EVT_MEMO_DRAW, 0x1c00025	; Append/draw a text line in the debug memo window (firmware EV_MEMODRAW); param = string pointer.
.equ EVT_AUTO_INC, 0x1c00026	; Auto-increment (key-repeat) timer tick (firmware EV_AUTOINC). The root re-sends the recorded *_AIC event for a
.equ EVT_SW_IN_AIC, 0x1c00027	; Auto-repeat version of EV_SW_IN, re-sent while a switch is held (e.g. fast value scroll).
.equ EVT_RETURN_TITLE, 0x1c00028	; Close an interrupt title and return to the title it interrupted (firmware EV_RETURN_TITLE).
.equ EVT_I_AM_SELECTED, 0x1c00029	; Notification from an item that it became the selected one (firmware EV_IAMSELECTED); receivers update their pa
.equ EVT_YOU_ARE_SELECTED, 0x1c0002a	; Tells an item it is now the selected one (firmware EV_YOUARESELECTED); the receiver marks itself selected.
.equ EVT_SEND_SW_IN, 0x1c0002b	; EV_SW_IN re-delivered by the group box to an IvMainEditSw (firmware EV_SENDSWIN); the receiver relays it to it
.equ EVT_CHANGE_DIAL_FOCUS, 0x1c0002c	; The dial focus moved to a different object (firmware EV_CHANGEDIALFOCUS); list and radio boxes redraw their se
.equ EVT_TRSW_PART, 0x1c0002d	; Sequencer track-switch part state (firmware EV_TRSWPART), posted by the sequencer engine to the track mixer/sw
.equ EVT_TRSW_COMMAND, 0x1c0002e	; Sequencer track-switch command/status (firmware EV_TRSWCOMMAND), posted by the sequencer engine to the track-s
.equ EVT_PART_SELECT, 0x1c0002f	; Part-select changed (firmware EV_PARTSELECT); param = current part-select state (0x8D3A).
.equ EVT_SW_BOTH, 0x1c00030	; Both switches of a pair are held together (firmware EV_SWBOTH), e.g. up and down pressed at once; param = swit
.equ EVT_INDEXSW_BOTH, 0x1c00031	; Both index switches pressed together (firmware EV_INDEXSW_BOTH); edit boxes reset the value to its default.
.equ EVT_SEND_SW_ON, 0x1c00032	; EV_SW_ON re-delivered by the group box to an IvMainEditSw (firmware EV_SENDSWON).
.equ EVT_SEND_SW_OFF, 0x1c00033	; EV_SW_OFF re-delivered by the group box to an IvMainEditSw (firmware EV_SENDSWOFF).
.equ EVT_SEND_SW_BOTH, 0x1c00034	; EV_SW_BOTH re-delivered by the group box to an IvMainEditSw (firmware EV_SENDSWBOTH).
.equ EVT_PAGE_INIT, 0x1c00035	; Initialise a page/sub-page widget (firmware EV_PAGEINIT).
.equ EVT_UPDATE_SCREEN, 0x1c00036	; Push the frame to the LCD now (firmware EV_UPDATESCREEN).
.equ EVT_DELIVERY_EVENT, 0x1c00037	; Wrapper event that carries another event (firmware EV_DELIVERYEVENT); param = pointer to {target, event, param
.equ EVT_ASSSWB, 0x1c00038	; Raw control-panel key packet broadcast (firmware EV_ASSSWB); param = (chain<<24)|(param<<16)|(byte C07E<<8)|by
.equ EVT_OLD_TITLE, 0x1c0003a	; Broadcast that the current title is being left (firmware EV_OLD_TITLE).
.equ EVT_SW_IN_MODE, 0x1c0003b	; A mode-select panel switch was pressed (firmware EV_SWIN_MODE); param = mode id 0x01800000 + switch value. The
.equ EVT_CHECK_CLASS_SP, 0x1e00004	; MT_CheckClassSp. Class-level is-a test. Walks the parent chain from this class and returns 1 if it reaches the
.equ EVT_GET_PROP_STRING_EX, 0x1e00005	; MT_GetPropStringEx. Builds the full property-signature string (one type letter per field) into the caller's bu
.equ EVT_GET_PROP_COUNT_SP, 0x1e00006	; MT_GetPropCountSp. Number of properties, computed as the strlen of the property string.
.equ EVT_GET_PROP_NAME_SP, 0x1e00007	; MT_GetPropNameSp. Class-level lookup of the name of property #n (param = {index, buffer}). Recurses to the par
.equ EVT_COPY_PROPERTY_EX, 0x1e00008	; MT_CopyPropertyEx. Type-object method (table 0x260, id 0x02600000+(typechar-'A')) that copies one property val
.equ EVT_DUMP_PROPERTY_EX, 0x1e00009	; MT_DumpPropertyEx. Type-object method that reads one property value out of an instance record for a dump. Scal
.equ EVT_DUMP_POINTER_EX, 0x1e0000a	; MT_DumpPointerEx. Type-object method that dumps the data a pointer-typed property points to. Only the pointer 
.equ EVT_GET_PROPERTY_EX, 0x1e0000b	; MT_GetPropertyEx. Type-object method that reads property #n of an instance into the caller's value slot. The f
.equ EVT_SET_PROPERTY_EX, 0x1e0000c	; MT_SetPropertyEx. Type-object method that writes a value (param+4) into property #n of an instance record.
.equ EVT_GET_CLASS, 0x1e00010	; MT_GetClass. Object-level: returns the object's class id, which ObjectProc has already obtained with MT_GetCla
.equ EVT_GET_PARENT_CLASS, 0x1e00011	; MT_GetParentClass. Object-level: returns the parent class of the object's class (forwards MT_GetParentClassSp)
.equ EVT_GET_CLASS_NAME, 0x1e00012	; MT_GetClassName. Object-level: returns the name string of the object's class (forwards MT_GetName to the class
.equ EVT_GET_PROCEDURE, 0x1e00013	; MT_GetProcedure. Object-level: returns the proc of the object's class (forwards MT_GetProcedureSp).
.equ EVT_SET_NAME, 0x1e00016	; MT_SetName. Renames a view: copies the new string over the view's name-table entry if it fits.
.equ EVT_GET_PROP_COUNT, 0x1e00017	; MT_GetPropCount. Object-level: number of properties (forwards MT_GetPropCountSp).
.equ EVT_GET_PROP_NAME, 0x1e00018	; MT_GetPropName. Object-level: copies the name of property #n into the caller's buffer.
.equ EVT_GET_PROP_STRING, 0x1e00019	; MT_GetPropString. Object-level: fills the caller's buffer with the object's full property-signature string (MT
.equ EVT_COPY_PROPERTY, 0x1e0001a	; MT_CopyProperty. Object-level: forwards MT_CopyPropertyEx to the type object of the property's letter.
.equ EVT_DUMP_PROPERTY, 0x1e0001b	; MT_DumpProperty. Object-level: forwards MT_DumpPropertyEx to the property's type object.
.equ EVT_DUMP_POINTER, 0x1e0001c	; MT_DumpPointer. Object-level: forwards MT_DumpPointerEx to the property's type object.
.equ EVT_GET_PROPERTY, 0x1e0001d	; MT_GetProperty. Object-level: forwards MT_GetPropertyEx to the property's type object.
.equ EVT_SET_PROPERTY, 0x1e0001e	; MT_SetProperty. Object-level: forwards MT_SetPropertyEx to the property's type object.
.equ EVT_GET_PROP_DATA, 0x1e0001f	; MT_GetPropData. Object-level: forwards MT_GetPropDataSp to the class.
.equ EVT_GET_PROP_DATA_COUNT, 0x1e00020	; MT_GetPropDataCount. Object-level: forwards MT_GetPropDataCountSp to the class.
.equ EVT_GET_INSTANCE_SIZE, 0x1e00021	; MT_GetInstanceSize. Object-level: forwards MT_GetInstanceSizeSp to the class.
.equ EVT_GET_PROP_CHAR, 0x1e00022	; MT_GetPropChar. Returns the type letter of property #param, i.e. that byte of the property string.
.equ EVT_AUTO_FREE, 0x1e00023	; MT_AutoFree. Frees the heap block given as the parameter (Free(param)). It is queued right after an asynchrono
.equ EVT_SEARCH_CLASS, 0x1e00024	; MT_SearchClass. Searches a view and its subtree (subview +6, then next sibling +8) for a view that is-a the cl
.equ EVT_CHECK_PROP_STRING, 0x1e00025	; MT_CheckPropString. Per-type hook. While MT_GetPropStringEx and MT_GetPropNameSp walk a class's own type lette
.equ EVT_GET_PROP_MEMBER, 0x1e00026	; MT_GetPropMember. Compound property types return member information (a member-name suffix, or the number of me
.equ EVT_GET_PROP_SIZE, 0x1e00027	; MT_GetPropSize. Sent to a property-type object; returns the byte size of one field of that type (descriptor wo
.equ EVT_MAKE_DUMP, 0x1e00028	; MT_MakeDump. Type-object method that formats a property value as text for a debug dump.
.equ EVT_MAKE_EDIT_SW_ID, 0x1e00029	; MT_MakeEditSwID. Sent to the EditSwID type object 0x02600024 with a raw panel switch code. Returns the edit-sw
.equ EVT_GET_FUNCTION, 0x1e0002a	; MT_GetFunction. Returns the code address held by a Function-table entry (function id to pointer).
.equ EVT_GET_MODE_PROC, 0x1e0002b	; MT_GetModeProc. Returns the code address of a mode's procedure (the function id at mode record +0, resolved wi
.equ EVT_GET_MODE_PROC_ID, 0x1e0002c	; MT_GetModeProcID. Returns a mode's procedure function id (mode record +0).
.equ EVT_GET_START_TITLE, 0x1e0002d	; MT_GetStartTitle. Returns a mode's start title id (mode record +4).
.equ EVT_GET_MODE_NOW, 0x1e0002e	; MT_GetModeNow. Returns the current mode id (RAM 0x03EF82).
.equ EVT_GET_MODE_OLD, 0x1e0002f	; MT_GetModeOld. Returns the previous mode id (RAM 0x03EF86).
.equ EVT_GET_USER_ID, 0x1e00030	; MT_GetUserID. Returns the user-id word of a mode or title record (+8, sign-extended).
.equ EVT_GET_TITLE_PROC, 0x1e00031	; MT_GetTitleProc. Returns the code address of a title's procedure (title record +0, resolved with MT_GetFunctio
.equ EVT_GET_TITLE_PROC_ID, 0x1e00032	; MT_GetTitleProcID. Returns a title's procedure function id (title record +0).
.equ EVT_GET_START_SCREEN, 0x1e00033	; MT_GetStartScreen. Returns a title's start screen id (title record +4).
.equ EVT_GET_TITLE_NOW, 0x1e00034	; MT_GetTitleNow. Returns the current title id (RAM 0x03EF8A).
.equ EVT_GET_TITLE_OLD, 0x1e00035	; MT_GetTitleOld. Returns the previous title id (RAM 0x03EF8E).
.equ EVT_GET_SUPERVIEW, 0x1e00036	; MT_GetSuperview. Returns the id of a view's superview (Viewable +4 'super', relative to the view's table).
.equ EVT_GET_SUBVIEW, 0x1e00037	; MT_GetSubview. Returns the id of a view's first subview (Viewable +6 'sub').
.equ EVT_GET_NEXTVIEW, 0x1e00038	; MT_GetNextview. Returns the id of a view's next sibling (Viewable +8 'next').
.equ EVT_GET_PREVVIEW, 0x1e00039	; MT_GetPrevview. Returns the id of a view's previous sibling (Viewable +10 'prev').
.equ EVT_GET_STRING, 0x1e0003a	; MT_GetString. Asks a box, or the ApFunction behind it, to write its current display or edit string into the ca
.equ EVT_SET_PARAM, 0x1e0003b	; MT_SetParam. Sets the value behind a parameter box or its ApFunction to the parameter; the function (e.g. Cycl
.equ EVT_CHECK_SELECTED, 0x1e0003c	; MT_CheckSelected. Returns 1 if this box is the one currently selected for the edit switch in the parameter (bo
.equ EVT_CALC_PARAM, 0x1e0003d	; MT_CalcParam. Adds a signed delta (the parameter) to a box's value; this is the dial, scroll and auto-incremen
.equ EVT_GET_LARGE_STEP, 0x1e0003e	; MT_GetLargeStep. Asks an edit box's ApFunction for its large step (auto-increment and page step). It is the fi
.equ EVT_GET_SMALL_STEP, 0x1e0003f	; MT_GetSmallStep. Asks an edit box's ApFunction for its small (single-click) step.
.equ EVT_GET_LSW_ADDRESS, 0x1e00040	; MT_GetLswAddress. Returns the Lsw parameter id that an Lsw edit box edits. That id is the key passed to MainLs
.equ EVT_GET_LSW_OUTPUT, 0x1e00041	; MT_GetLswOutput. Returns the third Lsw argument (block +6) that is passed with the Lsw id to MainLswPut and Ma
.equ EVT_GET_LSW_STRING, 0x1e00042	; MT_GetLswString. Formats an Lsw value as display text into the caller's buffer.
.equ EVT_GET_MAX, 0x1e00043	; MT_GetMax. Upper limit of the value edited through a RAM or PM-bank edit box.
.equ EVT_GET_MIN, 0x1e00044	; MT_GetMin. Lower limit of the value edited through a RAM or PM-bank edit box.
.equ EVT_GET_RAM_ADDRESS, 0x1e00045	; MT_GetRamAddress. Address of the RAM variable that a RAM edit box edits.
.equ EVT_GET_RAM_SIZE, 0x1e00046	; MT_GetRamSize. Byte size (1, 2 or 4) of that RAM variable.
.equ EVT_GET_RAM_STRING, 0x1e00047	; MT_GetRamString. Formats the RAM variable's value as display text.
.equ EVT_SET_PARENT_WINDOW, 0x1e00048	; MT_SetParentWindow. Stores a window's parent-window link. Screens ignore it.
.equ EVT_SET_CHILD_WINDOW, 0x1e00049	; MT_SetChildWindow. Stores the child-window link of a screen or window.
.equ EVT_GET_PARENT_WINDOW, 0x1e0004a	; MT_GetParentWindow. Returns a window's parent-window link (a screen returns its default).
.equ EVT_GET_CHILD_WINDOW, 0x1e0004b	; MT_GetChildWindow. Returns the child window of a screen or window, or 0xFFFFFFFF if there is none.
.equ EVT_GET_TABLE_STRING, 0x1e0004c	; MT_GetTableString. A table edit box asks its function for the display string of a table entry.
.equ EVT_SET_SELECTED, 0x1e0004d	; MT_SetSelected. Makes the parameter the selected index of a selection box (writes the shared selection word), 
.equ EVT_DRAW_SELECTED, 0x1e0004e	; MT_DrawSelected. Draws a box's frame in the selected state (parameter nonzero, colour 0xF2) or the normal stat
.equ EVT_SET_MENU_RECT, 0x1e0004f	; MT_SetMenuRect. Sets a view's rectangle (+14..+20) to the menu-column position of the edit switch given in the
.equ EVT_CHECK_INDEX, 0x1e00050	; MT_CheckIndex. Returns 1 if the box's index field (VwBox +26, AcIndexToggle +40) equals the parameter. Grid an
.equ EVT_GET_INDEX, 0x1e00051	; MT_GetIndex. Returns the box's index field (VwBox +26 word, AcIndexToggle +40).
.equ EVT_SET_EDIT_SW_RECT, 0x1e00052	; MT_SetEditSwRect. Sets a view's rectangle to the screen position of the LCD edit switch (side button) given in
.equ EVT_CHECK_EDIT_SW, 0x1e00053	; MT_CheckEditSw. Hit test: returns 1 if this (visible) box owns the panel edit switch whose code is the paramet
.equ EVT_GET_PAGE_MIN, 0x1e00054	; MT_GetPageMin. First page number of a paged box or window.
.equ EVT_GET_PAGE_MAX, 0x1e00055	; MT_GetPageMax. Last page number of a paged box or window.
.equ EVT_GET_PAGE_NOW, 0x1e00056	; MT_GetPageNow. Current page number of a paged box or window.
.equ EVT_LSW_PUT, 0x1e00057	; MT_LswPut. Request to MainFunction 0x01400002 (MainPmanControl) to write an Lsw parameter. Block layout: +0 id
.equ EVT_LSW_ADD, 0x1e00058	; MT_LswAdd. Request to MainPmanControl to add a delta to an Lsw parameter.
.equ EVT_LSW_GET, 0x1e00059	; MT_LswGet. Request to MainPmanControl to read an Lsw parameter. The reply is EV_LSWDATA 0x01C0001C carrying a 
.equ EVT_LSW_PART_PUT, 0x1e0005a	; MT_LswPartPut. Per-part form of MT_LswPut.
.equ EVT_LSW_PART_ADD, 0x1e0005b	; MT_LswPartAdd. Per-part form of MT_LswAdd.
.equ EVT_LSW_PART_GET, 0x1e0005c	; MT_LswPartGet. Per-part form of MT_LswGet.
.equ EVT_SET_WALL_PALETTE, 0x1e0005d	; MT_SetWallPalette. Firmware name only; no use was found in v10 or hdae5000.
.equ EVT_GET_SOUND_NAME, 0x1e0005e	; MT_GetSoundName. Request to the sound-name MainFunction to build a part's sound name. It replies asynchronousl
.equ EVT_GET_RHYTHM_NAME, 0x1e0005f	; MT_GetRhythmName. Request to build the current rhythm name. The reply is EV_RHYTHMNAME 0x01C00021.
.equ EVT_GET_PMEM_NAME, 0x1e00060	; MT_GetPmemName. Request to MainFunction 0x01400006 for the current panel-memory name. The reply is EV_PMEMNAME
.equ EVT_GET_SOUND_SW_NO, 0x1e00061	; MT_GetSoundSwNo. Request for a part's sound-switch (category button) number. The reply is EV_SOUNDSWNO 0x01C00
.equ EVT_GET_BIT_STRING, 0x1e00062	; MT_GetBitString. Formats a bit-edit box's on/off state as text.
.equ EVT_GET_BIT_ADDRESS, 0x1e00063	; MT_GetBitAddress. Address of the variable that holds the edited bit.
.equ EVT_GET_BIT, 0x1e00064	; MT_GetBit. Bit mask of the edited bit.
.equ EVT_GET_DIRECTION, 0x1e00065	; MT_GetDirection. Polarity of a bit-edit box. With 0, scrolling up sets the bit to 1; with a nonzero answer the
.equ EVT_BIT_GET, 0x1e00066	; MT_BitGet. Request to MainBitControl to read a bit variable. The reply is EV_BITDATA 0x01C00024, followed by M
.equ EVT_BIT_PUT, 0x1e00067	; MT_BitPut. Request to MainBitControl to write a bit variable; the change is notified with EV_BITDATA 0x01C0002
.equ EVT_RAM_GET, 0x1e00068	; MT_RamGet. Request to MainRamControl to read a 1-, 2- or 4-byte RAM variable. The reply is EV_RAMDATA 0x01C000
.equ EVT_RAM_PUT, 0x1e00069	; MT_RamPut. Request to MainRamControl to write a RAM variable.
.equ EVT_RAM_ADD, 0x1e0006a	; MT_RamAdd. Request to MainRamControl to add a delta to a RAM variable, with a range check for each size.
.equ EVT_GET_PARAM, 0x1e0006b	; MT_GetParam. Reads the current value of a parameter box or the function behind it.
.equ EVT_TOGGLE_PARAM, 0x1e0006c	; MT_ToggleParam. Flips a toggle box's on/off parameter.
.equ EVT_DRAW_MEMO, 0x1e0006d	; MT_DrawMemo. Firmware name only; no use was found in v10 or hdae5000.
.equ EVT_AICEN_SET, 0x1e0006e	; MT_AicenSet ('auto-increment enable'). A nonzero parameter arms, and zero kills, the auto-repeat ApTimers that
.equ EVT_VALEN_SET, 0x1e0006f	; MT_ValenSet. Sets the dial (value) enable flag.
.equ EVT_EDIT_DOWN_SET, 0x1e00070	; MT_EditDownSet. Registers the dial's down-direction target (sender object, EV_SWIN 0x01C00007, parameter).
.equ EVT_EDIT_UP_SET, 0x1e00071	; MT_EditUpSet. Registers the dial's up-direction target (sender object, EV_SWIN 0x01C00007, parameter).
.equ EVT_SET_PARENT_SCREEN, 0x1e00072	; MT_SetParentScreen. Firmware name only; no use was found.
.equ EVT_SET_CHILD_SCREEN, 0x1e00073	; MT_SetChildScreen. Firmware name only; no use was found.
.equ EVT_GET_PARENT_SCREEN, 0x1e00074	; MT_GetParentScreen. Firmware name only; no use was found.
.equ EVT_GET_CHILD_SCREEN, 0x1e00075	; MT_GetChildScreen. Firmware name only; no use was found.
.equ EVT_GET_RETURN_SCREEN, 0x1e00076	; MT_GetReturnScreen. Returns a title's return screen (title record +14). If it is unset (-1), it is first initi
.equ EVT_SET_RETURN_SCREEN, 0x1e00077	; MT_SetReturnScreen. Sets a title's return screen (title record +14 = parameter).
.equ EVT_RESET_INTERRUPT_TIME, 0x1e00078	; MT_ResetInterruptTime. Restarts an interrupt title's timeout, i.e. the ApTimer that will post EV_RETURN_TITLE 
.equ EVT_INTERRUPT_EXIT, 0x1e00079	; MT_InterruptExit. Ends an interrupt title at once: EV_RETURN_TITLE 0x01C00028 is fired immediately (ResetApTim
.equ EVT_IS_INTERRUPT, 0x1e0007a	; MT_IsInterrupt. Returns nonzero if the title is an interrupt title (record +18 != 0xFFFF).
.equ EVT_SET_AP_FUNCTION, 0x1e0007b	; MT_SetApFunction. Gives a naming window the ApFunction id of its check function (the parameter).
.equ EVT_GET_STRING_LENGTH, 0x1e0007c	; MT_GetStringLength. The naming window asks its check ApFunction for the length of the name to edit; the window
.equ EVT_RETURN_STRING, 0x1e0007d	; MT_ReturnString. Firmware name only; no use was found.
.equ EVT_REQUEST_STRING, 0x1e0007e	; MT_RequestString. Firmware name only; no use was found.
.equ EVT_SET_PAGE, 0x1e0007f	; MT_SetPage. Sets the current page (the parameter) of a paged box or window, including the naming window's char
.equ EVT_SET_CURSOR, 0x1e00080	; Firmware method MT_SetCursor. The parameter is a cursor index, and the receiving box stores it as its cursor p
.equ EVT_SET_CHARA, 0x1e00081	; Firmware method MT_SetChara. The parameter is a character code, and the naming window writes it into its name 
.equ EVT_RAM_DATA_REQ, 0x1e00082	; Firmware method MT_RamData. A RAM-edit box sends it to its ApFunction after it writes a new value to the edite
.equ EVT_LSW_DATA_REQ, 0x1e00083	; Firmware method MT_LswData. This is the Lsw counterpart of MT_RamData: an Lsw parameter edit box sends it to i
.equ EVT_GET_NAMING_MODE, 0x1e00084	; Firmware method MT_GetNamingMode. The naming window asks its owner which naming mode (character set) to offer,
.equ EVT_ARE_YOU_CLASS_PROC, 0x1e00085	; Firmware method MT_AreYouClassProc. It is a capability query sent to an object's callback before events are ro
.equ EVT_SET_STRING, 0x1e00086	; Firmware method MT_SetString. The parameter is a char pointer, and the call sets the object's text. The naming
.equ EVT_SET_DIAL_FOCUS, 0x1e00087	; Firmware method MT_SetDialFocus. It sets which object receives the data-entry dial. The value is stored at 0x3
.equ EVT_GET_DIAL_FOCUS, 0x1e00088	; Firmware method MT_GetDialFocus. It returns the current dial-focus value (0x3ef6a), or -1 while the dial is di
.equ EVT_GET_STR_PTR, 0x1e00089	; Firmware method MT_GetStrPtr. It returns the char pointer a text box displays. Subclasses override it to suppl
.equ EVT_GET_FIXED_COL_STR, 0x1e0008a	; Firmware method MT_GetFixedColStr. The grid box asks for the label of a fixed (header) column, and the handler
.equ EVT_GET_FIXED_ROW_STR, 0x1e0008b	; Firmware method MT_GetFixedRowStr. The grid box asks for the label of a fixed (header) row, and the handler co
.equ EVT_GRID_DRAW, 0x1e0008c	; Firmware method MT_GridDraw. It draws one grid cell. The parameter points to a {col, row, ...} record, where -
.equ EVT_REQUEST_GRID_DRAW, 0x1e0008d	; Firmware method MT_RequestGridDraw. It asks for one cell to be redrawn. The parameter is (col<<16)|row, and th
.equ EVT_SET_SELECTED_CEL, 0x1e0008e	; Firmware method MT_SetSelectedCel. It selects a grid cell. The parameter is (col<<16)|row, and 0xFFFF in eithe
.equ EVT_GET_SELECTED, 0x1e00090	; Firmware method MT_GetSelected. It returns a list box's selected index.
.equ EVT_CHECK_GRID_INDEX, 0x1e00091	; Firmware method MT_CheckGridIndex. It checks whether an index lies in the grid's index window, which starts at
.equ EVT_REQUEST_TRACK_SWITCH, 0x1e00092	; Firmware method MT_RequestTrackSwitch. A track-switch widget sends it to the main function 0x0140000A to apply
.equ EVT_TOGGLE_TRACK_SWITCH, 0x1e00093	; Firmware method MT_ToggleTrackSwitch. It toggles the track switch for the track or part in the parameter.
.equ EVT_CHECK_SHOW_WINDOW, 0x1e00094	; Firmware method MT_CheckShowWindow. It asks whether a window is currently showing a sub-object, and returns 1 
.equ EVT_INTERRUPT_HOLD, 0x1e00098	; Firmware method MT_InterruptHold. It suspends the current title's interrupt timeout: if the title has an inter
.equ EVT_SET_INTERRUPT_TIME, 0x1e00099	; Firmware method MT_SetInterruptTime. It (re)arms the title's interrupt timer, an ApTimer that delivers 0x01C00
.equ EVT_SET_HOLD, 0x1e0009a	; Firmware method MT_SetHold. It sets or clears the title's hold flag (bit 0 of the title-flags word at 0x2bc30)
.equ EVT_TOGGLE_HOLD, 0x1e0009b	; Firmware method MT_ToggleHold. It toggles the title's hold flag (0x2bc30 bit 0) and resets the interrupt timer
.equ EVT_GET_INTERRUPT_TIME, 0x1e0009d	; Firmware method MT_GetInterruptTime. It returns an interrupt view's timeout interval.
.equ EVT_SET_NOT_DRAW_FLAG, 0x1e0009e	; Firmware method MT_SetNotDrawFlag. It sets or clears the title's do-not-draw flag (bit 2, value 0x4, of the ti
.equ EVT_GET_LANGUAGE_PTR, 0x1e0009f	; Firmware method MT_GetLanguagePtr. A language-text view asks its function for its table of per-language string
.equ EVT_PART_SELECT_PUT, 0x1e000a0	; Firmware method MT_PartSelectPut. It writes the selected part (0-15, 0x15 or 0x16) to 0x8d3a and to the panel 
.equ EVT_EASY_SET_ON, 0x1e000a5	; Firmware method MT_EasySetOn. A panel button has been pressed. The title starts an ApTimer that delivers MT_Ea
.equ EVT_EASY_SET_OFF, 0x1e000a6	; Firmware method MT_EasySetOff. The panel button has been released before the hold time, so the title kills the
.equ EVT_REFRESH_PARA_DRAW, 0x1e000a7	; Firmware method MT_RefreshParaDraw. It asks a parameter display (drawbar, mixer slider, RAM box) to redraw fro
.equ EVT_SET_SOUND_SW_NO, 0x1e000a8	; Firmware method MT_SetSoundSwNo. It sets the sound-switch (sound selection) number for a part. The packed para
.equ EVT_ADD_SOUND_SW_NO, 0x1e000a9	; Firmware method MT_AddSoundSwNo. It steps a part's sound-switch number by a delta, which is relative sound nav
.equ EVT_CHECK_HOLD, 0x1e000aa	; Firmware method MT_CheckHold. It returns whether the current title's hold flag (0x2bc30 bit 0) is set.
.equ EVT_OTHER_PART_LED, 0x1e000ab	; Firmware method MT_OtherPartLed. It requests the 'other part' panel LED on (1) or off (0). MainTitleControl ap
.equ EVT_SLEEP_MAIN_TASK, 0x1e000ac	; Firmware method MT_SleepMainTask. It suspends the main task while the application task runs. The firmware's ow
.equ EVT_WAKE_UP_MAIN_TASK, 0x1e000ad	; Firmware method MT_WakeUpMainTask. It wakes the main task. The firmware's own routine WakeUpMainTask sends it.
.equ EVT_SLEEP_AP_TASK, 0x1e000ae	; Firmware method MT_SleepApTask. It suspends the application (Ap) task. The firmware's own routine SleepApTask 
.equ EVT_WAKE_UP_AP_TASK, 0x1e000af	; Firmware method MT_WakeUpApTask. It wakes the application task. The firmware's own routine WakeUpApTask sends 
.equ EVT_REFRESH_AP_TASK, 0x1e000b0	; Firmware method MT_RefreshApTask. It resets the application task's input state: it clears switch state, delete
.equ EVT_GET_BOX_BORDER, 0x1e000b1	; Firmware method MT_GetBoxBorder. A box returns its border/wallpaper pattern (instance word +0x18). Screen setu
.equ EVT_GET_BOX_COLOR, 0x1e000b2	; Firmware method MT_GetBoxColor. A box returns its colour (instance word +0x16). Screen setup uses the answer a
.equ EVT_SET_KEEP, 0x1e000b3	; Firmware method MT_SetKeep. It sets (non-zero parameter, which also kills the interrupt timer) or clears the t
.equ EVT_REFRESH_SW_EVENT, 0x1e000b4	; Firmware method MT_RefreshSwEvent. It flushes held-switch state: it clears switch state, deletes queued 0x01C0
.equ EVT_SEARCH_LINK, 0x1e000b5	; Firmware method MT_SearchLink. It searches the view tree for a view that answers another method. The parameter
.equ EVT_INTERRUPT_OFF, 0x1e000b6	; Firmware method MT_InterruptOff. It asks whether a view is an interrupt view whose timeout is off (interval 0)
.equ EVT_EASY_SET_GO, 0x1e000b7	; Firmware method MT_EasySetGo. The press-and-hold timer armed by MT_EasySetOn has expired. The title clears its
.equ EVT_CHECK_INIT_DATA, 0x1e000b8	; Firmware method MT_CheckInitData. It asks whether a parameter has an initial (reset/centre) value. The answer 
.equ EVT_GET_INIT_DATA, 0x1e000b9	; Firmware method MT_GetInitData. It returns a parameter's initial (reset/centre) value. The reset button stores
.equ EVT_SET_TITLE_FLAG, 0x1e000ba	; Firmware method MT_SetTitleFlag. It reports the new title-flags word (0x2bc30: hold 0x1, not-draw 0x4, vari 0x
.equ EVT_MAIN_LOOP_COUNT, 0x1e000bb	; Firmware method MT_MainLoopCount. It is the per-pass tick of the main loop sent to the main title function. Th
.equ NAKA_FUNC_AcTransposeBoxProc, 0x1020003	; NAKA Function object id: entry 3 of Toshi Function table (registry slot 0x102, Toshi_Function_Table@0xED2F66, 
.equ NAKA_FUNC_AcFreeSplitBoxProc, 0x1020004	; NAKA Function object id: entry 4 of Toshi Function table (registry slot 0x102, Toshi_Function_Table@0xED2F66, 
.equ NAKA_FUNC_AcChordBoxProc, 0x1020005	; NAKA Function object id: entry 5 of Toshi Function table (registry slot 0x102, Toshi_Function_Table@0xED2F66, 
.equ NAKA_APFUNC_DefaultFunction, 0x1200000	; NAKA ApFunction object id: entry 0 of the Root ApFunction table (registry slot 0x120), firmware name "DefaultF
.equ NAKA_APFUNC_NamingCheck, 0x1200005	; NAKA ApFunction object id: entry 5 of the Root ApFunction table (registry slot 0x120), firmware name "NamingCh
.equ NAKA_APFUNC_ApTaskControl, 0x120000b	; NAKA ApFunction object id: entry 11 of the Root ApFunction table (registry slot 0x120), firmware name "ApTaskC
.equ NAKA_APFUNC_LswSound, 0x1210027	; NAKA ApFunction object id: entry 39 of the Murai ApFunction table (registry slot 0x121), firmware name "LswSou
.equ NAKA_APFUNC_ApPreControl, 0x1210028	; NAKA ApFunction object id: entry 40 of the Murai ApFunction table (registry slot 0x121), firmware name "ApPreC
.equ NAKA_APFUNC_HDDNamingCheck, 0x12a0001	; NAKA ApFunction object id of the HD-AE5000: entry 1 of its ApFunction table (registry slot 0x12A = module 0x0A
.equ NAKA_APFUNC_HDD_DIRNAMECheck, 0x12a0002	; NAKA ApFunction object id of the HD-AE5000: entry 2 of its ApFunction table (registry slot 0x12A = module 0x0A
.equ NAKA_APFUNC_FlsNamingCheck, 0x12a0017	; NAKA ApFunction object id of the HD-AE5000: entry 23 of its ApFunction table (registry slot 0x12A = module 0x0
.equ NAKA_APFUNC_CP_FD_DIRNAMECheck, 0x12a0019	; NAKA ApFunction object id of the HD-AE5000: entry 25 of its ApFunction table (registry slot 0x12A = module 0x0
.equ NAKA_MAINFUNC_MainTitleControl, 0x1400001	; NAKA MainFunction object id: entry 1 of the Root MainFunction table (registry slot 0x140, table 0xEB3698), fir
.equ NAKA_MAINFUNC_MainPmanControl, 0x1400002	; NAKA MainFunction object id: entry 2 of the Root MainFunction table (registry slot 0x140, table 0xEB3698), fir
.equ NAKA_MAINFUNC_MainAutoFree, 0x1400003	; NAKA MainFunction object id: entry 3 of the Root MainFunction table (registry slot 0x140, table 0xEB3698), fir
.equ NAKA_MAINFUNC_MainGetSoundName, 0x1400004	; NAKA MainFunction object id: entry 4 of the Root MainFunction table (registry slot 0x140, table 0xEB3698), fir
.equ NAKA_MAINFUNC_MainGetRhythmName, 0x1400005	; NAKA MainFunction object id: entry 5 of the Root MainFunction table (registry slot 0x140, table 0xEB3698), fir
.equ NAKA_MAINFUNC_MainGetPmemName, 0x1400006	; NAKA MainFunction object id: entry 6 of the Root MainFunction table (registry slot 0x140, table 0xEB3698), fir
.equ NAKA_MAINFUNC_MainBitControl, 0x1400007	; NAKA MainFunction object id: entry 7 of the Root MainFunction table (registry slot 0x140, table 0xEB3698), fir
.equ NAKA_MAINFUNC_MainRamControl, 0x1400008	; NAKA MainFunction object id: entry 8 of the Root MainFunction table (registry slot 0x140, table 0xEB3698), fir
.equ NAKA_MAINFUNC_MainTrSwControl, 0x140000a	; NAKA MainFunction object id: entry 10 of the Root MainFunction table (registry slot 0x140, table 0xEB3698), fi
.equ NAKA_MAINFUNC_MainTaskControl, 0x140000c	; NAKA MainFunction object id: entry 12 of the Root MainFunction table (registry slot 0x140, table 0xEB3698), fi
.equ NAKA_MAINFUNC_MainPreControl, 0x1410000	; NAKA MainFunction object id: entry 0 of the Murai MainFunction table (registry slot 0x141, table 0xE86638), fi
.equ NAKA_MAINFUNC_MainMemDrawControl, 0x1410001	; NAKA MainFunction object id: entry 1 of the Murai MainFunction table (registry slot 0x141, table 0xE86638), fi
.equ NAKA_MAINFUNC_MainVariSet, 0x1420000	; NAKA MainFunction object id: entry 0 of the Toshi MainFunction table (registry slot 0x142, Toshi_MainFunction_
.equ NAKA_MAINFUNC_MainSvariIni, 0x1420001	; NAKA MainFunction object id: entry 1 of the Toshi MainFunction table (registry slot 0x142, Toshi_MainFunction_
.equ NAKA_MAINFUNC_MainChordPre, 0x1420007	; NAKA MainFunction object id: entry 7 of the Toshi MainFunction table (registry slot 0x142, Toshi_MainFunction_
.equ NAKA_MAINFUNC_MainPmGet, 0x1420008	; NAKA MainFunction object id: entry 8 of the Toshi MainFunction table (registry slot 0x142, Toshi_MainFunction_
.equ NAKA_MAINFUNC_MainSysControl, 0x142000a	; NAKA MainFunction object id: entry 10 of the Toshi MainFunction table (registry slot 0x142, Toshi_MainFunction
.equ NAKA_MAINFUNC_MainMssSetUp, 0x142000d	; NAKA MainFunction object id: entry 13 of the Toshi MainFunction table (registry slot 0x142, Toshi_MainFunction
.equ NAKA_MAINFUNC_MainTimeFlashFunc, 0x142000e	; NAKA MainFunction object id: entry 14 of the Toshi MainFunction table (registry slot 0x142, Toshi_MainFunction
.equ NAKA_MAINFUNC_MainWallSetFlashFunc, 0x142000f	; NAKA MainFunction object id: entry 15 of the Toshi MainFunction table (registry slot 0x142, Toshi_MainFunction
.equ NAKA_MAINFUNC_MainPcgOutSend, 0x1430000	; NAKA MainFunction object id: entry 0 of the East MainFunction table (registry slot 0x143, table 0xE5AD8C), fir
.equ NAKA_MAINFUNC_MainExcSend, 0x1430001	; NAKA MainFunction object id: entry 1 of the East MainFunction table (registry slot 0x143, table 0xE5AD8C), fir
.equ NAKA_MAINFUNC_MainMpstFunc, 0x1430002	; NAKA MainFunction object id: entry 2 of the East MainFunction table (registry slot 0x143, table 0xE5AD8C), fir
.equ NAKA_MAINFUNC_MainFlashFunc, 0x1430003	; NAKA MainFunction object id: entry 3 of the East MainFunction table (registry slot 0x143, table 0xE5AD8C), fir
.equ NAKA_MAINFUNC_MainVocalistPage1OKFunc, 0x1430004	; NAKA MainFunction object id: entry 4 of the East MainFunction table (registry slot 0x143, table 0xE5AD8C), fir
.equ NAKA_MAINFUNC_MainVocalistPage2OKFunc, 0x1430005	; NAKA MainFunction object id: entry 5 of the East MainFunction table (registry slot 0x143, table 0xE5AD8C), fir
.equ NAKA_MAINFUNC_MainRevEqPresetLoad, 0x1430006	; NAKA MainFunction object id: entry 6 of the East MainFunction table (registry slot 0x143, table 0xE5AD8C), fir
.equ NAKA_MAINFUNC_MiddleNameFunc, 0x144000a	; NAKA MainFunction object id: entry 10 of the Suna MainFunction table (registry slot 0x144, table 0xE1CA6E), fi
.equ NAKA_MAINFUNC_MainCmpCpFunc, 0x144000b	; NAKA MainFunction object id: entry 11 of the Suna MainFunction table (registry slot 0x144, table 0xE1CA6E), fi
.equ NAKA_MAINFUNC_MiddleCmpClrFunc, 0x144000c	; NAKA MainFunction object id: entry 12 of the Suna MainFunction table (registry slot 0x144, table 0xE1CA6E), fi
.equ NAKA_MAINFUNC_MainCmpSetFunc, 0x144000d	; NAKA MainFunction object id: entry 13 of the Suna MainFunction table (registry slot 0x144, table 0xE1CA6E), fi
.equ NAKA_MAINFUNC_MainS2cFunc, 0x144000e	; NAKA MainFunction object id: entry 14 of the Suna MainFunction table (registry slot 0x144, table 0xE1CA6E), fi
.equ NAKA_MAINFUNC_MainMspRgpSetFunc, 0x144000f	; NAKA MainFunction object id: entry 15 of the Suna MainFunction table (registry slot 0x144, table 0xE1CA6E), fi
.equ NAKA_MAINFUNC_MainMspBnkNameFunc, 0x1440010	; NAKA MainFunction object id: entry 16 of the Suna MainFunction table (registry slot 0x144, table 0xE1CA6E), fi
.equ NAKA_MAINFUNC_MspRecTtlFunc, 0x1440015	; NAKA MainFunction object id: entry 21 of the Suna MainFunction table (registry slot 0x144, table 0xE1CA6E), fi
.equ NAKA_MAINFUNC_MainEsCmpFunc, 0x1440018	; NAKA MainFunction object id: entry 24 of the Suna MainFunction table (registry slot 0x144, table 0xE1CA6E), fi
.equ NAKA_MAINFUNC_MainCstmNameFunc, 0x144001a	; NAKA MainFunction object id: entry 26 of the Suna MainFunction table (registry slot 0x144, table 0xE1CA6E), fi
.equ NAKA_MAINFUNC_SndArgNmGet, 0x144001b	; NAKA MainFunction object id: entry 27 of the Suna MainFunction table (registry slot 0x144, table 0xE1CA6E), fi
.equ NAKA_MAINFUNC_MainStylCnvFunc, 0x1440023	; NAKA MainFunction object id: entry 35 of the Suna MainFunction table (registry slot 0x144, table 0xE1CA6E), fi
.equ NAKA_MAINFUNC_DiskNameFunc, 0x145000b	; NAKA MainFunction object id: entry 11 of the Cheap MainFunction table (registry slot 0x145, table 0xEA7FCE), f
.equ NAKA_MAINFUNC_SaveFileNameFunc, 0x145000e	; NAKA MainFunction object id: entry 14 of the Cheap MainFunction table (registry slot 0x145, table 0xEA7FCE), f
.equ NAKA_MAINFUNC_FileRenameFunc, 0x1450022	; NAKA MainFunction object id: entry 34 of the Cheap MainFunction table (registry slot 0x145, table 0xEA7FCE), f
.equ NAKA_MAINFUNC_FileRenameSmfFunc, 0x1450023	; NAKA MainFunction object id: entry 35 of the Cheap MainFunction table (registry slot 0x145, table 0xEA7FCE), f
.equ NAKA_MAINFUNC_SaveFileNameSmfFunc, 0x145002f	; NAKA MainFunction object id: entry 47 of the Cheap MainFunction table (registry slot 0x145, table 0xEA7FCE), f
.equ NAKA_MAINFUNC_SetupFlashFunc, 0x1450030	; NAKA MainFunction object id: entry 48 of the Cheap MainFunction table (registry slot 0x145, table 0xEA7FCE), f
.equ NAKA_MAINFUNC_FmmPasswordFunc, 0x1450038	; NAKA MainFunction object id: entry 56 of the Cheap MainFunction table (registry slot 0x145, table 0xEA7FCE), f
.equ NAKA_MAINFUNC_MiddleFuncCall, 0x147001c	; NAKA MainFunction object id: entry 28 of the Yoko MainFunction table (registry slot 0x147, table 0xE25042), fi
.equ NAKA_MAINFUNC_NameGetFuncCall, 0x147001d	; NAKA MainFunction object id: entry 29 of the Yoko MainFunction table (registry slot 0x147, table 0xE25042), fi
.equ NAKA_MAINFUNC_ApPlaySyori_Yoko, 0x147001e	; NAKA MainFunction object id: entry 30 of the Yoko MainFunction table (slot 0x147, table 0xE25042), firmware na
.equ NAKA_MAINFUNC_ApEditSyori, 0x1480000	; NAKA MainFunction object id: entry 0 of the Kubo MainFunction table (registry slot 0x148, table 0xE3051C), fir
.equ NAKA_MAINFUNC_MainExeCall, 0x1480001	; NAKA MainFunction object id: entry 1 of the Kubo MainFunction table (registry slot 0x148, table 0xE3051C), fir
.equ NAKA_MAINFUNC_EffEditMain, 0x1480002	; NAKA MainFunction object id: entry 2 of the Kubo MainFunction table (registry slot 0x148, table 0xE3051C), fir
.equ NAKA_MAINFUNC_ApPlaySyori_Kubo, 0x1480003	; NAKA MainFunction object id: entry 3 of the Kubo MainFunction table (slot 0x148, table 0xE3051C), firmware nam
.equ NAKA_MAINFUNC_SngSelSyori, 0x148001e	; NAKA MainFunction object id: entry 30 of the Kubo MainFunction table (registry slot 0x148, table 0xE3051C), fi
.equ NAKA_MAINFUNC_NoteEditSyori, 0x148001f	; NAKA MainFunction object id: entry 31 of the Kubo MainFunction table (registry slot 0x148, table 0xE3051C), fi
.equ NAKA_MAINFUNC_MimeSyori, 0x1480023	; NAKA MainFunction object id: entry 35 of the Kubo MainFunction table (registry slot 0x148, table 0xE3051C), fi
.equ NAKA_MAINFUNC_HelpLangChkMain, 0x1480028	; NAKA MainFunction object id: entry 40 of the Kubo MainFunction table (registry slot 0x148, table 0xE3051C), fi
.equ NAKA_MAINFUNC_HelpFlashFunc, 0x1480029	; NAKA MainFunction object id: entry 41 of the Kubo MainFunction table (registry slot 0x148, table 0xE3051C), fi
.equ NAKA_MAINFUNC_MainPanic, 0x148002b	; NAKA MainFunction object id: entry 43 of the Kubo MainFunction table (registry slot 0x148, table 0xE3051C), fi
.equ NAKA_MAINFUNC_HDAETitleFunc, 0x14a0000	; NAKA MainFunction object id of the HD-AE5000: entry 0 of its MainFunction table (slot 0x14A, HDAE5000_ScreenPr
.equ NAKA_CLASS_Function, 0x1600001	; NAKA class id 0x0160:1 = class "Function" (parent Object) of the root Class table (slot 0x160, InitializeRoot)
.equ NAKA_CLASS_ApFunction, 0x1600002	; NAKA class id 0x0160:2 = class "ApFunction" (parent Function). ApFunctionProc returns it for MT_GetClassSp; Ap
.equ NAKA_CLASS_MainFunction, 0x1600003	; NAKA class id 0x0160:3 = class "MainFunction" (parent Function). MainFunctionProc returns it for MT_GetClassSp
.equ NAKA_CLASS_Class, 0x1600004	; NAKA class id 0x0160:4 = class "Class" (parent Object): the class of the class-definition tables (slots 0x160-
.equ NAKA_CLASS_SupportClass, 0x1600005	; NAKA class id 0x0160:5 = class "SupportClass" (parent Object). InitializeObjectTable registers registry slot 0
.equ NAKA_CLASS_Mode, 0x1600006	; NAKA class id 0x0160:6 = class "Mode" (parent Object; fields proc, title, user, name): the class of mode objec
.equ NAKA_CLASS_Title, 0x1600007	; NAKA class id 0x0160:7 = class "Title" (parent Object): the class of title objects 0x01A0nnnn. InitializeObjec
.equ NAKA_CLASS_ResEvent, 0x160000c	; NAKA class id 0x0160:12 = class "ResEvent" (parent Object; field name): the class of the named events 0x01Cmnn
.equ NAKA_CLASS_ResMethod, 0x160000d	; NAKA class id 0x0160:13 = class "ResMethod" (parent Object; field name): the class of the named methods 0x01Em
.equ NAKA_CLASS_ResName, 0x160000f	; NAKA class id 0x0160:15 = class "ResName" (parent Object): the class of the per-Viewable-table name tables (sl
.equ NAKA_CLASS_Viewable, 0x1600010	; NAKA class id 0x0160:16 = class "Viewable" (parent Object): base class of every UI widget record (+0 class, +4
.equ NAKA_CLASS_AcTitleMenu, 0x160001d	; NAKA class id 0x0160:29 = class "AcTitleMenu" (parent PsMenuBox; +42 str, +46 title, +50 icon): a menu entry t
.equ NAKA_CLASS_PsWideESBox, 0x1600021	; NAKA class id 0x0160:33 = class "PsWideESBox" (parent PsEditSwBox): the wide (two-switch) edit-switch box. AcI
.equ NAKA_CLASS_PsPageBox, 0x1600024	; NAKA class id 0x0160:36 = class "PsPageBox" (parent VwBox): page box. TtlScreen_PaintHandler asks SendEvent(sc
.equ NAKA_CLASS_IvMainEditSw, 0x1600029	; NAKA class id 0x0160:41 = class "IvMainEditSw" (parent PsInvisibleBox): invisible main-edit-switch catcher. Gr
.equ NAKA_CLASS_Screen, 0x1600033	; NAKA class id 0x0160:51 = class "Screen" (parent GroupBox; +26 exit, +30 window). Screen_Init tests MT_CheckCl
.equ NAKA_CLASS_Window, 0x1600035	; NAKA class id 0x0160:53 = class "Window" (parent GroupBox; +26 modal, +28 parent, +32 child). WindowID_EnumFil
.equ NAKA_CLASS_AcModeMenu, 0x1600040	; NAKA class id 0x0160:64 = class "AcModeMenu" (parent PsMenuBox): menu entry that changes mode. It shares AcTit
.equ NAKA_CLASS_AcScreenMenu, 0x1600041	; NAKA class id 0x0160:65 = class "AcScreenMenu" (parent PsMenuBox): menu entry that opens a screen. AcTitleMenu
.equ NAKA_CLASS_AcWindowMenu, 0x1600042	; NAKA class id 0x0160:66 = class "AcWindowMenu" (parent PsMenuBox): menu entry that opens a window. AcTitleMenu
.equ NAKA_CLASS_IvExit, 0x1600047	; NAKA class id 0x0160:71 = class "IvExit" (parent PsInvisibleBox): invisible exit handler. Screen_OK asks MT_Se
.equ NAKA_CLASS_PsTrackSwitch, 0x1600058	; NAKA class id 0x0160:88 = class "PsTrackSwitch" (parent Viewable). PsTrkSw_ShowHide gets MT_GetClass (0x01E000
.equ NAKA_CLASS_IvIntVari, 0x1600062	; NAKA class id 0x0160:98 = class "IvIntVari" (parent IvInterrupt): variation interrupt handler. GroupBox_SndCmd
.equ NAKA_CLASS_HDTitleMenu, 0x16a0005	; NAKA class id of the HD-AE5000: entry 5 of its Class table (slot 0x16A = module 0x0A, HDAE5000_RECORD_TABLE@0x
.equ NAKA_MODE_MD_PS, 0x1800000	; NAKA mode id: entry 0 of the Mode table (registry slot 0x180, class Mode 0x01600006, RAM 0x328FC), registered 
.equ NAKA_MODE_MD_NORMAL, 0x1800001	; NAKA mode id: entry 1 of the Mode table (slot 0x180), registered by RegMode as "MD_NORMAL" (module 2 Toshi, pr
.equ NAKA_MODE_MD_SOUND, 0x1800002	; NAKA mode id: entry 2 of the Mode table (slot 0x180), registered by RegMode as "MD_SOUND" (module 1 Murai, pro
.equ NAKA_MODE_MD_SOUNDEDIT, 0x1800003	; NAKA mode id: entry 3 of the Mode table (slot 0x180), registered by RegMode as "MD_SOUNDEDIT" (module 6 Scoop,
.equ NAKA_MODE_MD_ENTERTAINER, 0x1800007	; NAKA mode id: entry 7 of the Mode table (slot 0x180), registered by RegMode as "MD_ENTERTAINER" (module 8 Kubo
.equ NAKA_MODE_MD_SEQ, 0x1800008	; NAKA mode id: entry 8 of the Mode table (slot 0x180), registered by RegMode as "MD_SEQ" (module 8 Kubo, proc 0
.equ NAKA_MODE_MD_DEMO, 0x1800013	; NAKA mode id: entry 19 of the Mode table (slot 0x180), registered by RegMode as "MD_DEMO" (module 7 Yoko, proc
.equ EVT_GET_PART, 0x1e10000	; Firmware method MT_GetPart (ResMethod slot 0x1E1, Murai): ask an LSW mixer-item object for the mixer part that
.equ EVT_GET_LSW_DATA_NO, 0x1e10001	; Firmware method MT_GetLswDataNo: ask an LSW item object for the sound-parameter (LSW data) number of item XDE
.equ EVT_CHECK_PART, 0x1e10002	; Firmware method MT_CheckPart: ask an LSW item object whether item XDE is a per-part item; returns -1 when bit 
.equ EVT_READ_PRESENTATION_REQ, 0x1e10003	; Firmware method MT_ReadPresentation: load the Feature-Demo presentation file; the result is posted as 0x01C100
.equ EVT_READ_ACTION_REQ, 0x1e10004	; Firmware method MT_ReadAction: load a presentation action (named resource; XDE = malloc'd name); the result is
.equ EVT_READ_SONG_REQ, 0x1e10005	; Firmware method MT_ReadSong: load the song data of a presentation; the result is posted as 0x01C10003
.equ EVT_START_PRESENTATION, 0x1e10006	; Firmware method MT_StartPresentation: start the loaded presentation ((0x28A4) := 19, Demo_SelectEntry_ProcessS
.equ EVT_EXEC_PRESENTATION_REQ, 0x1e10007	; Firmware method MT_ExecPresentation: run a presentation (ApPreControl -> Seq_InitializeAndStart); MainPreContr
.equ EVT_REFRESH_PARAM, 0x1e10008	; Firmware method MT_RefreshParam: re-read the drawbar / memory-drawbar parameters into the display objects
.equ EVT_REQUEST_MEMORY_DRAWBAR, 0x1e10009	; Firmware method MT_RequestMemoryDrawbar: (re)initialise the memory-drawbar item workspace for the selected par
.equ EVT_SET_MEMORY_DRAWBAR, 0x1e1000a	; Firmware method MT_SetMemoryDrawbar: store one memory-drawbar item (XDE = item<<16 | value) and send it to the
.equ EVT_EXIST_PRESENTATION, 0x1e1000b	; Firmware method MT_ExistPresentation: query whether a presentation is loaded; MainPreControl returns the word 
.equ EVT_INIT_PRESENTATION, 0x1e1000c	; Firmware method MT_InitPresentation: clear the presentation-loaded flag (word 0x0251D8 := 0)
.equ EVT_EXIT_PRESENTATION, 0x1e1000d	; Firmware method MT_ExitPresentation: leave the presentation: if one is loaded (0x0251D8 != 0) call Part_InitFr
.equ EVT_GET_TONE_MODE, 0x1e1000e	; Firmware method MT_GetToneMode: query the voice/tone mode of drawbar part XDE; the answer is posted as 0x01C10
.equ EVT_VARI_WRITE, 0x1e20000	; Firmware method MT_VariWrite (slot 0x1E2, Toshi): write a variation parameter block (XDE) to the channels (MID
.equ EVT_SVARI_INI, 0x1e20001	; Firmware method MT_SvariIni: build the current sound-variation parameter block and broadcast it as MT_SvariSet
.equ EVT_SVARI_SET, 0x1e20002	; Firmware method MT_SvariSet: broadcast notification carrying the 6-byte sound-variation block built by MT_Svar
.equ EVT_GET_SND_NAME, 0x1e20003	; Firmware method MT_GetSndName: request the current sound name; answered by broadcasting MT_SOUNDNAME (0x01E200
.equ EVT_GET_SND_GRP_NAME, 0x1e20004	; Firmware method MT_GetSndGrpName: request the current sound-group name; answered with MT_SOUNDGRPNAME (0x01E20
.equ EVT_TOSHI_SOUND_NAME, 0x1e20005	; Firmware method MT_SOUNDNAME: reply to MT_GetSndName carrying the sound name
.equ EVT_SOUND_GRP_NAME, 0x1e20006	; Firmware method MT_SOUNDGRPNAME: reply to MT_GetSndGrpName carrying the sound-group name
.equ EVT_RVARI_INI, 0x1e20007	; Firmware method MT_RvariIni: build the current rhythm-variation block and broadcast it as MT_RvariSet (0x01E20
.equ EVT_RVARI_SET, 0x1e20008	; Firmware method MT_RvariSet: notification carrying the rhythm-variation block built by MT_RvariIni
.equ EVT_GET_RHY_NAME, 0x1e20009	; Firmware method MT_GetRhyName: request the current rhythm (style) name; answered with MT_RHYTHMNAME (0x01E2000
.equ EVT_GET_RHY_GRP_NAME, 0x1e2000a	; Firmware method MT_GetRhyGrpName: request the current rhythm-group name; answered with MT_RHYTHMGRPNAME (0x01E
.equ EVT_TOSHI_RHYTHM_NAME, 0x1e2000b	; Firmware method MT_RHYTHMNAME: reply to MT_GetRhyName carrying the rhythm name
.equ EVT_RHYTHM_GRP_NAME, 0x1e2000c	; Firmware method MT_RHYTHMGRPNAME: reply to MT_GetRhyGrpName carrying the rhythm-group name
.equ EVT_CHORD_PRE, 0x1e2000d	; Firmware method MT_ChordPre: chord-preset request from the chord box
.equ EVT_PM_BANK_SET_NOTIFY, 0x1e2000e	; Firmware method MT_PMBANKSET (upper case; the firmware distinguishes it from MT_PmBankSet 0x01E2000F only by c
.equ EVT_PM_BANK_SET, 0x1e2000f	; Firmware method MT_PmBankSet: panel-memory bank request; MainPmGet reads the current bank and broadcasts MT_PM
.equ EVT_PM_BANK_NAME, 0x1e20010	; Firmware method MT_PmBankName: request a panel-memory bank name block; answered by posting 0x01C20002 with an 
.equ EVT_PM_BANK_MK, 0x1e20011	; Firmware method MT_PmBankMk: query the mark (used/empty flag) of panel-memory bank XDE; answered by posting 0x
.equ EVT_PM_NAME_REQ, 0x1e20012	; Firmware method MT_PmName: request a panel-memory entry name; answered by posting 0x01C20003 with a 19-byte bl
.equ EVT_SYS_INI, 0x1e20013	; Firmware method MT_SYSINI: system initialise (factory reset) request; shows message 40 on title 0xEE, then res
.equ EVT_TOSHI_FLASH_WRITE, 0x1e20014	; Firmware method MT_FLASHWRITE of the Toshi module (same firmware name as 0x01E30005, hence the module qualifie
.equ EVT_TOSHI_FLASH_LOAD, 0x1e20015	; Firmware method MT_FLASHLOAD of the Toshi module (same firmware name as 0x01E30006): reload the wallpaper (sec
.equ EVT_WALL_INI, 0x1e20016	; Firmware method MT_WALLINI: reset the user wallpaper to the default and save it
.equ EVT_KEY_INFO, 0x1e20017	; Firmware method MT_KEYINFO: broadcast notification that a key was played (note/velocity latched at 0x8D84/0x8D
.equ EVT_OTP_CNT_SET, 0x1e20018	; Firmware method MT_OTPCNTSET (OTP presumably One Touch Play; the expansion is not verified): set the counter w
.equ EVT_OTP_CNT_RESET, 0x1e20019	; Firmware method MT_OTPCNTRESET: clear that mode ((0x8D4E) := 0)
.equ EVT_PCG_SEND, 0x1e30000	; Firmware method MT_PCGSEND (slot 0x1E3, East): transmit the computer-interface PCG output
.equ EVT_EXC_SEND, 0x1e30001	; Firmware method MT_EXCSEND: send a MIDI exclusive (SysEx) message
.equ EVT_DRAW_KEY, 0x1e30002	; Firmware method MT_DRAWKEY: format/draw the key name of a split-point value (Sprintf into the item text)
.equ EVT_MPST_LOAD, 0x1e30003	; Firmware method MT_MPSTLOAD: load a MIDI preset
.equ EVT_MPST_WRITE, 0x1e30004	; Firmware method MT_MPSTWRITE: write (copy) a MIDI preset
.equ EVT_EAST_FLASH_WRITE, 0x1e30005	; Firmware method MT_FLASHWRITE of the East module (same firmware name as 0x01E20014): save the parameter-load o
.equ EVT_EAST_FLASH_LOAD, 0x1e30006	; Firmware method MT_FLASHLOAD of the East module (same firmware name as 0x01E20015): reload flash section 7
.equ EVT_VST_PST_OK, 0x1e30007	; Firmware method MT_VST_PST_OK: vocalist page 1 (preset) OK
.equ EVT_VST_SEND_OK, 0x1e30008	; Firmware method MT_VST_SEND_OK: vocalist page 2 (send) OK
.equ EVT_REV_LOAD, 0x1e30009	; Firmware method MT_REVLOAD: load a reverb preset
.equ EVT_EQ_LOAD, 0x1e3000a	; Firmware method MT_EQLOAD: load an EQ preset
.equ EVT_REV_EQ_LOAD, 0x1e3000b	; Firmware method MT_REVEQLOAD: load a combined reverb+EQ preset
.equ EVT_CMP_NAME_SET, 0x1e40000	; Firmware method MT_CmpNameSet (slot 0x1E4, Suna): store the composer name (Strcpy XDE -> 0x34BC) and refresh
.equ EVT_MSP_NAME_SET, 0x1e40001	; Firmware method MT_MspNameSet: store the music-stylist preset name (Strcpy, then the ROM slot address from (0x
.equ EVT_RHY_GRP_NM_GET, 0x1e40002	; Firmware method MT_RhyGrpNmGet: request the rhythm-group name for composer copy; answered with MT_APRHYGRPNM (
.equ EVT_RHY_VARI_NM_GET, 0x1e40003	; Firmware method MT_RhyVariNmGet: request the rhythm-variation name for composer copy; answered with MT_APRHYVA
.equ EVT_AP_RHY_GRP_NM, 0x1e40004	; Firmware method MT_APRHYGRPNM: reply carrying the rhythm-group name (17-byte block) to the composer-copy group
.equ EVT_AP_RHY_VARI_NM, 0x1e40005	; Firmware method MT_APRHYVARINM: reply carrying the rhythm-variation name to the composer-copy variation box
.equ EVT_CMP_CLR_YES, 0x1e40006	; Firmware method MT_CmpClrYes: composer clear confirmed (set bit 2 of 0x34CD, close the dialog, message 35, sou
.equ EVT_CMP_CLR_NO, 0x1e40007	; Firmware method MT_CmpClrNo: composer clear cancelled (close the dialog)
.equ EVT_PAN_DN, 0x1e40009	; Firmware method MT_PanDn: composer-set grid: decrement the pan byte (min 0) of part XDE, then MT_RequestGridDr
.equ EVT_RLMT_DN, 0x1e4000b	; Firmware method MT_RLmtDn: composer-set grid: decrement the range-limit byte (min 0) of part XDE
.equ EVT_CMP_SET_P1_UP, 0x1e4000e	; Firmware method MT_CmpSetP1Up: composer-set page 1 value up ((0x3540) := value, DrumVoice_Select, then MT_Requ
.equ EVT_CMP_SET_P1_DN, 0x1e4000f	; Firmware method MT_CmpSetP1Dn: composer-set page 1 value down
.equ EVT_S2C_TR_UP, 0x1e40010	; Firmware method MT_S2cTrUp: S2c grid: value up for row XDE ((0x3990) := row, Tempo_AdjustEffect(0)), then redr
.equ EVT_S2C_TR_DN, 0x1e40011	; Firmware method MT_S2cTrDn: S2c grid: value down for row XDE (Tempo_AdjustEffect(1))
.equ EVT_RGP_BNK_UP, 0x1e40012	; Firmware method MT_RgpBnkUp: music-stylist rhythm-group bank up
.equ EVT_RGP_BNK_DN, 0x1e40013	; Firmware method MT_RgpBnkDn: music-stylist rhythm-group bank down
.equ EVT_RGP_PAD_UP, 0x1e40014	; Firmware method MT_RgpPadUp: music-stylist rhythm-group pad up
.equ EVT_RGP_PAD_DN, 0x1e40015	; Firmware method MT_RgpPadDn: music-stylist rhythm-group pad down
.equ EVT_CSTM_CP_OK, 0x1e40016	; Firmware method MT_CstmCpOk: custom-style copy confirmed: Flash_InitBytecodeBlock((0x39B6),(0x39B7)); on resul
.equ EVT_MSP_USR1_NM_GET, 0x1e40017	; Firmware method MT_MspUsr1NmGet: request the music-stylist user bank 1 name. The receiving main function is a 
.equ EVT_MSP_USR2_NM_GET, 0x1e40018	; Firmware method MT_MspUsr2NmGet: request the user bank 2 name (ignored: the receiver is a stub)
.equ EVT_MSP_RGP1_NM_GET, 0x1e40019	; Firmware method MT_MspRgp1NmGet: request the rhythm-group bank 1 name (ignored: the receiver is a stub)
.equ EVT_MSP_RGP2_NM_GET, 0x1e4001a	; Firmware method MT_MspRgp2NmGet: request the rhythm-group bank 2 name (ignored: the receiver is a stub)
.equ EVT_MSP_USR1_NM_DISP, 0x1e4001b	; Firmware method MT_MspUsr1NmDisp: reply that would display the user bank 1 name in the bank-name box. Nothing 
.equ EVT_MSP_USR2_NM_DISP, 0x1e4001c	; Firmware method MT_MspUsr2NmDisp: reply that would display the user bank 2 name (never sent in v10)
.equ EVT_MSP_RGP1_NM_DISP, 0x1e4001d	; Firmware method MT_MspRgp1NmDisp: reply that would display the rhythm-group bank 1 name (never sent in v10)
.equ EVT_MSP_RGP2_NM_DISP, 0x1e4001e	; Firmware method MT_MspRgp2NmDisp: reply that would display the rhythm-group bank 2 name (never sent in v10)
.equ EVT_MSP_PLY_MD_SET, 0x1e4001f	; Firmware method MT_MspPlyMdSet: set the music-stylist play-mode bit (bit 4 of the slot byte at 0x1E8820+16*(0x
.equ EVT_ARG_TONE_NM_GET, 0x1e40020	; Firmware method MT_ArgToneNmGet: sound-arranger grid: request the tone name of a cell; answered with MT_ArgTon
.equ EVT_ARG_CHO_GET, 0x1e40021	; Firmware method MT_ArgChoGet: sound-arranger grid: request the chord of a cell; answered with MT_ArgChoDisp (0
.equ EVT_ARG_TONE_NM_DISP, 0x1e40022	; Firmware method MT_ArgToneNmDisp: reply that displays a sound-arranger tone name (XDE = 0x10000 | cell)
.equ EVT_ARG_CHO_DISP, 0x1e40023	; Firmware method MT_ArgChoDisp: reply that displays a sound-arranger chord (XDE = 0x20000 | cell)
.equ EVT_SET_PT_SEL, 0x1e40024	; Firmware method MT_SetPtSel: set the sound-arranger part selection
.equ EVT_ES_CMP_STYL_UP, 0x1e40027	; Firmware method MT_EsCmpStylUp: easy-composer style up
.equ EVT_ES_CMP_STYL_DN, 0x1e40028	; Firmware method MT_EsCmpStylDn: easy-composer style down
.equ EVT_ES_CMP_VARI_UP, 0x1e40029	; Firmware method MT_EsCmpVariUp: easy-composer variation up
.equ EVT_ES_CMP_VARI_DN, 0x1e4002a	; Firmware method MT_EsCmpVariDn: easy-composer variation down
.equ EVT_CSTM_F_NM_GET, 0x1e4002b	; Firmware method MT_CstmFNmGet: request the custom-style copy source ('from') name (slot (0x39B6)); answered wi
.equ EVT_CSTM_T_NM_GET, 0x1e4002c	; Firmware method MT_CstmTNmGet: request the custom-style copy destination ('to') name (slot (0x39B7)); answered
.equ EVT_CSTM_F_NM_DISP, 0x1e4002d	; Firmware method MT_CstmFNmDisp: reply carrying the source name (17-byte block) to the custom-copy name box
.equ EVT_CSTM_T_NM_DISP, 0x1e4002e	; Firmware method MT_CstmTNmDisp: reply carrying the destination name to the custom-copy name box
.equ EVT_SET_SELECTED_LINE, 0x1e4002f	; Firmware method MT_SetSelectedLine: tell a parameter list box which line is selected (stored at view+38)
.equ EVT_STYL_CNV_STOR, 0x1e40030	; Firmware method MT_StylCnvStor: store the converted style into the bank slot selected at 0x3A4D (style-convert
.equ EVT_CLR_GRID_HANTEN, 0x1e40031	; Firmware method MT_ClrGridHanten: clear the grid reverse-video ('hanten') highlight: re-query the focused cell
.equ EVT_GET_FILE_SFX, 0x1e50000	; Firmware method MT_GetFileSfx (slot 0x1E5, Cheap): the file-suffix box asks its file-name main function for th
.equ EVT_SET_FILE_SFX, 0x1e50001	; Firmware method MT_SetFileSfx: reply carrying the file suffix to the suffix box
.equ EVT_SET_SELECTED_FILE_NUMBER, 0x1e50002	; Firmware method MT_SetSelectedFileNumber: tell a file-name list box which file index (XDE) is selected; the fi
.equ EVT_GET_SELECTED_FILE_NUMBER, 0x1e50003	; Firmware method MT_GetSelectedFileNumber: query the selected file index of a file-name main function
.equ EVT_PS_FILE_NAME_BOX_ID, 0x1e50004	; Firmware method MT_PsFileNameBoxID: a file-name list box, on create, registers its own object id (XDE) with it
.equ EVT_ON_WINDOW, 0x1e50005	; Firmware method MT_OnWindow: show a (wait) window
.equ EVT_OFF_WINDOW, 0x1e50006	; Firmware method MT_OffWindow: hide a (wait) window
.equ EVT_WHICH_WINDOW, 0x1e50007	; Firmware method MT_WhichWindow: tell the window-toggle main function which of its two windows is showing (XDE 
.equ EVT_I_WILL_WAKE_UP, 0x1e50008	; Firmware method MT_IWillWakeUp: a one-shot timer object, on create, registers itself (XDE = timer id) with its
.equ EVT_WAKE_UP_TIME, 0x1e50009	; Firmware method MT_WakeUpTime: arm a one-shot timer; after the delay the timer posts MT_WakeUpNow
.equ EVT_WAKE_UP_NOW, 0x1e5000a	; Firmware method MT_WakeUpNow: the one-shot timer fired; the timer forwards it to its callback main function
.equ EVT_CHEAP_FLASH_WRITE, 0x1e5000b	; Firmware method MT_FlashWrite of the Cheap module (cf. MT_FLASHWRITE 0x01E20014 / 0x01E30005): save the disk S
.equ EVT_CHEAP_FLASH_LOAD, 0x1e5000c	; Firmware method MT_FlashLoad of the Cheap module: reload flash section 6
.equ EVT_SET_PASSWORD, 0x1e5000d	; Firmware method MT_SetPassword: set the disk password
.equ EVT_CHECK_PASSWORD, 0x1e5000e	; Firmware method MT_CheckPassword: check the password before a delete
.equ EVT_CHECK_PASSWORD2, 0x1e5000f	; Firmware method MT_CheckPassword2: check the password before a save
.equ EVT_CHECK_PASSWORD3, 0x1e50010	; Firmware method MT_CheckPassword3: check the password before a load
.equ EVT_DEMO_SONG_SEL, 0x1e70000	; Firmware method MT_DemoSongSel (slot 0x1E7, Yoko): select a demo song ((0x28A4) := E; Demo_SelectEntry_Process
.equ EVT_SONG_NAME_SET, 0x1e70001	; Firmware method MT_SongNameSet: store a song name (Strcpy XDE -> RAM 0x1159) and apply it
.equ EVT_PS_SONG_SEL_BOX_ID, 0x1e70002	; Firmware method MT_PsSongSelBoxID: a song-select box, on create, registers its object id with its main functio
.equ EVT_SET_SELECTED_FILE_NUM, 0x1e70003	; Firmware method MT_SetSelectedFileNum (Yoko; near-namesake of Cheap's MT_SetSelectedFileNumber 0x01E50002): te
.equ EVT_TR_AS_TRACK_INC, 0x1e70004	; Firmware method MT_TrAsTrackInc: track-assign grid: next track
.equ EVT_TR_AS_TRACK_DEC, 0x1e70005	; Firmware method MT_TrAsTrackDec: track-assign grid: previous track
.equ EVT_TR_AS_PART_INC, 0x1e70006	; Firmware method MT_TrAsPartInc: track-assign grid: next part
.equ EVT_TR_AS_PART_DEC, 0x1e70007	; Firmware method MT_TrAsPartDec: track-assign grid: previous part
.equ EVT_TR_AS_PAGE_INC, 0x1e70008	; Firmware method MT_TrAsPageInc: track-assign grid: next page
.equ EVT_TR_AS_PAGE_DEC, 0x1e70009	; Firmware method MT_TrAsPageDec: track-assign grid: previous page
.equ EVT_AMD_CALL, 0x1e7000a	; Firmware method MT_AmdCall: track-assign: apply the AMD setting (the expansion of AMD is not established)
.equ EVT_DIRECT_PLAY_MUTE, 0x1e7000b	; Firmware method MT_DirectPlayMute: apply the direct-play / SMF track mute settings
.equ EVT_TRACK_MIDI_CALL, 0x1e7000c	; Firmware method MT_TrackMidiCall: track-assign: apply the track MIDI setting
.equ EVT_GET_CUR_SONG_NAME, 0x1e7000d	; Firmware method MT_GetCurSongName: copy the current song name (16 chars) for display
.equ EVT_GET_DISK_FILE_NAME, 0x1e7000e	; Firmware method MT_GetDiskFileName: get the disk file name for display
.equ EVT_GET_SMF_FILE_NAME, 0x1e7000f	; Firmware method MT_GetSmfFileName: get the SMF file name
.equ EVT_GET_SMF_SONG_NAME, 0x1e70010	; Firmware method MT_GetSmfSongName: get the SMF song name
.equ EVT_GET_DOC_SONG_NAME, 0x1e70012	; Firmware method MT_GetDocSongName: get the DOC song name
.equ EVT_GET_DOC_FILE_NO, 0x1e70013	; Firmware method MT_GetDocFileNo: get the DOC file number
.equ EVT_GET_PD_SONG_NAME, 0x1e70014	; Firmware method MT_GetPDSongName: get the PD song name
.equ EVT_GET_PD_FILE_NO, 0x1e70015	; Firmware method MT_GetPDFileNo: get the PD file number
.equ EVT_GET_MEAS_STRING, 0x1e70016	; Firmware method MT_GetMeasString: format the measure-number string of the measure box
.equ EVT_GET_TOGGLE_SW, 0x1e70017	; Firmware method MT_GetToggleSw: query the on/off state of a mute toggle switch
.equ EVT_LYRICS_CHARA_REQ, 0x1e70018	; Firmware method MT_LyricsCharaReq: request the lyrics characters for the lyrics display
.equ EVT_GET_LYRICS_SONG_NAME, 0x1e70019	; Firmware method MT_GetLyricsSongName: get the song name shown with the lyrics
.equ EVT_GET_COMPOSER_NAME, 0x1e7001a	; Firmware method MT_GetComporserName [sic, misspelt in ROM]: get the composer name of the song
.equ EVT_GET_EFF_FIX_STRING, 0x1e80000	; Kubo method MT_GetEffFixString: an effect widget asks its ApFunction for the effect-type ("fixed") string; Dsp
.equ EVT_GET_EFF_DLT0_STR, 0x1e80001	; Kubo method MT_GetEffDlt0Str: get the display string of effect parameter 0; formatted by DspItem0CngFunc (DspI
.equ EVT_GET_EFF_DLT1_STR, 0x1e80002	; Kubo method MT_GetEffDlt1Str: get the display string of effect parameter 1; formatted by DspItem0CngFunc (DspI
.equ EVT_GET_EFF_DLT2_STR, 0x1e80003	; Kubo method MT_GetEffDlt2Str: get the display string of effect parameter 2; formatted by DspItem0CngFunc (DspI
.equ EVT_GET_EFF_DLT3_STR, 0x1e80004	; Kubo method MT_GetEffDlt3Str: get the display string of effect parameter 3; formatted by DspItem0CngFunc (DspI
.equ EVT_GET_EFF_DLT4_STR, 0x1e80005	; Kubo method MT_GetEffDlt4Str: get the display string of effect parameter 4; formatted by DspItem0CngFunc (DspI
.equ EVT_GET_EFF_DLT5_STR, 0x1e80006	; Kubo method MT_GetEffDlt5Str: get the display string of effect parameter 5; formatted by DspItem0CngFunc (DspI
.equ EVT_GET_EFF_DLT6_STR, 0x1e80007	; Kubo method MT_GetEffDlt6Str: get the display string of effect parameter 6; formatted by DspItem0CngFunc (DspI
.equ EVT_GET_EFF_DLT7_STR, 0x1e80008	; Kubo method MT_GetEffDlt7Str: get the display string of effect parameter 7; formatted by DspItem0CngFunc (DspI
.equ EVT_GET_ITEM_EXIST, 0x1e80009	; Kubo method MT_GetItemExist: does item XDE exist? DspItem0CngFunc case returns (XDE < item count byte at RAM 0
.equ EVT_SET_ITEM_OFF, 0x1e8000a	; Kubo method MT_SetItemOff: store the list item offset; DspItem0CngFunc case writes E to RAM 0x02109a. EffectBo
.equ EVT_GET_ITEM_OFF, 0x1e8000b	; Kubo method MT_GetItemOff: return the list item offset (RAM byte 0x02109a) via the DspItem0CngFunc case.
.equ EVT_SET_ITEM_TOP, 0x1e8000c	; Kubo method MT_SetItemTop: store the first displayed item; DspItem0CngFunc case writes E to RAM 0x021098. Effe
.equ EVT_GET_ITEM_TOP, 0x1e8000d	; Kubo method MT_GetItemTop: return the first displayed item (RAM byte 0x021098) via the DspItem0CngFunc case.
.equ EVT_RET_EFF_FIX, 0x1e8000e	; Kubo method MT_RetEffFix: delivered by the effect editor main function (EffEditMain, on EV_PAINT) to the effec
.equ EVT_RET_EFF_PARA, 0x1e8000f	; Kubo method MT_RetEffPara: delivered by EffEditMain for each effect parameter n (XDE = n; 8 for effect blocks 
.equ EVT_CNG_EFF_TYPE, 0x1e80011	; Kubo method MT_CngEffType: an effect widget posts the new effect type to EffEditMain (MainPostEvent), whose ha
.equ EVT_CNG_EFF_PARA, 0x1e80012	; Kubo method MT_CngEffPara: an effect/EQ widget posts a changed parameter value to EffEditMain, handled by EffE
.equ EVT_GET_DISP_POS, 0x1e80013	; Kubo method MT_GetDispPos: the equalizer widget asks EqualizerCngFunc for the display position of EQ item XDE 
.equ EVT_INC_VAL, 0x1e80014	; Kubo method MT_IncVal: increment the selected parameter (XDE = parameter index); posted by the sequencer value
.equ EVT_DEC_VAL, 0x1e80015	; Kubo method MT_DecVal: decrement the selected parameter; posted by the down-scroll handlers, handled by ApEdit
.equ EVT_GET_TRK_STRING, 0x1e80016	; Kubo method MT_GetTrkString: get the display string of the track field (sequencer edit); formatted by SqedtFun
.equ EVT_GET_FM_STRING, 0x1e80017	; Kubo method MT_GetFMString: get the display string of the from-measure field (sequencer edit); formatted by Sq
.equ EVT_GET_LM_STRING, 0x1e80018	; Kubo method MT_GetLMString: get the display string of the last-measure field (sequencer edit); formatted by Sq
.equ EVT_GET_ADLY_STRING, 0x1e80019	; Kubo method MT_GetAdlyString: get the display string of the "Adly" (firmware abbreviation, not decoded) field 
.equ EVT_GET_TRNS_STRING, 0x1e8001a	; Kubo method MT_GetTrnsString: get the display string of the transpose field (sequencer edit); formatted by Sqe
.equ EVT_GET_VELO_STRING, 0x1e8001b	; Kubo method MT_GetVeloString: get the display string of the velocity field (sequencer edit); formatted by Sqed
.equ EVT_GET_MERS_STRING, 0x1e8001c	; Kubo method MT_GetMersString: get the display string of the "Mers" (firmware abbreviation, not decoded) field 
.equ EVT_GET_QTZ_VAL_STRING, 0x1e8001d	; Kubo method MT_GetQtzValString: get the display string of the quantize value field (sequencer edit); formatted
.equ EVT_GET_QTZ_STR_STRING, 0x1e8001e	; Kubo method MT_GetQtzStrString: get the display string of the quantize strength field (sequencer edit); format
.equ EVT_GET_QTZ_WIN_STRING, 0x1e8001f	; Kubo method MT_GetQtzWinString: get the display string of the quantize window field (sequencer edit); formatte
.equ EVT_GET_TN_STRING, 0x1e80020	; Kubo method MT_GetTnString: get the display string of the "Tn" (firmware abbreviation) field (sequencer edit);
.equ EVT_GET_CN_STRING, 0x1e80021	; Kubo method MT_GetCnString: get the display string of the "Cn" (firmware abbreviation) field (sequencer edit);
.equ EVT_GET_MRG_TR_A_STRING, 0x1e80022	; Kubo method MT_GetMrgTrAString: get the display string of the merge track A field (sequencer edit); formatted 
.equ EVT_GET_MRG_TR_B_STRING, 0x1e80023	; Kubo method MT_GetMrgTrBString: get the display string of the merge track B field (sequencer edit); formatted 
.equ EVT_GET_MRG_TR_C_STRING, 0x1e80024	; Kubo method MT_GetMrgTrCString: get the display string of the merge track C field (sequencer edit); formatted 
.equ EVT_GET_MCP_TR_A_STRING, 0x1e80025	; Kubo method MT_GetMcpTrAString: get the display string of the measure-copy track A field (sequencer edit); for
.equ EVT_GET_MCP_FM_STRING, 0x1e80026	; Kubo method MT_GetMcpFMString: get the display string of the measure-copy from-measure field (sequencer edit);
.equ EVT_GET_MCP_LM_STRING, 0x1e80027	; Kubo method MT_GetMcpLMString: get the display string of the measure-copy last-measure field (sequencer edit);
.equ EVT_GET_MCP_TR_B_STRING, 0x1e80028	; Kubo method MT_GetMcpTrBString: get the display string of the measure-copy track B field (sequencer edit); for
.equ EVT_GET_MCP_SM_STRING, 0x1e80029	; Kubo method MT_GetMcpSMString: get the display string of the measure-copy start-measure field (sequencer edit)
.equ EVT_GET_MCP_REP_STRING, 0x1e8002a	; Kubo method MT_GetMcpRepString: get the display string of the measure-copy repeat count field (sequencer edit)
.equ EVT_GET_MINS_TR_A_STRING, 0x1e8002b	; Kubo method MT_GetMinsTrAString: get the display string of the measure-insert track A field (sequencer edit); 
.equ EVT_GET_MINS_FM_STRING, 0x1e8002c	; Kubo method MT_GetMinsFMString: get the display string of the measure-insert from-measure field (sequencer edi
.equ EVT_GET_MINS_LM_STRING, 0x1e8002d	; Kubo method MT_GetMinsLMString: get the display string of the measure-insert last-measure field (sequencer edi
.equ EVT_GET_MINS_TR_B_STRING, 0x1e8002e	; Kubo method MT_GetMinsTrBString: get the display string of the measure-insert track B field (sequencer edit); 
.equ EVT_GET_MINS_SM_STRING, 0x1e8002f	; Kubo method MT_GetMinsSMString: get the display string of the measure-insert start-measure field (sequencer ed
.equ EVT_GET_MINS_REP_STRING, 0x1e80030	; Kubo method MT_GetMinsRepString: get the display string of the measure-insert repeat count field (sequencer ed
.equ EVT_GET_SCP_FSNG_STRING, 0x1e80031	; Kubo method MT_GetScpFsngString: get the display string of the song-copy from-song field (sequencer edit); for
.equ EVT_GET_SCP_FTR_STRING, 0x1e80032	; Kubo method MT_GetScpFtrString: get the display string of the song-copy from-track field (sequencer edit); for
.equ EVT_GET_SCP_TSNG_STRING, 0x1e80033	; Kubo method MT_GetScpTsngString: get the display string of the song-copy to-song field (sequencer edit); forma
.equ EVT_GET_SCP_TTR_STRING, 0x1e80034	; Kubo method MT_GetScpTtrString: get the display string of the song-copy to-track field (sequencer edit); forma
.equ EVT_SET_CUR_POS, 0x1e80035	; Kubo method MT_SetCurPos: set the cursor position (XDE) of a sequencer value list (SqplyFunc / SqedtFunc).
.equ EVT_GET_CUR_POS, 0x1e80036	; Kubo method MT_GetCurPos: get the cursor position of a sequencer value list (SqplyFunc / SqedtFunc).
.equ EVT_CUR_TO_PARAM, 0x1e80037	; Kubo method MT_CurToParam: convert the cursor position to a parameter of a sequencer value list (SqplyFunc / S
.equ EVT_CHK_CUR, 0x1e80038	; Kubo method MT_ChkCur: check the cursor (returns a flag) of a sequencer value list (SqplyFunc / SqedtFunc).
.equ EVT_CHK_CUR2, 0x1e80039	; Kubo method MT_ChkCur2: second cursor check of a sequencer value list (SqplyFunc / SqedtFunc).
.equ EVT_GET_FROM_CUR, 0x1e8003a	; Kubo method MT_GetFromCur: get the from-cursor of a sequencer value list (SqplyFunc / SqedtFunc).
.equ EVT_SET_FROM_CUR, 0x1e8003b	; Kubo method MT_SetFromCur: set the from-cursor of a sequencer value list (SqplyFunc / SqedtFunc).
.equ EVT_GET_TO_CUR, 0x1e8003c	; Kubo method MT_GetToCur: get the to-cursor of a sequencer value list (SqplyFunc / SqedtFunc).
.equ EVT_SET_TO_CUR, 0x1e8003d	; Kubo method MT_SetToCur: set the to-cursor of a sequencer value list (SqplyFunc / SqedtFunc).
.equ EVT_KUBO_GET_MEAS_STRING, 0x1e8003e	; Kubo method MT_GetMeasString: display string of the current measure ("%3d.", "***." above 999, RAM word 0x2744
.equ EVT_GET_BEAT_STRING, 0x1e8003f	; Kubo method MT_GetBeatString: get the display string of the beat field (sequencer play screen); SqplyFunc 10-w
.equ EVT_GET_MEM_STRING, 0x1e80040	; Kubo method MT_GetMemString: get the display string of the memory field (sequencer play screen); SqplyFunc 10-
.equ EVT_GET_CYC_EN_STRING, 0x1e80041	; Kubo method MT_GetCycEnString: get the display string of the cycle on/off field (sequencer play screen); Sqply
.equ EVT_GET_CYC_SRT_M_STRING, 0x1e80042	; Kubo method MT_GetCycSrtMString: get the display string of the cycle start measure field (sequencer play scree
.equ EVT_GET_CYC_END_M_STRING, 0x1e80043	; Kubo method MT_GetCycEndMString: get the display string of the cycle end measure field (sequencer play screen)
.equ EVT_SET_CYCLE, 0x1e80044	; Kubo method MT_SetCycle: CycleOnOffFunc posts it to MainFunction 0x1480003 (ApPlaySyori) when its toggle chang
.equ EVT_SET_METRO, 0x1e80045	; Kubo method MT_SetMetro: MetroOnOffFunc posts it (XDE = 0/1) to ApPlaySyori; handler NoteEditSy_ModeScroll (mi
.equ EVT_SET_PUNCH, 0x1e80046	; Kubo method MT_SetPunch: PunchInOutFunc posts it (XDE = 0/1) to ApPlaySyori; handler NoteEditSy_ModeScrollRetu
.equ EVT_GET_SOLO_EN_STRING, 0x1e80047	; Kubo method MT_GetSoloEnString: get the display string of the solo on/off field (sequencer play screen); Sqply
.equ EVT_GET_SCLR_NO_STRING, 0x1e80048	; Kubo method MT_GetSclrNoString ("Sclr" read as scale: an inference): SqedtVal3 asks SqedtFunc for the scale nu
.equ EVT_GET_SCLR_NAME_STRING, 0x1e80049	; Kubo method MT_GetSclrNameString ("Sclr" read as scale: an inference): SqedtVal3 asks SqedtFunc for the scale 
.equ EVT_GET_SCLR_KB_STRING, 0x1e8004a	; Kubo method MT_GetSclrKbString ("Sclr" read as scale: an inference): SqedtVal3 asks SqedtFunc for the scale ke
.equ EVT_GET_SCLR_PER_STRING, 0x1e8004b	; Kubo method MT_GetSclrPerString ("Sclr" read as scale: an inference): SqedtVal3 asks SqedtFunc for the scale p
.equ EVT_GET_ACC_LVL_STR, 0x1e8004c	; Kubo method MT_GetAccLvlStr: display string of the accompaniment level; sent by AccIll_ClearDrawBuffer2, handl
.equ EVT_GET_P_MEAS_STRING, 0x1e8004d	; Kubo method MT_GetPMeasString: SqplyFunc formats the "P" measure ("-2"/"-1" while counting in, else "%3d") for
.equ EVT_GET_P_IN_MEAS_STRING, 0x1e8004e	; Kubo method MT_GetPInMeasString: SqplyFunc formats the "P" in-measure (RAM word 0xf238, " %3d ") for the play 
.equ EVT_GET_P_OUT_MEAS_STRING, 0x1e8004f	; Kubo method MT_GetPOutMeasString: SqplyFunc formats the "P" out-measure (RAM word 0xf23a) for the play screen 
.equ EVT_GET_P_CNT_IN_STRING, 0x1e80050	; Kubo method MT_GetPCntInString: SqplyFunc formats the "P" count-in (RAM word 0xf23f) for the play screen ("P" 
.equ EVT_GET_END_POS, 0x1e80051	; Kubo method MT_GetEndPos: note edit: get the end position; NoteEditFunc 16-way switch (base 0x01E80051). The `
.equ EVT_GET_TRI_POS, 0x1e80052	; Kubo method MT_GetTriPos: note edit: get the "Tri" position (firmware abbreviation); NoteEditFunc 16-way switc
.equ EVT_GET_LINE_POS, 0x1e80053	; Kubo method MT_GetLinePos: note edit: get the line position; NoteEditFunc 16-way switch (base 0x01E80051).
.equ EVT_GET_HAKU_STRING, 0x1e80054	; Kubo method MT_GetHakuString: note edit: display string of the beat ("haku"); NoteEditFunc 16-way switch (base
.equ EVT_GET_POS_STRING, 0x1e80055	; Kubo method MT_GetPosString: note edit: display string of the position; NoteEditFunc 16-way switch (base 0x01E
.equ EVT_GET_INC_STRING, 0x1e80056	; Kubo method MT_GetIncString: note edit: display string of the increment; NoteEditFunc 16-way switch (base 0x01
.equ EVT_GET_NOTE_STRING, 0x1e80057	; Kubo method MT_GetNoteString: note edit: display string of the note; NoteEditFunc 16-way switch (base 0x01E800
.equ EVT_GET_VEL_STRING, 0x1e80058	; Kubo method MT_GetVelString: note edit: display string of the velocity; NoteEditFunc 16-way switch (base 0x01E
.equ EVT_GET_INPUT_VEL_STRING, 0x1e80059	; Kubo method MT_GetInputVelString: note edit: display string of the input velocity; NoteEditFunc 16-way switch 
.equ EVT_GET_LEN_STRING, 0x1e8005a	; Kubo method MT_GetLenString: note edit: display string of the length; NoteEditFunc 16-way switch (base 0x01E80
.equ EVT_GET_INPUT_LEN_STRING, 0x1e8005b	; Kubo method MT_GetInputLenString: note edit: display string of the input length; NoteEditFunc 16-way switch (b
.equ EVT_GET_MEAS_TOP_NUM_SV, 0x1e8005c	; Kubo method MT_GetMeasTopNumSv: note edit: get the saved measure top number; NoteEditFunc 16-way switch (base 
.equ EVT_GET_MEAS_CNG_SV, 0x1e8005d	; Kubo method MT_GetMeasCngSv: note edit: get the saved measure change; NoteEditFunc 16-way switch (base 0x01E80
.equ EVT_NOTE_BAR_DISP, 0x1e8005e	; Kubo method MT_NoteBarDisp: note edit: draw the note bars; NoteEditFunc 16-way switch (base 0x01E80051).
.equ EVT_NOTE_BAR_DISP2, 0x1e8005f	; Kubo method MT_NoteBarDisp2: note edit: draw the note bars (second form); NoteEditFunc 16-way switch (base 0x0
.equ EVT_NOTE_HILIGHT_DISP, 0x1e80060	; Kubo method MT_NoteHilightDisp: note edit: draw the note highlight; NoteEditFunc 16-way switch (base 0x01E8005
.equ EVT_GET_EQ0_STR, 0x1e80061	; Kubo method MT_GetEq0Str: get the display string of EQ band 0; EqualizerCngFunc 9-way switch (base 0x01E80061)
.equ EVT_GET_EQ1_STR, 0x1e80062	; Kubo method MT_GetEq1Str: get the display string of EQ band 1; EqualizerCngFunc 9-way switch (base 0x01E80061)
.equ EVT_GET_EQ2_STR, 0x1e80063	; Kubo method MT_GetEq2Str: get the display string of EQ band 2; EqualizerCngFunc 9-way switch (base 0x01E80061)
.equ EVT_GET_EQ3_STR, 0x1e80064	; Kubo method MT_GetEq3Str: get the display string of EQ band 3; EqualizerCngFunc 9-way switch (base 0x01E80061)
.equ EVT_GET_EQ4_STR, 0x1e80065	; Kubo method MT_GetEq4Str: get the display string of EQ band 4; EqualizerCngFunc 9-way switch (base 0x01E80061)
.equ EVT_GET_EQ5_STR, 0x1e80066	; Kubo method MT_GetEq5Str: get the display string of EQ band 5; EqualizerCngFunc 9-way switch (base 0x01E80061)
.equ EVT_GET_EQ6_STR, 0x1e80067	; Kubo method MT_GetEq6Str: get the display string of EQ band 6; EqualizerCngFunc 9-way switch (base 0x01E80061)
.equ EVT_GET_EQ7_STR, 0x1e80068	; Kubo method MT_GetEq7Str: get the display string of EQ band 7; EqualizerCngFunc 9-way switch (base 0x01E80061)
.equ EVT_GET_TTL_NOW, 0x1e80069	; Kubo method MT_GetTtlNow: return the current title's entry number; every Kubo ApFunction that handles it (Note
.equ EVT_GET_KB1_STR, 0x1e8006a	; Kubo method MT_GetKb1Str: NoteEditFunc copies the 6-char key name of key (RAM byte 0x2798)+1 (case NoteEdit_Fo
.equ EVT_GET_KB2_STR, 0x1e8006b	; Kubo method MT_GetKb2Str: NoteEditFunc copies the 6-char key name of key (RAM byte 0x2798) (case NoteEdit_Form
.equ EVT_GET_DR_NUM_STRING, 0x1e8006c	; Kubo method MT_GetDrNumString: NoteEditFunc sprintf's the drum note number (RAM 0x279e + 0x021096) (case NoteE
.equ EVT_GET_DR_NAME_STRING, 0x1e8006d	; Kubo method MT_GetDrNameString: NoteEditFunc copies the 10-char drum instrument name (13-byte records) (case N
.equ EVT_CHK_TOGGLE_EDIT_SW, 0x1e8006e	; Kubo method MT_ChkToggleEditSw: AcIndexWideToggleProc sends it to itself on a switch press; handler AcIndexTog
.equ EVT_GET_LANG, 0x1e8006f	; Kubo method MT_GetLang: AcIndexWideToggleFunc returns the help language (RAM byte 0x0340e4); asked by AcIndexT
.equ EVT_SET_LANG, 0x1e80070	; Kubo method MT_SetLang: AcIndexWideToggleFunc stores the new help language at 0x0340e4 and posts the same meth
.equ EVT_CHK_LANG, 0x1e80071	; Kubo method MT_ChkLang: AcIndexWideToggleFunc returns 1 if XDE equals the current help language (0x0340e4).
.equ EVT_GET_F_SNG_NAME_STRING, 0x1e80072	; Kubo method MT_GetFSngNameString: SqedtFunc copies the 16-char from-song name (RAM 0x2842) (case SqedtFunc_Mod
.equ EVT_GET_T_SNG_NAME_STRING, 0x1e80073	; Kubo method MT_GetTSngNameString: SqedtFunc copies the 16-char to-song name (RAM 0x2852) (case SqedtFunc_ModeB
.equ EVT_KUBO_FLASH_WRITE, 0x1e80074	; Kubo method MT_FLASHWRITE: HelpOkSwFunc calls MainFunction 0x1480029 (HelpFlashFunc) with it; the handler send
.equ EVT_KUBO_FLASH_LOAD, 0x1e80075	; Kubo method MT_FLASHLOAD: the help screens (HelpLangChk_CheckIzZero, HelpFunc_CheckIzZero) call HelpFlashFunc 
.equ EVT_PANIC, 0x1e80076	; Kubo method MT_PANIC: PanicFunc (the panic switch, on EVT_SW_ON) calls MainFunction 0x148002b (MainPanic), 
.equ EVT_HDAE_OVER_FLOW, 0x1ea0000	; HD-AE5000 method MT_OverFlow: HDAE5000_SelectListProc, on MT_ChangeSelNum, finds the new selection >= the row 
.equ EVT_HDAE_UNDER_FLOW, 0x1ea0001	; HD-AE5000 method MT_UnderFlow: SelectListProc reports a new selection < 0 to its owner; the screens page back 
.equ EVT_HDAE_CHANGE_SEL_NUM, 0x1ea0002	; HD-AE5000 method MT_ChangeSelNum: to the list (SelectListProc) it means "move the selection by XDE" (dial/page
.equ EVT_HDAE_SET_SEL_NUM, 0x1ea0003	; HD-AE5000 method MT_SetSelNum: set the list's selection to XDE; SelectListProc stores it at *(instance+0x2e), 
.equ EVT_HDAE_REQ_SEL_NUM, 0x1ea0004	; HD-AE5000 method MT_ReqSelNum: ask the list for its selection; SelectListProc answers the owner with MT_AckSel
.equ EVT_HDAE_ACK_SEL_NUM, 0x1ea0005	; HD-AE5000 method MT_AckSelNum: the answer to MT_ReqSelNum; SelectListProc MainFuncCall's the owner (instance+0
.equ EVT_HDAE_SELECT_OK, 0x1ea0006	; HD-AE5000 method MT_SelectOK: SelectListProc forwards a press of soft button base+3 to its owner with the curr
.equ EVT_HDAE_SELECT_OK2, 0x1ea0007	; HD-AE5000 method MT_SelectOK2: SelectListProc forwards soft button base+6 with the current selection; handled 
.equ EVT_HDAE_SELECT_SAVE, 0x1ea0008	; HD-AE5000 method MT_SelectSAVE: SelectListProc forwards soft button base+4 with the current selection; FILE_LO
.equ EVT_HDAE_SELECT_ALL, 0x1ea0009	; HD-AE5000 method MT_SelectAll: SelectListProc forwards soft button base+8; HDAE5000_CopyToHDScreen marks all e
.equ EVT_HDAE_SET_STR_ADR, 0x1ea000a	; HD-AE5000 method MT_SetStrAdr: give a list its row-string table; SelectListProc stores XDE at *(instance+0x26)
.equ EVT_HDAE_SELECT_DEL, 0x1ea000c	; HD-AE5000 method MT_SelectDEL: SelectListProc forwards soft button base+7; HDAE5000_FILE_LOAD_Screen opens the
.equ EVT_HDAE_SELECT_DEL_FILE, 0x1ea000d	; HD-AE5000 method MT_SelectDelFile: SelectListProc forwards soft button base+5; HDAE5000_FILE_LOAD_Screen selec
.equ EVT_HDAE_FD_FRESH_UP, 0x1ea000e	; HD-AE5000 method MT_FdFreshUp: refresh the floppy lyric-file list; HDAE5000_FDFileSelectProc clears the FdLyri
.equ EVT_HDAE_FD_INFO, 0x1ea000f	; HD-AE5000 method MT_FdInfo: accepted by HDAE5000_FDFileSelectProc as a stub (returns 0); no sender in the ROM.
.equ EVT_HDAE_FD_LOAD_LYRIC, 0x1ea0010	; HD-AE5000 method MT_FdLoadLyric: accepted by HDAE5000_FDFileSelectProc as a stub (returns 0); no sender in the
.equ EVT_HDAE_FD_SAVE_LYRIC, 0x1ea0011	; HD-AE5000 method MT_FdSaveLyric: accepted by HDAE5000_FDFileSelectProc as a stub (returns 0); no sender in the
