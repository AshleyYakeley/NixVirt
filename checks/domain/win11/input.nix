xml:
{
  type = "kvm";
  name = "Win11";
  uuid = "ee43005c-2e7b-4af2-bfae-8c52eeb22672";
  metadata = with xml;
    [
      (elem "boxes:gnome-boxes" [ (attr "xmlns:boxes" "https://wiki.gnome.org/Apps/Boxes") ]
        [
          (elem "os-state" [ ] "installation")
          (elem "media-id" [ ] "http://microsoft.com/win/11:0")
          (elem "media" [ ] "/SourceMedia/Win11_23H2_EnglishInternational_x64v2.iso")
        ])
      (elem "libosinfo:libosinfo" [ (attr "xmlns:libosinfo" "http://libosinfo.org/xmlns/libvirt/domain/1.0") ]
        [
          (elem "libosinfo:os" [ (attr "id" "http://microsoft.com/win/11") ] [ ])
        ])
      (elem "edited:edited" [ (attr "xmlns:edited" "https://wiki.gnome.org/Apps/Boxes/edited") ] "2024-01-25T22:39:41-0800")
    ];
  memory = { count = 4194304; unit = "KiB"; };
  vcpu =
    {
      placement = "static";
      count = 16;
    };
  os =
    {
      type = "hvm";
      arch = "x86_64";
      machine = "pc-q35-8.1";
      loader =
        {
          readonly = true;
          type = "pflash";
          path = "/Storage/OVMF/OVMF_CODE_4M.secboot.fd";
        };
      nvram = { path = "/Storage/OVMF/OVMF_VARS_4M.fd"; };
      boot = [{ dev = "cdrom"; } { dev = "hd"; }];
      bootmenu = { enable = true; };
    };
  features =
    {
      acpi = { };
      apic = { };
    };
  cpu =
    {
      mode = "host-passthrough";
      check = "none";
      migratable = true;
      topology =
        {
          sockets = 1;
          dies = 1;
          cores = 8;
          threads = 2;
        };
    };
  clock =
    {
      offset = "localtime";
      timer =
        [
          { name = "rtc"; tickpolicy = "catchup"; }
          { name = "pit"; tickpolicy = "delay"; }
          { name = "hpet"; present = false; }
        ];
    };
  on_poweroff = "destroy";
  on_reboot = "destroy";
  on_crash = "destroy";
  pm =
    {
      suspend-to-mem = { enabled = false; };
      suspend-to-disk = { enabled = false; };
    };
  devices =
    let
      pci_address = bus: slot: function:
        {
          type = "pci";
          domain = 0;
          bus = bus;
          slot = slot;
          inherit function;
        };
      usb_address = port:
        {
          type = "usb";
          bus = 0;
          inherit port;
        };
      drive_address = unit:
        {
          type = "drive";
          controller = 0;
          bus = 0;
          target = 0;
          inherit unit;
        };
    in
    {
      emulator = "/run/current-system/sw/bin/qemu-system-x86_64";
      disk =
        [
          {
            type = "file";
            device = "disk";
            driver =
              {
                name = "qemu";
                type = "qcow2";
                cache = "writeback";
              };
            source =
              {
                file = /Storage/Win11.qcow3;
              };
            target =
              {
                bus = "sata";
                dev = "sda";
              };
            address = drive_address 0;
          }
          {
            type = "file";
            device = "cdrom";
            driver =
              {
                name = "qemu";
                type = "raw";
              };
            source =
              {
                file = /SourceMedia/Win11_23H2_EnglishInternational_x64v2.iso;
                startupPolicy = "mandatory";
              };
            target =
              {
                bus = "sata";
                dev = "hdc";
              };
            readonly = true;
            address = drive_address 2;
          }
        ];
      controller =
        [
          {
            type = "usb";
            index = 0;
            model = "qemu-xhci";
            ports = 15;
            address = pci_address 3 0 0;
          }
          {
            type = "sata";
            index = 0;
            address = pci_address 0 31 2;
          }
          {
            type = "pci";
            index = 0;
            model = "pcie-root";
          }
          {
            type = "virtio-serial";
            index = 0;
            address = pci_address 4 0 0;
          }
          {
            type = "ccid";
            index = 0;
            address = usb_address 1;
          }
          {
            type = "pci";
            index = 1;
            model = "pcie-root-port";
            address = pci_address 0 2 0 // { multifunction = true; };
          }
          {
            type = "pci";
            index = 2;
            model = "pcie-to-pci-bridge";
            address = pci_address 1 0 0;
          }
          {
            type = "pci";
            index = 3;
            model = "pcie-root-port";
            address = pci_address 0 2 1;
          }
          {
            type = "pci";
            index = 4;
            model = "pcie-root-port";
            address = pci_address 0 2 2;
          }
          {
            type = "pci";
            index = 5;
            model = "pcie-root-port";
            address = pci_address 0 2 3;
          }
          {
            type = "pci";
            index = 6;
            model = "pcie-root-port";
            address = pci_address 0 2 4;
          }
        ];
      interface =
        {
          type = "bridge";
          mac = { address = "52:54:00:10:c4:28"; };
          source = { bridge = "virbr0"; };
          model = { type = "virtio"; };
          address = pci_address 2 1 0;
        };
      smartcard =
        {
          mode = "passthrough";
          type = "spicevmc";
          address =
            {
              type = "ccid";
              controller = 0;
              slot = 0;
            };
        };
      serial =
        {
          type = "pty";
          target =
            {
              type = "isa-serial";
              port = 0;
              model = { name = "isa-serial"; };
            };
        };
      console =
        {
          type = "pty";
          target = { type = "serial"; port = 0; };
        };
      channel =
        [
          {
            type = "spicevmc";
            target =
              {
                type = "virtio";
                name = "com.redhat.spice.0";
              };
            address =
              {
                type = "virtio-serial";
                controller = 0;
                bus = 0;
                port = 1;
              };
          }
          {
            type = "spiceport";
            source =
              {
                channel = "org.spice-space.webdav.0";
              };
            target =
              {
                type = "virtio";
                name = "org.spice-space.webdav.0";
              };
            address =
              {
                type = "virtio-serial";
                controller = 0;
                bus = 0;
                port = 2;
              };
          }
        ];
      input =
        [
          {
            type = "tablet";
            bus = "usb";
            address = usb_address 2;
          }
          {
            type = "mouse";
            bus = "ps2";
          }
          {
            type = "keyboard";
            bus = "ps2";
          }
        ];
      tpm =
        {
          model = "tpm-crb";
          backend =
            {
              type = "emulator";
              version = "2.0";
            };
        };
      graphics =
        {
          type = "spice";
          listen = { type = "none"; };
          image = { compression = false; };
          gl = { enable = false; };
        };
      sound =
        {
          model = "ich9";
          address = pci_address 0 27 0;
        };
      audio =
        {
          id = 1;
          type = "spice";
        };
      video =
        {
          model =
            {
              type = "qxl";
              ram = 65536;
              vram = 65536;
              vgamem = 16384;
              heads = 1;
              primary = true;
              acceleration = { accel3d = false; };
            };
          address = pci_address 0 1 0;
        };
      redirdev =
        [
          {
            bus = "usb";
            type = "spicevmc";
            address = usb_address 3;
          }
          {
            bus = "usb";
            type = "spicevmc";
            address = usb_address 4;
          }
          {
            bus = "usb";
            type = "spicevmc";
            address = usb_address 5;
          }
          {
            bus = "usb";
            type = "spicevmc";
            address = usb_address 6;
          }
        ];
      watchdog =
        {
          model = "itco";
          action = "reset";
        };
    };
}
