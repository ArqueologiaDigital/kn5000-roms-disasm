import subprocess, os, re, tempfile
MC="/home/fsanches/compartilhado/llvm-project/build/bin/llvm-mc"
_cache={}
def encode_many(lines):
    """Assemble each line independently; return {line: bytes|None}. Batched."""
    todo=[l for l in dict.fromkeys(lines) if l not in _cache]
    for i in range(0,len(todo),200):
        chunk=todo[i:i+200]
        _run(chunk)
    return {l:_cache.get(l) for l in lines}
def _run(chunk):
    fd,p=tempfile.mkstemp(suffix=".s"); os.write(fd,("\n".join(chunk)+"\n").encode()); os.close(fd)
    r=subprocess.run([MC,"-triple=tlcs900","--show-encoding",p],capture_output=True,text=True)
    os.unlink(p)
    if r.returncode!=0:
        if len(chunk)==1:
            _cache[chunk[0]]=None; return
        _run(chunk[:len(chunk)//2]); _run(chunk[len(chunk)//2:]); return
    encs=re.findall(r'encoding:\s*\[([^\]]*)\]', r.stdout)
    if len(encs)!=len(chunk):
        if len(chunk)==1:
            _cache[chunk[0]]=None; return
        _run(chunk[:len(chunk)//2]); _run(chunk[len(chunk)//2:]); return
    for l,e in zip(chunk,encs):
        _cache[l]=bytes(int(x,16) for x in e.replace(" ","").split(",") if x)
