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
      ];

in
obj: xml.toText (process obj)
