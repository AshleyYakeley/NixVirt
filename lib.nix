pkgs:
let
    xml = import ./xml.nix;

    yesno = t: if t then "yes" else "no";
    onoff = t: if t then "on" else "off";
    ifn = t: s: if t then s else null;
    optattr = v: a: ifn (builtins.hasAttr a v) a;
    map1 = f: x: if builtins.isList x then builtins.map f x else [(f x)];
    id = x: x;

    sub = with builtins;
        a: contents: subject:
            xml.opt (hasAttr a subject) (contents (getAttr a subject));

    elem = with builtins;
        etype: attrs: contents: subject:
            xml.elem etype
                (map (a: a subject) attrs)
                (if isList contents then map (c: c subject) contents else contents subject);

    subelem = etype: attrs: contents: sub etype (elem etype attrs contents);

    attr = atype: contents: subject: xml.attr atype (contents subject);

    subattr = atype: contents: sub atype (attr atype contents);

    many = contents: subject: xml.many (map1 contents subject);

    submanyelem = etype: attrs: contents: sub etype (many (elem etype attrs contents));

    process =  with builtins; elem "domain" [(subattr "type" id)]
        [
            (subelem "name" [] id)
            (subelem "uuid" [] id)
            (subelem "title" [] id)
            (subelem "metadata" [] id)
            (subelem "memory" [] id)
            (subelem "currentMemory" [] id)
            (subelem "vcpu" [(subattr "placement" id)] (x: toString x.count))
            (subelem "os" []
                [
                    (elem "type" [(subattr "arch" id) (subattr "machine" id)] (getAttr "type"))
                    (submanyelem "boot" [(attr "dev" id)] [])
                    (subelem "bootmenu" [(subattr "enable" yesno)] [])
                ]
            )
            (subelem "features" []
                [
                    (subelem "acpi" [] [])
                    (subelem "apic" [] [])
                ]
            )
            (subelem "cpu"
                [
                    (subattr "mode" id)
                    (subattr "check" id)
                    (subattr "migratable" onoff)
                ]
                [
                    (subelem "topology"
                        [
                            (subattr "sockets" toString)
                            (subattr "dies" toString)
                            (subattr "cores" toString)
                            (subattr "threads" toString)
                        ]
                        []
                    )
                ]
            )
            (subelem "clock"
                [
                    (subattr "offset" id)
                ]
                [
                    (submanyelem "timer"
                        [
                            (subattr "name" id)
                            (subattr "tickpolicy" id)
                            (subattr "present" yesno)
                        ] [])
                ]
            )
            (sub "on" (sub "poweroff" (elem "on_poweroff" [] id)))
            (sub "on" (sub "reboot" (elem "on_reboot" [] id)))
            (sub "on" (sub "crash" (elem "on_crash" [] id)))
            (subelem "pm" []
                [
                    (subelem "suspend-to-mem" [(attr "enabled" yesno)] [])
                    (subelem "suspend-to-disk" [(attr "enabled" yesno)] [])
                ]
            )
            (let
                addresselem = subelem "address"
                    [
                        (subattr "type" id)
                        (subattr "controller" toString)
                        (subattr "domain" toString)
                        (subattr "bus" toString)
                        (subattr "target" toString)
                        (subattr "unit" toString)
                        (subattr "slot" toString)
                        (subattr "function" toString)
                        (subattr "multifunction" onoff)
                    ]
                    [];
            in subelem "devices" [(subattr "type" id)]
                [
                    (submanyelem "emulator" [] toString)
                    (submanyelem "disk" [(subattr "type" id) (subattr "device" id)]
                        [
                            (subelem "driver"
                                [
                                    (subattr "name" id)
                                    (subattr "type" id)
                                    (subattr "cache" id)
                                ] []
                            )
                            (subelem "source" [(subattr "file" toString)] [])
                            (subelem "target" [(subattr "dev" id) (subattr "bus" id)] [])
                            addresselem
                        ]
                    )
                    (submanyelem "controller"
                        [
                            (subattr "type" id)
                            (subattr "index" toString)
                            (subattr "model" id)
                        ]
                        [
                            (subelem "master" [(subattr "startport" toString)] [])
                            addresselem
                        ])
                    (submanyelem "interface"
                        [
                            (subattr "type" id)
                        ]
                        [
                            (subelem "mac" [(subattr "address" id)] [])
                            (subelem "source" [(subattr "bridge" id)] [])
                            (subelem "model" [(subattr "type" id)] [])
                            addresselem
                        ])
                ]
            )
        ];

    domainXML = domain: xml.toText (process domain);

in
{
    inherit xml;

    inherit domainXML;

    writeDomainXML = domain: pkgs.writeTextFile
    {
        name = "NixVirt-domain-" + domain.name;
        text = domainXML domain;
    };
}
