{
  description = "LibVirt domain management";

  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-23.11";
    };

    nixpkgs-ovmf = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-unstable";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-ovmf,
    }:
    let
      system = "x86_64-linux";

      packages = import nixpkgs { inherit system; };
      packages-ovmf = import nixpkgs-ovmf { inherit system; };

    in
    import ./default.nix {
      inherit system;

      pkgs = packages;
      OVMFFull = packages-ovmf.OVMFFull;
    };
}
