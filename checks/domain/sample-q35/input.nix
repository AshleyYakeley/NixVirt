lib: lib.domain.templates.sample-q35 { qemu = "QEMU_PATH"; }
{
  name = "test-q35";
  uuid = "2904419d-b283-4cfd-9f2c-7c3713ff809f";
  memory = { count = 6; unit = "GiB"; };
  storage_vol_path = /Storage/MyHD.qcow2;
  mac_address = "52:54:00:02:04:06";
}
