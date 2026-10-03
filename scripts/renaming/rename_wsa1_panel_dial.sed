# WSA1 prom_a 0xFD7BC3 / 0xFD7BDE / 0xFD7C01 (prom_b imports them by .set): the dial-as-buttons helpers.
# (0x2075) bit 0 makes the dial act as the buttons in PanelDial_UpButton / PanelDial_DownButton
# (wsa1/include/wsa1_ram.inc; PanelEvent_Code21_Dial).
s/\bsub_FD7BC3\b/PanelDial_SetButtonMode/g
s/\bsub_FD7BDE\b/PanelDial_SetDirectionButton/g
s/\bsub_FD7C01\b/PanelDial_ActAsButton/g
