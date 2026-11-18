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

  # PowerDevil can leave every screen dimmed to 30% after waking from an
  # idle-suspend (KDE bug 513809). Its idle-dim action only exists while some
  # display has brightness control. When they all drop out at once, as can
  # happen across a resume, the action is deleted but its 30% limit is not,
  # and the returning displays inherit it. The brightness slider and the
  # monitors' own DDC/CI value both still read 100% (KWin applies the dim in
  # software on DDC/CI monitors), so only `kscreen-doctor -o` shows
  # "dimming to 30%". The patch is upstream MR 739 (commit 9f056c5b), vendored
  # verbatim and targeted at Plasma 6.9.0. Once powerdevil ships it, the patch
  # stops applying and the powerdevil build fails: delete this overlay and the
  # patch file then.
  nixpkgs.overlays = [
    (final: prev: {
      kdePackages = prev.kdePackages.overrideScope (kfinal: kprev: {
        powerdevil = kprev.powerdevil.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ../../patches/powerdevil-undim-when-displays-vanish.patch
          ];
        });
      });
    })
  ];

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
