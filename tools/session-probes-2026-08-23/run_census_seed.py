import importlib.util, json, os, sys
REPO='/home/fsanches/compartilhado/kn5000-roms-disasm'; os.chdir(REPO)
_s=importlib.util.spec_from_file_location('crr',REPO+'/scripts/converters/convert_reachable_ranges.py')
crr=importlib.util.module_from_spec(_s); _s.loader.exec_module(crr)
import pickle
d=pickle.load(open(REPO+'/tools/spelling-probes/class-a-sweep/decodes.pkl','rb'))
crr.decode_range=lambda rom,terr,start,limit=16384: d.get(start,[])
# force the SEED target list (687) by hiding the closure file from os.path.exists
_ex=os.path.exists
crr.os.path.exists=lambda p: False if p.endswith('v7_branch_closure_targets.json') else _ex(p)
sys.argv=[sys.argv[0]]
crr.main()
