stuff:
let
  base = import domain/base.nix stuff;
in
base //
{
  linux = import domain/linux.nix stuff;
  linux-microvm = import domain/linux-microvm.nix stuff;
  windows = import domain/windows.nix stuff;
}
