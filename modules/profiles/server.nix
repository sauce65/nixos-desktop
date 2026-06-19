# Headless server baseline for homelab nodes. Intentionally thin — it gets
# fleshed out when the homelab phase begins (sealed Matrix, Jellyfin, Home
# Assistant + companions, Frigate, ZFS NAS, LoRa gateway). It pointedly does
# NOT import profiles/desktop.nix, so a server never pulls in a display
# manager, audio stack, or browser.
{ lib, ... }:

{
  # Headless: never silently bring up a display manager.
  services.xserver.enable = lib.mkDefault false;

  # Keep journald off the disk on always-on nodes by default; raise per-host
  # where persistent logs are actually wanted (e.g. a NAS).
  services.journald.extraConfig = lib.mkDefault "Storage=volatile";
}
