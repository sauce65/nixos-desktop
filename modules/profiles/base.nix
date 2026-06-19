# Minimal, headless-safe baseline shared by EVERY machine — desktops and
# servers alike. Anything desktop-specific (display manager, audio, browser,
# NetworkManager, relaxed dmesg) lives in profiles/desktop.nix so a headless
# server never inherits it.
#
# Deliberately does NOT define a user account — that's personal/machine config
# and stays in the consuming repo. These profiles are user-agnostic.
{ lib, ... }:

{
  # Bootloader: systemd-boot by default. mkDefault so a machine can swap it
  # (gamingpc forces lanzaboote; an aarch64 host uses its own loader).
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  # Show the boot menu long enough to pick a previous generation when a bad
  # rebuild leaves the current one unbootable. Press any key to pause.
  boot.loader.timeout = lib.mkDefault 5;

  # SSH server: key-only, no root. Lets a broken machine be recovered from
  # another box on the LAN. Requires ~/.ssh/authorized_keys on each host.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Locale / time.
  time.timeZone = lib.mkDefault "America/Denver";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  nixpkgs.config.allowUnfree = lib.mkDefault true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Keep the legacy NIX_PATH wired up so the /etc/nixos recovery fallback works
  # without --flake. Daily-driver rebuilds use --flake and ignore this.
  nix.nixPath = [ "nixos-config=/etc/nixos/configuration.nix" ];
}
