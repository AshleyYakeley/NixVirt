let
  xml = import ./xml.nix;
  generate = import ./generate.nix;

  # https://libvirt.org/formatstorage.html
  process = with generate;
    elem "volume" [ (subattr "type" typeString) ]
      [
        (subelem "name" [ ] typeString)
        (subelem "capacity" [ (subattr "unit" typeString) ] (sub "count" typeInt))
        (subelem "allocation" [ (subattr "unit" typeString) ] (sub "count" typeInt))
        (subelem "target" [ ]
          [
            (subelem "format" [ (subattr "type" typeString) ] [ ])
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
      ];

in
obj: xml.toText (process obj)
