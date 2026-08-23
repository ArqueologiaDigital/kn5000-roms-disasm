import importlib.util, os, pickle, sys, collections
REPO="/home/fsanches/compartilhado/kn5000-roms-disasm"; os.chdir(REPO)
_s=importlib.util.spec_from_file_location("crr",os.path.join(REPO,"scripts/converters/convert_reachable_ranges.py"))
crr=importlib.util.module_from_spec(_s); _s.loader.exec_module(crr)
_d=importlib.util.spec_from_file_location("_decodes",os.path.join(os.path.dirname(os.path.abspath(__file__)),"_decodes.py"))
_dm=importlib.util.module_from_spec(_d); _d.loader.exec_module(_dm)
decodes=_dm.load(crr)          # builds decodes.pkl if absent -- see _decodes.py
crr.decode_range=lambda rom,terr,start,limit=16384: decodes.get(start,[])
sys.argv=[sys.argv[0],"--forms"]
crr.main()
