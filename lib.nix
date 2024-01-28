pkgs:
let
    xml = import ./xml.nix;

    domainXML = with xml; domain: toText
    (
        elem "domain" {type = domain.type;}
        [
            (elem "name" {} domain.name)
            (elem "uuid" {} domain.uuid)
            (elem "title" {} domain.title)
        ]
    );
in
{
    inherit xml;

    inherit domainXML;

    writeDomainXML = domain: pkgs.writeTextFile
    {
        name = "NixVirt-domain-" + domain.name;
        text = domainXML domain;
    };
}
