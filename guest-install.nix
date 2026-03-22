packages:
{
  virtio-win.iso =
    packages.runCommand "virtio-win.iso" { } "${packages.cdrtools}/bin/mkisofs -J -V VIRTIO-WIN -o $out ${packages.virtio-win}";
}
