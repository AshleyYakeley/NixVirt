stuff@{ packages, ... }:
{ name
, uuid
, vcpu ? { count = 2; }
, memory ? { count = 2; unit = "GiB"; }
, storage_vol ? null
, backing_vol ? null
, cloud_init_vol ? null
, bridge_name ? "virbr0"
, net_iface_mac ? null
, ...
}:
let
  base = import ./base.nix stuff;
  inherit (base) mkstorage;
  mksourcetype = src:
    if builtins.isAttrs src && src ? "volume" then "volume" else "file";
  mksource = src:
    if builtins.isString src || builtins.isPath src then { file = src; } else src;
in
{
  type = "kvm";
  inherit name uuid vcpu memory;

  os =
    {
      type = "hvm";
      arch = "x86_64";
      machine = "microvm";
      boot = [{ dev = "hd"; }];
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
        (if builtins.isNull storage_vol then [ ] else [ (mkstorage true storage_vol backing_vol) ]) ++
        (if builtins.isNull cloud_init_vol then [ ] else
          [
            {
              type = mksourcetype cloud_init_vol;
              device = "disk";
              driver =
                {
                  name = "qemu";
                  type = "raw";
                };
              source = mksource cloud_init_vol;
              target = { dev = "vdb"; bus = "virtio"; };
              readonly = true;
            }
          ]);
      interface =
        {
          type = "bridge";
          model = { type = "virtio"; };
          mac = if builtins.isNull net_iface_mac then null else { address = net_iface_mac; };
          source = { bridge = bridge_name; };
        };
      channel =
        [
          {
            type = "unix";
            target = { type = "virtio"; name = "org.qemu.guest_agent.0"; };
          }
        ];
      serial = { type = "pty"; };
      console = { type = "pty"; target = { type = "virtio"; }; };
      rng =
        {
          model = "virtio";
          backend = { model = "random"; source = /dev/urandom; };
        };
    };
}