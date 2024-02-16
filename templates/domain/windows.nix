# https://www.microsoft.com/en-us/windows/windows-11-specifications
# https://sysguides.com/install-a-windows-11-virtual-machine-on-kvm
stuff@{ packages, guest-install, ... }:
{ name
, uuid
, memory ? { count = 4; unit = "GiB"; }
, storage_vol_path
, mac_address
, install_vol_path ? null
, nvram_path
, virtio_net ? false
, virtio_drive ? false
, install_virtio ? false
, ...
}:
let
  base = import ./base.nix stuff
    {
      inherit name uuid memory storage_vol_path mac_address install_vol_path virtio_net;
    };
in
base //
{
  vcpu.count = 2;
  os = base.os //
  {
    loader =
      {
        readonly = true;
        type = "pflash";
        path = "${packages.OVMFFull.fd}/FV/OVMF_CODE.ms.fd";
      };
    nvram =
      {
        template = "${packages.OVMFFull.fd}/FV/OVMF_VARS.ms.fd";
        path = nvram_path;
      };
  };
  features = base.features //
  {
    hyperv =
      {
        mode = "custom";
        relaxed = { state = true; };
        vapic = { state = true; };
        spinlocks = { state = true; retries = 8191; };
        vpindex = { state = true; };
        runtime = { state = true; };
        synic = { state = true; };
        stimer = { state = true; direct = { state = true; }; };
        reset = { state = true; };
        vendor_id = { state = true; value = "KVM Hv"; };
        frequencies = { state = true; };
        reenlightenment = { state = true; };
        tlbflush = { state = true; };
        ipi = { state = true; };
      };
  };
  clock = base.clock //
  {
    offset = "localtime";
    timer = base.clock.timer ++ [{ name = "hypervclock"; present = true; }];
  };
  pm =
    {
      suspend-to-mem = { enabled = false; };
      suspend-to-disk = { enabled = false; };
    };
  devices = base.devices //
  {
    disk =
      [
        {
          type = "file";
          device = "disk";
          driver =
            {
              name = "qemu";
              type = "qcow2";
              cache = "none";
              discard = "unmap";
            };
          source =
            {
              file = storage_vol_path;
            };
          target = if virtio_drive then { dev = "vda"; bus = "virtio"; } else
          { dev = "sda"; bus = "sata"; };
        }
        {
          type = "file";
          device = "cdrom";
          driver = { name = "qemu"; type = "raw"; };
          source =
            if builtins.isNull install_vol_path then null else
            {
              file = install_vol_path;
              startupPolicy = "mandatory";
            };
          target = { bus = "sata"; dev = "hdc"; };
          readonly = true;
        }
      ] ++ (if install_virtio then
        [
          {
            type = "file";
            device = "cdrom";
            driver = { name = "qemu"; type = "raw"; };
            source = { file = "${guest-install.virtio-win.iso}"; };
            target = { bus = "sata"; dev = "hdd"; };
            readonly = true;
          }
        ] else [ ]);
    channel = base.devices.channel ++
    [
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
    graphics = base.devices.graphics //
    {
      listen = { type = "none"; };
      gl = { enable = false; };
    };
    video.model = base.devices.video.model //
    {
      acceleration = { accel3d = false; };
    };
  };
}
