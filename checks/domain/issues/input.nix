{ ... }: {
  name = "issues";
  cpu.model.name = "test"; # ISSUE #66
  devices.interface = [
    {
      type = "vhostuser";
      source = {
        type = "unix";
        path = "/tmp/vhost.sock";
        mode = "client";
        reconnect = {
          enabled = true;
          timeout = 10;
        };
      };
    }
  ];
}
