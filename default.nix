{
  system ? "x86_64-linux",
  OVMFFull ? pkgs.OVMFFull, # OVMF Package -> From unstable recommended
  pkgs, # upstream is pinned on NixOS/Pkgs 23.11
  ...
}:
let
  packages = pkgs;

  nixvirtPythonModulePackage =
    packages.runCommand "nixvirtPythonModulePackage" { } ''
      mkdir  -p $out/lib/python3.11/site-packages/
      ln -s ${tool/nixvirt.py} $out/lib/python3.11/site-packages/nixvirt.py
    ''
    // {
      pythonModule = packages.python311;
    };

  pythonInterpreterPackage = packages.python311.withPackages (ps: [
    ps.libvirt
    ps.lxml
    ps.xmldiff
    nixvirtPythonModulePackage
  ]);

  setShebang =
    name: path:
    packages.runCommand name { } ''
      sed -e "1s|.*|\#\!${pythonInterpreterPackage}/bin/python3|" ${path} > $out
      chmod 755 $out
    '';

  virtdeclareFile = setShebang "virtdeclare" tool/virtdeclare;
  moduleHelperFile = setShebang "nixvirt-module-helper" tool/nixvirt-module-helper;

  mklib = import ./lib.nix;

  modules = import ./modules.nix { inherit packages moduleHelperFile; };

  stuff = {
    inherit packages OVMFFull;
  };
in
{
  lib = mklib stuff;

  apps.${system} = {
    virtdeclare = {
      type = "app";
      program = "${virtdeclareFile}";
    };

    # for debugging
    nixvirt-module-helper = {
      type = "app";
      program = "${moduleHelperFile}";
    };
  };

  formatter.${system} = packages.nixpkgs-fmt;

  packages.${system}.default = packages.runCommand "NixVirt" { } ''
    mkdir -p $out/bin
    ln -s ${virtdeclareFile} $out/bin/virtdeclare
  '';

  homeModules.default = modules.homeModule;

  nixosModules.default = modules.nixosModule;

  checks.${system} = import checks/checks.nix stuff mklib;
}
