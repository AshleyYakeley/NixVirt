> :warning:  NixVirt isn't fully working yet.

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

  * `active` (`true`, `false`, `null`)  
  Running/stopped state to put the domain in (or null to ignore).  
  Default: `null`.

Note that NixOS already has options under `virtualisation.libvirtd` for controlling the libvirt daemon.

### `homeModules.default`

The same as above, as a Home Manager module, except:

* The default connection is `"qemu:///session"`.

* `virtualisation.libvirtd.enable` must already be switched on in NixOS.

### `apps.x86_64-linux.virtdeclare`

`virtdeclare` is a command-line tool for defining and controlling libvirt objects idempotently, used by the modules.

```
usage: virtdeclare [-h] [-v] --connect URI {domain} ...

Define and control libvirt objects idempotently.

options:
  -h, --help     show this help message and exit
  -v, --verbose  report actions to stderr
  --connect URI  connection URI (e.g. qemu:///session)

subcommands:
  object to control

  {domain}
```

Currently it only controls libvirt domains.

#### Domains

* A domain definition will replace any previous definition with that UUID. The name of a definition can change, but libvirt will not allow two domains with the same name.

* Stopping a domain immediately terminates it (like shutting the power off).

* If an existing domain is redefined, and the definition differs, and the domain is running,
and `--state inactive` is not specified, then `virtdeclare` will stop and restart the domain with the new definition.

```
usage: virtdeclare domain [-h] (--define PATH | --name ID) [--state {active,inactive}] [--auto]

Define and start/stop libvirt domains idempotently.

options:
  -h, --help            show this help message and exit
  --define PATH         XML domain definition file path
  --name ID             domain name or UUID
  --state {active,inactive}
                        state to put domain in
  --auto                set autostart to match state
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
