packages:
{
  virtio-win.iso =
    packages.runCommand "virtio-win.iso" { } "${packages.cdrtools}/bin/mkisofs -o $out ${packages.virtio-win}";
}
