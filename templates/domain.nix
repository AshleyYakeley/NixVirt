stuff:
{
  pc = import domain/pc.nix stuff;
  q35 = import domain/q35.nix stuff;
  linux = import domain/linux.nix stuff;
  windows = import domain/windows.nix stuff;
}
