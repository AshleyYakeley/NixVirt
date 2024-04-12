# Changelog

## [UNRELEASED]
* Lib:
    * XML domain generation:
        * Allow in feature section, customization of the `smbios` option
        * Allow in cpu section, customization of the `feature` and `cache` option
        * Add section `sysinfo`
        * add bootorder for device `disk` and `hostdev`
        * Updated section `memoryBacking`

## [0.5.0]
* Lib:
    * XML domain generation:
        * Allow in feature section, customization of the `kvm` options, in domains
        * Allow in device section, devices of type `shmem` and `hostdev`

## [0.4.2]

* Lib:
    * XML generation:
        * Allow QEMU `commandline` in domains
    * Domain Templates:
        * Fix defect in `storage_vol` in Windows template
        * add `virtio_drive` option for all
        * set `cache="none"` for disk drivers

## [0.4.1]

* Fix defect causing libvirt not to find executable files during activation

## [0.4.0]

* Modules:
    * Specify volumes to be present/absent within pools
* Lib:
    * Better support for volume sources in domains in generation and templates
    * Templates for both Intel 440FX and Intel Q35

## [0.3.0]

* Modules:
    * Fixed defect where domains were defined before `swtpm` package was available
    * Set `libvirtd` package to match `libvirt` (NixOS)
    * Added `virtualisation.libvirt.swtpm.enable` option
    * Deactivate domains on network change
    * Added `virtualisation.libvirt.verbose` option
    * Assign missing MAC addresses reproducibly
* Lib:
    * Improved XML generation
    * Provided templates for network and domains
* Apps:
    * Cleaned up `virtdeclare` error reporting
    * Removed `virtpurge`

## [0.2.0] - 2024-02-08

* Added support for storage pools
* Fixed defect preventing removal of active objects
* Fixed defect preventing removal of domains with NVRAM or TPM state

## [0.1.0] - 2024-02-04

* NixOS and home manager modules
* Supports domains and networks
