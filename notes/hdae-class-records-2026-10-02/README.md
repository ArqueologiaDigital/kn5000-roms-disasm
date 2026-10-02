# HD-AE5000 class records: the "undecoded" fields are the NAKA class fields (2026-10-02)

| script | question it answers | run |
|---|---|---|
| `hdae_class_fields_probe.py` | Do the 13 HD-AE5000 class records (hdae5000_data_tables.s) follow the main CPU's class-definition layout? Checks selfsize == summed signature sizes and allsize == parent allsize + selfsize, the parent looked up by class id in v10's class tables. | `make all; python3 notes/hdae-class-records-2026-10-02/hdae_class_fields_probe.py` |

Result: VERDICT PASS, all 13.  So +0x04 is the parent class id (all in the root table,
0x0160_00xx) and +0x08 / +0x0A are allsize / selfsize.  The records now say so
(`.long NAKA_CLASS_VwBox ; +0x04 parent class`, `.short 60, 32 ; +0x08 allsize, +0x0A
selfsize`); the 9 parent classes became NAKA_CLASS_* constants in every tree's
shared/event_codes.s through scripts/tools/apply_event_constants.py with
`class_constants.json`; NamePtr / SigPtr point at labels `ClassName_<Name>` /
`ClassSig_<Name>` (scripts/tools/label_hdae_class_strings.py).
