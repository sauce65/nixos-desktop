# Overlay exposing the helper packages, so any machine can reference
# pkgs.nrs / pkgs.ssh-load-keys. (Vintage Story moved to the nixos-gaming flake.)
#
# Single source of truth: the derivations live in ../pkgs and are reused by both
# this overlay and the home-manager module (which callPackages them directly).
final: prev: {
  nrs = final.callPackage ../pkgs/nrs.nix { };
  ssh-load-keys = final.callPackage ../pkgs/ssh-load-keys.nix { };
}
