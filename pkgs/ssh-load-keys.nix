# `ssh-load-keys` — load the usual SSH keys into the agent, prompting for
# passphrases and YubiKey touches as needed. Driven at graphical-session start
# by the home-manager module's systemd user service.
#
# Machine-specific keys (e.g. a work VM key) are injected privately via
# $SSH_LOAD_KEYS (space/newline-separated paths) so their names never need to
# live in this public tool.
{ writeShellScriptBin }:

writeShellScriptBin "ssh-load-keys" ''
  echo "Current keys in agent:"
  ssh-add -l 2>/dev/null || echo "  (none)"
  echo ""

  # Regular keys (passphrase prompt)
  echo "Loading regular keys..."
  ssh-add ~/.ssh/id_ed25519 2>/dev/null && echo "  ✓ id_ed25519"

  # Extra machine-specific keys injected via $SSH_LOAD_KEYS.
  for k in ''${SSH_LOAD_KEYS:-}; do
    ssh-add "$k" 2>/dev/null && echo "  ✓ $(basename "$k")"
  done

  # FIDO2 keys (touch required)
  echo ""
  echo "Loading FIDO2 keys (touch security key when it blinks)..."
  ssh-add ~/.ssh/id_ed25519_sk 2>/dev/null && echo "  ✓ id_ed25519_sk"
  ssh-add ~/.ssh/id_ed25519_sk_noverify 2>/dev/null && echo "  ✓ id_ed25519_sk_noverify"
  ssh-add ~/.ssh/id_ed25519_sk_personal 2>/dev/null && echo "  ✓ id_ed25519_sk_personal"

  echo ""
  echo "Loaded keys:"
  ssh-add -l
''
