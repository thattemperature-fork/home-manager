{ lib, realPkgs, ... }:
let
  failures = import ./gvariant-constructors.nix { inherit lib; };
  cases = import ./gvariant-constructors.nix {
    inherit lib;
    returnCases = true;
  };
in
{
  test.asserts.assertions.expected = [ ];
  assertions = [
    {
      assertion = failures == [ ];
      message = builtins.toJSON failures;
    }
  ];
  nmt.script = ''
    ${realPkgs.python3}/bin/python ${./gvariant-parser.py} \
      ${lib.getLib realPkgs.glib}/lib/libglib-2.0${realPkgs.stdenv.hostPlatform.extensions.sharedLibrary} \
      ${realPkgs.writeText "gvariant-cases.json" (builtins.toJSON cases)}
  '';
}
