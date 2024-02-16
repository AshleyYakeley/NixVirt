stuff:
{
  base = import domain/base.nix stuff;
  linux = import domain/linux.nix stuff;
  windows = import domain/windows.nix stuff;
}
