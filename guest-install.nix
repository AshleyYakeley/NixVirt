packages:
{
  virtio-win.iso =
    packages.runCommand "virtio-win.iso" { } "${packages.cdrtools}/bin/mkisofs -V VIRTIO-WIN -o $out ${packages.virtio-win}";
}
