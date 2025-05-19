let
  xml = import ./xml.nix;
  generate = import ./generate.nix;
  bandwidthElem = import ./netbandwidth.nix;

  # https://libvirt.org/formatnetwork.html
  process = with generate;
    elem "network" [ (subattr "ipv6" typeBoolYesNo) (subattr "trustGuestRxFilters" typeBoolYesNo) ]
      [
        (subelem "name" [ ] typeString)
        (subelem "uuid" [ ] typeString)
        (subelem "title" [ ] typeString)
        (subelem "description" [ ] typeString)
        (subelemraw "metadata" [ ])

        (subelem "bridge"
          [
            (subattr "name" typeString)
            (subattr "stp" typeBoolOnOff)
            (subattr "delay" typeInt)
            (subattr "macTableManager" typeString)
            (subattr "zone" typeString)
          ] [ ])
        (subelem "mtu" [ (subattr "size" typeInt) ] [ ])
        (subelem "domain"
          [
            (subattr "name" typeString)
            (subattr "localOnly" typeBoolYesNo)
          ] [ ])
        (subelem "forward"
          [
            (subattr "mode" typeString)
            (subattr "dev" typeString)
          ]
          [
            (subelem "nat"
              [
                (subattr "ipv6" typeBoolYesNo)
              ]
              [
                (subelem "address"
                  [
                    (subattr "start" typeString)
                    (subattr "end" typeString)
                  ]
                  [ ])
                (subelem "port"
                  [
                    (subattr "start" typeInt)
                    (subattr "end" typeInt)
                  ]
                  [ ])
              ])
            (subelem "interface"
              [
                (subattr "dev" typeString)
                (subattr "connections" typeInt)
              ] [ ])
            (subelem "pf"
              [
                (subattr "dev" typeString)
              ] [ ])
            (subelem "address"
              [
                (subattr "type" typeString)
                (subattr "domain" typeInt)
                (subattr "bus" typeInt)
                (subattr "slot" typeInt)
                (subattr "function" typeInt)
              ]
              [ ])
          ])
        bandwidthElem
        (subelem "vlan"
          [
            (subattr "trunk" typeBoolYesNo)
          ]
          [
            (subelem "tag"
              [
                (subattr "id" typeInt)
                (subattr "nativeMode" typeString)
              ] [ ])
          ])
        (subelem "port"
          [
            (subattr "isolated" typeBoolYesNo)
          ] [ ])
        (subelem "portgroup"
          [
            (subattr "name" typeString)
            (subattr "default" typeBoolYesNo)
            (subattr "trustGuestRxFilters" typeBoolYesNo)
          ]
          [
            (subelem "virtualport"
              [
                (subattr "type" typeString)
              ]
              [
                (subelem "parameters"
                  [
                    (subattr "profileid" typeString)
                    (subattr "instanceid" typeString)
                    (subattr "interfaceid" typeString)
                  ] [ ])
              ])
            bandwidthElem
          ])
        (subelem "route"
          [
            (subattr "family" typeString)
            (subattr "address" typeString)
            (subattr "prefix" typeInt)
            (subattr "gateway" typeString)
            (subattr "metric" typeInt)
          ] [ ])
        (subelem "mac" [ (subattr "address" typeString) ] [ ])
        (subelem "dns"
          [
            (subattr "enable" typeBoolYesNo)
            (subattr "forwardPlainNames" typeBoolYesNo)
          ]
          [
            (subelem "forwarder"
              [
                (subattr "domain" typeString)
                (subattr "addr" typeString)
              ] [ ])
            (subelem "txt"
              [
                (subattr "name" typeString)
                (subattr "value" typeString)
              ] [ ])
            (subelem "host"
              [
                (subattr "ip" typeString)
              ]
              [
                (subelem "hostname" [ ] typeString)
              ])
            (subelem "srv"
              [
                (subattr "service" typeString)
                (subattr "protocol" typeString)
                (subattr "target" typeString)
                (subattr "port" typeInt)
                (subattr "priority" typeInt)
                (subattr "weight" typeInt)
                (subattr "domain" typeString)
              ]
              [ ])
          ])
        (subelem "ip"
          [
            (subattr "address" typeString)
            (subattr "prefix" typeInt)
            (subattr "netmask" typeString)
            (subattr "family" typeString)
            (subattr "localPtr" typeBoolYesNo)
          ]
          [
            (subelem "tftp" [ (subattr "root" typeString) ] [ ])
            (subelem "dhcp" [ ]
              [
                (subelem "range"
                  [
                    (subattr "start" typeString)
                    (subattr "end" typeString)
                  ]
                  [
                    (subelem "lease"
                      [
                        (subattr "expiry" typeInt)
                        (subattr "unit" typeString)
                      ] [ ])
                  ])
                (subelem "host"
                  [
                    (subattr "mac" typeString)
                    (subattr "name" typeString)
                    (subattr "ip" typeString)
                  ]
                  [
                    (subelem "lease"
                      [
                        (subattr "expiry" typeInt)
                        (subattr "unit" typeString)
                      ] [ ])
                  ])
                (subelem "bootp"
                  [
                    (subattr "file" typeString)
                    (subattr "server" typeString)
                  ] [ ])
              ])
          ])
      ];

in
obj: xml.toText (process obj)
