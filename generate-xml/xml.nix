with builtins;
let
  indentLine = i: s:
    if i == 0 then s + "\n" else "  " + indentLine (i - 1) s;

  escapeText = replaceStrings [ "&" "<" ">" "'" "\"" ] [ "&amp;" "&lt;" "&gt;" "&apos;" "&quot;" ];

  concat = concatStringsSep "";

  none = i: "";

  opt = t: e:
    if t then e else none;

  many = ee: i: concat (map (e: e i) ee);

  attr = n: v: i: " " + n + "='" + escapeText v + "'";

  elem = etype: aa: body: i:
    let
      head = "<" + etype + concat (map (a: a i) aa);
      starttag = head + ">";
      endtag = "</" + etype + ">";
      onlytag = head + "/>";
    in
    if isNull body
    then indentLine i onlytag
    else if isString body
    then if body == ""
    then indentLine i onlytag
    else indentLine i (starttag + escapeText body + endtag)
    else if isList body
    then
      let
        contents = many body (i + 1);
      in
      if contents == ""
      then indentLine i onlytag
      else
        indentLine i starttag +
        contents +
        indentLine i endtag
    else throw "XML: not text or list"
  ;

  toText = e: e 0;
in
{
  inherit none opt many attr elem toText;
}
