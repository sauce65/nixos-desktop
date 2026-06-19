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
    preferences = {
      # Make Teams web serve the full Edge/Chrome client instead of the
      # degraded Firefox "lite" path, and let WebRTC negotiate H.264 — which
      # AMD VCN decodes in hardware (VP8 doesn't, and Teams' Firefox path
      # loves VP8).
      "general.useragent.override.teams.microsoft.com" =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36 Edg/135.0.0.0";
      "general.useragent.override.teams.live.com" =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36 Edg/135.0.0.0";

      # Override Firefox's gfxInfo blocklist on AMD Mesa — Phoenix/780M +
      # Mesa 26.0.6 is fine, but Firefox flagged DMABUF_SURFACE_EXPORT as
      # BROKEN_DRIVER. Forcing these enables zero-copy GPU->compositor handoff
      # and native KWin compositor passthrough. Harmless on Nvidia.
      "widget.dmabuf.force-enabled" = true;
      "gfx.webrender.compositor.force-enabled" = true;
    };
    preferencesStatus = "default";
  };
}
