pkgs: mklib:
let
  lib = mklib
    {
      writeTextFile = pkgs.writeTextFile;
      qemu = "QEMU_PATH";
      OVMFFull.fd = "OVMFFull_FD_PATH";
    };
  test = xlib: dirpath:
    let
      found = xlib.writeXML ((import "${dirpath}/input.nix") lib);
      expected = "${dirpath}/expected.xml";
    in
    pkgs.runCommand "check" { }
      ''
        diff -u ${expected} ${found}
        echo "pass" > $out
      '';
in
{
  network-empty = test lib.network network/empty;
  network-bridge = test lib.network network/bridge;

  domain-empty = test lib.domain domain/empty;
  domain-linux = test lib.domain domain/template-linux;
  domain-windows = test lib.domain domain/template-windows;
  domain-win11 = test lib.domain domain/win11;

  pool-empty = test lib.pool pool/empty;
}
