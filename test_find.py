def find_strings_in_data(data):
    i = 0
    chunks = []
    while i < len(data):
        start = i
        has_original_string = False
        
        while i < len(data) and 0x20 <= data[i][0] <= 0x7E:
            if data[i][1]: has_original_string = True
            i += 1
            
        if i < len(data) and data[i][0] == 0x00:
            if data[i][1]: has_original_string = True
            length = i - start
            if length >= 3 or has_original_string:
                text = "".join(chr(x[0]) for x in data[start:i])
                i += 1
                if i < len(data) and data[i][0] == 0xff:
                    i += 1
                chunks.append(('string', text))
                continue
                
        chunks.append(('byte', data[start][0]))
        i = start + 1
    return chunks

data = [(76, True), (67, True), (68, True), (32, True), (80, True), (65, True), (78, True), (69, True), (76, True), (32, True), (84, True), (69, True), (83, True), (84, True), (0, True), (255, False)]
print(find_strings_in_data(data))
