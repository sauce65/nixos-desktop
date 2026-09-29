# Headless baseline for homelab nodes. Imports nothing desktop (no display
# manager, audio, or browser) and layers the hardening every always-on,
# internet-adjacent box should carry: modern-crypto sshd, fail2ban, network +
# memory sysctls, and a weekly CVE scan. Server-only by construction — the
# introspection sysctls below would block strace/perf/BPF debugging if they ever
# reached a desktop, so they live here rather than in base.nix.
{ lib, pkgs, ... }:

{
  services.xserver.enable = lib.mkDefault false;

  # Keep journald off the disk on always-on nodes by default; raise per-host
  # where persistent logs are actually wanted (e.g. a NAS, an internet-facing box).
  # `services.journald.extraConfig` was removed from nixpkgs in 2026-09; the
  # structured `settings` option is the replacement and is what consumers must
  # override (`settings.Journal.Storage`, not `extraConfig`).
  services.journald.settings.Journal.Storage = lib.mkDefault "volatile";

  # base.nix already sets key-only auth; clan's serverModule owns PermitRootLogin
  # (prohibit-password, for deploys). Here: modern-crypto-only + session bounds.
  services.openssh.settings = {
    KexAlgorithms = [
      "sntrup761x25519-sha512@openssh.com"
      "curve25519-sha256"
      "curve25519-sha256@libssh.org"
    ];
    Ciphers = [
      "chacha20-poly1305@openssh.com"
      "aes256-gcm@openssh.com"
      "aes128-gcm@openssh.com"
    ];
    Macs = [
      "hmac-sha2-512-etm@openssh.com"
      "hmac-sha2-256-etm@openssh.com"
      "umac-128-etm@openssh.com"
    ];
    MaxAuthTries = 3;
    MaxSessions = 10;
    ClientAliveInterval = 300;
    ClientAliveCountMax = 2;
  };

  # The openssh module's openFirewall exposes :22 on the public IPv6 GUA, so ban
  # scanners. NixOS's fail2ban reads the journal (no /var/log/auth.log needed).
  # Whitelist only loopback + tailnet; the LAN is untrusted, so a LAN brute-force
  # gets banned too.
  services.fail2ban = {
    enable = true;
    bantime = "1h";
    ignoreIP = [ "127.0.0.0/8" "::1" "100.64.0.0/10" ];
  };

  boot.kernel.sysctl = {
    # Memory / introspection hardening — safe on a headless box (see header).
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.perf_event_paranoid" = 2;
    "kernel.yama.ptrace_scope" = 2;
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    "fs.suid_dumpable" = 0;

    # Network hygiene — reinforces the fleet's firewall/IPv6 posture.
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
  };

  # Weekly CVE scan of the system closure → journal (journalctl -u vulnix-scan).
  # vulnix exits 2 when it finds matches, which is a normal result, not a failure.
  systemd.services.vulnix-scan = {
    description = "Scan the system closure for known CVEs (vulnix)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.vulnix}/bin/vulnix --system";
      SuccessExitStatus = "0 2";
      CacheDirectory = "vulnix";
      Environment = "XDG_CACHE_HOME=/var/cache";
    };
  };
  systemd.timers.vulnix-scan = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun 03:00";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}
