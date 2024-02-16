packages: mklib:
let
  lib = mklib packages;
  testlib = mklib
    {
      writeTextFile = packages.writeTextFile;
      runCommand = name: args: script: "BUILD " + name;
      qemu = "QEMU_PATH";
      OVMFFull.fd = "OVMFFull_FD_PATH";
    };
  test = xlib: dirpath:
    let
      found = xlib.writeXML (import "${dirpath}/input.nix" testlib);
      expected = "${dirpath}/expected.xml";
    in
    packages.runCommand "check" { }
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
  domain-windows = test testlib.domain domain/template-windows;
  domain-win11 = test testlib.domain domain/win11;

  pool-empty = test testlib.pool pool/empty;

  virtio-iso = lib.guest-install.virtio-win.iso;
}
