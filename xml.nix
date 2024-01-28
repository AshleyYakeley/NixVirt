with builtins;
let
    indentLine = i: s:
        if i == 0 then s + "\n" else "  " + indentLine (i - 1) s;

    quoteAttr = s: "'" + s + "'"; # TBD

    escapeText = s: s; # TBD

    concat = concatStringsSep "";

    none = i: "";

    opt = t: e:
        if t then e else none;

    many = ee: i: concat (map (e: e i) ee);

    elem = etype: aa: body: i:
        let
            attrs = concat (map (n: " " + n + "=" + quoteAttr (getAttr n aa)) (attrNames aa));
            head = etype + attrs;
        in
        if isNull body
        then indentLine i ("<" + head + "/>")
        else if isString body
        then if body == ""
            then indentLine i ("<" + head + "/>")
            else indentLine i ("<" + head + ">" + escapeText body + "</" + etype + ">")
        else if isList body
        then if body == []
            then indentLine i ("<" + head + "/>")
            else
                indentLine i ("<" + head + ">") +
                many body (i + 1) +
                indentLine i ("</" + etype + ">")
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
