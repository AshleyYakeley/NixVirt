pkgs:
let
    xml = import ./xml.nix;

    yesno = t: if t then "yes" else "no";
    onoff = t: if t then "on" else "off";

    domainXML = with builtins; with xml; domain: toText
    (
        elem "domain" {type = domain.type;}
        [
            (elem "name" {} domain.name)
            (elem "uuid" {} domain.uuid)
            (elem "title" {} domain.title)
            (elem "metadata" {} domain.metadata)
            (elem "memory" {unit="KiB";} domain.memory)
            (elem "currentMemory" {unit="KiB";} domain.currentMemory)
            (elem "vcpu" {placement=domain.vcpu.placement;} (toString domain.vcpu.count))
            (elem "os" {}
                ([
                    (elem "type" {arch = domain.os.arch;machine = domain.os.machine;} domain.os.type)
                ] ++
                (map (x: elem "boot" {dev=x;} []) domain.os.boot) ++
                [
                    (elem "bootmenu" {enable = yesno domain.os.bootmenu.enable;} [])
                ]
                )
            )
            (elem "features" {}
                [
                    (opt domain.features.acpi (elem "acpi" {} []))
                    (opt domain.features.apic (elem "apic" {} []))
                ]
            )
            (elem "cpu" {mode=domain.cpu.mode;check=domain.cpu.check;migratable=onoff domain.cpu.migratable;}
                [
                    (elem "topology"
                        {
                            sockets=toString domain.cpu.topology.sockets;
                            dies=toString domain.cpu.topology.dies;
                            cores=toString domain.cpu.topology.cores;
                            threads=toString domain.cpu.topology.threads;
                        } []
                    )
                ]
            )
            (elem "clock" {offset=domain.clock.offset;}
                (map (t: elem "timer"
                    {
                        name = t.name;
                    } []) domain.clock.timers)
            )
            (elem "on_poweroff" {} domain.on.poweroff)
            (elem "on_reboot" {} domain.on.reboot)
            (elem "on_crash" {} domain.on.crash)
            (elem "pm" {}
                [
                    (elem "suspend-to-mem" {enabled=yesno domain.pm.suspend-to-mem;} [])
                    (elem "suspend-to-disk" {enabled=yesno domain.pm.suspend-to-disk;} [])
                ]
            )
            (elem "devices" {}
                ([
                    (elem "emulator" {} (toString domain.devices.emulator))
                ] ++
                map (d: elem "disk" {type=d.type;device=d.device;}
                    [
                        (elem "driver" {name=d.driver.name;type=d.driver.type;cache=d.driver.cache;} [])
                        (elem "source" {file=toString d.source.file;} [])
                        (elem "target" {dev=d.target.dev;bus=d.target.bus;} [])
                        (elem "address"
                            {
                                type = d.address.type;
                                controller = toString d.address.controller;
                                bus = toString d.address.bus;
                                target = toString d.address.target;
                                unit = toString d.address.unit;
                            } [])
                    ]) domain.devices.disks
                )
            )
        ]
    );
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
