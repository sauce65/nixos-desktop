{
  description = "Reusable NixOS + home-manager modules: desktop baseline, helper packages, overlays";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems
        (system: f system (import nixpkgs { inherit system; }));
    in
    {
      # NixOS profiles — layer base + (desktop | server) per host.
      nixosModules = {
        base = import ./modules/profiles/base.nix;
        desktop = import ./modules/profiles/desktop.nix;
        server = import ./modules/profiles/server.nix;
      };

      # Overlay: pkgs.nrs / pkgs.ssh-load-keys.
      overlays.default = import ./overlays/default.nix;

      # Helper packages, also usable standalone (`nix run .#nrs`, etc.).
      packages = forAllSystems (system: pkgs: {
        nrs = pkgs.callPackage ./pkgs/nrs.nix { };
        ssh-load-keys = pkgs.callPackage ./pkgs/ssh-load-keys.nix { };
      });

      # Proof the profiles compose into a valid NixOS system. `nix flake check`
      # evaluates this; the test fixture supplies the eval's hard requirements
      # (root fs, state version).
      checks = forAllSystems (system: pkgs: {
        desktop-eval = (nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            self.nixosModules.base
            self.nixosModules.desktop
            ./test/fixture.nix
          ];
        }).config.system.build.toplevel;
      });
    };
}
