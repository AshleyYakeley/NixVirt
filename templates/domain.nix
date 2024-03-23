stuff:
{
  pc-i440fx = import domain/pc-i440fx.nix stuff;
  pc-q35 = import domain/pc-q35.nix stuff;
  linux = import domain/linux.nix stuff;
  windows = import domain/windows.nix stuff;
}
