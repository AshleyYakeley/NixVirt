{ virtdeclareFile, virtpurgeFile }:
let
    module = isHomeManager: {config, lib, ...}:
    let
        cfg = config.virtualisation.libvirt;
        defaultConnectionURI = if isHomeManager then "qemu:///session" else "qemu:///system";
        mkObjectOption =  with lib.types; {singular,plural}: lib.mkOption
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
            connections = lib.mkOption
            {
                type = attrsOf
                (submodule
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
                });
                default = {};
                description = "set of objects, keyed by hypervisor connection URI (e.g. \"" + defaultConnectionURI + "\")";
            };
        };

        config = lib.mkIf cfg.enable
        (let
            concatStr = builtins.concatStringsSep "";
            concatStrMap = f: x: concatStr (builtins.map f x);

            scriptForObject = connection: objtype: {definition, active}:
                let
                    stateOption = if builtins.isNull active
                        then ""
                        else if active then "--state active" else "--state inactive";
                in
                ''
                ${virtdeclareFile} --connect ${connection} --type ${objtype} --define ${definition} ${stateOption}
                '';

            fileForObject = {definition, ...}:
                ''
                echo ${definition} >> $f
                '';

            scriptForType = connection: objtype: optList:
                if builtins.isNull optList then "" else
                    concatStrMap (scriptForObject connection objtype) optList +
                    ''
                    f=$(mktemp)
                    '' +
                    concatStrMap fileForObject optList +
                    ''
                    ${virtpurgeFile} --connect ${connection} --type ${objtype} --keep $f
                    rm $f
                    '';

            scriptForConnection = with builtins; connection:
            let
                opts = getAttr connection cfg.connections;
            in concatStr
            [
                (scriptForType connection "domain" (getAttr "domains" opts))
                (scriptForType connection "network" (getAttr "networks" opts))
            ];

            script = concatStrMap scriptForConnection (builtins.attrNames cfg.connections);
        in
        if isHomeManager
        then
        {
            home.activation.libvirt-domains = script;
        }
        else
        {
            virtualisation.libvirtd.enable = true;
            systemd.services.nixvirt =
            {
                serviceConfig.Type = "oneshot";
                description = "Configure libvirt objects";
                wantedBy = ["multi-user.target"];
                requires = ["libvirtd.service"];
                after = ["libvirtd.service"];
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
