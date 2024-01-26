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
    {
        apps.x86_64-linux.virtdeclare =
        {
            type = "app";
            program = ./virtdeclare;
        };
    };
}
