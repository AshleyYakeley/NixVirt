{ packages, ... }:
let
  mksourcetype = with builtins;
    src:
    if isAttrs src && src ? "volume" then "volume"
    else "file";
  mksource = with builtins;
    src:
    if isString src || isPath src then { file = src; }
    else src;
  mkbackingstore = with builtins;
    backing:
    if isAttrs backing || isNull backing then backing
    else {
      type = mksourcetype backing;
      format = { type = "qcow2"; };
      source = mksource backing;
      backingStore = { };
    };
  mkstorage = virtio_drive: storage_vol: backing_vol:
    {
      type = mksourcetype storage_vol;
      device = "disk";
      driver =
        {
          name = "qemu";
          type = "qcow2";
          cache = "none";
          discard = "unmap";
        };
      source = mksource storage_vol;
      backingStore = mkbackingstore backing_vol;
      target =
        if virtio_drive
        then { dev = "vda"; bus = "virtio"; }
        else
          { dev = "sda"; bus = "sata"; };
    };
  base = machinetype: cdtarget:
    { name
    , uuid
    , memory ? { count = 2; unit = "GiB"; }
    , storage_vol ? null
    , backing_vol ? null
    , install_vol ? null
    , bridge_name ? "virbr0"
    , virtio_drive ? true
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
          machine = machinetype;
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
          disk = (if builtins.isNull storage_vol then [ ] else [ (mkstorage virtio_drive storage_vol backing_vol) ]) ++
            [
              {
                type = mksourcetype install_vol;
                device = "cdrom";
                driver =
                  {
                    name = "qemu";
                    type = "raw";
                  };
                source = mksource install_vol;
                target = cdtarget;
                readonly = true;
              }
            ];
          interface =
            {
              type = "bridge";
              model = if virtio_net then { type = "virtio"; } else null;
              source = { bridge = bridge_name; };
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
    };
in
{
  inherit mkstorage;
  pc = base "pc" { dev = "hdc"; bus = "ide"; };
  q35 = base "q35" { dev = "sdc"; bus = "sata"; };
}
