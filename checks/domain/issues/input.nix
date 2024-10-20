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
    {
      type = "network";
      driver = {
        name = "vhost";
        txmode = "iothread";
        mode = "client";
        ioeventfd = true;
        event_idx = false;
        queues = 5;
        rx_queue_size = 256;
        tx_queue_size = 256;
        host = {
          csum = false;
          gso = false;
          tso4 = false;
          tso6 = false;
          ecn = false;
          ufo = false;
          mrg_rxbuf = false;
        };
        guest = {
          csum = false;
          tso4 = false;
          tso6 = false;
          ecn = false;
          ufo = false;
        };
      };
    }
  ];
}
