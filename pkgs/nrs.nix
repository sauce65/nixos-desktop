# `nrs` — nixos-rebuild switch with a hostname-derived flake target, so running
# it on one machine can't accidentally apply another machine's config (which on
# a GPU box can brick the display until a PSU power drain).
#
#   nrs                       → flake target = $(hostname)
#   nrs 3d-printing           → explicit override
#   nrs gamingpc --show-trace → explicit target + passthrough args
#
# The flake dir defaults to ~/nixos-configs; override with $NRS_FLAKE.
{ writeShellScriptBin }:

writeShellScriptBin "nrs" ''
  set -euo pipefail
  flake="''${NRS_FLAKE:-$HOME/nixos-configs}"
  if [[ $# -gt 0 && "$1" != -* ]]; then
    target="$1"; shift
  else
    target="$(hostname)"
  fi
  exec sudo nixos-rebuild switch --flake "$flake#$target" "$@"
''
