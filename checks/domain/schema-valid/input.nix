{ ... }:
{
  type = "kvm";
  name = "schema-valid";

  memory = {
    unit = "KiB";
    count = 1048576;
  };
  vcpu.count = 2;
  iothreads.count = 2;

  os.type = "hvm";

  cpu = {
    cache.mode = "passthrough";
    maxphysaddr = {
      mode = "emulate";
      bits = 48;
    };
  };

  devices = {
    emulator = "/usr/bin/qemu-system-x86_64";

    disk = {
      type = "file";
      device = "disk";
      driver = {
        name = "qemu";
        type = "qcow2";
        queues = 2;
        iothread = 1;
      };
      source.file = "/var/lib/libvirt/images/schema-valid.qcow2";
      target = {
        dev = "vda";
        bus = "virtio";
      };
      address = {
        type = "pci";
        domain = 0;
        bus = 0;
        slot = 6;
        function = 0;
      };
    };

    controller = [
      {
        type = "usb";
        index = 0;
        model = "qemu-xhci";
      }
      {
        type = "scsi";
        index = 0;
        model = "virtio-scsi";
        driver = {
          queues = 2;
          iothread = 2;
        };
        address = {
          type = "pci";
          domain = 0;
          bus = 0;
          slot = 5;
          function = 0;
        };
      }
    ];

    hub = {
      type = "usb";
      address = {
        type = "usb";
        bus = 0;
        port = 1;
      };
    };
  };
}
