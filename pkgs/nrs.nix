# `nrs` — nixos-rebuild switch with a hostname-derived flake target, so running
# it on one machine can't accidentally apply another machine's config (which on
# a GPU box can brick the display until a PSU power drain).
#
#   nrs                       → flake target = $(hostname)
#   nrs 3d-printing           → explicit override
#   nrs gamingpc --show-trace → explicit target + passthrough args
#
# The flake dir defaults to ~/nixos-configs; override with $NRS_FLAKE.
#
# Before switching it checks that declarative passwords can still be satisfied —
# see the comment on the check itself. Set $NRS_SKIP_PASSWD_CHECK to bypass.
{ writeShellScriptBin, jq }:

writeShellScriptBin "nrs" ''
  set -euo pipefail
  flake="''${NRS_FLAKE:-$HOME/nixos-configs}"
  if [[ $# -gt 0 && "$1" != -* ]]; then
    target="$1"; shift
  else
    target="$(hostname)"
  fi

  # Precondition: with users.mutableUsers = false, every account's password comes
  # from a hashedPasswordFile and NOTHING else — /etc/shadow is rewritten from it
  # on each activation. If that file is missing at activation time (a secrets
  # backend that can't decrypt, a key that was never deployed, a renamed secret)
  # the account is written LOCKED, with no error loud enough to stop the switch.
  # On a machine whose only other way in is a physical console, that is a keyboard
  # -and-monitor recovery trip for a mistake the shell could have caught first.
  #
  # So catch it first. The current generation's users-groups.json says which files
  # this system's accounts depend on; a plain existence test says whether the
  # machine can still produce them. Both are readable unprivileged — the json is a
  # world-readable store path, and secret files sit under traversable (o+x)
  # directories even when the contents are root-only — so this costs no sudo, no
  # evaluation and no build.
  #
  # It reads the RUNNING system, not the one about to be built: a machine that
  # already decrypts is a machine that will still decrypt, while the target config
  # can legitimately name files that do not exist yet (adding a password secret
  # for the first time), which would make a target-based check cry wolf. That also
  # makes it fail OPEN if the layout it reads ever changes — hence the warning
  # rather than silence, since a safety check nobody notices dying is worse than
  # no check at all.
  if [[ -z "''${NRS_SKIP_PASSWD_CHECK:-}" && -r /run/current-system/activate ]]; then
    ugj="$(grep -om1 '/nix/store/[a-z0-9]\{32\}-users-groups.json' /run/current-system/activate || true)"
    if [[ -z "$ugj" || ! -r "$ugj" ]]; then
      echo "nrs: warning: can't read the current generation's users-groups.json;" >&2
      echo "nrs: skipping the declarative-password check." >&2
    elif [[ "$(${jq}/bin/jq -r '.mutableUsers' "$ugj")" == "false" ]]; then
      missing="$(${jq}/bin/jq -r \
        '.users[] | select(.hashedPasswordFile) | .name + "\t" + .hashedPasswordFile' "$ugj" |
        while IFS=$'\t' read -r u f; do
          [[ -e "$f" ]] || printf '    %s -> %s\n' "$u" "$f"
        done)"
      if [[ -n "$missing" ]]; then
        {
          echo "nrs: refusing to switch — declarative passwords are in use"
          echo "nrs: (users.mutableUsers = false) but these files are missing:"
          echo
          echo "$missing"
          echo
          echo "  Switching now would write those accounts LOCKED. Restore the files"
          echo "  first (on a secrets backend, that usually means giving this machine"
          echo "  its decryption key back), then re-run."
          echo
          echo "  NRS_SKIP_PASSWD_CHECK=1 nrs $target   # if they'll appear during this switch"
        } >&2
        exit 1
      fi
    fi
  fi

  exec sudo nixos-rebuild switch --flake "$flake#$target" "$@"
''
