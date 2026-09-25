# dconf2nix src/Nix.hs emits raw tuple members and dictionary entries under mkTyped.
{ gv, dictionaryEntry }:
with gv;
[
  {
    value = mkTyped "(ua{su}au)" (mkTuple [
      1
      [ (dictionaryEntry "key" 2) ]
      [ ]
    ]);
    expected = "(uint32 1, {'key': uint32 2}, @au [])";
  }
  {
    value = mkTyped "a{sa(uu)}" [
      (dictionaryEntry "key" [
        (mkTuple [
          1
          2
        ])
      ])
    ];
    expected = "{'key': [(uint32 1, uint32 2)]}";
  }
  {
    value = mkTyped "((u)au)" (mkTuple [
      (mkTuple [ 1 ])
      [ ]
    ]);
    expected = "((uint32 1,), @au [])";
  }
  {
    value = mkTyped "(a{sv})" (mkTuple [ [ ] ]);
    expected = "(@a{sv} {},)";
  }
  {
    value = mkTyped "(u)" (mkTuple [ (mkTyped "u" 1) ]);
    expected = "(uint32 1,)";
  }
  {
    value = mkTyped "(u)" (mkTuple [ (mkInt32 1) ]);
    expected = "@(u) (@i 1,)";
    text = "@(u) (@i 1,)";
  }
  {
    value = mkTyped "(u)" (mkTuple [ (mkCast "int32" 1) ]);
    expected = "@(u) (int32 1,)";
  }
  {
    value = mkTyped "(u)" (mkTuple [ (mkTyped "i" 1) ]);
    expected = "@(u) (@i 1,)";
    text = "@(u) (@i 1,)";
  }
  {
    value = mkTyped "o" (mkString "/a");
    expected = "@o @s '/a'";
  }
  {
    value = mkCast "int32" (mkDouble "2.0");
    invalid = true;
  }
  {
    value = mkByteString "a'\"\\n\\377\\\\end";
    expected = "[byte 97, 39, 34, 10, 255, 92, 101, 110, 100, 0]";
  }
  {
    value = mkByteString "line\nbreak";
    expected = "[byte 108, 105, 110, 101, 10, 98, 114, 101, 97, 107, 0]";
  }
  {
    value = mkTyped "ms" null;
    expected = "@ms nothing";
  }
]
