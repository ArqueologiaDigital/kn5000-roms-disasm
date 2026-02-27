import re, ast
s = r'\"#$%'
print(f"Regex group: {s}")
def unescape(s):
    try:
        return ast.literal_eval('"' + s.replace('"', '\\"') + '"')
    except Exception as e:
        print("Fallback!")
        res = ""
        i = 0
        while i < len(s):
            if s[i] == '\\':
                if i+1 < len(s):
                    res += s[i+1]
                    i += 2
                else:
                    res += '\\'
                    i += 1
            else:
                res += s[i]
                i += 1
        return res
text = unescape(s)
print(f"Unescaped: {repr(text)}")
safe_str = text.replace('\\', '\\\\').replace('"', '\\"')
print(f"Output: .ascii \"{safe_str}\"")
