{ packages, ... }:
{ name
, uuid
, memory ? { count = 2; unit = "GiB"; }
, storage_vol_path
, install_vol_path ? null
, virtio_net ? false
, virtio_video ? true
, ...
}:
{
  type = "kvm";
  inherit name uuid memory;

  os =
    {
      type = "hvm";
      arch = "x86_64";
      machine = "q35";
      boot = [{ dev = "cdrom"; } { dev = "hd"; }];
    };
  features =
    {
      acpi = { };
      apic = { };
    };
  cpu = { mode = "host-passthrough"; };
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
            source = { file = storage_vol_path; };
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
            source = if builtins.isNull install_vol_path then null else { file = install_vol_path; };
            target = { dev = "sdc"; };
            readonly = true;
          }
        ];
      interface =
        {
          type = "bridge";
          model = if virtio_net then { type = "virtio"; } else null;
          source = { bridge = "virbr0"; };
        };
      channel =
        [
          {
            type = "spicevmc";
            target = { type = "virtio"; name = "com.redhat.spice.0"; };
          }
        ];
      input =
        [
          { type = "tablet"; bus = "usb"; }
          { type = "mouse"; bus = "ps2"; }
          { type = "keyboard"; bus = "ps2"; }
        ];
      graphics =
        {
          type = "spice";
          autoport = true;
          listen = { type = "none"; };
          image = { compression = false; };
          gl = { enable = virtio_video; };
        };
      sound = { model = "ich9"; };
      audio = { id = 1; type = "spice"; };
      video =
        {
          model =
            if virtio_video
            then
              {
                type = "virtio";
                heads = 1;
                primary = true;
                acceleration = { accel3d = true; };
              }
            else
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
          { bus = "usb"; type = "spicevmc"; }
          { bus = "usb"; type = "spicevmc"; }
        ];
    };
}
