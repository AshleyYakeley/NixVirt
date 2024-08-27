lib:
let
  inputArgs = {
    name = "test-windows-3";
    uuid = "a67f3ed6-fdad-462a-8c3b-d970db34d8da";
    storage_vol = {
      pool = "default";
      volume = "win10.qcow2";
    };
    install_vol = /Source/Win11_23H2_EnglishInternational_x64v2.iso;
    nvram_path = /Storage/MyNVRAM.fd;
  };
in
lib.domain.templates.windows inputArgs
// {
  features = {
    kvm = {
      hidden.state = true;
      hint-dedicated.state = false;
      poll-control.state = true;
      pv-ipi.state = true;
      dirty-ring = {
        state = true;
        size = 16384;
      };
    };
  } // (lib.domain.templates.windows inputArgs).features;
}
