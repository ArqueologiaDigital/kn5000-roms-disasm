#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names across multiple files using binary I/O."""
import sys
import os

def rename_labels(renames, files):
    """Apply renames across all files. renames is a dict of old->new."""
    for filepath in files:
        with open(filepath, 'rb') as f:
            data = f.read()
        original = data
        for old, new in renames.items():
            data = data.replace(old.encode('ascii'), new.encode('ascii'))
        if data != original:
            with open(filepath, 'wb') as f:
                f.write(data)
            print(f"  Updated: {filepath}")

if __name__ == '__main__':
    import json
    renames = json.loads(sys.argv[1])
    files = sys.argv[2:]
    rename_labels(renames, files)
