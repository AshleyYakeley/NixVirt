> :warning:  NixVirt isn't fully working yet.

## NixVirt

NixVirt lets you declare virtual machines ([libvirt](https://libvirt.org/) domains) and associated objects in Nix. NixVirt is a Nix flake with these outputs:

### `nixosModules.default`

A NixOS module with these options:

* `virtualisation.libvirt.enable` (boolean)  
Whether to use NixVirt.
Switching this on will also switch on `virtualisation.libvirtd.enable`.  
Default: `false`.

* `virtualisation.libvirt.<connection>` (set)  
`<connection>` is the hypervisor connection URI, typically `"qemu:///system"` (or `"qemu:///session"` for Home Manager).  

* `virtualisation.libvirt.<connection>.domains` (list of sets)  
Each set represents a domain, and has these attributes:

  * `definition` (path)  
  Path to a [libvirt domain definition XML](https://libvirt.org/formatdomain.html) file.

  * `active` (`true`, `false`, `null`)  
  State to put the domain in (running/stopped), or null to ignore.  
  Default: `null`.

  Any libvirt domain not defined in this set will be removed.

* `virtualisation.libvirt.<connection>.networks` (list of sets)  
Each set represents a network, and has these attributes:

  * `definition` (path)  
  Path to a [libvirt network definition XML](https://libvirt.org/formatnetwork.html) file.

  * `active` (`true`, `false`, `null`)  
  State to put the network in, or null to ignore.  
  Default: `null`.

  Any libvirt network not defined in this set will be removed.

Note that NixOS already has options under `virtualisation.libvirtd` for controlling the libvirt daemon.

### `homeModules.default`

The same as above, as a Home Manager module, except that `virtualisation.libvirtd.enable` must already be switched on in NixOS.

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

* A object definition will replace any previous definition with that UUID. The name of a definition can change, but libvirt will not allow two objects of the same type with the same name.

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

Functions for creating libvirt domain XML from Nix sets; this is still under development.

#### `lib.domainXML`

Create domain XML for a given structure (returns a string).

#### `lib.writeDomainXML`

Write domain XML for a given structure (returns a path).

#### `lib.xml`

Various functions for creating XML text.
