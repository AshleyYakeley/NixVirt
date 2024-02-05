let
    xml = import ./xml.nix;
    generate = import ./generate.nix;

    process = with builtins; with generate;
        elem "domain" [(subattr "type" typeString)]
        [
            (subelem "name" [] typeString)
            (subelem "uuid" [] typeString)
            (subelem "title" [] typeString)
            (subelem "metadata" [] id)
            (subelem "memory" [(subattr "unit" typeString)] (sub "count" typeInt))
            (subelem "currentMemory" [(subattr "unit" typeString)] (sub "count" typeInt))
            (subelem "vcpu" [(subattr "placement" typeString)] (sub "count" typeInt))
            (subelem "os" []
                [
                    (elem "type" [(subattr "arch" typeString) (subattr "machine" typeString)] (getAttr "type"))
                    (submanyelem "boot" [(attr "dev" typeString)] [])
                    (subelem "bootmenu" [(subattr "enable" typeBoolYesNo)] [])
                ]
            )
            (subelem "features" []
                [
                    (suboptelem "acpi" [] [])
                    (suboptelem "apic" [] [])
                    (subelem "vmport" [(subattr "state" typeBoolOnOff)] [])
                ]
            )
            (subelem "cpu"
                [
                    (subattr "mode" typeString)
                    (subattr "match" typeString)
                    (subattr "check" typeString)
                    (subattr "migratable" typeBoolOnOff)
                ]
                [
                    (subelem "model"
                        [
                            (subattr "fallback" typeInt)
                        ]
                        [(subelem name [] typeString)]
                    )
                    (subelem "topology"
                        [
                            (subattr "sockets" typeInt)
                            (subattr "dies" typeInt)
                            (subattr "cores" typeInt)
                            (subattr "threads" typeInt)
                        ]
                        []
                    )
                ]
            )
            (subelem "clock"
                [
                    (subattr "offset" typeString)
                ]
                [
                    (submanyelem "timer"
                        [
                            (subattr "name" typeString)
                            (subattr "tickpolicy" typeString)
                            (subattr "present" typeBoolYesNo)
                        ] [])
                ]
            )
            (subelem "on_poweroff" [] typeString)
            (subelem "on_reboot" [] typeString)
            (subelem "on_crash" [] typeString)
            (subelem "pm" []
                [
                    (subelem "suspend-to-mem" [(attr "enabled" typeBoolYesNo)] [])
                    (subelem "suspend-to-disk" [(attr "enabled" typeBoolYesNo)] [])
                ]
            )
            (let
                addresselem = subelem "address"
                    [
                        (subattr "type" typeString)
                        (subattr "controller" typeInt)
                        (subattr "domain" typeInt)
                        (subattr "bus" typeInt)
                        (subattr "target" typeInt)
                        (subattr "unit" typeInt)
                        (subattr "slot" typeInt)
                        (subattr "port" typeInt)
                        (subattr "function" typeInt)
                        (subattr "multifunction" typeBoolOnOff)
                    ]
                    [];
                targetelem = subelem "target"
                    [
                        (subattr "type" typeString)
                        (subattr "name" typeString)
                        (subattr "chassis" typeInt)
                        (subattr "port" typeInt)
                        (subattr "dev" typeString)
                        (subattr "bus" typeString)
                    ]
                    [
                        (subelem "model" [(subattr "name" typeString)] [])
                    ];
            in subelem "devices" [(subattr "type" typeString)]
                [
                    (submanyelem "emulator" [] typePath)
                    (submanyelem "disk" [(subattr "type" typeString) (subattr "device" typeString)]
                        [
                            (subelem "driver"
                                [
                                    (subattr "name" typeString)
                                    (subattr "type" typeString)
                                    (subattr "cache" typeString)
                                    (subattr "discard" typeString)
                                ] []
                            )
                            (subelem "source" [(subattr "file" typePath)] [])
                            targetelem
                            (suboptelem "readonly" [] [])
                            addresselem
                        ]
                    )
                    (submanyelem "controller"
                        [
                            (subattr "type" typeString)
                            (subattr "index" typeInt)
                            (subattr "model" typeString)
                            (subattr "ports" typeInt)
                        ]
                        [
                            (subelem "master" [(subattr "startport" typeInt)] [])
                            targetelem
                            addresselem
                        ])
                    (submanyelem "interface"
                        [
                            (subattr "type" typeString)
                        ]
                        [
                            (subelem "mac" [(subattr "address" typeString)] [])
                            (subelem "source"
                                [
                                    (subattr "bridge" typeString)
                                    (subattr "dev" typeString)
                                    (subattr "mode" typeString)
                                    (subattr "network" typeString)
                                ] [addresselem])
                            (subelem "model" [(subattr "type" typeString)] [])
                            addresselem
                        ])
                    (submanyelem "smartcard" [(subattr "mode" typeString) (subattr "type" typeString)] [addresselem])
                    (submanyelem "serial" [(subattr "type" typeString)] [targetelem])
                    (submanyelem "console" [(subattr "type" typeString)] [targetelem])
                    (submanyelem "channel" [(subattr "type" typeString)]
                        [
                            (subelem "source" [(subattr "channel" typeString)] [])
                            targetelem
                            addresselem
                        ])
                    (submanyelem "input" [(subattr "type" typeString) (subattr "bus" typeString)] [addresselem])
                    (submanyelem "graphics"
                        [
                            (subattr "type" typeString)
                            (subattr "autoport" typeBoolYesNo)
                        ]
                        [
                            (subelem "listen" [(subattr "type" typeString)] [])
                            (subelem "image" [(subattr "compression" typeBoolOnOff)] [])
                            (subelem "gl" [(subattr "enable" typeBoolYesNo)] [])
                        ])
                    (submanyelem "sound" [(subattr "model" typeString)] [addresselem])
                    (submanyelem "audio" [(subattr "id" typeInt) (subattr "type" typeString)] [])
                    (submanyelem "video" []
                        [
                            (subelem "model"
                                [
                                    (subattr "type" typeString)
                                    (subattr "ram" typeInt)
                                    (subattr "vram" typeInt)
                                    (subattr "vgamem" typeInt)
                                    (subattr "heads" typeInt)
                                    (subattr "primary" typeBoolYesNo)
                                ]
                                [
                                    (subelem "acceleration" [(subattr "accel3d" typeBoolYesNo)] [])
                                ])
                            addresselem
                        ])
                    (submanyelem "redirdev" [(subattr "bus" typeString) (subattr "type" typeString)] [addresselem])
                    (submanyelem "watchdog" [(subattr "model" typeString) (subattr "action" typeString)] [])
                    (submanyelem "rng" [(subattr "model" typeString)]
                        [
                            (subelem "backend" [(subattr "model" typeString)] (sub "source" typePath))
                            addresselem
                        ])
                    (submanyelem "memballoon" [(subattr "model" typeString)] [addresselem])
                ]
            )
        ];

in
domain: xml.toText (process domain)
