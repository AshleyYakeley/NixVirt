let
  xml = import ./xml.nix;
  generate = import ./generate.nix;

  # https://libvirt.org/formatdomain.html
  process = with generate;
    elem "domain" [ (subattr "type" typeString) ]
      [
        (subelem "name" [ ] typeString)
        (subelem "uuid" [ ] typeString)
        (subelem "title" [ ] typeString)
        (subelem "description" [ ] typeString)
        (subelemraw "metadata" [ ])

        (subelem "memory" [ (subattr "unit" typeString) ] (sub "count" typeInt))
        (subelem "currentMemory" [ (subattr "unit" typeString) ] (sub "count" typeInt))
        (subelem "vcpu" [ (subattr "placement" typeString) ] (sub "count" typeInt))
        (subelem "os" [ ]
          [
            (elem "type" [ (subattr "arch" typeString) (subattr "machine" typeString) ] (sub "type" typeString))
            (subelem "loader" [ (subattr "readonly" typeBoolYesNo) (subattr "type" typeString) ] (sub "path" typePath))
            (subelem "nvram"
              [
                (subattr "template" typePath)
                (subattr "type" typeString)
                (subattr "format" typeString)
              ]
              (sub "path" typePath))
            (subelem "boot" [ (subattr "dev" typeString) ] [ ])
            (subelem "bootmenu" [ (subattr "enable" typeBoolYesNo) ] [ ])

            (subelem "kernel" [ ] (sub "path" typeString))
            (subelem "initrd" [ ] (sub "path" typeString))
            (subelem "cmdline" [ ] (sub "options" typeString))

          ]
        )
        (subelem "memoryBacking" [ ]
          [
            (subelem "source" [ (subattr "type" typeString) ] [ ])
            (subelem "access" [ (subattr "mode" typeString) ] [ ])
          ]
        )
        (subelem "features" [ ]
          [
            (subelem "acpi" [ ] [ ])
            (subelem "apic" [ ] [ ])
            (subelem "hyperv" [ (subattr "mode" typeString) ]
              [
                (subelem "relaxed" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "vapic" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "spinlocks" [ (subattr "state" typeBoolOnOff) (subattr "retries" typeInt) ] [ ])
                (subelem "vpindex" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "runtime" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "synic" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "stimer" [ (subattr "state" typeBoolOnOff) ]
                  [
                    (subelem "direct" [ (subattr "state" typeBoolOnOff) ] [ ])
                  ])
                (subelem "reset" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "vendor_id" [ (subattr "state" typeBoolOnOff) (subattr "value" typeString) ] [ ])
                (subelem "frequencies" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "reenlightenment" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "tlbflush" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "ipi" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "evmcs" [ (subattr "state" typeBoolOnOff) ] [ ])
              ])
            (subelem "vmport" [ (subattr "state" typeBoolOnOff) ] [ ])
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
              [ (subelem name [ ] typeString) ]
            )
            (subelem "topology"
              [
                (subattr "sockets" typeInt)
                (subattr "dies" typeInt)
                (subattr "cores" typeInt)
                (subattr "threads" typeInt)
              ]
              [ ]
            )
          ]
        )
        (subelem "clock"
          [
            (subattr "offset" typeString)
          ]
          [
            (subelem "timer"
              [
                (subattr "name" typeString)
                (subattr "tickpolicy" typeString)
                (subattr "present" typeBoolYesNo)
              ] [ ])
          ]
        )
        (subelem "on_poweroff" [ ] typeString)
        (subelem "on_reboot" [ ] typeString)
        (subelem "on_crash" [ ] typeString)
        (subelem "pm" [ ]
          [
            (subelem "suspend-to-mem" [ (subattr "enabled" typeBoolYesNo) ] [ ])
            (subelem "suspend-to-disk" [ (subattr "enabled" typeBoolYesNo) ] [ ])
          ]
        )
        (
          let
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
              [ ];
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
                (subelem "model" [ (subattr "name" typeString) ] [ ])
              ];
          in
          subelem "devices" [ (subattr "type" typeString) ]
            [
              (subelem "emulator" [ ] typePath)
              (subelem "disk" [ (subattr "type" typeString) (subattr "device" typeString) ]
                [
                  (subelem "driver"
                    [
                      (subattr "name" typeString)
                      (subattr "type" typeString)
                      (subattr "cache" typeString)
                      (subattr "discard" typeString)
                    ] [ ]
                  )
                  (subelem "source" [ (subattr "file" typePath) (subattr "startupPolicy" typeString) ] [ ])
                  targetelem
                  (subelem "readonly" [ ] [ ])
                  addresselem
                ]
              )
              (subelem "filesystem" [ (subattr "type" typeString) (subattr "accessmode" typeString) ]
                [
                  (subelem "driver"
                    [
                      (subattr "name" typeString)
                      (subattr "type" typeString)
                      (subattr "cache" typeString)
                      (subattr "discard" typeString)
                    ] [ ]
                  )
                  (subelem "binary" [ (subattr "path" typeString) ] [ ])
                  (subelem "source" [ (subattr "dir" typeString) (subattr "name" typeString) ] [ ])
                  (subelem "target" [ (subattr "dir" typeString) ] [ ])
                  (subelem "readonly" [ ] [ ])
                  addresselem
                ]
              )
              (subelem "controller"
                [
                  (subattr "type" typeString)
                  (subattr "index" typeInt)
                  (subattr "model" typeString)
                  (subattr "ports" typeInt)
                ]
                [
                  (subelem "master" [ (subattr "startport" typeInt) ] [ ])
                  targetelem
                  addresselem
                ])
              (subelem "interface"
                [
                  (subattr "type" typeString)
                ]
                [
                  (subelem "mac" [ (subattr "address" typeString) ] [ ])
                  (subelem "source"
                    [
                      (subattr "bridge" typeString)
                      (subattr "dev" typeString)
                      (subattr "mode" typeString)
                      (subattr "network" typeString)
                    ] [ addresselem ])
                  (subelem "model" [ (subattr "type" typeString) ] [ ])
                  addresselem
                ])
              (subelem "smartcard" [ (subattr "mode" typeString) (subattr "type" typeString) ] [ addresselem ])
              (subelem "serial" [ (subattr "type" typeString) ] [ targetelem ])
              (subelem "console" [ (subattr "type" typeString) ] [ targetelem ])
              (subelem "channel" [ (subattr "type" typeString) ]
                [
                  (subelem "source" [ (subattr "channel" typeString) ] [ ])
                  targetelem
                  addresselem
                ])
              (subelem "input" [ (subattr "type" typeString) (subattr "bus" typeString) ] [ addresselem ])
              (subelem "tpm" [ (subattr "model" typeString) ]
                [
                  (subelem "backend" [ (subattr "type" typeString) (subattr "version" typeString) ] [ ])
                ])
              (subelem "graphics"
                [
                  (subattr "type" typeString)
                  (subattr "autoport" typeBoolYesNo)
                ]
                [
                  (subelem "listen" [ (subattr "type" typeString) ] [ ])
                  (subelem "image" [ (subattr "compression" typeBoolOnOff) ] [ ])
                  (subelem "gl" [ (subattr "enable" typeBoolYesNo) ] [ ])
                ])
              (subelem "sound" [ (subattr "model" typeString) ] [ addresselem ])
              (subelem "audio" [ (subattr "id" typeInt) (subattr "type" typeString) ] [ ])
              (subelem "video" [ ]
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
                      (subelem "acceleration" [ (subattr "accel3d" typeBoolYesNo) ] [ ])
                    ])
                  addresselem
                ])
              (subelem "redirdev" [ (subattr "bus" typeString) (subattr "type" typeString) ] [ addresselem ])
              (subelem "watchdog" [ (subattr "model" typeString) (subattr "action" typeString) ] [ ])
              (subelem "rng" [ (subattr "model" typeString) ]
                [
                  (subelem "backend" [ (subattr "model" typeString) ] (sub "source" typePath))
                  addresselem
                ])
              (subelem "memballoon" [ (subattr "model" typeString) ] [ addresselem ])
            ]
        )
      ];

in
obj: xml.toText (process obj)
