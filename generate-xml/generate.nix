let
  xml = import ./xml.nix;

  many = contents: subject: xml.many (map1 contents subject);
  yesno = t: if t then "yes" else "no";
  onoff = t: if t then "on" else "off";
  map1 = f: x: if builtins.isList x then builtins.map f x else [ (f x) ];
  id = x: x;

  typeCheck = tname: test: x:
    if test x then x else builtins.abort ("NixVirt: expected " + tname + ", found " + builtins.typeOf x);

  typeConvert = tname: test: conv: x: conv (typeCheck tname test x);

  attrOrNull = a: subject:
    if builtins.hasAttr a subject then builtins.getAttr a subject else null;

  checkNull = f: x: xml.opt (!(isNull x)) (f x);

in
rec
{
  sub = with builtins;
    a: contents: checkNull (x: checkNull contents (attrOrNull a (typeCheck "set or null" isAttrs x)));

  elem = with builtins;
    etype: attrs: contents: subject:
      xml.elem etype
        (map (a: a subject) attrs)
        (if isList contents then map (c: c subject) contents else contents subject);

  subelemraw = etype: attrs: sub etype (elem etype attrs id);

  attr = atype: contents: subject: xml.attr atype (contents subject);

  subattr = atype: contents: sub atype (attr atype contents);

  subelem = etype: attrs: contents: sub etype (many (elem etype attrs contents));

  typeConstant = c: x: c;
  typeString = typeConvert "string" builtins.isString id;
  typeInt = typeConvert "int" builtins.isInt builtins.toString;
  typeBoolYesNo = typeConvert "bool" builtins.isBool yesno;
  typeBoolOnOff = typeConvert "bool" builtins.isBool onoff;
  typePath = typeConvert "path or string" (x: builtins.isPath x || builtins.isString x) builtins.toString;
}
