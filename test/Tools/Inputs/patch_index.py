#!/usr/bin/env python3
"""Writes a copy of a metaphir-index file with one part of its header changed,
for tests of how a damaged index is rejected:

    patch_index.py <kind> <in> <out> [value]

kinds: magic, version, llvm (the LLVM version string becomes 'x'),
schema (the number of feature names), directory (the directory's size).
"""

import sys


def uleb(data, pos):
    value = shift = 0
    while True:
        byte = data[pos]
        pos += 1
        value |= (byte & 0x7F) << shift
        shift += 7
        if not byte & 0x80:
            return value, pos


def encode_uleb(value):
    out = bytearray()
    while True:
        byte = value & 0x7F
        value >>= 7
        if value:
            out.append(byte | 0x80)
        else:
            out.append(byte)
            return bytes(out)


def string_at(data, pos):
    length, start = uleb(data, pos)
    return start, start + length


def main():
    kind, source, target = sys.argv[1], sys.argv[2], sys.argv[3]
    value = int(sys.argv[4]) if len(sys.argv) > 4 else 0
    data = bytearray(open(source, "rb").read())
    magic = 7
    if kind == "magic":
        data[0] ^= 0xFF
    elif kind == "version":
        data[magic : magic + 4] = value.to_bytes(4, "little")
    elif kind == "llvm":
        start, end = string_at(data, magic + 4)
        data[start:end] = b"x" * (end - start)
    else:
        start, end = string_at(data, magic + 4)
        pos = end
        names, pos = uleb(data, pos)
        for _ in range(names):
            _, pos = string_at(data, pos)
        _, pos = string_at(data, pos)  # the root
        modules, pos = uleb(data, pos)
        directory_at = pos
        size, pos = uleb(data, pos)
        if kind == "schema":
            names_at = end
            _, body = uleb(data, names_at)
            data[names_at:body] = encode_uleb(value) + b""
        elif kind == "directory":
            data[directory_at:pos] = encode_uleb(value)
    open(target, "wb").write(bytes(data))


if __name__ == "__main__":
    main()
