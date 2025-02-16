let
  xml = import ./xml.nix;
  generate = import ./generate.nix;

  # https://libvirt.org/formatstorage.html
  process = with generate;
    elem "pool" [ (subattr "type" typeString) ]
      [
        (subelem "name" [ ] typeString)
        (subelem "uuid" [ ] typeString)

        (subelem "features" [ ]
          [
            (subelem "cow" [ (subattr "state" typeBoolYesNo) ] [ ])
          ])
        (subelem "source" [ ]
          [
            (subelem "device"
              [
                (subattr "path" typeString)
                (subattr "part_separator" typeBoolYesNo)
              ] [ ]
            )
            (subelem "dir" [ (subattr "path" typeString) ] [ ])
            (subelem "host" [ (subattr "name" typeString) ] [ ])
            (subelem "auth"
              [
                (subattr "type" typeString)
                (subattr "username" typeString)
              ]
              [
                (subelem "secret"
                  [
                    (subattr "type" typeString)
                    (subattr "uuid" typeString)
                    (subattr "usage" typeString)
                  ] [ ]
                )
              ]
            )
            (subelem "name" [ ] typeString)
            (subelem "format" [ (subattr "type" typeString) ] [ ])
            (subelem "protocol" [ (subattr "ver" typeString) ] [ ])
            (subelem "vendor" [ (subattr "name" typeString) ] [ ])
            (subelem "product" [ (subattr "name" typeString) ] [ ])
          ]
        )
        (subelem "refresh" [ ]
          [
            (subelem "volume" [ (subattr "allocation" typeString) ] [ ])
          ]
        )
        (subelem "target" [ ]
          [
            (subelem "path" [ ] typeString)
            (subelem "permissions" [ ]
              [
                (subelem "mode" [ ] (sub "octal" typeString))
                (subelem "owner" [ ] (sub "uid" typeInt))
                (subelem "group" [ ] (sub "gid" typeInt))
                (subelem "label" [ ] (sub "MAC" typeString))
              ]
            )
          ]
        )
      ];

in
obj: xml.toText (process obj)
