#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in region EABD04-EAC9E8.
Uses binary I/O to handle encoding safely.

This region contains:
  - A pointer table (EAB908) for bitmap filenames used by instrument icon buttons
  - Bitmap filename strings (EABD04-EABE7C) for instrument category icons and transport controls
  - A GUI widget property descriptor system (EABE98-EAC9E8):
      Each widget type has a pointer table pointing to a list of null-terminated property
      name strings, terminated by a sentinel entry (0x00, 0xff). The pattern is:
        <ptr_table_label>: series of .long pointers (last points at empty-string sentinel)
        <sentinel_label>: .byte 0x00, 0xff   (end of property list)
        <propN_label>: aligned_string "propname"
        ...
      Widget types identified include: object, proplist, window, widget-base, spinbox,
      checkbox, label, textbox, listbox, scrollbar, tab, grid, sequencer-track, etc.
"""
import os
import re

RENAMES = [
    # --- EAB908: Pointer table for bitmap filename strings (instrument icons + transport) ---
    ('LABEL_EAB908', 'BmpFilenameTable_InstrIcons', 'Pointer table: instrument icon BMP filenames + transport controls'),

    # --- Bitmap filename strings: instrument category icons ---
    ('LABEL_EABD04', 'BmpStr_Sentinel',         'Empty string sentinel for BMP filename table'),
    ('LABEL_EABD06', 'BmpStr_MicIcon',          'Filename: 19mic.bmp'),
    ('LABEL_EABD10', 'BmpStr_MetroIcon',        'Filename: 18metro.bmp'),
    ('LABEL_EABD1C', 'BmpStr_GmSpecialIcon',    'Filename: 14gmsp.bmp'),
    ('LABEL_EABD28', 'BmpStr_LedSwOffIcon',     'Filename: ledswoff.bmp'),
    ('LABEL_EABD36', 'BmpStr_LedSwOnIcon',      'Filename: ledswon.bmp'),
    ('LABEL_EABD42', 'BmpStr_AccordionIcon',    'Filename: 13accod.bmp'),
    ('LABEL_EABD4E', 'BmpStr_DrawbarIcon',      'Filename: 12draw.bmp'),
    ('LABEL_EABD5A', 'BmpStr_SynthIcon',        'Filename: 10synth.bmp'),
    ('LABEL_EABD66', 'BmpStr_StringsIcon',      'Filename: 02string.bmp'),
    ('LABEL_EABD74', 'BmpStr_SaxIcon',          'Filename: 05sax.bmp'),
    ('LABEL_EABD7E', 'BmpStr_PianoIcon',        'Filename: 00piano.bmp'),
    ('LABEL_EABD8A', 'BmpStr_OrchIcon',         'Filename: 09orch.bmp'),
    ('LABEL_EABD96', 'BmpStr_OrganIcon',        'Filename: 08organ.bmp'),
    ('LABEL_EABDA2', 'BmpStr_MemBIcon',         'Filename: 17memb.bmp'),
    ('LABEL_EABDAE', 'BmpStr_MemAIcon',         'Filename: 16mema.bmp'),
    ('LABEL_EABDBA', 'BmpStr_MalletIcon',       'Filename: 06mallet.bmp'),
    ('LABEL_EABDC8', 'BmpStr_WorldIcon',        'Filename: 07world.bmp'),
    ('LABEL_EABDD4', 'BmpStr_GuitarIcon',       'Filename: 01guitar.bmp'),
    ('LABEL_EABDE2', 'BmpStr_FluteIcon',        'Filename: 04flute.bmp'),
    ('LABEL_EABDEE', 'BmpStr_DrumIcon',         'Filename: 15drum.bmp'),
    ('LABEL_EABDFA', 'BmpStr_BrassIcon',        'Filename: 03brass.bmp'),
    ('LABEL_EABE06', 'BmpStr_BassIcon',         'Filename: 11bass.bmp'),

    # --- Bitmap filename strings: transport/sequencer control icons ---
    ('LABEL_EABE12', 'BmpStr_NextIcon',         'Filename: next.bmp'),
    ('LABEL_EABE1C', 'BmpStr_BeforeIcon',       'Filename: before.bmp'),
    ('LABEL_EABE28', 'BmpStr_StartIcon',        'Filename: start.bmp'),
    ('LABEL_EABE32', 'BmpStr_PauseIcon',        'Filename: pause.bmp'),
    ('LABEL_EABE3C', 'BmpStr_BwdIcon',          'Filename: bwd.bmp'),
    ('LABEL_EABE44', 'BmpStr_FwdIcon',          'Filename: fwd.bmp'),
    ('LABEL_EABE4C', 'BmpStr_MixPointIcon',     'Filename: mixpoint.bmp'),
    ('LABEL_EABE5A', 'BmpStr_MixCtrIcon',       'Filename: mixctr.bmp'),
    ('LABEL_EABE66', 'BmpStr_SlMoveIcon',       'Filename: slmove.bmp'),
    ('LABEL_EABE72', 'BmpStr_SlideIcon',        'Filename: slide.bmp'),
    ('LABEL_EABE7C', 'BmpStr_TechnicsIcon',     'Filename: technics.bmp'),

    # --- EABE98: Widget property descriptor block: "func" widget ---
    # Structure: ptr_table -> [sentinel, "func"]
    ('LABEL_EABE98', 'WidgetPropTab_Func',          'Widget property pointer table: func widget'),
    ('LABEL_EABEA2', 'WidgetPropSentinel_Func',      'Sentinel (end of property list) for func widget'),
    ('LABEL_EABEA4', 'WidgetPropStr_FuncFunc',       'Property string: "func" (for func widget)'),

    # --- EABEAE: Widget property descriptor block: object/class base ---
    # Properties: propname, propdata, name, selfsize, allsize, parent, proc
    ('LABEL_EABEAE', 'WidgetPropSentinelHdr_Object', 'Sentinel header for object class property table'),
    ('LABEL_EABEB4', 'WidgetPropStr_ObjectSentinel', 'Empty string sentinel for object class'),
    ('LABEL_EABEB6', 'WidgetPropTab_Object',         'Widget property pointer table: object/class base'),
    ('LABEL_EABED6', 'WidgetPropSentinel_Object',    'Sentinel (end of property list) for object class'),
    ('LABEL_EABED8', 'WidgetPropStr_PropName',       'Property string: "propname"'),
    ('LABEL_EABEE2', 'WidgetPropStr_PropData',       'Property string: "propdata"'),
    ('LABEL_EABEEC', 'WidgetPropStr_ObjName',        'Property string: "name" (object name)'),
    ('LABEL_EABEF2', 'WidgetPropStr_SelfSize',       'Property string: "selfsize"'),
    ('LABEL_EABEFC', 'WidgetPropStr_AllSize',        'Property string: "allsize"'),
    ('LABEL_EABF04', 'WidgetPropStr_Parent',         'Property string: "parent"'),
    ('LABEL_EABF0C', 'WidgetPropStr_Proc',           'Property string: "proc"'),

    # --- EABF12: Widget property descriptor block: property-list descriptor ---
    # Properties: prop, size, count, proc
    ('LABEL_EABF12', 'WidgetPropTab_PropList',       'Widget property pointer table: property list descriptor'),
    ('LABEL_EABF26', 'WidgetPropSentinel_PropList',  'Sentinel (end of property list) for proplist'),
    ('LABEL_EABF28', 'WidgetPropStr_Prop',           'Property string: "prop"'),
    ('LABEL_EABF2E', 'WidgetPropStr_Size',           'Property string: "size"'),
    ('LABEL_EABF34', 'WidgetPropStr_Count',          'Property string: "count"'),
    ('LABEL_EABF3A', 'WidgetPropStr_PropListProc',   'Property string: "proc" (for proplist)'),

    # --- EABF40: Widget property descriptor block: named function/task descriptor ---
    # Properties: name, user, title, proc
    ('LABEL_EABF40', 'WidgetPropTab_Task',           'Widget property pointer table: named task/function descriptor'),
    ('LABEL_EABF54', 'WidgetPropStr_TaskSentinel',   'Empty string sentinel for task descriptor'),
    ('LABEL_EABF56', 'WidgetPropStr_TaskName',       'Property string: "name" (task name)'),
    ('LABEL_EABF5C', 'WidgetPropStr_TaskUser',       'Property string: "user"'),
    ('LABEL_EABF62', 'WidgetPropStr_TaskTitle',      'Property string: "title"'),
    ('LABEL_EABF68', 'WidgetPropStr_TaskProc',       'Property string: "proc" (task)'),

    # --- EABF6E: Widget property descriptor block: linked-list node descriptor ---
    # Properties: next, prev, "now", name, user, "top", proc
    ('LABEL_EABF6E', 'WidgetPropTab_ListNode',       'Widget property pointer table: linked-list node'),
    ('LABEL_EABF8E', 'WidgetPropSentinel_ListNode',  'Sentinel (end of property list) for list node'),
    ('LABEL_EABF90', 'WidgetPropStr_Next',           'Property string: "next"'),
    ('LABEL_EABF96', 'WidgetPropStr_Prev',           'Property string: "prev"'),
    ('LABEL_EABF9C', 'WidgetPropStr_Now',            'Property string: "now" (current node)'),
    ('LABEL_EABFA0', 'WidgetPropStr_NodeName',       'Property string: "name" (node name)'),
    ('LABEL_EABFA6', 'WidgetPropStr_NodeUser',       'Property string: "user" (node user data)'),
    ('LABEL_EABFAC', 'WidgetPropStr_Top',            'Property string: "top" (list top)'),
    ('LABEL_EABFB0', 'WidgetPropStr_NodeProc',       'Property string: "proc" (node)'),

    # --- EABFBE: Single-property descriptor blocks: "data" property ---
    # These are minimal descriptors with just one property each
    ('LABEL_EABFBE', 'WidgetPropSentinel_Data0',     'Sentinel for single-data property block 0'),
    ('LABEL_EABFC0', 'WidgetPropStr_Data0',          'Property string: "data" (block 0)'),
    ('LABEL_EABFCE', 'WidgetPropSentinel_Data1',     'Sentinel for single-data property block 1'),
    ('LABEL_EABFD0', 'WidgetPropStr_Data1',          'Property string: "data" (block 1)'),
    ('LABEL_EABFDE', 'WidgetPropSentinel_Data2',     'Sentinel for single-data property block 2'),
    ('LABEL_EABFE0', 'WidgetPropStr_Data2',          'Property string: "data" (block 2)'),
    ('LABEL_EABFEE', 'WidgetPropSentinel_Data3',     'Sentinel for single-data property block 3'),
    ('LABEL_EABFF0', 'WidgetPropStr_Data3',          'Property string: "data" (block 3)'),

    # --- EAC000-EAC030: Single-property "name" descriptor blocks ---
    ('LABEL_EABFFE', 'WidgetPropSentinel_Name0',     'Sentinel for single-name property block 0'),
    ('LABEL_EAC000', 'WidgetPropStr_Name0',          'Property string: "name" (block 0)'),
    ('LABEL_EAC00E', 'WidgetPropSentinel_Name1',     'Sentinel for single-name property block 1'),
    ('LABEL_EAC010', 'WidgetPropStr_Name1',          'Property string: "name" (block 1)'),
    ('LABEL_EAC01E', 'WidgetPropSentinel_Data4',     'Sentinel for single-data property block 4'),
    ('LABEL_EAC020', 'WidgetPropStr_Data4',          'Property string: "data" (block 4)'),
    ('LABEL_EAC02E', 'WidgetPropSentinel_Name2',     'Sentinel for single-name property block 2'),
    ('LABEL_EAC030', 'WidgetPropStr_Name2',          'Property string: "name" (block 2)'),

    # --- EAC036: Widget property descriptor block: widget base (visual element) ---
    # Properties: rect, flag, prev, next, sub, super, class
    ('LABEL_EAC036', 'WidgetPropTab_WidgetBase',     'Widget property pointer table: visual widget base'),
    ('LABEL_EAC056', 'WidgetPropSentinel_WidgetBase','Sentinel for widget base property list'),
    ('LABEL_EAC058', 'WidgetPropStr_Rect',           'Property string: "rect" (bounding rect)'),
    ('LABEL_EAC05E', 'WidgetPropStr_Flag',           'Property string: "flag"'),
    ('LABEL_EAC064', 'WidgetPropStr_WidgetPrev',     'Property string: "prev" (widget chain prev)'),
    ('LABEL_EAC06A', 'WidgetPropStr_WidgetNext',     'Property string: "next" (widget chain next)'),
    ('LABEL_EAC070', 'WidgetPropStr_Sub',            'Property string: "sub" (sub-widget)'),
    ('LABEL_EAC074', 'WidgetPropStr_Super',          'Property string: "super" (parent widget)'),
    ('LABEL_EAC07A', 'WidgetPropStr_Class',          'Property string: "class"'),

    # --- EAC080: Widget property descriptor block: color/border scheme ---
    # Properties: index, border, color
    ('LABEL_EAC080', 'WidgetPropTab_ColorScheme',    'Widget property pointer table: color/border scheme'),
    ('LABEL_EAC090', 'WidgetPropStr_ColorSentinel',  'Empty string sentinel for color scheme'),
    ('LABEL_EAC092', 'WidgetPropStr_ColorIndex',     'Property string: "index" (color scheme index)'),
    ('LABEL_EAC098', 'WidgetPropStr_Border',         'Property string: "border"'),
    ('LABEL_EAC0A0', 'WidgetPropStr_Color',          'Property string: "color"'),

    # --- EAC0EC: Widget property descriptor block: spinbox/dial control ---
    # Properties: selected, dial, editsw, length, align, fontcolor, font, caption
    ('LABEL_EAC0EC', 'WidgetPropStr_SpinSentinel',   'Empty string sentinel for spinbox/dial'),
    ('LABEL_EAC0EE', 'WidgetPropTab_Spinbox',        'Widget property pointer table: spinbox/dial control'),
    ('LABEL_EAC112', 'WidgetPropSentinel_Spinbox',   'Sentinel (end of property list) for spinbox'),
    ('LABEL_EAC114', 'WidgetPropStr_Selected',       'Property string: "selected"'),
    ('LABEL_EAC11E', 'WidgetPropStr_Dial',           'Property string: "dial"'),
    ('LABEL_EAC124', 'WidgetPropStr_EditSw',         'Property string: "editsw"'),
    ('LABEL_EAC12C', 'WidgetPropStr_Length',         'Property string: "length"'),
    ('LABEL_EAC134', 'WidgetPropStr_Align',          'Property string: "align"'),
    ('LABEL_EAC13A', 'WidgetPropStr_FontColor',      'Property string: "fontcolor"'),
    ('LABEL_EAC144', 'WidgetPropStr_Font',           'Property string: "font"'),
    ('LABEL_EAC14A', 'WidgetPropStr_Caption',        'Property string: "caption"'),

    # --- EAC15A: Widget property descriptor block: figures/numeric display ---
    # Properties: figures (and sub-descriptors)
    ('LABEL_EAC15A', 'WidgetPropSentinel_Figures',   'Sentinel for figures/numeric display widget'),
    ('LABEL_EAC15C', 'WidgetPropStr_Figures',        'Property string: "figures"'),
    ('LABEL_EAC16C', 'WidgetPropSentinel_FigFunc',   'Sentinel for figures-func sub-descriptor'),
    ('LABEL_EAC16E', 'WidgetPropStr_FigFunc',        'Property string: "func" (for figures widget)'),
    ('LABEL_EAC17C', 'WidgetPropSentinel_OnOff',     'Sentinel for on/off display sub-descriptor'),
    ('LABEL_EAC17E', 'WidgetPropStr_OnOff',          'Property string: "onoff" (on/off display)'),

    # --- EAC188: Widget property descriptor block: range/step control (spinbox range) ---
    # Properties: smallstep, largestep, "min", "max", figures, "num"
    ('LABEL_EAC188', 'WidgetPropTab_RangeCtrl',      'Widget property pointer table: range/step control'),
    ('LABEL_EAC1A0', 'WidgetPropStr_RangeSentinel',  'Empty string sentinel for range control'),
    ('LABEL_EAC1A2', 'WidgetPropStr_SmallStep',      'Property string: "smallstep"'),
    ('LABEL_EAC1AC', 'WidgetPropStr_LargeStep',      'Property string: "largestep"'),
    ('LABEL_EAC1B6', 'WidgetPropStr_Min',            'Property string: "min" (range minimum)'),

    # EAC1BA and EAC1BE: mid-block pointer targets in the range control table
    # They point into the raw byte data at EAC1B6 (property strings "min", "max", "figures", "num")
    ('LABEL_EAC1BA', 'WidgetPropStr_Max',            'Property string: "max" (range maximum, mid-block target)'),
    ('LABEL_EAC1BE', 'WidgetPropStr_RangeFigures',   'Property string: "figures" (range figures, mid-block target)'),

    # --- EAC1F0: Widget property descriptor block: data/func pair ---
    ('LABEL_EAC1F0', 'WidgetPropStr_DataFuncSentinel','Empty string sentinel for data/func pair'),
    ('LABEL_EAC1F2', 'WidgetPropStr_DataProp',       'Property string: "data" (data/func pair)'),
    ('LABEL_EAC1F8', 'WidgetPropStr_FuncProp',       'Property string: "func" (data/func pair)'),

    # --- EAC1FE: Widget property descriptor block: text/label widget ---
    # Properties: selected, editsw, align, fontcolor, font
    ('LABEL_EAC1FE', 'WidgetPropTab_TextLabel',      'Widget property pointer table: text/label widget'),
    ('LABEL_EAC216', 'WidgetPropSentinel_TextLabel',  'Sentinel for text/label property list'),
    ('LABEL_EAC218', 'WidgetPropStr_LblSelected',    'Property string: "selected" (label)'),
    ('LABEL_EAC222', 'WidgetPropStr_LblEditSw',      'Property string: "editsw" (label)'),
    ('LABEL_EAC22A', 'WidgetPropStr_LblAlign',       'Property string: "align" (label)'),
    ('LABEL_EAC230', 'WidgetPropStr_LblFontColor',   'Property string: "fontcolor" (label)'),
    ('LABEL_EAC23A', 'WidgetPropStr_LblFont',        'Property string: "font" (label)'),

    # --- EAC240: Widget property descriptor block: icon/title pair ---
    # Properties: icon, title, "str"
    ('LABEL_EAC240', 'WidgetPropTab_IconTitle',      'Widget property pointer table: icon/title widget'),
    ('LABEL_EAC250', 'WidgetPropStr_IconTitleSentinel','Empty string sentinel for icon/title widget'),
    ('LABEL_EAC252', 'WidgetPropStr_Icon',           'Property string: "icon"'),
    ('LABEL_EAC258', 'WidgetPropStr_Title',          'Property string: "title"'),
    ('LABEL_EAC25E', 'WidgetPropStr_Str',            'Property string: "str" (string)'),

    # --- EAC276: Widget property descriptor block: styled text edit widget ---
    # Properties: editsw, align, "fontcolor", font, "style"
    ('LABEL_EAC276', 'WidgetPropSentinel_StyledText', 'Sentinel for styled text edit widget'),
    ('LABEL_EAC278', 'WidgetPropStr_StEditSw',       'Property string: "editsw" (styled text)'),
    ('LABEL_EAC280', 'WidgetPropStr_StAlign',        'Property string: "align" (styled text)'),
    ('LABEL_EAC286', 'WidgetPropStr_StFontColor',    'Property string: "fontcolor" (styled text, encoded)'),
    ('LABEL_EAC29E', 'WidgetPropStr_Style',          'Property string: "style"'),
    ('LABEL_EAC2B2', 'WidgetPropStr_StyleFunc',      'Property string: "func" (style handler)'),

    # --- EAC2C8: Widget property descriptor block: editsw2/style pair ---
    ('LABEL_EAC2C8', 'WidgetPropStr_EditSw2Sentinel','Empty string sentinel for editsw2/style block'),
    ('LABEL_EAC2CA', 'WidgetPropStr_EditSw2',        'Property string: "editsw2"'),
    ('LABEL_EAC2DA', 'WidgetPropSentinel_Style2',    'Sentinel for style2 block'),
    ('LABEL_EAC2DC', 'WidgetPropStr_Style2',         'Property string: "style" (style2 block)'),

    # --- EAC2EE: Widget property descriptor block: styled func widget ---
    ('LABEL_EAC2EE', 'WidgetPropSentinel_StyleFunc2','Sentinel for styled func widget'),
    ('LABEL_EAC2F0', 'WidgetPropStr_StyleFunc2',     'Property string: "func" (styled func)'),
    ('LABEL_EAC2F6', 'WidgetPropStr_StyleStr2',      'Property string: "style" (style string encoded, block 2)'),

    # --- EAC304: Single-property sentinel blocks ---
    ('LABEL_EAC304', 'WidgetPropSentinel_Style3',    'Sentinel for style block 3'),
    ('LABEL_EAC306', 'WidgetPropStr_Page',           'Property string: "page"'),

    # --- EAC318: Widget property descriptor block: paged control ---
    # Properties: pagemax, pagemin
    ('LABEL_EAC318', 'WidgetPropStr_PagedSentinel',  'Empty string sentinel for paged control'),
    ('LABEL_EAC31A', 'WidgetPropStr_PageMax',        'Property string: "pagemax"'),
    ('LABEL_EAC322', 'WidgetPropStr_PageMin',        'Property string: "pagemin"'),

    # --- EAC32A: Widget property descriptor block: toggle/switch widget ---
    # Properties: editsw, onoff, stroff, stron, font
    ('LABEL_EAC32A', 'WidgetPropTab_ToggleSwitch',   'Widget property pointer table: toggle/switch widget'),
    ('LABEL_EAC342', 'WidgetPropSentinel_Toggle',    'Sentinel for toggle/switch property list'),
    ('LABEL_EAC344', 'WidgetPropStr_ToggleEditSw',   'Property string: "editsw" (toggle)'),
    ('LABEL_EAC34C', 'WidgetPropStr_OnOff2',         'Property string: "onoff" (toggle on/off state)'),
    ('LABEL_EAC352', 'WidgetPropStr_StrOff',         'Property string: "stroff" (off-state label)'),
    ('LABEL_EAC35A', 'WidgetPropStr_StrOn',          'Property string: "stron" (on-state label)'),
    ('LABEL_EAC360', 'WidgetPropStr_ToggleFont',     'Property string: "font" (toggle)'),

    # --- EAC36A: Widget property descriptor block: window/page navigator ---
    # Properties: window, page
    ('LABEL_EAC36A', 'WidgetPropSentinel_WinPage',   'Sentinel for window/page navigator'),
    ('LABEL_EAC378', 'WidgetPropStr_WinPageSentinel','Empty string sentinel for window/page prop'),
    ('LABEL_EAC37A', 'WidgetPropStr_Window',         'Property string: "window"'),
    ('LABEL_EAC382', 'WidgetPropStr_PageProp',       'Property string: "page" (page property)'),

    # --- EAC390: Misc single-property sentinel blocks ---
    ('LABEL_EAC390', 'WidgetPropStr_FuncSentinel2',  'Empty string sentinel for func block 2'),
    ('LABEL_EAC392', 'WidgetPropStr_Func2',          'Property string: "func" (block 2)'),
    ('LABEL_EAC3A0', 'WidgetPropStr_PartSentinel',   'Empty string sentinel for part property'),
    ('LABEL_EAC3A2', 'WidgetPropStr_Part',           'Property string: "part" (channel/part)'),

    # --- EAC3A8: Widget property descriptor block: font/color display ---
    # Properties: fontcolor, font, "str"
    ('LABEL_EAC3A8', 'WidgetPropTab_FontColor',      'Widget property pointer table: font/color display'),
    ('LABEL_EAC3B8', 'WidgetPropStr_FcSentinel',     'Empty string sentinel for font/color display'),
    ('LABEL_EAC3BA', 'WidgetPropStr_FcFontColor',    'Property string: "fontcolor" (font/color)'),
    ('LABEL_EAC3C4', 'WidgetPropStr_FcFont',         'Property string: "font" (font/color)'),
    ('LABEL_EAC3CA', 'WidgetPropStr_FcStr',          'Property string: "str" (font/color)'),

    # --- EAC3D6: Widget property descriptor: bmp/icon sub-blocks ---
    ('LABEL_EAC3D6', 'WidgetPropSentinel_Bmp',       'Sentinel for bmp property sub-block'),
    ('LABEL_EAC3D8', 'WidgetPropStr_Bmp',            'Property string: "bmp" (bitmap reference)'),
    ('LABEL_EAC3E4', 'WidgetPropSentinel_IconProp',  'Sentinel for icon property sub-block'),
    ('LABEL_EAC3E6', 'WidgetPropStr_IconProp',       'Property string: "icon" (icon sub-block)'),

    # --- EAC3F8: Widget property descriptor block: line/drawing widget ---
    # Properties: linemode, color
    ('LABEL_EAC3F8', 'WidgetPropStr_LineSentinel',   'Empty string sentinel for line/drawing widget'),
    ('LABEL_EAC3FA', 'WidgetPropStr_LineMode',       'Property string: "linemode"'),
    ('LABEL_EAC404', 'WidgetPropStr_LineColor',      'Property string: "color" (line)'),

    # --- EAC41A: Widget property descriptor block: border/frame widget ---
    # Properties: color, width, frame
    ('LABEL_EAC41A', 'WidgetPropSentinel_Frame',     'Sentinel for border/frame widget'),
    ('LABEL_EAC41C', 'WidgetPropStr_FrameColor',     'Property string: "color" (frame)'),
    ('LABEL_EAC422', 'WidgetPropStr_FrameWidth',     'Property string: "width" (frame)'),
    ('LABEL_EAC428', 'WidgetPropStr_Frame',          'Property string: "frame"'),

    # --- EAC43E: Widget property descriptor block: indexed/table widget ---
    # Properties: index, "func", "border", "color"
    ('LABEL_EAC43E', 'WidgetPropSentinel_IndexedTab','Sentinel for indexed/table widget'),
    ('LABEL_EAC440', 'WidgetPropStr_Index',          'Property string: "index"'),
    ('LABEL_EAC446', 'WidgetPropStr_FuncEncoded',    'Property string: "func" (encoded, indexed widget)'),
    ('LABEL_EAC460', 'WidgetPropStr_IdxSentinel',    'Empty string sentinel for indexed color props'),
    ('LABEL_EAC462', 'WidgetPropStr_IdxBorder',      'Property string: "border" (indexed widget)'),
    ('LABEL_EAC46A', 'WidgetPropStr_IdxColor',       'Property string: "color" (indexed widget)'),

    # --- EAC474: Widget property descriptor block: window/exit widget ---
    # Properties: window, exit
    ('LABEL_EAC474', 'WidgetPropSentinel_WinExit',   'Sentinel for window/exit widget'),
    ('LABEL_EAC482', 'WidgetPropSentinel_WinExit2',  'Sentinel 2 for window/exit widget'),
    ('LABEL_EAC484', 'WidgetPropStr_WinExit',        'Property string: "window" (exit widget)'),
    ('LABEL_EAC48C', 'WidgetPropStr_Exit',           'Property string: "exit"'),

    # --- EAC49E: Widget property descriptor block: icon-title dialog ---
    # Properties: icon, "title", child, parent, modal
    ('LABEL_EAC49E', 'WidgetPropSentinel_Dialog',    'Sentinel for icon-title dialog widget'),
    ('LABEL_EAC4A0', 'WidgetPropStr_DlgIcon',        'Property string: "icon" (dialog)'),
    ('LABEL_EAC4A6', 'WidgetPropStr_DlgTitle',       'Property string: "title" (dialog, encoded)'),
    ('LABEL_EAC4BC', 'WidgetPropStr_DlgSentinel',    'Empty string sentinel for dialog child/parent'),
    ('LABEL_EAC4BE', 'WidgetPropStr_Child',          'Property string: "child"'),
    ('LABEL_EAC4C4', 'WidgetPropStr_DlgParent',      'Property string: "parent" (dialog)'),
    ('LABEL_EAC4CC', 'WidgetPropStr_Modal',          'Property string: "modal"'),

    # --- EAC4D2: Widget property descriptor block: text/multiline widget ---
    # Properties: lines, alignment, fontcolor, "font", text
    ('LABEL_EAC4D2', 'WidgetPropTab_MultilineText',  'Widget property pointer table: multiline text widget'),
    ('LABEL_EAC4EA', 'WidgetPropSentinel_Multiline', 'Sentinel for multiline text property list'),
    ('LABEL_EAC4EC', 'WidgetPropStr_Lines',          'Property string: "lines"'),
    ('LABEL_EAC4F2', 'WidgetPropStr_Alignment',      'Property string: "alignment"'),
    ('LABEL_EAC4FC', 'WidgetPropStr_MlFontColor',    'Property string: "fontcolor" (multiline)'),
    ('LABEL_EAC506', 'WidgetPropStr_MlFontEncoded',  'Property string: "font" (multiline, encoded)'),
    ('LABEL_EAC50C', 'WidgetPropStr_Text',           'Property string: "text"'),

    # --- EAC526: Widget property descriptor block: rich text widget ---
    # Properties: alignment, fontcolor, font, "str"
    ('LABEL_EAC526', 'WidgetPropSentinel_RichText',  'Sentinel for rich text widget'),
    ('LABEL_EAC528', 'WidgetPropStr_RtAlignment',    'Property string: "alignment" (rich text)'),
    ('LABEL_EAC532', 'WidgetPropStr_RtFontColor',    'Property string: "fontcolor" (rich text)'),
    ('LABEL_EAC53C', 'WidgetPropStr_RtFont',         'Property string: "font" (rich text)'),
    ('LABEL_EAC542', 'WidgetPropStr_RtStr',          'Property string: "str" (rich text, encoded)'),

    # --- EAC55E: Widget property descriptor block: named user window ---
    # Properties: name, user, title, proc, mode
    ('LABEL_EAC55E', 'WidgetPropSentinel_UserWindow','Sentinel for named user window'),
    ('LABEL_EAC560', 'WidgetPropStr_UwName',         'Property string: "name" (user window)'),
    ('LABEL_EAC566', 'WidgetPropStr_UwUser',         'Property string: "user" (user window)'),
    ('LABEL_EAC56C', 'WidgetPropStr_UwTitle',        'Property string: "title" (user window)'),
    ('LABEL_EAC572', 'WidgetPropStr_UwProc',         'Property string: "proc" (user window)'),
    ('LABEL_EAC578', 'WidgetPropStr_Mode',           'Property string: "mode"'),

    # --- EAC596: Widget property descriptor block: named user item ---
    # Properties: name, user, "top", proc, "title"
    ('LABEL_EAC596', 'WidgetPropSentinel_UserItem',  'Sentinel for named user item'),
    ('LABEL_EAC598', 'WidgetPropStr_UiName',         'Property string: "name" (user item)'),
    ('LABEL_EAC59E', 'WidgetPropStr_UiUser',         'Property string: "user" (user item)'),
    ('LABEL_EAC5A4', 'WidgetPropStr_UiTop',          'Property string: "top" (user item)'),
    ('LABEL_EAC5A8', 'WidgetPropStr_UiProc',         'Property string: "proc" (user item)'),
    ('LABEL_EAC5AE', 'WidgetPropStr_UiTitle',        'Property string: "title" (user item, encoded)'),

    # --- EAC5BE: Widget property descriptor block: on/off with editsw ---
    ('LABEL_EAC5BE', 'WidgetPropSentinel_EditOnOff', 'Sentinel for editsw/onoff block'),
    ('LABEL_EAC5CC', 'WidgetPropStr_EoSentinel',     'Empty string sentinel for editsw/onoff'),
    ('LABEL_EAC5CE', 'WidgetPropStr_EoEditSw',       'Property string: "editsw" (edit on/off)'),
    ('LABEL_EAC5D6', 'WidgetPropStr_EoPart',         'Property string: "part" (edit on/off, encoded)'),

    # --- EAC5E8: Widget property descriptor block: icon with str ---
    ('LABEL_EAC5E8', 'WidgetPropStr_IcStrSentinel',  'Empty string sentinel for icon/str block'),
    ('LABEL_EAC5EA', 'WidgetPropStr_IcStrIcon',      'Property string: "icon" (icon/str block)'),
    ('LABEL_EAC5F0', 'WidgetPropStr_IcStr',          'Property string: "str" (icon/str, encoded)'),

    # --- EAC600: Widget property descriptor block: style/str blocks ---
    ('LABEL_EAC600', 'WidgetPropStr_StrSentinel',    'Empty string sentinel for str block'),
    ('LABEL_EAC602', 'WidgetPropStr_StrBlock',       'Property string: "str" (str block)'),
    ('LABEL_EAC606', 'WidgetPropStr_StyleBlock',     'Property string: "style" (style block, encoded)'),
    ('LABEL_EAC618', 'WidgetPropStr_StyleSentinel',  'Empty string sentinel for style block'),
    ('LABEL_EAC61A', 'WidgetPropStr_StyleStr',       'Property string: "str" (style block)'),  # intentional duplicate name in different block
    ('LABEL_EAC61E', 'WidgetPropStr_StyleBlock2',    'Property string: "style" (style block 2, encoded)'),

    # --- EAC634: Widget property descriptor block: icon/mode pair ---
    ('LABEL_EAC634', 'WidgetPropStr_ImSentinel',     'Empty string sentinel for icon/mode block'),
    ('LABEL_EAC636', 'WidgetPropStr_ImIcon',         'Property string: "icon" (icon/mode block)'),
    ('LABEL_EAC63C', 'WidgetPropStr_ImMode',         'Property string: "mode" (icon/mode block)'),
    ('LABEL_EAC642', 'WidgetPropStr_ImStr',          'Property string: "str" (icon/mode, encoded)'),

    # --- EAC656: Widget property descriptor block: icon/screen widget ---
    # Properties: icon, screen
    ('LABEL_EAC656', 'WidgetPropSentinel_IconScreen','Sentinel for icon/screen widget'),
    ('LABEL_EAC658', 'WidgetPropStr_IsIcon',         'Property string: "icon" (icon/screen)'),
    ('LABEL_EAC65E', 'WidgetPropStr_Screen',         'Property string: "screen"'),
    ('LABEL_EAC666', 'WidgetPropStr_IsStr',          'Property string: "str" (icon/screen, encoded)'),

    # --- EAC67A: Widget property descriptor block: icon/window widget ---
    ('LABEL_EAC67A', 'WidgetPropSentinel_IconWin',   'Sentinel for icon/window widget'),
    ('LABEL_EAC67C', 'WidgetPropStr_IwIcon',         'Property string: "icon" (icon/window)'),
    ('LABEL_EAC682', 'WidgetPropStr_IwWindow',       'Property string: "window" (icon/window)'),
    ('LABEL_EAC68A', 'WidgetPropStr_IwStr',          'Property string: "str" (icon/window, encoded)'),

    # --- EAC69A: Widget property descriptor block: data/func callback widget ---
    ('LABEL_EAC69A', 'WidgetPropSentinel_DataFunc',  'Sentinel for data/func callback widget'),
    ('LABEL_EAC69C', 'WidgetPropStr_DfData',         'Property string: "data" (data/func callback)'),
    ('LABEL_EAC6A2', 'WidgetPropStr_DfFunc',         'Property string: "func" (data/func callback)'),

    # --- EAC6B0: Misc single-property func/editsw2 blocks ---
    ('LABEL_EAC6B0', 'WidgetPropStr_FuncSentinel3',  'Empty string sentinel for func block 3'),
    ('LABEL_EAC6B2', 'WidgetPropStr_Func3',          'Property string: "func" (block 3)'),
    ('LABEL_EAC6C0', 'WidgetPropStr_EditSw2Sentinel2','Empty string sentinel for editsw2 block 2'),
    ('LABEL_EAC6C2', 'WidgetPropStr_EditSw2b',       'Property string: "editsw2" (block 2)'),

    # --- EAC6CE: Widget property descriptor block: mode widget ---
    ('LABEL_EAC6CE', 'WidgetPropSentinel_Mode',      'Sentinel for mode widget'),
    ('LABEL_EAC6D4', 'WidgetPropSentinel_Mode2',     'Sentinel 2 for mode widget'),
    ('LABEL_EAC6DE', 'WidgetPropSentinel_Mode3',     'Sentinel 3 for mode widget'),
    ('LABEL_EAC6E0', 'WidgetPropStr_ModeProp',       'Property string: "mode" (mode widget)'),

    # --- EAC6EE: Widget property descriptor block: screen/window navigator ---
    ('LABEL_EAC6EE', 'WidgetPropSentinel_ScreenWin', 'Sentinel for screen/window navigator'),
    ('LABEL_EAC6F0', 'WidgetPropStr_ScreenProp',     'Property string: "screen" (screen navigator)'),
    ('LABEL_EAC700', 'WidgetPropStr_WinSentinel',    'Empty string sentinel for window prop'),
    ('LABEL_EAC702', 'WidgetPropStr_WinProp',        'Property string: "window" (screen navigator)'),

    # --- EAC70E: Widget property descriptor block: cursor widget ---
    ('LABEL_EAC70E', 'WidgetPropSentinel_Cursor',    'Sentinel for cursor widget'),
    ('LABEL_EAC718', 'WidgetPropStr_CursorSentinel', 'Empty string sentinel for cursor widget'),
    ('LABEL_EAC71A', 'WidgetPropStr_Cursor',         'Property string: "cursor"'),

    # --- EAC72A: Widget property descriptor block: func widget ---
    ('LABEL_EAC72A', 'WidgetPropSentinel_Func3',     'Sentinel for func block 3'),
    ('LABEL_EAC72C', 'WidgetPropStr_Func3Prop',      'Property string: "func" (block 3 prop)'),

    # --- EAC73E: Widget property descriptor block: tag/index pair ---
    ('LABEL_EAC73E', 'WidgetPropSentinel_TagIndex',  'Sentinel for tag/index widget'),
    ('LABEL_EAC740', 'WidgetPropStr_Tag',            'Property string: "tag"'),
    ('LABEL_EAC744', 'WidgetPropStr_TagIndex',       'Property string: "index" (tag)'),

    # --- EAC756: Widget property descriptor block: data/func for list item ---
    ('LABEL_EAC756', 'WidgetPropSentinel_ListData',  'Sentinel for list item data widget'),
    ('LABEL_EAC758', 'WidgetPropStr_ListData',       'Property string: "data" (list item)'),
    ('LABEL_EAC75E', 'WidgetPropStr_ListFunc',       'Property string: "func" (list item, encoded)'),

    # --- EAC768: Widget property descriptor block: tab/column widget ---
    # Properties: "tag", selected, editsw, align, fontcolor, font
    ('LABEL_EAC768', 'WidgetPropTab_TabColumn',      'Widget property pointer table: tab/column widget'),
    ('LABEL_EAC780', 'WidgetPropStr_TabSentinel',    'Empty string sentinel for tab/column widget'),
    ('LABEL_EAC782', 'WidgetPropStr_TabTag',         'Property string: "tag" (tab/column)'),
    ('LABEL_EAC786', 'WidgetPropStr_TabSelected',    'Property string: "selected" (tab)'),
    ('LABEL_EAC790', 'WidgetPropStr_TabEditSw',      'Property string: "editsw" (tab)'),
    ('LABEL_EAC798', 'WidgetPropStr_TabAlign',       'Property string: "align" (tab)'),
    ('LABEL_EAC79E', 'WidgetPropStr_TabFontColor',   'Property string: "fontcolor" (tab)'),
    ('LABEL_EAC7A8', 'WidgetPropStr_TabFont',        'Property string: "font" (tab)'),

    # --- EAC7B6: Widget property descriptor block: str/func for tab ---
    ('LABEL_EAC7B6', 'WidgetPropSentinel_TabStr',    'Sentinel for tab str/func sub-block'),
    ('LABEL_EAC7B8', 'WidgetPropStr_TabStr',         'Property string: "str" (tab, encoded)'),
    ('LABEL_EAC7C4', 'WidgetPropSentinel_TabFunc',   'Sentinel for tab func sub-block'),
    ('LABEL_EAC7C6', 'WidgetPropStr_TabFunc',        'Property string: "func" (tab, encoded)'),

    # --- EAC7D0: Widget property descriptor block: row/column grid widget ---
    # Properties: selected, "row", align, fontcolor, font
    ('LABEL_EAC7D0', 'WidgetPropTab_GridCell',       'Widget property pointer table: grid cell widget'),
    ('LABEL_EAC7E4', 'WidgetPropStr_GridSentinel',   'Empty string sentinel for grid cell'),
    ('LABEL_EAC7E6', 'WidgetPropStr_GridSelected',   'Property string: "selected" (grid)'),
    ('LABEL_EAC7F0', 'WidgetPropStr_GridRow',        'Property string: "row" (grid)'),
    ('LABEL_EAC7F4', 'WidgetPropStr_GridAlign',      'Property string: "align" (grid)'),
    ('LABEL_EAC7FA', 'WidgetPropStr_GridFontColor',  'Property string: "fontcolor" (grid)'),
    ('LABEL_EAC804', 'WidgetPropStr_GridFont',       'Property string: "font" (grid)'),

    # --- EAC83A: Widget property descriptor block: grid header/metrics ---
    # Properties: crow, prow, pcol, selcol, selrow, vertline, "col", "row"
    ('LABEL_EAC83A', 'WidgetPropSentinel_GridMeta',  'Sentinel for grid header/metrics'),
    ('LABEL_EAC83C', 'WidgetPropStr_CRow',           'Property string: "crow" (current row)'),
    ('LABEL_EAC842', 'WidgetPropStr_PRow',           'Property string: "prow" (previous row)'),
    ('LABEL_EAC848', 'WidgetPropStr_PCol',           'Property string: "pcol" (previous col)'),
    ('LABEL_EAC84E', 'WidgetPropStr_SelCol',         'Property string: "selcol" (selected col)'),
    ('LABEL_EAC856', 'WidgetPropStr_SelRow',         'Property string: "selrow" (selected row)'),
    ('LABEL_EAC85E', 'WidgetPropStr_VertLine',       'Property string: "vertline"'),
    ('LABEL_EAC86C', 'WidgetPropStr_GridRowStr',     'Property string: "row" (grid col, encoded)'),
    ('LABEL_EAC870', 'WidgetPropStr_GridColAlign',   'Property string: "align" (grid col)'),
    ('LABEL_EAC876', 'WidgetPropStr_GridColFont',    'Property string: "fontcolor"/"font" (grid col, encoded)'),
    ('LABEL_EAC892', 'WidgetPropStr_GridDial',       'Property string: "dial" (grid)'),

    # --- EAC8A0: Widget property descriptor block: grid control (fixedrow/fixedcol) ---
    ('LABEL_EAC8A0', 'WidgetPropTab_GridCtrl',       'Widget property pointer table: grid control (fixed rows/cols)'),
    ('LABEL_EAC8B0', 'WidgetPropStr_GcSentinel',     'Empty string sentinel for grid control'),
    ('LABEL_EAC8B2', 'WidgetPropStr_GcFunc',         'Property string: "func" (grid control)'),
    ('LABEL_EAC8B8', 'WidgetPropStr_FixedRow',       'Property string: "fixedrow"'),
    ('LABEL_EAC8C2', 'WidgetPropStr_FixedCol',       'Property string: "fixedcol"'),

    # --- EAC8D4: Widget property descriptor block: page sub-block ---
    ('LABEL_EAC8D4', 'WidgetPropSentinel_PageSub',   'Sentinel for page sub-block'),
    ('LABEL_EAC8D6', 'WidgetPropStr_PageSub',        'Property string: "page" (sub-block, encoded)'),

    # --- EAC8E0: Widget property descriptor block: sequencer track widget ---
    # Properties: recplay, part, onoff, "track"
    ('LABEL_EAC8E0', 'WidgetPropTab_SeqTrack',       'Widget property pointer table: sequencer track widget'),
    ('LABEL_EAC8F0', 'WidgetPropStr_SeqSentinel',    'Empty string sentinel for sequencer track'),
    ('LABEL_EAC8F2', 'WidgetPropStr_RecPlay',        'Property string: "recplay" (rec/play state)'),
    ('LABEL_EAC8FA', 'WidgetPropStr_SeqPart',        'Property string: "part" (sequencer part)'),
    ('LABEL_EAC900', 'WidgetPropStr_SeqOnOff',       'Property string: "onoff" (sequencer on/off)'),
    ('LABEL_EAC906', 'WidgetPropStr_SeqTrack',       'Property string: "track" (sequencer track, encoded)'),

    # --- EAC916: Widget property descriptor block: address/time sub-blocks ---
    ('LABEL_EAC916', 'WidgetPropSentinel_Addr',      'Sentinel for address/time sub-block'),
    ('LABEL_EAC91C', 'WidgetPropSentinel_Addr2',     'Sentinel 2 for address sub-block'),
    ('LABEL_EAC922', 'WidgetPropSentinel_Addr3',     'Sentinel 3 for address sub-block'),
    ('LABEL_EAC92C', 'WidgetPropSentinel_Addr4',     'Sentinel 4 for address sub-block'),
    ('LABEL_EAC92E', 'WidgetPropStr_Adr',            'Property string: "adr" (address, encoded)'),
    ('LABEL_EAC93A', 'WidgetPropSentinel_Time',      'Sentinel for time sub-block'),
    ('LABEL_EAC93C', 'WidgetPropStr_Time',           'Property string: "time"'),
    ('LABEL_EAC946', 'WidgetPropSentinel_Time2',     'Sentinel 2 for time sub-block'),
    ('LABEL_EAC94C', 'WidgetPropSentinel_Time3',     'Sentinel 3 for time sub-block'),
    ('LABEL_EAC952', 'WidgetPropSentinel_Time4',     'Sentinel 4 for time sub-block'),

    # --- EAC95E: Widget property descriptor block: generic func/lines text ---
    ('LABEL_EAC95E', 'WidgetPropSentinel_GenFunc',   'Sentinel for generic func sub-block'),
    ('LABEL_EAC968', 'WidgetPropStr_GenSentinel',    'Empty string sentinel for generic func'),
    ('LABEL_EAC96A', 'WidgetPropStr_GenFunc',        'Property string: "func" (generic)'),

    # --- EAC970: Widget property descriptor block: multiline text with font ---
    # Properties: lines, alignment, fontcolor, font
    ('LABEL_EAC970', 'WidgetPropTab_MlTextFont',     'Widget property pointer table: multiline text with font'),
    ('LABEL_EAC984', 'WidgetPropStr_MtfSentinel',    'Empty string sentinel for multiline text font'),
    ('LABEL_EAC986', 'WidgetPropStr_MtfLines',       'Property string: "lines" (multiline text font)'),
    ('LABEL_EAC98C', 'WidgetPropStr_MtfAlignment',   'Property string: "alignment" (multiline text font)'),
    ('LABEL_EAC996', 'WidgetPropStr_MtfFontColor',   'Property string: "fontcolor" (multiline text font)'),
    ('LABEL_EAC9A0', 'WidgetPropStr_MtfFont',        'Property string: "font" (multiline text font)'),

    # --- EAC9AE: Widget property descriptor block: func terminal blocks ---
    ('LABEL_EAC9AE', 'WidgetPropSentinel_FuncTerm',  'Sentinel for func terminal block'),
    ('LABEL_EAC9B0', 'WidgetPropStr_FuncTerm',       'Property string: "func" (terminal block)'),
    ('LABEL_EAC9BA', 'WidgetPropSentinel_FuncTerm2', 'Sentinel 2 for func terminal block'),
    ('LABEL_EAC9C0', 'WidgetPropSentinel_FuncTerm3', 'Sentinel 3 for func terminal block'),
    ('LABEL_EAC9CA', 'WidgetPropSentinel_FuncTerm4', 'Sentinel 4 for func terminal block'),
    ('LABEL_EAC9CC', 'WidgetPropStr_FuncTerm4',      'Property string: "func" (terminal block 4)'),
    ('LABEL_EAC9D6', 'WidgetPropSentinel_FuncTerm5', 'Sentinel 5 for func terminal block'),
    ('LABEL_EAC9DC', 'WidgetPropSentinel_FuncTerm6', 'Sentinel 6 for func terminal block'),
    ('LABEL_EAC9E6', 'WidgetPropSentinel_FileProp',  'Sentinel for file property block'),
    ('LABEL_EAC9E8', 'WidgetPropStr_FileProp',       'Property string: "file"'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')
    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')
    renamed = 0
    for old_label, new_label, comment in RENAMES:
        if old_label not in content:
            print(f'  WARNING: {old_label} not found, skipping')
            continue
        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        new_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)
        if new_content != content:
            content = new_content
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:40s} ({refs} refs)')
    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))
    print(f'\nRenamed {renamed} labels in maincpu')


if __name__ == '__main__':
    main()
