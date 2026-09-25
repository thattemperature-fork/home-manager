"""Check generated text and inferred types with GLib, not a mock parser."""
import ctypes
import json
import sys

lib = ctypes.CDLL(sys.argv[1])
lib.g_variant_parse.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_void_p,
                               ctypes.c_void_p, ctypes.c_void_p]
lib.g_variant_parse.restype = ctypes.c_void_p
lib.g_variant_get_type_string.argtypes = [ctypes.c_void_p]
lib.g_variant_get_type_string.restype = ctypes.c_char_p
lib.g_variant_unref.argtypes = [ctypes.c_void_p]
lib.g_variant_get_fixed_array.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_size_t), ctypes.c_size_t]
lib.g_variant_get_fixed_array.restype = ctypes.c_void_p
with open(sys.argv[2]) as stream:
    cases = json.load(stream)
for text, expected_type, _ in cases:
    value = lib.g_variant_parse(None, text.encode(), None, None, None)
    assert value, f"GLib could not parse {text!r}"
    actual = lib.g_variant_get_type_string(value).decode()
    assert actual == expected_type, (text, actual, expected_type)
    if text.startswith("b'"):
        length = ctypes.c_size_t()
        data = lib.g_variant_get_fixed_array(value, ctypes.byref(length), 1)
        expected = {
            "b''": b"\0",
            "b'a\\''": b"a'\0",
        }.get(text, b"a'\"\n\xff\\end\0")
        assert ctypes.string_at(data, length.value) == expected
    lib.g_variant_unref(value)
print(f"GLib parsed {len(cases)} values with matching types and byte payloads")
