import ast
def unescape(s):
    try:
        return ast.literal_eval('"' + s.replace('"', '"') + '"')
    except:
        res = ""
        i = 0
        while i < len(s):
            if s[i] == '':
                if i+1 < len(s):
                    res += s[i+1]
                    i += 2
                else:
                    res += ''
                    i += 1
            else:
                res += s[i]
                i += 1
        return res
print(unescape('^\[Zx'))
