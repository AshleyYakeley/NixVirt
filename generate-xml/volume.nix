let
  xml = import ./xml.nix;
  generate = import ./generate.nix;

  # https://libvirt.org/formatstorage.html
  process = with generate;
    elem "volume" [ ]
      [
        (subelem "name" [ ] typeString)
        (subelem "allocation" [ (subattr "unit" typeString) ] (sub "count" typeInt))
        (subelem "capacity" [ (subattr "unit" typeString) ] (sub "count" typeInt))
        (subelem "target" [ ]
          [
            (subelem "format" [ (subattr "type" typeString) ] [ ])
            (subelem "permissions" [ ]
              [
                (subelem "mode" [ ] (sub "octal" typeString))
                (subelem "owner" [ ] (sub "uid" typeInt))
                (subelem "group" [ ] (sub "gid" typeInt))
                (subelem "label" [ ] (sub "MAC" typeString))
              ]
            )
            (subelem "compat" [ ] typeString)
            (subelem "nocow" [ ] [ ])
            (subelem "clusterSize" [ (subattr "unit" typeString) ] (sub "count" typeInt))
            (subelem "features" [ ]
              [
                (subelem "lazy_refcounts" [ ] [ ])
                (subelem "extended_l2" [ ] [ ])
              ]
            )
          ]
        )
        (subelem "backingStore" [ ]
          [
            (subelem "path" [ ] typeString)
            (subelem "format" [ (subattr "type" typeString) ] [ ])
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
