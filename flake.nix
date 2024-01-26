{
    description = "LibVirt domain management";

    inputs =
    {
        nixpkgs =
        {
            type = "github";
            owner = "NixOS";
            repo = "nixpkgs";
            ref = "nixos-23.11";
        };
    };

    outputs = { self, nixpkgs }:
    let
        pkgs = import nixpkgs {system = "x86_64-linux";};
        pythonPkg = pkgs.python3.withPackages(ps: [ps.libvirt]);
        virtdeclareFile = pkgs.runCommand "virtdeclare" {}
            ''
            sed -e "1s|.*|\#\!${pythonPkg}/bin/python3|" ${./virtdeclare} > $out
            chmod 755 $out
            '';
    in
    {
        apps.x86_64-linux.virtdeclare =
        {
            type = "app";
            program = "${virtdeclareFile}";
        };
    };
}
