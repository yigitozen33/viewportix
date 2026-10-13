#!/usr/bin/env python3
"""Save a pen.dev `execute` dump (a printed JSON line ending in "hash" and "length") to a JSON file.

The snippet prints `{...,"hash":<FNV-1a over UTF-16 code units>,"length":<n>}`; this script finds that line in a
saved tool output (or stdin), checks hash + length so nothing was lost in transit, strips both keys and writes the
JSON pretty-printed.

Usage: python3 save_dump.py <tool-output.txt|-> <out.json>
stdlib only.
"""
import json, struct, sys
from pathlib import Path


def fnv1a_utf16(text):
    raw = text.encode("utf-16-le")
    h = 2166136261
    for unit in struct.unpack(f"<{len(raw) // 2}H", raw):
        h = ((h ^ unit) * 16777619) & 0xFFFFFFFF
    return h, len(raw) // 2


def main():
    src, out = sys.argv[1], Path(sys.argv[2])
    text = sys.stdin.read() if src == "-" else Path(src).read_text()
    lines = [l.rstrip() for l in text.splitlines() if l.startswith('{"generatedAt"')]
    if not lines:
        sys.exit("no dump line found (did the snippet print ERROR?)")
    line = lines[-1]
    data = json.loads(line)
    want_hash, want_len = data.pop("hash"), data.pop("length")
    got_hash, got_len = fnv1a_utf16(line[: line.rindex(',"hash"')] + "}")
    if (got_hash, got_len) != (want_hash, want_len):
        sys.exit(f"hash mismatch: got {got_hash}/{got_len}, snippet printed {want_hash}/{want_len}")
    out.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n")
    print(f"OK {out.name}: {got_len} chars, hash {got_hash}")


if __name__ == "__main__":
    main()
