lib: lib.domain.templates.linux
{
  name = "test-q35";
  uuid = "2904419d-b283-4cfd-9f2c-7c3713ff809f";
  memory = { count = 6; unit = "GiB"; };
  storage_vol = /Storage/MyHD.qcow2;
  backing_vol = /Storage/Base.qcow2;
}
