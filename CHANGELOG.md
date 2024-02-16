# Changelog

## [Unreleased]

* fixed defect in Home Manager module where domains were defined before swtpm package was available
* clean up virtdeclare & virtpurge error reporting
* improved XML generation
* provided templates for network and domains
* NixOS module: set libvirtd package to match libvirt

## [0.2.0] - 2024-02-08

* added support for storage pools
* fixed defect preventing removal of active objects
* fixed defect preventing removal of domains with NVRAM or TPM state

## [0.1.0] - 2024-02-04

* NixOS and home manager modules
* supports domains and networks
