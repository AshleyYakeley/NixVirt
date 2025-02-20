stuff@{ packages, ... }:
{ name
, uuid
, memory ? { count = 4; unit = "GiB"; }
, storage_vol ? null
, backing_vol ? null
, install_vol ? null
, bridge_name ? "virbr0"
, net_iface_mac ? null
, virtio_drive ? true
, virtio_video ? true
, ...
}:
let
  base = (import ./base.nix stuff).q35
    {
      inherit name uuid memory storage_vol backing_vol install_vol bridge_name net_iface_mac virtio_drive virtio_video;
      virtio_net = true;
    };
in
base //
{
  devices = base.devices //
  {
    channel = base.devices.channel ++
    [
      {
        type = "unix";
        target = { type = "virtio"; name = "org.qemu.guest_agent.0"; };
      }
    ];
    rng =
      {
        model = "virtio";
        backend = { model = "random"; source = /dev/urandom; };
      };
  };
}
