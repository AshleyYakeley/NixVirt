{
  description = "LibVirt domain management";

  inputs =
    {
      nixpkgs =
        {
          type = "github";
          owner = "shlevy";
          repo = "nixpkgs";
          ref = "ovmf-ms";
        };
    };

  outputs = { self, nixpkgs }:
    let
      packages = import nixpkgs { system = "x86_64-linux"; };

      nixvirtPythonModulePackage = packages.runCommand "nixvirtPythonModulePackage" { }
        ''
          mkdir  -p $out/lib/python3.11/site-packages/
          ln -s ${tool/nixvirt.py} $out/lib/python3.11/site-packages/nixvirt.py
        '' // { pythonModule = packages.python311; };

      pythonInterpreterPackage = packages.python311.withPackages (ps:
        [
          ps.libvirt
          ps.lxml
          ps.xmldiff
          nixvirtPythonModulePackage
        ]);

      setShebang = name: path: packages.runCommand name { }
        ''
          sed -e "1s|.*|\#\!${pythonInterpreterPackage}/bin/python3|" ${path} > $out
          chmod 755 $out
        '';

      virtdeclareFile = setShebang "virtdeclare" tool/virtdeclare;
      moduleHelperFile = setShebang "nixvirt-module-helper" tool/nixvirt-module-helper;

      mklib = import ./lib.nix;

      modules = import ./modules.nix { inherit packages moduleHelperFile; };
    in
    {
      lib = mklib packages;

      apps.x86_64-linux.virtdeclare =
        {
          type = "app";
          program = "${virtdeclareFile}";
        };

      # for debugging
      apps.x86_64-linux.nixvirt-module-helper =
        {
          type = "app";
          program = "${moduleHelperFile}";
        };

      formatter.x86_64-linux = packages.nixpkgs-fmt;

      packages.x86_64-linux.default = packages.runCommand "NixVirt" { }
        ''
          mkdir -p $out/bin
          ln -s ${virtdeclareFile} $out/bin/virtdeclare
        '';

      homeModules.default = modules.homeModule;

      nixosModules.default = modules.nixosModule;

      checks.x86_64-linux = import checks/checks.nix packages mklib;
    };
}
