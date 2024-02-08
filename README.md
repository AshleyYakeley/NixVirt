# NixVirt

NixVirt lets you declare virtual machines ([libvirt](https://libvirt.org/) domains) and associated objects in Nix.

## Flake

NixVirt is a Nix flake, which you can obtain here or from FlakeHub. [![FlakeHub](https://img.shields.io/endpoint?url=https://flakehub.com/f/AshleyYakeley/NixVirt/badge)](https://flakehub.com/flake/AshleyYakeley/NixVirt)

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
Switching this on will also switch on `virtualisation.libvirtd.enable`.  
Default: `false`.

* `virtualisation.libvirt.<connection>` (set)  
`<connection>` is the hypervisor connection URI, typically `"qemu:///system"`.  

* `virtualisation.libvirt.<connection>.domains` (list of sets)  
Each set represents a libvirt domain, and has these attributes:

  * `definition` (path)  
  Path to a [domain definition XML](https://libvirt.org/formatdomain.html) file.
  You can obtain this for your existing domains with `virsh dumpxml`.

  * `active` (`true`, `false`, `null`)  
  State to put the domain in (running/stopped), or null to ignore.  
  Default: `null`.

  :warning: If this option is specified and not null, any libvirt domain not defined in the list will be removed.

* `virtualisation.libvirt.<connection>.networks` (list of sets)  
Each set represents a libvirt network, and has these attributes:

  * `definition` (path)  
  Path to a [network definition XML](https://libvirt.org/formatnetwork.html) file.
  You can obtain this for your existing networks with `virsh net-dumpxml`.

  * `active` (`true`, `false`, `null`)  
  State to put the network in, or null to ignore.  
  Default: `null`.

  :warning: If this option is specified and not null, any libvirt network not defined in the list will be removed.

* `virtualisation.libvirt.<connection>.pools` (list of sets)  
Each set represents a libvirt storage pool, and has these attributes:

  * `definition` (path)  
  Path to a [pool definition XML](https://libvirt.org/formatstorage.html) file.
  You can obtain this for your existing pools with `virsh pool-dumpxml`.

  * `active` (`true`, `false`, `null`)  
  State to put the pool in, or null to ignore.  
  Default: `null`.

  :warning: If this option is specified and not null, any libvirt pool not defined in the list will be removed.
  However, removing a pool does not delete the files or other storage holding the volumes it contained.

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

`virtpurge` is a command-line tool for removing unused libvirt objects, used by the modules.
Its behaviour is subject to change and should not be relied upon.

### `packages.x86_64-linux.default`

A package containing `virtdeclare` and `virtpurge`.

### `lib`

Functions for creating libvirt object definition XML from Nix sets; this is still under development.

#### `lib.domain.getXML`

Create domain XML for a given structure (returns a string).

#### `lib.domain.writeXML`

Write domain XML for a given structure (returns a path).

#### `lib.network.getXML`

Create network XML for a given structure (returns a string).

#### `lib.network.writeXML`

Write network XML for a given structure (returns a path).

#### `lib.pool.getXML`

Create pool XML for a given structure (returns a string).

#### `lib.pool.writeXML`

Write pool XML for a given structure (returns a path).

#### `lib.xml`

Various functions for creating XML text.
