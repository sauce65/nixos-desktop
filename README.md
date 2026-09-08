# nixos-desktop

Reusable NixOS modules + overlays extracted from a personal multi-machine
fleet. The desktop baseline, a couple of hard-won fixes, and small helper
packages — the bits worth sharing, with machine-specific and personal config
kept out.

## What's here

| Output | Contents |
|---|---|
| `nixosModules.base` | Headless-safe baseline: systemd-boot, key-only SSH, locale, flakes. User-agnostic. |
| `nixosModules.desktop` | KDE Plasma 6 (Wayland/SDDM), PipeWire, printing, NetworkManager, Firefox AMD/Teams fixes. |
| `nixosModules.server` | Thin headless baseline (no GUI, volatile journald). |
| `overlays.default` | `pkgs.nrs`, `pkgs.ssh-load-keys`, `pkgs.vintagestory-latest`. |
| `packages.<system>` | The same helpers, runnable standalone (`nix run github:sauce65/nixos-desktop#nrs`). |

The `desktop` profile carries some real debugging: it forces the Edge UA on
Teams web (full client + H.264 that AMD VCN decodes in hardware) and overrides
Firefox's gfx blocklist so DMABUF zero-copy works on AMD Mesa.

## Usage

```nix
{
  inputs.nixos-desktop.url = "github:sauce65/nixos-desktop";

  # In a NixOS module / machine config:
  imports = [
    inputs.nixos-desktop.nixosModules.base
    inputs.nixos-desktop.nixosModules.desktop   # or .server
  ];

  # Overlay, to get pkgs.nrs / pkgs.vintagestory-latest etc.:
  nixpkgs.overlays = [ inputs.nixos-desktop.overlays.default ];
}
```

The profiles are user-agnostic — define your own user account and home-manager
config on the consuming side.

## Helpers

- **`nrs`** — `nixos-rebuild switch` with a `$(hostname)`-derived flake target,
  so you can't apply one machine's config to another. Flake dir defaults to
  `~/nixos-configs`; override with `$NRS_FLAKE`. Refuses to switch when the
  running system uses declarative passwords (`users.mutableUsers = false`) but a
  `hashedPasswordFile` has gone missing — that switch would rewrite the accounts
  as locked, which on a machine with no remote login means recovering from a
  physical console. Costs no sudo and no extra evaluation; bypass with
  `$NRS_SKIP_PASSWD_CHECK`.
- **`ssh-load-keys`** — load SSH keys into the agent (regular + FIDO2). Inject
  extra machine-specific key paths via `$SSH_LOAD_KEYS`. Wire it to a
  `graphical-session`-bound systemd user service rather than bashrc, or FIDO2
  keys block a display-manager autologin waiting on a security-key touch.
- **`vintagestory-latest`** — Vintage Story client bumped ahead of nixpkgs.
