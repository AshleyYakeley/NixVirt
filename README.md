# NixVirt

NixVirt lets you declare virtual machines ([libvirt](https://libvirt.org/) domains) and associated objects in Nix.

## Flake

NixVirt is a Nix flake, which you can obtain from FlakeHub. [![FlakeHub](https://img.shields.io/endpoint?url=https://flakehub.com/f/AshleyYakeley/NixVirt/badge)](https://flakehub.com/flake/AshleyYakeley/NixVirt) (Note that the master branch on GitHub is frequently broken.)

Add NixVirt to your own `flake.nix`:

```nix
{
  inputs.NixVirt.url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";

  outputs = { self, NixVirt }:
  {
    # Use in your outputs
  };
}
```

These are the available outputs:

### `nixosModules.default`

A NixOS module with these options:

* `virtualisation.libvirt.enable` (boolean)  
Whether to use NixVirt.
Switching this on will also switch on `virtualisation.libvirtd.enable`,
and set by default `virtualisation.libvirtd.package` to match libvirt version.  
Default: `false`.

* `virtualisation.libvirt.swtpm.enable` (boolean)  
Whether to make swtpm (software TPM emulator) available.
Default: `false`.

* `virtualisation.libvirt.connections.<connection>` (set)  
`<connection>` is the hypervisor connection URI, typically `"qemu:///system"`.  

* `virtualisation.libvirt.connections.<connection>.domains` (list of sets)  
Each set represents a libvirt domain, and has these attributes:

  * `definition` (path)  
  Path to a [domain definition XML](https://libvirt.org/formatdomain.html) file.
  You can obtain this for your existing domains with `virsh dumpxml`.

  * `active` (`true`, `false`, `null`)  
  State to put the domain in (running/stopped), or null to ignore.  
  Default: `null`.

  :warning: If this option is specified and not null, any libvirt domain not defined in the list will be deleted.
  Deleting a domain will not delete its volumes, NVRAM, or TPM state.

* `virtualisation.libvirt.connections.<connection>.networks` (list of sets)  
Each set represents a libvirt network, and has these attributes:

  * `definition` (path)  
  Path to a [network definition XML](https://libvirt.org/formatnetwork.html) file.
  You can obtain this for your existing networks with `virsh net-dumpxml`.

  * `active` (`true`, `false`, `null`)  
  State to put the network in, or null to ignore.  
  Default: `null`.

  :warning: If this option is specified and not null, any libvirt network not defined in the list will be deleted.

* `virtualisation.libvirt.connections.<connection>.pools` (list of sets)  
Each set represents a libvirt storage pool, and has these attributes:

  * `definition` (path)  
  Path to a [pool definition XML](https://libvirt.org/formatstorage.html) file.
  You can obtain this for your existing pools with `virsh pool-dumpxml`.

  * `active` (`true`, `false`, `null`)  
  State to put the pool in, or null to ignore.  
  Default: `null`.

  :warning: If this option is specified and not null, any libvirt pool not defined in the list will be deleted.
  However, deleting a pool does not delete the files or other storage holding the volumes it contained.

Note that NixOS already has options under `virtualisation.libvirtd` for controlling the libvirt daemon.

### `homeModules.default`

The same as above, as a Home Manager module, except that `virtualisation.libvirtd.enable` must already be switched on in NixOS.
You may want to use `"qemu:///session"` for the connection.

### `apps.x86_64-linux.virtdeclare`

`virtdeclare` is a command-line tool for defining and controlling libvirt objects idempotently, used by the modules.

```
usage: virtdeclare [-h] [-v] --connect URI --type {domain,network} (--define PATH | --uuid ID | --name ID)
                   [--state {active,inactive}] [--auto]

Define and control libvirt objects idempotently.

options:
  -h, --help            show this help message and exit
  -v, --verbose         report actions to stderr
  --connect URI         connection URI (e.g. qemu:///session)
  --type {domain,network}
                        object type
  --define PATH         XML object definition file path
  --uuid ID             object UUID
  --name ID             object name
  --state {active,inactive}
                        state to put object in
  --auto                set autostart to match state
```

Currently `virtdeclare` only controls libvirt domains and networks.

* An object definition will replace any previous definition with that UUID. The name of a definition can change, but libvirt will not allow two objects of the same type with the same name.

* For domains, active means running.

* Deactivating a domain immediately terminates it (like shutting the power off).

* If an existing object is redefined, and the definition differs, and the object is active,
and `--state inactive` is not specified, then `virtdeclare` will deactivate and reactivate the object with the new definition.

### `apps.x86_64-linux.virtpurge`

`virtpurge` is a command-line tool for deleting unused libvirt objects, used by the modules.
Its behaviour is subject to change and should not be relied upon.

### `packages.x86_64-linux.default`

A package containing `virtdeclare` and `virtpurge`.

### `lib`

Functions for creating libvirt object definition XML from Nix sets.

#### `lib.domain.getXML`

Create domain XML for a given structure (returns a string).
The Nix structure roughly follows [the XML format](https://libvirt.org/formatdomain.html), but is currently missing elements.
Please edit [the file](generate-xml/domain.nix) and create a PR for anything you need.

##### Example

See [this file](checks/domain/win11/input.nix).

#### `lib.domain.writeXML`

Write domain XML for a given structure (returns a path).

#### `lib.domain.templates`

Templates for domains, suitable for passing to `lib.domain.writeXML`.
These definitions are currently not stable, and are mostly for getting started with, so you should not depend on their precise configuration.

If you have suggestions for improvements, please create a PR.

#### `lib.domain.templates.base`

A template function for a kinda basic Q35 machine.

These are the arguments:

* `name`: the libvirt name (string, required)
* `uuid`: the libvirt identifier (UUID string, required)
* `memory`: amount of RAM (set with `count` (integer) and `unit` (string) attributes, default `{ count = 2; unit = "GiB"; }`)
* `storage_vol_path`: path to a QCOW2 volume for storage (string or path, required)
* `mac_address`: MAC address (string, required)
* `install_vol_path`: path to an ISO image for an inserted CDROM, or null (string or path, default null)
* `virtio_net`: whether to use VirtIO for networking (faster, but may require special guest drivers) (boolean, default false)

#### `lib.domain.templates.linux`

A template function for a domain suitable for installing Linux on.

These are the arguments:

* `name`: the libvirt name (string, required)
* `uuid`: the libvirt identifier (UUID string, required)
* `memory`: amount of RAM (set with `count` (integer) and `unit` (string) attributes, default `{ count = 4; unit = "GiB"; }`)
* `storage_vol_path`: path to a QCOW2 volume for storage (string or path, required)
* `mac_address`: MAC address (string, required)
* `install_vol_path`: path to an ISO image for an inserted CDROM, or null (string or path, default null)

##### Example

In your Home Manager configuration:

```nix
virtualisation.libvirt.connections."qemu:///session".domains =
  [
    {
      definition = nixvirt.lib.domain.writeXML (nixvirt.lib.domain.templates.linux
        {
          name = "Penguin";
          uuid = "cc7439ed-36af-4696-a6f2-1f0c4474d87e";
          memory = { count = 6; unit = "GiB"; };
          storage_vol_path = /home/ashley/VM-Storage/MyPool/Penguin.qcow2;
          mac_address = "52:54:00:d4:ae:7f";
        });
    }
  ];
```

#### `lib.domain.templates.windows`

A template function for a domain suitable for installing Windows 11 on.
It supports Secure Boot via OVMF and an emulated TPM; you will want to switch on `virtualisation.libvirt.swtpm.enable`.

These are the arguments:

* `name`: the libvirt name (string, required)
* `uuid`: the libvirt identifier (UUID string, required)
* `memory`: amount of RAM (set with `count` (integer) and `unit` (string) attributes, default `{ count = 4; unit = "GiB"; }`)
* `storage_vol_path`: path to a QCOW2 volume for storage (string or path, required)
* `mac_address`: MAC address (string, required)
* `install_vol_path`: path to an ISO image for an inserted CDROM, or null (string or path, default null)
* `nvram_path`: path to a file for storing NVRAM, this file will be created if missing (string or path, required)
* `virtio_net`: whether to use VirtIO for networking: this is faster, but requires installing a driver during Windows 11 installation (boolean, default false)
* `virtio_drive`: whether to use VirtIO for the storage device: this is faster, but requires installing a driver during Windows 11 installation (boolean, default false)
* `install_virtio`: whether to add an additional CDROM drive with a disc containing VirtIO drivers for Windows (boolean, default false)

##### Example

In your Home Manager configuration:

```nix
virtualisation.libvirt.swtpm.enable = true;
virtualisation.libvirt.connections."qemu:///session".domains =
  [
    {
      definition = nixvirt.lib.domain.writeXML (nixvirt.lib.domain.templates.windows
        {
          name = "Bellevue";
          uuid = "def734bb-e2ca-44ee-80f5-0ea0f2593aaa";
          memory = { count = 8; unit = "GiB"; };
          storage_vol_path = /home/ashley/VM-Storage/MyPool/Bellevue.qcow2;
          mac_address = "52:54:00:71:74:8e";
          install_vol_path = /home/ashley/VM-Storage/Win11_23H2_EnglishInternational_x64v2.iso;
          nvram_path = /home/ashley/VM-Storage/Bellevue.nvram;
          virtio_net = true;
          virtio_drive = true;
          install_virtio = true;
        });
    }
  ];
```

#### `lib.network.getXML`

Create network XML for a given structure (returns a string).
The Nix structure roughly follows [the XML format](https://libvirt.org/formatnetwork.html), but is currently missing elements.
Please edit [the file](generate-xml/network.nix) and create a PR for anything you need.

##### Example

```nix
lib.network.getXML
  {
    name = "default";
    uuid = "c4acfd00-4597-41c7-a48e-e2302234fa89";
    forward =
      {
        mode = "nat";
        nat = { port = { start = 1024; end = 65535; }; };
      };
    bridge = { name = "virbr0"; };
    mac = { address = "52:54:00:02:77:4b"; };
    ip =
      {
        address = "192.168.74.1";
        netmask = "255.255.255.0";
        dhcp = { range = { start = "192.168.74.2"; end = "192.168.74.254"; }; };
      };
  }
```

#### `lib.network.writeXML`

Write network XML for a given structure (returns a path).

#### `lib.network.templates.bridge`

A template function for a typical bridge to be created in `qemu:///system`.
Domains created in `qemu:///session` will be able to use it.

These are the arguments:

* `name`: the libvirt name (string, default `"default"`)
* `uuid`: the libvirt identifier (UUID string, required)
* `bridge_name`: the network name this bridge will create (string, default `"virbr0"`)
* `mac_address`: MAC address (string, required)
* `subnet_byte`: byte of the subnet (integer in range 1-254, required). Given x, the subnet of the bridge will be 192.168.x.0/24.

##### Example

In your NixOS configuration:

```nix
virtualisation.libvirt.connections."qemu:///system".networks =
  [
    {
      definition = nixvirt.lib.network.writeXML (nixvirt.lib.network.templates.bridge
        {
          uuid = "70b08691-28dc-4b47-90a1-45bbeac9ab5a";
          mac_address = "52:54:00:4f:c7:ca";
          subnet_byte = 71;
        });
      active = true;
    }
  ];
```

#### `lib.pool.getXML`

Create pool XML for a given structure (returns a string).
The Nix structure roughly follows [the XML format](https://libvirt.org/formatstorage.html), but is currently missing elements.
Please edit [the file](generate-xml/pool.nix) and create a PR for anything you need.

##### Example

```nix
lib.pool.getXML
{
  name = "MyPool";
  uuid = "650c5bbb-eebd-4cea-8a2f-36e1a75a8683";
  type = "dir";
  target = { path = "/home/ashley/VM-Storage/MyPool"; };
}
```

#### `lib.pool.writeXML`

Write pool XML for a given structure (returns a path).

#### `lib.xml`

Various functions for creating XML text.

#### `lib.guest-install.virtio-win.iso`

ISO disc image of `virtio-win`, for installing paravirtualised drivers, etc., inside Windows guests.
