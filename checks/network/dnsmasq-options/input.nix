_: {
  name = "test-dnsmasq-options";
  uuid = "7f3caa98-cf49-4a7a-8796-a950723571a4";
  forward = {
    mode = "nat";
    nat = {
      port = {
        start = 1024;
        end = 65535;
      };
    };
  };
  bridge = {
    name = "virbr1";
  };
  ip = {
    address = "192.168.1.0";
    netmask = "255.255.255.0";
    dhcp = {
      range = {
        start = "192.168.1.2";
        end = "192.168.1.254";
      };
    };
  };
  dns = {
    enable = false;
  };
  "xmlns:dnsmasq" = "http://libvirt.org/schemas/network/dnsmasq/1.0";
  "dnsmasq:options" = {
    "dnsmasq:option" = [
      { value = "dhcp-option=6,9.9.9.10"; }
    ];
  };
}
