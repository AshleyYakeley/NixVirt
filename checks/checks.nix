stuff: mklib:
let
  lib = mklib stuff;
  teststuff =
    {
      packages =
        {
          writeTextFile = stuff.packages.writeTextFile;
          runCommand = name: args: script: "BUILD " + name;
          qemu = "QEMU_PATH";
        };
      packages-ovmf =
        {
          OVMFFull.fd = "OVMFFull_FD_PATH";
        };
    };
  testlib = mklib teststuff;
  test = xlib: dirpath:
    let
      found = xlib.writeXML (import "${dirpath}/input.nix" testlib);
      expected = "${dirpath}/expected.xml";
    in
    stuff.packages.runCommand "check" { }
      ''
        diff -u ${expected} ${found}
        echo "pass" > $out
      '';
in
{
  network-empty = test testlib.network network/empty;
  network-bridge = test testlib.network network/bridge;

  domain-empty = test testlib.domain domain/empty;
  domain-linux = test testlib.domain domain/template-linux;
  domain-windows-1 = test testlib.domain domain/template-windows-1;
  domain-windows-2 = test testlib.domain domain/template-windows-2;
  domain-windows-3 = test testlib.domain domain/template-windows-3;
  domain-win11 = test testlib.domain domain/win11;

  pool-empty = test testlib.pool pool/empty;

  volume-typical = test testlib.volume volume/typical;

  virtio-iso = lib.guest-install.virtio-win.iso;

  ovmf-secboot =
    stuff.packages.runCommand "ovmf-secboot" { }
      ''
        test -f ${stuff.packages-ovmf.OVMFFull.fd}/FV/OVMF_CODE.ms.fd
        test -f ${stuff.packages-ovmf.OVMFFull.fd}/FV/OVMF_VARS.ms.fd
        echo "pass" > $out
      '';
}
