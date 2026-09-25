# Standalone evaluation tests; run with nix-instantiate --eval --strict.
{
  lib ? (import <nixpkgs> { }).lib,
  returnCases ? false,
}:
let
  gv = import ../../../modules/lib/gvariant.nix { inherit lib; };
  check = value: text: type: {
    expr = [
      (toString value)
      (gv.typeOf value)
      (gv.isGVariant value)
    ];
    expected = [
      text
      type
      true
    ];
  };
  cases = {
    testBytes = check (gv.mkByteString "a'\"\\n\\377\\\\end") "b'a\\'\"\\n\\377\\\\end'" "ay";
    testBytesEmpty = check (gv.mkByteString "") "b''" "ay";
    testTypedTupleArray = check (gv.mkTyped "(au)" (gv.mkTuple [ [ 1 ] ])) "@(au) ([1],)" "(au)";
    testSingleton = check (gv.mkTuple [ 1 ]) "@(i) (1,)" "(i)";
    testTypedEmpty = check (gv.mkTyped "a{sv}" [ ]) "@a{sv} []" "a{sv}";
    testTypedMaybe = check (gv.mkTyped "ms" "hi") "@ms 'hi'" "ms";
    testTypedNestedArray = check (gv.mkTyped "aau" [
      [ 1 ]
      [ ]
    ]) "@aau [[1],[]]" "aau";
    testTypedTuple = check (gv.mkTyped "(uu)" (
      gv.mkTuple [
        1
        2
      ]
    )) "@(uu) (1,2)" "(uu)";
    testTypedDictionary = check (gv.mkTyped "a{su}" [
      (gv.mkDictionaryEntry [
        "key"
        1
      ])
    ]) "@a{su} [{'key',1}]" "a{su}";
    testTypedSingleton = check (gv.mkTyped "(u)" (gv.mkTuple [ 1 ])) "@(u) (1,)" "(u)";
    testCastSignature = check (gv.mkCast "signature" "a{sv}") "signature 'a{sv}'" "g";
    testCastDouble = check (gv.mkCast "double" 2) "double 2" "d";
    testTypedVariant = check (gv.mkVariant (gv.mkTyped "ms" "hi")) "@v <@ms 'hi'>" "v";
    testTypedArrayExplicit = check (gv.mkTyped "au" (gv.mkArray "u" [ 1 ])) "@au @au [1]" "au";
    testBytesEscapedQuote = check (gv.mkByteString "a\\'") "b'a\\''" "ay";
    testCastBoolean = check (gv.mkCast "boolean" false) "boolean false" "b";
    testCastHandle = check (gv.mkCast "handle" 22) "handle 22" "h";
    testCastString = check (gv.mkCast "string" "it's\\fine\n") "string 'it\\'s\\\\fine\\n'" "s";
    testCastNested = check (gv.mkCast "uint32" (gv.mkCast "uint32" 7)) "uint32 uint32 7" "u";
    testCastVariant = check (gv.mkVariant (gv.mkCast "objectpath" "/a")) "@v <objectpath '/a'>" "v";
  };
in
if returnCases then
  lib.mapAttrsToList (_: c: c.expr) cases
else
  lib.runTests (
    cases
    // {
      testIncompleteByteEscape = {
        expr = (builtins.tryEval (toString (gv.mkByteString "\\"))).success;
        expected = false;
      };
      testUnknownCast = {
        expr = (builtins.tryEval (gv.typeOf (gv.mkCast "unknown" 0))).success;
        expected = false;
      };
    }
  )
