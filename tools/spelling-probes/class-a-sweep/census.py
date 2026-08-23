import importlib.util, os, pickle, sys, collections
REPO="/home/fsanches/compartilhado/kn5000-roms-disasm"; os.chdir(REPO)
_s=importlib.util.spec_from_file_location("crr",os.path.join(REPO,"scripts/converters/convert_reachable_ranges.py"))
crr=importlib.util.module_from_spec(_s); _s.loader.exec_module(crr)
CACHE=os.path.join(os.path.dirname(os.path.abspath(__file__)),"decodes.pkl")
decodes=pickle.load(open(CACHE,"rb"))
crr.decode_range=lambda rom,terr,start,limit=16384: decodes.get(start,[])
sys.argv=[sys.argv[0],"--forms"]
crr.main()
