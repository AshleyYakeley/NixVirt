stuff:
{
  bridge = { name ? "default", uuid, bridge_name ? "virbr0", subnet_byte }:
    let
      prefix = "192.168.${builtins.toString subnet_byte}.";
    in
    {
      inherit name uuid;
      forward =
        {
          mode = "nat";
          nat =
            {
              port =
                {
                  start = 1024;
                  end = 65535;
                };
            };
        };
      bridge = { name = bridge_name; };
      ip =
        {
          address = "${prefix}1";
          netmask = "255.255.255.0";
          dhcp =
            {
              range =
                {
                  start = "${prefix}2";
                  end = "${prefix}254";
                };
            };
        };
    };
}
