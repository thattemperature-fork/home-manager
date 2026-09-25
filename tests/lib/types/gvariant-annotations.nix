# nix-build tests/lib/types/gvariant-annotations.nix --arg pkgs 'import /path/to/nixpkgs {}'
{ pkgs }:
let
  inherit (pkgs) lib;
  gv = import ../../../modules/lib/gvariant.nix { inherit lib; };
  cases = import ./gvariant-annotation-cases.nix {
    inherit gv;
    dictionaryEntry =
      key: value:
      gv.mkDictionaryEntry [
        key
        value
      ];
  };
  data = pkgs.writeText "gvariant-annotation-cases.json" (
    builtins.toJSON (
      map (case: {
        text =
          assert !(case ? text) || toString case.value == case.text;
          toString case.value;
        type = case.value.type;
        expected = case.expected or null;
        invalid = case.invalid or false;
      }) cases
    )
  );
in
pkgs.runCommand "gvariant-annotation-tests" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  python ${./gvariant-annotation-parser.py} ${lib.getLib pkgs.glib}/lib/libglib-2.0${pkgs.stdenv.hostPlatform.extensions.sharedLibrary} ${data}
  mkdir "$out"
''
