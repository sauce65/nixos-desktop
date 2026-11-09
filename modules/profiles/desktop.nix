# Desktop/workstation profile: KDE Plasma 6 (Wayland via SDDM), PipeWire,
# printing, Firefox, NetworkManager. Layered on top of profiles/base.nix by
# workstation machines. NOT for headless servers.
{ pkgs, ... }:

{
  # NetworkManager is the desktop networking story; servers prefer
  # systemd-networkd, so it lives here rather than in base.
  networking.networkmanager.enable = true;

  # Let any user in the local session read the kernel ring buffer. The default
  # dmesg_restrict=1 blocks unprivileged dmesg, which broke GPU crash triage
  # (capturing NVRM/Xid without sudo). Acceptable on a single-user desktop;
  # explicitly NOT in base, since a server should keep the secure default.
  boot.kernel.sysctl."kernel.dmesg_restrict" = 0;

  # Desktop: KDE Plasma 6 on Wayland via SDDM.
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # A baseline KDE app set most desktops want.
  environment.systemPackages = [ pkgs.kdePackages.kate ];

  # Printing.
  services.printing.enable = true;

  # Audio: PipeWire (with PulseAudio compat for older apps).
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.firefox = {
    enable = true;
    # Preferences set here or per machine land in
    # /etc/firefox/policies/policies.json on the DEFAULT pref branch, which
    # about:config's "modified" filter does not show. GPU-specific tuning stays
    # out of this shared profile: forcing widget.dmabuf / gfx.webrender.compositor
    # on Nvidia + KWin Wayland crashes Firefox on any video. The laptop carries
    # its own gfx.canvas.accelerated override in its configuration.nix.
    preferencesStatus = "default";
  };
}
