lib: lib.network.templates.bridge
{
  name = "test-bridge";
  bridge_name = "virbr1";
  uuid = "d2102492-5797-429b-aa31-96b1b0d6f8e8";
  subnet_byte = 74;
  dhcp_hosts = [
    {
      name = "host1";
      mac = "52:54:00:74:10:01";
      ip = "192.168.74.11";
    }
    {
      name = "host2";
      ip = "192.168.74.12";
    }
    {
      mac = "52:54:00:74:10:03";
      ip = "192.168.74.13";
    }
  ];
}
