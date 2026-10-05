{
  pkgs,
  caseName ? null,
}:
let
  lib = pkgs.lib.extend (_: _: { hm = import ../../../modules/lib { inherit lib; }; });
  gv = lib.hm.gvariant;
  cases = {
    element-if = {
      defs = [
        (gv.mkTyped "ai" [
          (lib.mkIf true 1)
          2
        ])
      ];
      expected = "@ai [1,2]";
    };
    element-before = {
      # listOf resolves an element's order property, but does not reorder
      # independent list entries (unlike definition-level mkBefore).
      defs = [
        (gv.mkTyped "ai" [
          2
          (lib.mkBefore 1)
        ])
      ];
      expected = "@ai [2,1]";
    };
    element-merge = {
      defs = [
        (gv.mkTyped "ai" [
          (lib.mkMerge [ 1 ])
          2
        ])
      ];
      expected = "@ai [1,2]";
    };
    element-disabled = {
      defs = [
        (gv.mkTyped "ai" [
          (lib.mkIf false (throw "disabled element forced"))
          2
        ])
      ];
      expected = "@ai [2]";
    };
    element-empty-merge = {
      defs = [
        (gv.mkTyped "ai" [
          (lib.mkMerge [ ])
          2
        ])
      ];
      expected = "@ai [2]";
    };
    element-nested-properties = {
      defs = [
        (gv.mkTyped "ai" [
          (lib.mkIf true (
            lib.mkMerge [
              (lib.mkIf false 9)
              (lib.mkBefore 1)
            ]
          ))
          2
        ])
      ];
      expected = "@ai [1,2]";
    };
    element-equal-merge = {
      defs = [
        (gv.mkTyped "ai" [
          (lib.mkMerge [
            1
            1
          ])
        ])
      ];
      expected = "@ai [1]";
    };
    element-equal-contextual-merge = {
      defs = [
        (gv.mkTyped "au" [
          (lib.mkMerge [
            1
            1
          ])
        ])
      ];
      expected = "@au [1]";
    };
    element-equal-null-merge = {
      defs = [
        (gv.mkTyped "amu" [
          (lib.mkMerge [
            null
            null
          ])
        ])
      ];
      expected = "@amu [nothing]";
    };
    element-priority = {
      defs = [
        (gv.mkTyped "ai" [
          (lib.mkMerge [
            (lib.mkDefault 1)
            (lib.mkForce 2)
          ])
        ])
      ];
      expected = "@ai [2]";
    };
    element-list-merge-order = {
      defs = [
        (gv.mkTyped "aau" [
          (lib.mkMerge [
            [ 2 ]
            (lib.mkBefore [ 1 ])
          ])
        ])
      ];
      expected = "@aau [[1,2]]";
    };
    element-contextual-maybe = {
      defs = [
        (gv.mkTyped "amu" [
          (lib.mkIf true null)
          (lib.mkMerge [ (lib.mkBefore 1) ])
        ])
      ];
      expected = "@amu [nothing,1]";
    };
    element-contextual-containers = {
      defs = [
        (gv.mkTyped "aamu" [
          (lib.mkIf true [
            null
            1
          ])
          (lib.mkMerge [ [ ] ])
        ])
      ];
      expected = "@aamu [[nothing,1],[]]";
    };
    element-nested-list-properties = {
      defs = [
        (gv.mkTyped "aamu" [
          [
            (lib.mkIf true null)
            (lib.mkIf false 9)
            (lib.mkBefore 1)
          ]
        ])
      ];
      expected = "@aamu [[nothing,1]]";
    };
    element-contextual-tuple = {
      defs = [ (gv.mkTyped "a(mu)" [ (lib.mkIf true (gv.mkTuple [ null ])) ]) ];
      expected = "@a(mu) [(nothing,)]";
    };
    element-byte-array = {
      defs = [
        (gv.mkTyped "ay" [
          (lib.mkIf true 97)
          (lib.mkMerge [ 0 ])
        ])
        (gv.mkTyped "ay" [
          98
          0
        ])
      ];
      expected = "@ay [97,0,98,0]";
    };
    outer-array-annotation = {
      defs = [ (gv.mkTyped "au" (gv.mkArray "i" [ 1 ])) ];
      expected = "@au @ai [1]";
    };
    byte-lf = {
      defs = [ (gv.mkVariant (gv.mkByteString "line\nbreak")) ];
      expected = "<b'line\\nbreak'>";
    };
    byte-continuation = {
      defs = [ (gv.mkByteString "line\\\nbreak") ];
      expected = "b'linebreak'";
    };
    byte-octal-continuation = {
      defs = [ (gv.mkByteString "\\1\\\n7") ];
      expected = "@ay [1,55,0]";
    };
    byte-two-digit-octal-continuation = {
      defs = [ (gv.mkByteString "\\12\\\n3") ];
      expected = "@ay [10,51,0]";
    };
    byte-three-digit-octal-continuation = {
      defs = [ (gv.mkByteString "\\123\\\n4") ];
      expected = "@ay [83,52,0]";
    };
    byte-repeated-octal-continuation = {
      defs = [ (gv.mkByteString "\\1\\\n\\\n7") ];
      expected = "@ay [1,55,0]";
    };
    byte-zero-octal-continuation = {
      defs = [ (gv.mkByteString "a\\0\\\n7") ];
      expected = "@ay [97,0]";
    };
    byte-escaped-octal-continuation = {
      defs = [ (gv.mkByteString "\\\\1\\\n7") ];
      expected = "@ay [92,49,55,0]";
    };
    byte-escaped-backslash-lf = {
      defs = [ (gv.mkByteString "line\\\\\nbreak") ];
      expected = "b'line\\\\\\nbreak'";
    };
    maybe = {
      defs = [
        (gv.mkTyped "amu" [
          null
          1
        ])
      ];
      expected = "@amu [nothing,1]";
    };
    maybe-merge = {
      defs = [
        (gv.mkTyped "amu" [ null ])
        (gv.mkTyped "amu" [ 1 ])
      ];
      expected = "@amu [nothing,1]";
    };
    nested-maybe = {
      defs = [
        (gv.mkTyped "aamu" [
          [
            null
            1
          ]
          [ ]
        ])
      ];
      expected = "@aamu [[nothing,1],[]]";
    };
    byte-force = {
      defs = [
        (gv.mkByteString "a")
        (lib.mkForce (gv.mkByteString "b"))
      ];
      expected = "b'b'";
    };
    byte-array-merge = {
      defs = [
        (gv.mkArray "y" [
          (gv.mkUchar 97)
          (gv.mkUchar 0)
        ])
        (gv.mkArray "y" [
          (gv.mkUchar 98)
          (gv.mkUchar 0)
        ])
      ];
      expected = "@ay [97,0,98,0]";
    };
    array-order = {
      defs = [
        (gv.mkTyped "au" [ 2 ])
        (lib.mkBefore (gv.mkTyped "au" [ 1 ]))
      ];
      expected = "@au [1,2]";
    };
    bytes-empty = {
      defs = [ (gv.mkByteString "") ];
      expected = "@ay [0]";
    };
    bytes-nul = {
      defs = [ (gv.mkByteString "a\\0b") ];
      expected = "@ay [97,0]";
    };
    bytes-octal = {
      defs = [ (gv.mkByteString "\\0017") ];
      expected = "@ay [1,55,0]";
    };
    bytes-wrapped = {
      defs = [ (gv.mkTyped "ay" (gv.mkByteString "abc")) ];
      expected = "b'abc'";
    };
    nested-tuple-maybe = {
      defs = [
        (gv.mkTyped "a(mu)" [ (gv.mkTuple [ null ]) ])
        (gv.mkTyped "a(mu)" [ (gv.mkTuple [ 1 ]) ])
      ];
      expected = "@a(mu) [(nothing,),(1,)]";
    };
    nested-maybe-merge = {
      defs = [
        (gv.mkTyped "aamu" [ [ null ] ])
        (gv.mkTyped "aamu" [ [ 1 ] ])
      ];
      expected = "@aamu [[nothing],[1]]";
    };
    bytes = {
      defs = [ (gv.mkByteString "abc") ];
      expected = "b'abc'";
    };
    wrapped = {
      defs = [ (gv.mkTyped "au" (gv.mkArray "u" [ 1 ])) ];
      expected = "@au [1]";
    };
    wrapped-merge = {
      defs = [
        (gv.mkTyped "au" (gv.mkArray "u" [ 1 ]))
        (gv.mkTyped "au" [ 2 ])
      ];
      expected = "@au [1,2]";
    };
    nested-bytes = {
      defs = [
        (gv.mkArray "ay" [ (gv.mkByteString "a") ])
        (gv.mkArray "ay" [ (gv.mkByteString "b") ])
      ];
      expected = "[b'a',b'b']";
    };
  };
  selected = if caseName == null then cases else { ${caseName} = cases.${caseName}; };
  evaluate =
    case:
    (import ../../../modules {
      inherit pkgs;
      configuration = {
        home.username = "test";
        home.homeDirectory = "/home/test";
        home.stateVersion = "26.05";
        dconf.settings = lib.mkMerge (map (value: { "org/test".value = value; }) case.defs);
      };
    }).config;
  rejected = {
    conflicting-element-merge = [
      (gv.mkTyped "ai" [
        (lib.mkMerge [
          1
          2
        ])
      ])
    ];
    conflicting-string-element-merge = [
      (gv.mkTyped "as" [
        (lib.mkMerge [
          "a"
          "b"
        ])
      ])
    ];
    byte-definitions = [
      (gv.mkByteString "a")
      (gv.mkByteString "b")
    ];
    identical-byte-definitions = [
      (gv.mkByteString "a")
      (gv.mkByteString "a")
    ];
    byte-array-mixture = [
      (gv.mkByteString "a")
      (gv.mkArray "y" [ (gv.mkUchar 1) ])
    ];
    mismatched-arrays = [
      (gv.mkTyped "au" [ 1 ])
      (gv.mkTyped "ai" [ 2 ])
    ];
  };
  rejectionResults = lib.mapAttrs (
    _name: defs:
    !(builtins.tryEval (toString (evaluate { inherit defs; }).dconf.settings."org/test".value)).success
  ) rejected;
  fixtures = lib.mapAttrsToList (
    name: case:
    let
      config = evaluate case;
      # Use the actual module-generated keyfile, without running activation.
      activation = config.home.activation.dconfSettings.data;
      ini = builtins.appendContext (builtins.head (builtins.match ".*dconf load / < ([^\n]+)\n.*" activation)) (
        builtins.getContext activation
      );
    in
    {
      inherit name ini;
      inherit (case) expected;
    }
  ) selected;
in
assert lib.assertMsg (lib.all (value: value) (
  lib.attrValues rejectionResults
)) "Unexpected successful merge: ${builtins.toJSON rejectionResults}";
pkgs.runCommand "gvariant-dconf"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.dconf
    ];
  }
  ''
    python ${./gvariant-dconf.py} \
      ${lib.getLib pkgs.glib}/lib/libglib-2.0${pkgs.stdenv.hostPlatform.extensions.sharedLibrary} \
      ${pkgs.writeText "dconf-cases.json" (builtins.toJSON fixtures)}
    touch $out
  ''
