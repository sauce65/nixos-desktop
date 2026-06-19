# Minimal stubs so the profiles can be evaluated as a complete NixOS system in
# `nix flake check`. Not a real machine — just satisfies the eval's hard
# requirements (a root filesystem and a state version).
{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  system.stateVersion = "24.11";
}
