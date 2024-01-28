pkgs:
let
    indentLine = i: s:
        if i == 0 then s + "\n" else "  " + indentLine (i - 1) s;

    quoteAttr = s: "'" + s + "'"; # TBD

    attrs = with builtins;
        aa: concatStringsSep "" (map (n: " " + n + "=" + quoteAttr (getAttr n aa)) (attrNames aa));

    escapeText = s: s; # TBD

    elem = etype: aa: body: i:
        if builtins.isString body
        then indentLine i ("<" + etype + attrs aa + ">" + escapeText body + "</" +etype + ">")
        else if builtins.isList body
        then
            indentLine i ("<" + etype + attrs aa + ">") +
            builtins.concatStringsSep "" (builtins.map (e: e (i + 1)) body) +
            indentLine i ("</" +etype + ">")
        else builtins.throw "XML: not text or list"
        ;

    toXML = e: e 0;

    domainXML = domain: toXML
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
    inherit domainXML;

    writeDomainXML = domain: pkgs.writeTextFile
    {
        name = "NixVirt-domain-" + domain.name;
        text = domainXML domain;
    };
}
