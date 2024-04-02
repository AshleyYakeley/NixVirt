lib: lib.domain.templates.windows
  {
    name = "test-windows-2";
    uuid = "a67f3ed6-fdad-462a-8c3b-d970db34d8da";
    storage_vol = { pool = "default"; volume = "win10.qcow2"; };
    install_vol = /Source/Win11_23H2_EnglishInternational_x64v2.iso;
    nvram_path = /Storage/MyNVRAM.fd;
  } //
{
  qemu-commandline =
    {
      arg =
        [
          { value = "-newarg"; }
          { value = "parameter"; }
        ];
      env =
        [
          { name = "ID"; value = "wibble"; }
          { name = "BAR"; }
        ];
    };
}
