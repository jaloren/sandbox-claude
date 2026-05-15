{
  description = "Claude sandbox dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-stable, claude-code }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-stable = import nixpkgs-stable { inherit system; };
      dotnet-sdk = pkgs.dotnetCorePackages.combinePackages [
        pkgs.dotnetCorePackages.sdk_8_0
        pkgs.dotnetCorePackages.sdk_9_0
        pkgs.dotnetCorePackages.sdk_10_0
      ];
    in {
      packages.${system}.default = pkgs.buildEnv {
        name = "sandbox-env";
        paths = with pkgs; [
          # Shell / core
          bash
          coreutils
          gnused
          gnugrep
          findutils
          gawk

          # Languages
          pkgs-stable.nodejs_22
          uv
          pkgs-stable.go_1_26
          (pkgs.writeShellScriptBin "dotnet" ''
            export DOTNET_ROOT=${dotnet-sdk}/share/dotnet
            exec ${dotnet-sdk}/bin/dotnet "$@"
          '')

          # Linters / build tools
          golangci-lint

          # VCS
          git
          git-lfs
          gh

          # CLI utilities
          sqlite
          curl
          jq
          vim
          zip
          xz
          patchutils
          gnupg
          cacert
          dos2unix
          fzf
          ripgrep
          delta

          # Claude Code CLI
          claude-code.packages.${system}.default
        ];
      };
    };
}
