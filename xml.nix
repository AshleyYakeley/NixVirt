with builtins;
let
    indentLine = i: s:
        if i == 0 then s + "\n" else "  " + indentLine (i - 1) s;

    quoteAttr = s: "'" + s + "'"; # TBD

    attrs = aa: concatStringsSep "" (map (n: " " + n + "=" + quoteAttr (getAttr n aa)) (attrNames aa));

    escapeText = s: s; # TBD

    concat = concatStringsSep "";

    none = i: "";

    opt = t: e:
        if t then e else none;

    many = ee: i: concat (map (e: e i) ee);

    elem = etype: aa: body: i:
        if isString body
        then if body == ""
            then indentLine i ("<" + etype + attrs aa + "/>")
            else indentLine i ("<" + etype + attrs aa + ">" + escapeText body + "</" +etype + ">")
        else if isList body
        then
            indentLine i ("<" + etype + attrs aa + ">") +
            many body (i + 1) +
            indentLine i ("</" +etype + ">")
        else throw "XML: not text or list"
        ;

    toText = e: e 0;
in
{
    inherit none;
    inherit opt;
    inherit many;
    inherit elem;
    inherit toText;
}
