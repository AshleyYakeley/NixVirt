packages: { name, uuid, memory ? { count = 2; unit = "GiB"; }, hdpath, mac_address, cdpath ? null }:
{
  type = "kvm";
  inherit name uuid memory;

  os =
    {
      type = "hvm";
      arch = "x86_64";
      machine = "pc-q35-8.1";
      boot = [{ dev = "cdrom"; } { dev = "hd"; }];
    };
  features =
    {
      acpi = { };
      apic = { };
    };
  clock =
    {
      offset = "utc";
      timer =
        [
          { name = "rtc"; tickpolicy = "catchup"; }
          { name = "pit"; tickpolicy = "delay"; }
          { name = "hpet"; present = false; }
        ];
    };
  devices =
    {
      emulator = "${packages.qemu}/bin/qemu-system-x86_64";
      disk =
        [
          {
            type = "file";
            device = "disk";
            driver =
              {
                name = "qemu";
                type = "qcow2";
                discard = "unmap";
              };
            source = { file = hdpath; };
            target = { dev = "vda"; };
          }
          {
            type = "file";
            device = "cdrom";
            driver =
              {
                name = "qemu";
                type = "raw";
              };
            source = if builtins.isNull cdpath then null else { file = cdpath; };
            target = { dev = "hdc"; };
            readonly = true;
          }
        ];
      interface =
        {
          type = "bridge";
          mac = { address = mac_address; };
          source = { bridge = "virbr0"; };
          model = { type = "virtio"; };
        };
      channel =
        [
          {
            type = "unix";
            target = { type = "virtio"; name = "org.qemu.guest_agent.0"; };
            address = { type = "virtio-serial"; controller = 0; bus = 0; port = 1; };
          }
          {
            type = "spicevmc";
            target = { type = "virtio"; name = "com.redhat.spice.0"; };
            address = { type = "virtio-serial"; controller = 0; bus = 0; port = 2; };
          }
        ];
      input =
        [
          { type = "mouse"; bus = "ps2"; }
          { type = "keyboard"; bus = "ps2"; }
        ];
      graphics =
        {
          type = "spice";
          autoport = true;
          listen = { type = "address"; };
          image = { compression = false; };
        };
      sound = { model = "ich9"; };
      audio = { id = 1; type = "spice"; };
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
            };
        };
      redirdev =
        [
          { bus = "usb"; type = "spicevmc"; }
          { bus = "usb"; type = "spicevmc"; }
        ];
      rng =
        {
          model = "virtio";
          backend = { model = "random"; source = /dev/urandom; };
        };
    };
}
