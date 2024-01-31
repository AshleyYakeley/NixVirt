virtdeclareFile:
let
    module = isHomeManager: { config, lib, ... }:
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
                        connection = lib.mkOption
                        {
                            type = str;
                            default = if isHomeManager then "qemu:///session" else "qemu:///system";
                            description = "hypervisor connection URI";
                        };
                        definition = lib.mkOption
                        {
                            type = path;
                            description = "path to definition XML";
                        };
                        state = lib.mkOption
                        {
                            type = types.enum [ "stopped" "running" "ignore" ];
                            default = "ignore";
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
            mkCommands = {connection,definition,state,auto}:
            let
                stateOption = if state != "ignore" then "--state ${state}" else "";
                autoOption = if auto then "--auto" else "";
            in
            ''
                ${virtdeclareFile} --connect ${connection} --define ${definition} ${stateOption} ${autoOption}
            '';
            script = lib.concatStrings (lib.lists.forEach cfg.domains mkCommands);
        in
        if isHomeManager
        then
        {
            home.activation.libvirt-domains = script;
        }
        else
        {
            virtualisation.libvirtd.enable = true;
            system.activationScripts.libvirt-domains = script;
        }
        );
    };
in
{
    nixosModule = module false;
    homeModule = module true;
}
