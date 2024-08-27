let
  xml = import ./xml.nix;
  generate = import ./generate.nix;

  # https://libvirt.org/formatstorage.html
  process =
    with generate;
    elem "pool" [ (subattr "type" typeString) ] [
      (subelem "name" [ ] typeString)
      (subelem "uuid" [ ] typeString)

      (subelem "features" [ ] [
        (subelem "cow" [
          subattr
          "state"
          typeBoolYesNo
        ] [ ])
      ])
      (subelem "source" [ ] [
        (subelem "device" [ (subattr "path" typeString) ] [ ])
        (subelem "dir" [ (subattr "path" typeString) ] [ ])
      ])
      (subelem "target" [ ] [
        (subelem "path" [ ] typeString)
        (subelem "permissions" [ ] [ ])
      ])
    ];

in
obj: xml.toText (process obj)
