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
                        hypervisor = lib.mkOption
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
            script = lib.concatStrings (lib.lists.forEach cfg.domains mkCommands);
        in
        if isHomeManager
        then
        {
            home.activation.libvirt-domains = script;
        }
        else
        {
            system.activationScripts.libvirt-domains = script;
        }
        );
    };
in
{
    nixosModule = module false;
    homeModule = module true;
}
