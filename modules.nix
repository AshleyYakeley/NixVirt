{ packages, moduleHelperFile }:
let
  module = isHomeManager: { config, lib, ... }:
    let
      cfg = config.virtualisation.libvirt;
      defaultConnectionURI = if isHomeManager then "qemu:///session" else "qemu:///system";
      mkObjectOption = with lib.types; { singular, plural }: lib.mkOption
        {
          type = nullOr (listOf (submodule
            {
              options =
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
              in
              "${moduleHelperFile} -v --connect ${connection} ${jsonFile}\n";

            script = concatStrMap scriptForConnection (builtins.attrNames cfg.connections);
            extraPackages = if cfg.swtpm.enable then [ packages.swtpm ] else [ ];
          in
          if isHomeManager
          then
            {
              home.packages = extraPackages;
              home.activation.NixVirt = lib.hm.dag.entryAfter [ "installPackages" ] script;
            }
          else
            {
              environment.systemPackages = extraPackages;
              virtualisation.libvirtd =
                {
                  enable = true;
                  package = lib.mkDefault packages.libvirt;
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
