pkgs:
let
    xml = import ./xml.nix;

    yesno = t: if t then "yes" else "no";
    onoff = t: if t then "on" else "off";
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

    opt = contents: subject: xml.opt subject (contents subject);

    suboptelem = etype: attrs: contents: sub etype (opt (elem etype attrs contents));

    process =  with builtins; elem "domain" [(subattr "type" id)]
        [
            (subelem "name" [] id)
            (subelem "uuid" [] id)
            (subelem "title" [] id)
            (subelem "metadata" [] id)
            (subelem "memory" [(subattr "unit" id)] (sub "count" toString))
            (subelem "currentMemory" [(subattr "unit" id)] (sub "count" toString))
            (subelem "vcpu" [(subattr "placement" id)] (sub "count" toString))
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
                        (subattr "port" toString)
                        (subattr "function" toString)
                        (subattr "multifunction" onoff)
                    ]
                    [];
                targetelem = subelem "target"
                    [
                        (subattr "type" id)
                        (subattr "name" id)
                        (subattr "port" toString)
                        (subattr "dev" id)
                        (subattr "bus" id)
                    ]
                    [
                        (subelem "model" [(subattr "name" toString)] [])
                    ];
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
                            targetelem
                            (suboptelem "readonly" [] [])
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
                    (submanyelem "smartcard" [(subattr "mode" id) (subattr "type" id)] [addresselem])
                    (submanyelem "serial" [(subattr "type" id)] [targetelem])
                    (submanyelem "console" [(subattr "type" id)] [targetelem])
                    (submanyelem "channel" [(subattr "type" id)]
                        [
                            (subelem "source" [(subattr "channel" id)] [])
                            targetelem
                            addresselem
                        ])
                    (submanyelem "input" [(subattr "type" id) (subattr "bus" id)] [])
                    (submanyelem "graphics" [(subattr "type" id)]
                        [
                            (subelem "listen" [(subattr "type" id)] [])
                            (subelem "image" [(subattr "compression" onoff)] [])
                            (subelem "gl" [(subattr "enable" yesno)] [])
                        ])
                    (submanyelem "sound" [(subattr "model" id)] [addresselem])
                    (submanyelem "audio" [(subattr "id" toString) (subattr "type" id)] [])
                    (submanyelem "video" []
                        [
                            (subelem "model"
                                [
                                    (subattr "type" id)
                                    (subattr "ram" toString)
                                    (subattr "vram" toString)
                                    (subattr "vgamem" toString)
                                    (subattr "heads" toString)
                                    (subattr "primary" yesno)
                                ]
                                [
                                    (subelem "acceleration" [(subattr "accel3d" yesno)] [])
                                ])
                            addresselem
                        ])
                    (submanyelem "redirdev" [(subattr "bus" id) (subattr "type" id)] [addresselem])
                    (submanyelem "memballoon" [(subattr "model" id)] [addresselem])
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
