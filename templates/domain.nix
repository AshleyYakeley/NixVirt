pkgs:
{
  base = import domain/base.nix pkgs;
  linux = import domain/linux.nix pkgs;
  windows = import domain/windows.nix pkgs;
}
