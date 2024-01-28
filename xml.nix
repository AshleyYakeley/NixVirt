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

    toText = e: e 0;
in
{
    inherit elem;
    inherit toText;
}
