lib: lib.domain.templates.windows
{
  qemu = "QEMU_PATH";
  OVMF.fd = "OVMF_FD_PATH";
}
{
  name = "test-windows";
  uuid = "a8bdda9a-6c4a-49bf-bf2d-0dc9792e7b18";
  memory = { count = 10; unit = "GiB"; };
  storage_vol_path = /Storage/MyHD.qcow2;
  mac_address = "52:54:00:02:08:5c";
  install_vol_path = /Source/Win11_23H2_EnglishInternational_x64v2.iso;
  nvram_path = /Storage/MyNVRAM.fd;
}
