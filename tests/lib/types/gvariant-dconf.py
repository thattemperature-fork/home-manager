"""Compile actual HM keyfiles and compare isolated dconf readback with GLib."""

import ctypes
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

lib = ctypes.CDLL(sys.argv[1])
lib.g_variant_parse.argtypes = [
    ctypes.c_void_p,
    ctypes.c_char_p,
    ctypes.c_void_p,
    ctypes.c_void_p,
    ctypes.c_void_p,
]
lib.g_variant_parse.restype = ctypes.c_void_p
lib.g_variant_equal.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
lib.g_variant_equal.restype = ctypes.c_int
lib.g_variant_unref.argtypes = [ctypes.c_void_p]


def parse(text):
    value = lib.g_variant_parse(None, text.encode(), None, None, None)
    assert value, f"GLib could not parse {text!r}"
    return value


with open(sys.argv[2]) as stream:
    cases = json.load(stream)
for case in cases:
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        keyfiles = root / "keyfiles"
        keyfiles.mkdir()
        text = Path(case["ini"]).read_text()
        (keyfiles / "settings").write_text(text)
        database = root / "database"
        subprocess.run(["dconf", "compile", str(database), str(keyfiles)], check=True)
        profile = root / "profile"
        profile.write_text(f"file-db:{database}\n")
        env = {
            **os.environ,
            "DCONF_PROFILE": str(profile),
            "XDG_CONFIG_HOME": str(root),
        }
        env.pop("DBUS_SESSION_BUS_ADDRESS", None)
        actual_text = subprocess.check_output(
            ["dconf", "read", "/org/test/value"], env=env, text=True
        )
        actual, expected = parse(actual_text), parse(case["expected"])
        assert lib.g_variant_equal(actual, expected), (
            case["name"],
            actual_text,
            case["expected"],
        )
        lib.g_variant_unref(actual)
        lib.g_variant_unref(expected)
        print(f"PASS {case['name']}: compiled keyfile and GLib-equal isolated readback")
print(f"Verified {len(cases)} actual dconf.settings cases")
