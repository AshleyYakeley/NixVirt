## NixVirt

NixVirt lets you declare virtual machines ([libvirt](https://libvirt.org/) domains) in Nix. NixVirt is a Nix flake with these outputs:

### `nixosModules.default`

A NixOS module with these options:

* `virtualisation.libvirt.enable` (boolean)  
Whether to use NixVirt.
Switching this on will also switch on `virtualisation.libvirtd.enable`.  
Default: `false`.

* `virtualisation.libvirt.domains` (list of sets)  
Each set represents a domain, and has these attributes:

  * `connection` (string)  
  The hypervisor connection.  
  Default: `"qemu:///system"`.

  * `definition` (path)  
  Path to a [libvirt domain definition XML](https://libvirt.org/formatdomain.html) file.

  * `state` (`"running"`, `"stopped"`, `"ignore"`)  
  State to put the domain in.  
  Default: `"ignore"`.

Note that NixOS already has options under `virtualisation.libvirtd` for controlling the libvirt daemon.

### `homeModules.default`

The same as above, as a Home Manager module, except:

* The default connection is `"qemu:///session"`.

* `virtualisation.libvirtd.enable` must already be switched on in NixOS.

### `apps.x86_64-linux.virtdeclare`

`virtdeclare` is a command-line tool for defining and starting/stopping libvirt domains idempotently.
The modules use it to control domains.

* A domain definition will replace any previous definition with that UUID.

* Stopping a domain immediately terminates it (like shutting the power off).

* If an existing domain is redefined, and the definition differs, and the domain is running,
and `--state stopped` is not specified, then `virtdeclare` will stop and restart the domain with the new definition.

```
usage: virtdeclare [-h] --connect URI (--define PATH | --name ID) [--state {running,stopped}] [--auto] [-v]

Define and start/stop libvirt domains idempotently.

options:
  -h, --help            show this help message and exit
  --connect URI         connection URI (e.g. qemu:///session)
  --define PATH         XML domain definition file path
  --name ID             domain name or UUID
  --state {running,stopped}
                        state to put domain in
  --auto                set autostart to match state
  -v, --verbose         report actions to stderr
```

### `packages.x86_64-linux.virtdeclare`

A package containing `virtdeclare`.

### `lib`

Functions for creating libvirt domain XML from Nix sets; this is still under development.

#### `lib.domainXML`

Create domain XML for a given structure (returns a string).

#### `lib.writeDomainXML`

Write domain XML for a given structure (returns a path).

#### `lib.xml`

Various functions for creating XML text.
