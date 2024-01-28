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
        pythonPkg = pkgs.python3.withPackages(ps:[ps.libvirt ps.lxml]);
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

        packages.x86_64-linux.virtdeclare = pkgs.runCommand "virtdeclare" {}
            ''
            mkdir -p $out/bin
            ln -s ${virtdeclareFile} $out/bin/virtdeclare
            '';

        homeModules.default = { config, lib, pkgs, ... }:
        let
            cfg = config.virtualisation.libvirt;
        in
        {
            options.virtualisation.libvirt = with lib.types;
            {
                enable = lib.mkOption
                {
                    type = bool;
                    default = false;
                    description = "Enable management of libvirt domains";
                };
                domains = lib.mkOption
                {
                    type = listOf (submodule
                    {
                        options =
                        {
                            hypervisor = lib.mkOption
                            {
                                type = str;
                                default = "qemu:///session";
                                description = "hypervisor connection URI";
                            };
                            definition = lib.mkOption
                            {
                                type = path;
                                description = "path to definition XML";
                            };
                            state = lib.mkOption
                            {
                                type = types.enum [ "stopped" "running" ];
                                default = "stopped";
                                description = "state to put the domain in";
                            };
                            auto = lib.mkOption
                            {
                                type = bool;
                                default = true;
                                description = "set autostart to match state";
                            };
                        };
                    });
                    default = [];
                    description = "libvirt domains";
                };
            };

            config = lib.mkIf cfg.enable
            (let
                mkCommands = {hypervisor,definition,state,auto}:
                ''
                    ${virtdeclareFile} --connect ${hypervisor} --define ${definition} --state ${state} ${if auto then "--auto" else ""}
                '';
            in
            {
                home.activation.libvirt-domains = lib.concatStrings (lib.lists.forEach cfg.domains mkCommands);
            });
        };

        nixosModules.default = { config, lib, pkgs, ... }:
        let
            cfg = config.virtualisation.libvirt;
        in
        {
            options.virtualisation.libvirt = with lib.types;
            {
                enable = lib.mkOption
                {
                    type = bool;
                    default = false;
                    description = "Enable management of libvirt domains";
                };
                domains = lib.mkOption
                {
                    type = listOf (submodule
                    {
                        options =
                        {
                            hypervisor = lib.mkOption
                            {
                                type = str;
                                default = "qemu:///system";
                                description = "hypervisor connection URI";
                            };
                            definition = lib.mkOption
                            {
                                type = path;
                                description = "path to definition XML";
                            };
                            state = lib.mkOption
                            {
                                type = types.enum [ "stopped" "running" ];
                                default = "stopped";
                                description = "state to put the domain in";
                            };
                            auto = lib.mkOption
                            {
                                type = bool;
                                default = true;
                                description = "set autostart to match state";
                            };
                        };
                    });
                    default = [];
                    description = "libvirt domains";
                };
            };

            config = lib.mkIf cfg.enable
            (let
                mkCommands = {hypervisor,definition,state,auto}:
                ''
                    ${virtdeclareFile} --connect ${hypervisor} --define ${definition} --state ${state} ${if auto then "--auto" else ""}
                '';
            in
            {
                system.activationScripts.libvirt-domains = lib.concatStrings (lib.lists.forEach cfg.domains mkCommands);
            });
        };
    };
}
