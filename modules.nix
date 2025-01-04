{ packages, moduleHelperFile }:
let
  module = isHomeManager: { config, lib, ... }:
    let
      cfg = config.virtualisation.libvirt;
      defaultConnectionURI = if isHomeManager then "qemu:///session" else "qemu:///system";
      mkObjectOption = with lib.types; { singular, plural, extraOptions ? { } }: lib.mkOption
        {
          type = nullOr (listOf (submodule
            {
              options = extraOptions //
                {
                  definition = lib.mkOption
                    {
                      type = path;
                      description = "path to " + singular + " definition XML";
                    };
                  active = lib.mkOption
                    {
                      type = nullOr bool;
                      default = null;
                      description = "state to put the " + singular + " in (or null for ignore)";
                    };
                  restart = lib.mkOption
                    {
                      type = nullOr bool;
                      default = null;
                      description = "whether to restart on activation (or null to only restart when changed)";
                    };
                };
            }));
          default = null;
          description = "libvirt " + plural;
        };
    in
    {
      options.virtualisation.libvirt = with lib.types;
        {
          enable = lib.mkOption
            {
              type = bool;
              default = false;
              description = "Enable management of libvirt objects";
            };
          package = lib.mkOption
            {
              type = package;
              default = packages.libvirt;
              description = "libvirt package to use";
            };
          verbose = lib.mkOption
            {
              type = bool;
              default = false;
              description = "Verbose output during module activation (for debugging)";
            };
          swtpm.enable = lib.mkOption
            {
              type = bool;
              default = false;
              description = "Make software TPM emulator available to libvirt";
            };
          connections = lib.mkOption
            {
              type = attrsOf
                (submodule
                  {
                    options =
                      {
                        domains = mkObjectOption
                          {
                            singular = "domain";
                            plural = "domains";
                          };
                        networks = mkObjectOption
                          {
                            singular = "network";
                            plural = "networks";
                          };
                        pools = mkObjectOption
                          {
                            singular = "pool";
                            plural = "pools";
                            extraOptions =
                              {
                                volumes = lib.mkOption
                                  {
                                    type = listOf
                                      (submodule
                                        {
                                          options =
                                            {
                                              present = lib.mkOption
                                                {
                                                  type = bool;
                                                  default = true;
                                                  description = "whether the volume should exist";
                                                };
                                              name = lib.mkOption
                                                {
                                                  type = nullOr str;
                                                  description = "name of the volume (for present=false)";
                                                  default = null;
                                                };
                                              definition = lib.mkOption
                                                {
                                                  type = nullOr path;
                                                  description = "path to volume definition XML";
                                                  default = null;
                                                };
                                            };
                                        });
                                    default = [ ];
                                    description = "volumes to create if missing";
                                  };
                              };
                          };
                      };
                  });
              default = { };
              description = "set of objects, keyed by hypervisor connection URI (e.g. \"" + defaultConnectionURI + "\")";
            };
        };

      config = lib.mkIf cfg.enable
        (
          let
            concatStr = builtins.concatStringsSep "";
            concatStrMap = f: x: concatStr (builtins.map f x);

            scriptForConnection = with builtins; connection:
              let
                opts = getAttr connection cfg.connections;
                jsonFile = packages.writeText "nixvirt module script" (builtins.toJSON opts);
                verboseFlag = if cfg.verbose then "-v" else "";
              in
              "${moduleHelperFile cfg.package} ${verboseFlag} --connect ${connection} ${jsonFile}\n";

            extraPackages = [ packages.qemu-utils ] ++ (if cfg.swtpm.enable then [ packages.swtpm ] else [ ]);
            extraPaths = concatStrMap (p: "${p}/bin:") extraPackages;
            script = "PATH=${extraPaths}$PATH\n" + concatStrMap scriptForConnection (builtins.attrNames cfg.connections);
          in
          if isHomeManager
          then
            {
              home.packages = extraPackages;
              home.activation.NixVirt = lib.hm.dag.entryAfter [ "installPackages" ] script;
              systemd.user.services.nixvirt = {
                Unit = {
                  Description = "Configure libvirt objects";
                  # Its missing the wantedBy etc but it should be fine 
                  # since those other services _should_ start before the 
                  # any of the user services start running,
                };
                Service = {
                  ExecStart = packages.writeShellScript "nixvirt-start" script;
                  Type = "oneshot";
                };
                Install = {
                  WantedBy = ["default.target"];
                };
              }; 
            }
          else
            {
              environment.systemPackages = extraPackages;
              virtualisation.libvirtd =
                {
                  enable = true;
                  package = lib.mkDefault cfg.package;
                  qemu.swtpm =
                    if cfg.swtpm.enable then
                      {
                        enable = true;
                        package = packages.swtpm;
                      }
                    else { };
                };
              systemd.services.nixvirt =
                {
                  serviceConfig.Type = "oneshot";
                  description = "Configure libvirt objects";
                  wantedBy = [ "multi-user.target" ];
                  requires = [ "libvirtd.service" ];
                  after = [ "libvirtd.service" ];
                  inherit script;
                };
            }
        );
    };
in
{
  nixosModule = module false;
  homeModule = module true;
}
