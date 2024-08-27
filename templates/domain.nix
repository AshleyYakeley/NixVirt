stuff:
let
  base = import domain/base.nix stuff;
in
base
// {
  linux = import domain/linux.nix stuff;
  windows = import domain/windows.nix stuff;
}
