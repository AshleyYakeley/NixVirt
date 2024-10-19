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
        (subelem "vcpu" [ (subattr "placement" typeString) (subattr "cpuset" typeString) ] (sub "count" typeInt))
        (subelem "iothreads" [ ] (sub "count" typeInt))
        (subelem "cputune" [ ] [
          (subelem "vcpupin" [ (subattr "vcpu" typeInt) (subattr "cpuset" typeString) ] [ ])
          (subelem "emulatorpin" [ (subattr "cpuset" typeString) ] [ ])
          (subelem "iothreadpin" [ (subattr "iothread" typeInt) (subattr "cpuset" typeString) ] [ ])
          (subelem "shares" [ ] typeInt)
          (subelem "period" [ ] typeInt)
          (subelem "quota" [ ] typeInt)
          (subelem "global_period" [ ] typeInt)
          (subelem "global_quota" [ ] typeInt)
          (subelem "emulator_period" [ ] typeInt)
          (subelem "emulator_quota" [ ] typeInt)
          (subelem "iothread_period" [ ] typeInt)
          (subelem "iothread_quota" [ ] typeInt)
          (subelem "vcpusched" [ (subattr "vcpus" typeString) (subattr "scheduler" typeString) (subattr "priority" typeInt) ] [ ])
          (subelem "iothreadsched" [ (subattr "iothreads" typeInt) (subattr "scheduler" typeString) ] [ ])
          (subelem "cachetune" [ (subattr "vcpus" typeString) ] [
            (subelem "cache" [ (subattr "id" typeInt) (subattr "level" typeInt) (subattr "type" typeString) (subattr "size" typeInt) (subattr "unit" typeString) ] [ ])
            (subelem "monitor" [ (subattr "level" typeInt) (subattr "vcpus" typeString) ] [ ])
          ])
          (subelem "memorytune" [ (subattr "vcpus" typeString) ] [
            (subelem "node" [ (subattr "id" typeInt) (subattr "bandwidth" typeInt) ] [ ])
          ])
        ])

        (subelem "sysinfo" [ (subattr "type" typeString) ] [
          (subelem "bios" [ ] [
            (subelem "entry" [ (subattr "name" typeString) ] (sub "value" typeString))
          ])
          (subelem "system" [ ] [
            (subelem "entry" [ (subattr "name" typeString) ] (sub "value" typeString))
          ])
        ])

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
            (subelem "kernel" [ ] (sub "path" typePath))
            (subelem "initrd" [ ] (sub "path" typePath))
            (subelem "init" [ ] typePath)
            (subelem "initarg" [ ] typeString)
            (subelem "cmdline" [ ] (sub "options" typeString))
            (subelem "smbios" [ (subattr "mode" typeString) ] [ ])
          ]
        )
        (subelem "memoryBacking" [ ]
          [
            (subelem "hugepages" [ ] [
              (subelem "page" [ (subattr "size" typeInt) (subattr "unit" typeString) (subattr "nodeset" typeString) ] [ ])
            ])
            (subelem "nosharepages" [ ] [ ])
            (subelem "locked" [ ] [ ])
            (subelem "source" [ (subattr "type" typeString) ] [ ])
            (subelem "access" [ (subattr "mode" typeString) ] [ ])
            (subelem "allocation" [ (subattr "mode" typeString) (subattr "threads" typeInt) ] [ ])
            (subelem "discard" [ ] [ ])
          ]
        )
        (subelem "features" [ ]
          [
            (subelem "acpi" [ ] [ ])
            (subelem "apic" [ (subattr "eoi" typeBoolOnOff) ] [ ])
            (subelem "pae" [ ] [ ])
            (subelem "privnet" [ ] [ ])
            (subelem "pvspinlock" [ (subattr "state" typeBoolOnOff) ] [ ])
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
            (subelem "capabilities" [ (subattr "policy" typeString) ]
              [
                (subelem "audit_control" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "audit_read" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "audit_write" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "block_suspend" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "bpf" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "checkpoint_restore" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "dac_override" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "dac_read_search" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "fowner" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "fsetid" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "ipc_lock" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "ipc_owner" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "kill" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "lease" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "linux_immutable" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "mac_admin" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "mac_override" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "mknod" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "net_admin" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "net_bind_service" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "net_broadcast" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "net_raw" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "perfmon" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "setfcap" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "setgid" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "setpcap" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "setuid" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "syslog" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "sys_admin" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "sys_boot" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "sys_chroot" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "sys_module" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "sys_nice" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "sys_pacct" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "sys_ptrace" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "sys_rawio" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "sys_resource" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "sys_time" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "sys_tty_config" [ (subattr "state" typeBoolOnOff) ] [ ])
                (subelem "wake_alarm" [ (subattr "state" typeBoolOnOff) ] [ ])
              ])
            (subelem "vmport" [ (subattr "state" typeBoolOnOff) ] [ ])
            (subelem "kvm" [ ] [
              (subelem "hidden" [ (subattr "state" typeBoolOnOff) ] [ ])
              (subelem "hint-dedicated" [ (subattr "state" typeBoolOnOff) ] [ ])
              (subelem "poll-control" [ (subattr "state" typeBoolOnOff) ] [ ])
              (subelem "pv-ipi" [ (subattr "state" typeBoolOnOff) ] [ ])
              (subelem "dirty-ring" [ (subattr "state" typeBoolOnOff) (subattr "size" typeInt) ] [ ])
            ])
            (subelem "ioapic" [ (subattr "driver" typeString) ] [ ])
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
                (subattr "fallback" typeString)
              ]
              (sub "name" typeString)
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
            (subelem "cache" [
              (subattr "level" typeInt)
              (subattr "mode" typeString)
            ] [ ])
            (subelem "feature" [
              (subattr "policy" typeString)
              (subattr "name" typeString)
            ] [ ])
          ]
        )
        (subelem "clock"
          [
            (subattr "offset" typeString)
            (subattr "timezone" typeString)
          ]
          [
            (subelem "timer"
              [
                (subattr "name" typeString)
                (subattr "track" typeString)
                (subattr "tickpolicy" typeString)
                (subattr "frequency" typeInt)
                (subattr "mode" typeString)
                (subattr "present" typeBoolYesNo)
              ]
              [
                (subelem "catchup"
                  [
                    (subattr "threshold" typeInt)
                    (subattr "slew" typeInt)
                    (subattr "limit" typeInt)
                  ] [ ]
                )
              ]
            )
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
              (subelem "disk"
                [
                  (subattr "type" typeString)
                  (subattr "device" typeString)
                  (subattr "model" typeString)
                  (subattr "snapshot" typeBoolYesNo)
                ]
                (
                  let
                    backingStuff =
                      [
                        (subelem "source"
                          [
                            (subattr "file" typePath)
                            (subattr "startupPolicy" typeString)
                            (subattr "protocol" typeString)
                            (subattr "name" typeString)
                            (subattr "query" typeString)
                            (subattr "dev" typePath)
                            (subattr "index" typeInt)
                            (subattr "pool" typeString)
                            (subattr "volume" typeString)
                            (subattr "dir" typePath)
                            (subattr "type" typeString)
                            (subattr "path" typePath)
                          ]
                          [
                            (subelem "host"
                              [
                                (subattr "name" typeString)
                                (subattr "port" typeInt)
                              ]
                              [ ])
                          ])
                        (subelem "backingStore" [ (subattr "type" typeString) ]
                          (
                            [
                              (subelem "format" [ (subattr "type" typeString) ] [ ])
                            ] ++
                            backingStuff
                          )
                        )
                      ];
                  in
                  [
                    (subelem "driver"
                      [
                        (subattr "name" typeString)
                        (subattr "type" typeString)
                        (subattr "cache" typeString)
                        (subattr "io" typeString)
                        (subattr "discard" typeString)
                      ] [ ]
                    )
                  ] ++
                  backingStuff ++
                  [
                    targetelem
                    (subelem "readonly" [ ] [ ])
                    addresselem
                    (subelem "boot" [ (subattr "order" typeInt) ] [ ])
                    (subelem "serial" [ ] typeString)
                  ]
                )
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
                  (subelem "binary" [ (subattr "path" typePath) (subattr "xattr" typeBoolOnOff) ] [ ])
                  (subelem "source" [ (subattr "dir" typePath) (subattr "name" typeString) ] [ ])
                  (subelem "target" [ (subattr "dir" typePath) ] [ ])
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
              (subelem "hostdev"
                [
                  (subattr "mode" typeString)
                  (subattr "type" typeString)
                  (subattr "managed" typeBoolYesNo)
                ]
                [
                  (subelem "driver" [ (subattr "name" typeString) (subattr "model" typeString) ] [ ])
                  (subelem "source" [ ]
                    [
                      (subelem "vendor" [ (subattr "id" typeInt) ] [ ])
                      (subelem "product" [ (subattr "id" typeInt) ] [ ])
                      addresselem
                    ]
                  )
                  (subelem "boot" [ (subattr "order" typeInt) ] [ ])
                  addresselem
                ]
              )
              (subelem "shmem"
                [
                  (subattr "name" typeString)
                ]
                [
                  (subelem "model" [ (subattr "type" typeString) ] [ ])
                  (subelem "size" [ (subattr "unit" typeString) ] (sub "count" typeInt))
                ]
              )
              (subelem "interface"
                [
                  (subattr "type" typeString)
                  (subattr "trustGuestRxFilters" typeBoolYesNo)
                ]
                [
                  (subelem "mac" [ (subattr "address" typeString) ] [ ])
                  (subelem "source"
                    [
                      (subattr "bridge" typeString)
                      (subattr "dev" typeString)
                      (subattr "mode" typeString)
                      (subattr "network" typeString)
                      (subattr "type" typeString)
                      # this typically points to a socket (/tmp/my.sock), so don't use typePath, which only allows in-store elements.
                      (subattr "path" typeString)
                    ] [
                    addresselem
                    (subelem "reconnect" [ (subattr "enabled" typeBoolYesNo) (subattr "timeout" typeInt) ] [ ])
                  ])
                 (subelem "model" [ (subattr "type" typeString) ] [ ])
                  targetelem
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
              (subelem "input"
                [
                  (subattr "type" typeString)
                  (subattr "bus" typeString)
                ]
                [
                  (subelem "source"
                    [
                      (subattr "dev" typeString)
                      (subattr "grab" typeString)
                      (subattr "grabToggle" typeString)
                      (subattr "repeat" typeBoolOnOff)
                    ] [ ])
                  addresselem
                ])
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
                  (subelem "gl" [ (subattr "enable" typeBoolYesNo) (subattr "rendernode" typeString) ] [ ])
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
                      (subattr "blob" typeBoolOnOff)
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
              (subelem "memballoon"
                [
                  (subattr "model" typeString)
                  (subattr "autodeflate" typeBoolOnOff)
                  (subattr "freePageReporting" typeBoolOnOff)
                ]
                [ addresselem ])
              (subelem "vsock" [ (subattr "model" typeString) ]
                [
                  (subelem "cid" [ (subattr "auto" typeBoolYesNo) (subattr "address" typeInt) ] [ ])
                  addresselem
                ])
            ]
        )
        (sub "qemu-commandline" (elem "commandline"
          [ (attr "xmlns" (typeConstant "http://libvirt.org/schemas/domain/qemu/1.0")) ]
          [
            (subelem "arg" [ (subattr "value" typeString) ] [ ])
            (subelem "env" [ (subattr "name" typeString) (subattr "value" typeString) ] [ ])
          ]))
        (sub "qemu-override" (elem "override"
          [ (attr "xmlns" (typeConstant "http://libvirt.org/schemas/domain/qemu/1.0")) ]
          [
            (subelem "device"
              [
                (subattr "alias" typeString)
              ]
              [
                (subelem "frontend" [ ]
                  [
                    (subelem "property"
                      [ (subattr "name" typeString) (subattr "type" typeString) (subattr "value" typeString) ]
                      [ ])
                  ])
              ])
          ]))
      ];

in
obj: xml.toText (process obj)
