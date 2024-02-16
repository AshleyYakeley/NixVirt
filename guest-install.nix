packages:
{
  virtio-win.iso =
    packages.runCommand "virtio-win.iso" { } "${packages.cdrtools}/bin/mkisofs -v VIRTIO-WIN -o $out ${packages.virtio-win}";
}
