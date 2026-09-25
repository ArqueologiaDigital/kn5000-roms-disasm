# One-off header / typing patches, lane sequi, 2026-09-25

Each script edited one owned source file ONCE, against the file state of the
moment, and is kept as the record of exactly what was written (they assert
their anchors, so they refuse to run on the current files rather than apply
twice).  The committed sources and the byte gate are the result; the numbers
quoted in the headers they wrote are re-derived by
`scripts/analysis/sequi_header_evidence.py`.

| script | file(s) | what it wrote |
|---|---|---|
| `sam_v10.py`, `sam_v7.py`, `rename_sam.py` | `sequencer/seq_audio_mode.s` | headers + `.long` typing for AccVoice_BankBaseTable / AccPedal_BankBaseTableCopy, names and headers for the four decoded dead routines (later renamed by `rename_sam.py` and a follow-up edit to AccTuning_ResetFiveParts) |
| `rhythm_v10.py` | `sequencer/rhythm_routines.s` (`img path key=ADDR ... ram:OLD=NEW`) | the four rhythm tables typed from ROM bytes, with reader headers; v7 run with a RAM-address remap |
| `smf.py` | `sequencer/smf_config_routines.s` | SMF_HeaderConstants / SMF_PartAssignTable / SMF_SlotParam_RPNReturn / SMF_SlotParam_PortamentoTime headers, reader addresses taken from each version's ELF |
| `smfchan.py` | `sequencer/smf_config_routines.s` | SMF_ChannelTranslationTable typed + header |
| `bmd.py` | `sequencer/bmdredit_routines.s` | names + headers for the four unreferenced routines and BmDrEdit_TestPartTableEntry |
| `composer.py` | `sequencer/composer_msp_defaults.s` | Composer_SettingsBlock layout header, Composer_FunctionTable label; its entry counts were WRONG and were corrected by commit 550dd8b1 |

Usage shape: `python3 notes/sequi-2026-09-25/patches/<script>.py <image> <file> [...]`
(see each script's `sys.argv` use).  Requires the image's ELF from `make`.
