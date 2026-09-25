"""Check generated text against GLib, including inferred type and binary value."""

import ctypes as c
import json
import sys


class GError(c.Structure):
    _fields_ = [("domain", c.c_uint32), ("code", c.c_int), ("message", c.c_char_p)]


glib = c.CDLL(sys.argv[1])
glib.g_variant_parse.argtypes = [c.c_void_p, c.c_char_p, c.c_void_p, c.c_void_p, c.POINTER(c.POINTER(GError))]
glib.g_variant_parse.restype = c.c_void_p
glib.g_variant_get_type_string.argtypes = [c.c_void_p]
glib.g_variant_get_type_string.restype = c.c_char_p
glib.g_variant_equal.argtypes = [c.c_void_p, c.c_void_p]
glib.g_variant_equal.restype = c.c_int
glib.g_variant_unref.argtypes = [c.c_void_p]
glib.g_error_free.argtypes = [c.POINTER(GError)]


def parse(text):
    error = c.POINTER(GError)()
    value = glib.g_variant_parse(None, text.encode(), None, None, c.byref(error))
    if not value:
        message = error.contents.message.decode()
        glib.g_error_free(error)
        raise AssertionError(f"Cannot parse {text!r}: {message}")
    return value


with open(sys.argv[2]) as source:
    cases = json.load(source)
for case in cases:
    if case.get("invalid", False):
        try:
            actual = parse(case["text"])
        except AssertionError:
            continue
        glib.g_variant_unref(actual)
        raise AssertionError(f"GLib accepted conflicting annotations: {case['text']}")
    actual = parse(case["text"])
    expected = parse(case["expected"])
    try:
        actual_type = glib.g_variant_get_type_string(actual).decode()
        assert actual_type == case["type"], (case, actual_type)
        assert glib.g_variant_equal(actual, expected), case
    finally:
        glib.g_variant_unref(actual)
        glib.g_variant_unref(expected)
print(f"GLib parsed and verified {len(cases)} GVariant values")
