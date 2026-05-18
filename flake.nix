{
  description = "Claude sandbox dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs, nixpkgs-stable }:
    let
      mkPackage = system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-stable = import nixpkgs-stable { inherit system; };
        in pkgs.buildEnv {
          name = "sandbox-env";
          paths = with pkgs; [
            # Shell / core
            bash
            coreutils
            gnused
            gnugrep
            findutils
            gawk

            # VCS
            git
            git-lfs
            gh

            # CLI utilities
            curl
            jq
            vim
            cacert
            ripgrep
            ncurses

            # Claude Code
            claude-code

            # direnv
            direnv
          ];
        };
    in {
      packages.x86_64-linux.default = mkPackage "x86_64-linux";
      packages.aarch64-linux.default = mkPackage "aarch64-linux";
    };
}
