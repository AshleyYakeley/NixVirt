stuff:
let
  objtype = name: getXML: {
    inherit getXML;
    writeXML =
      obj:
      stuff.packages.writeTextFile {
        name = "NixVirt-" + name + "-" + obj.name;
        text = getXML obj;
      };
  };
  guest-install = import ./guest-install.nix stuff.packages;
  stuff1 = stuff // {
    inherit guest-install;
  };
in
{
  xml = import generate-xml/xml.nix;
  domain = objtype "domain" (import generate-xml/domain.nix) // {
    templates = import ./templates/domain.nix stuff1;
  };
  network = objtype "network" (import generate-xml/network.nix) // {
    templates = import ./templates/network.nix stuff1;
  };
  pool = objtype "pool" (import generate-xml/pool.nix);
  volume = objtype "volume" (import generate-xml/volume.nix);
  inherit guest-install;
}
