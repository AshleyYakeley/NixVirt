packages:
let
  objtype = name: getXML:
    {
      inherit getXML;
      writeXML = obj: packages.writeTextFile
        {
          name = "NixVirt-" + name + "-" + obj.name;
          text = getXML obj;
        };
    };
  guest-install = import ./guest-install.nix packages;
  stuff = { inherit packages guest-install; };
in
{
  xml = import generate-xml/xml.nix;
  domain = objtype "domain" (import generate-xml/domain.nix) // { templates = import ./templates/domain.nix stuff; };
  network = objtype "network" (import generate-xml/network.nix) // { templates = import ./templates/network.nix stuff; };
  pool = objtype "pool" (import generate-xml/pool.nix);
  inherit guest-install;
}
