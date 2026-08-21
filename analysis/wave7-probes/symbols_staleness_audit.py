import subprocess, sys, collections
REPO="/home/fsanches/compartilhado/kn5000-roms-disasm"
NM="/home/fsanches/compartilhado/llvm-project/build/bin/llvm-nm"

def nm_syms(elf):
    out=subprocess.run([NM,"--defined-only",elf],cwd=REPO,capture_output=True,text=True).stdout
    t={}; a=0
    for line in out.splitlines():
        p=line.split()
        if len(p)!=3: continue
        addr,typ,name=p
        if typ=='t':
            t.setdefault(int(addr,16),set()).add(name)
        elif typ=='a': a+=1
    return t,a

def rows(path):
    r=[]
    for line in open(REPO+"/"+path):
        line=line.rstrip("\n")
        if line.startswith("#") or not line.strip(): continue
        p=line.split()
        r.append((p[0], int(p[1],16)))
    return r

def report(name, symfile, elf):
    t,acount = nm_syms(elf)
    r = rows(symfile)
    elf_names_all = set()
    for s in t.values(): elf_names_all|=s
    elf_lower = {n.lower():n for n in elf_names_all}
    exact=0; label=0
    allcaps_exact=0; allcaps_case=0; allcaps_absent=0
    mixed_exact=0; mixed_absent=0; mixed_other=0
    addrs=set()
    for nm_,ad in r:
        addrs.add(ad)
        here = t.get(ad,set())
        if nm_ in here: exact+=1
        if nm_.startswith("LABEL_"):
            label+=1; continue
        isupper = (nm_.upper()==nm_)
        inelf_exact = nm_ in elf_names_all
        inelf_ci = nm_.lower() in elf_lower
        if isupper:
            if inelf_exact: allcaps_exact+=1
            elif inelf_ci: allcaps_case+=1
            else: allcaps_absent+=1
        else:
            if inelf_exact: mixed_exact+=1
            elif inelf_ci: mixed_other+=1
            else: mixed_absent+=1
    # address coverage
    with_sym = sum(1 for a in addrs if a in t)
    build_addrs=set(t.keys())
    print(f"=== {name} ===")
    print(f"  file rows                : {len(r)}")
    print(f"  ELF 't' symbols          : {sum(len(v) for v in t.values())}  (distinct addrs {len(t)})   'a': {acount}")
    print(f"  rows exact NAME+ADDR     : {exact}  ({100.0*exact/len(r):.1f}%)")
    print(f"  LABEL_* rows             : {label}")
    print(f"  already-named rows       : {len(r)-label}")
    print(f"     ALLCAPS exact in ELF  : {allcaps_exact}")
    print(f"     ALLCAPS case-twin     : {allcaps_case}")
    print(f"     ALLCAPS absent        : {allcaps_absent}")
    print(f"     MixedCase exact       : {mixed_exact}")
    print(f"     MixedCase case-only   : {mixed_other}")
    print(f"     MixedCase absent      : {mixed_absent}")
    print(f"  distinct addrs in file   : {len(addrs)}")
    print(f"     that carry a sym      : {with_sym}   (no sym: {len(addrs)-with_sym})")
    print(f"  build addrs not in file  : {len(build_addrs-addrs)}")
    # case-insensitive name+address overlap
    ci=0
    for nm_,ad in r:
        here={x.lower() for x in t.get(ad,set())}
        if nm_.lower() in here: ci+=1
    print(f"  CI name+addr matches     : {ci}   (minus exact = {ci-exact})")

report("maincpu","symbols/maincpu_symbols_reference.txt","rebuilt_ROMs/kn5000_v10_program.llvm.elf")
report("subcpu","symbols/subcpu_symbols_reference.txt","rebuilt_ROMs/kn5000_subprogram_v142.llvm.elf")
report("subcpu_boot","symbols/subcpu_boot_symbols_reference.txt","rebuilt_ROMs/kn5000_subcpu_boot.llvm.elf")
report("table_data","symbols/table_data_symbols_reference.txt","rebuilt_ROMs/kn5000_table_data.llvm.elf")
report("hdae5000","symbols/hdae5000_symbols_reference.txt","rebuilt_ROMs/hd-ae5000_v2_06i.llvm.elf")
