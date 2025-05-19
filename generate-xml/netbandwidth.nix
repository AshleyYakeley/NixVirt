let
  generate = import ./generate.nix;

in
  with generate;
    subelem "bandwidth" [ ]
      [
        (subelem "inbound"
          [
            (subattr "average" typeInt)
            (subattr "peak" typeInt)
            (subattr "burst" typeInt)
            (subattr "floor" typeInt)
          ] [ ])
        (subelem "outbound"
          [
            (subattr "average" typeInt)
            (subattr "peak" typeInt)
            (subattr "burst" typeInt)
          ] [ ])
      ]

