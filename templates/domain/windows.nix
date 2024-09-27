# https://www.microsoft.com/en-us/windows/windows-11-specifications
# https://sysguides.com/install-a-windows-11-virtual-machine-on-kvm
stuff@{ packages, OVMFFull, guest-install, ... }:
{ name
, uuid
, memory ? { count = 4; unit = "GiB"; }
, storage_vol ? null
, install_vol ? null
, nvram_path
, virtio_net ? false
, virtio_drive ? false
, virtio_video ? true
, install_virtio ? false
, ...
}:
let
  basestuff = import ./base.nix stuff;
  base = basestuff.q35
    {
      inherit name uuid memory storage_vol install_vol virtio_net virtio_video;
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
        path = "${OVMFFull.fd}/FV/OVMF_CODE.ms.fd";
      };
    nvram =
      {
        template = "${OVMFFull.fd}/FV/OVMF_VARS.ms.fd";
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
    disk = (if builtins.isNull storage_vol then [ ] else [ (basestuff.mkstorage virtio_drive storage_vol) ]) ++
    [
      {
        type = "file";
        device = "cdrom";
        driver = { name = "qemu"; type = "raw"; };
        source =
          if builtins.isNull install_vol then null else
          {
            file = install_vol;
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
  };
}
