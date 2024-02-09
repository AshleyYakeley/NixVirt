pkgs: lib:
let
  test = xlib: dirpath:
    let
      found = xlib.writeXML (import "${dirpath}/input.nix");
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
  domain-empty = test lib.domain domain/empty;
  pool-empty = test lib.pool pool/empty;
}
