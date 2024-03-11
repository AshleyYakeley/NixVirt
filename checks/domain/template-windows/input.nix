lib: lib.domain.templates.windows
{
  name = "test-windows";
  uuid = "a8bdda9a-6c4a-49bf-bf2d-0dc9792e7b18";
  memory = { count = 10; unit = "GiB"; };
  storage_vol = /Storage/MyHD.qcow2;
  install_vol = /Source/Win11_23H2_EnglishInternational_x64v2.iso;
  nvram_path = /Storage/MyNVRAM.fd;
  install_virtio = true;
}
