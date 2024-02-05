let
    xml = import ./xml.nix;
in rec
{
    yesno = t: if t then "yes" else "no";
    onoff = t: if t then "on" else "off";
    map1 = f: x: if builtins.isList x then builtins.map f x else [(f x)];
    id = x: x;

    sub = with builtins;
        a: contents: subject:
            xml.opt (hasAttr a subject) (contents (getAttr a subject));

    elem = with builtins;
        etype: attrs: contents: subject:
            xml.elem etype
                (map (a: a subject) attrs)
                (if isList contents then map (c: c subject) contents else contents subject);

    subelem = etype: attrs: contents: sub etype (elem etype attrs contents);

    attr = atype: contents: subject: xml.attr atype (contents subject);

    subattr = atype: contents: sub atype (attr atype contents);

    many = contents: subject: xml.many (map1 contents subject);

    submanyelem = etype: attrs: contents: sub etype (many (elem etype attrs contents));

    opt = contents: subject: xml.opt subject (contents subject);

    suboptelem = etype: attrs: contents: sub etype (opt (elem etype attrs contents));

    checkType = tname: test: conv: x:
        if test x then conv x else builtins.abort ("expected " + tname + ", found " + builtins.typeOf x + " (" + builtins.toString x + ")");

    typeString = checkType "string" builtins.isString id;
    typeInt = checkType "int" builtins.isInt builtins.toString;
    typeBoolYesNo = checkType "bool" builtins.isBool yesno;
    typeBoolOnOff = checkType "bool" builtins.isBool onoff;
    typePath = checkType "path or string" (x: builtins.isPath x || builtins.isString x) builtins.toString;
}
