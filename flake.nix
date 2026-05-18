{
  description = "Claude sandbox dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    # claude-code intentionally omitted — installed at runtime via official
    # installer so it always gets the latest version without an image rebuild
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

          # Fetch official Microsoft .NET SDK binary directly.
          # Avoids combinePackages creating an uncached derivation that
          # triggers a multi-hour source build on aarch64-linux.
          # To refresh hashes: nix-prefetch-url --type sha512 <url>
          # Convert hex → SRI: sha512-$(echo <hex> | xxd -r -p | base64)
          dotnetSdkSrc = {
            x86_64-linux = {
              url = "https://builds.dotnet.microsoft.com/dotnet/Sdk/10.0.203/dotnet-sdk-10.0.203-linux-x64.tar.gz";
              hash = "sha512-/cNqJyhbbzm2JYFEVPTdPnbyJZwSedAxfX+il1FLumB94yMpDULK9n9iuQgasmtu2weeAPK4xwnFgm0zSaRR2Q==";
            };
            aarch64-linux = {
              url = "https://builds.dotnet.microsoft.com/dotnet/Sdk/10.0.203/dotnet-sdk-10.0.203-linux-arm64.tar.gz";
              hash = "sha512-f7yOiyC21stAJpVE6ktekZ3X/HsGa0KfMuf6kIciTxdEW5DHgHxGdFzELymd1+9lq9AjvsA/w0HOB6W7UqWSGA==";
            };
          };
          dotnet-sdk = pkgs.stdenv.mkDerivation {
            pname = "dotnet-sdk";
            version = "10.0.203";
            src = pkgs.fetchurl dotnetSdkSrc.${system};
            # The .NET tarball extracts multiple top-level dirs, not a single one
            sourceRoot = ".";
            nativeBuildInputs = [ pkgs.autoPatchelfHook ];
            buildInputs = with pkgs; [
              stdenv.cc.cc
              zlib
              icu
              libkrb5
              openssl
            ];
            # liblttng-ust.so.0 is the older soname (lttng-ust 2.12); nixpkgs ships .so.1
            # lttng is only used for optional runtime tracing — safe to skip
            autoPatchelfIgnoreMissingDeps = [ "liblttng-ust.so.0" ];
            installPhase = ''
              mkdir -p $out/share/dotnet $out/bin
              cp -r . $out/share/dotnet
              chmod +x $out/share/dotnet/dotnet
              ln -s $out/share/dotnet/dotnet $out/bin/dotnet
            '';
            postFixup = ''
              find $out/share/dotnet/shared -name 'libcoreclr.so' \
                -exec patchelf --add-needed libicui18n.so --add-needed libicuuc.so {} \;
              find $out/share/dotnet/shared -name 'System.Net.Security.Native.so' \
                -exec patchelf --add-needed libgssapi_krb5.so {} \;
              find $out/share/dotnet/shared -name 'System.Security.Cryptography.Native.OpenSsl.so' \
                -exec patchelf --add-needed libssl.so {} \;
            '';
            dontStrip = true;
            # If dotnet can't find its runtime at launch, set in docker-entrypoint.sh:
            #   export DOTNET_ROOT=~/.nix-profile/share/dotnet
          };
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

            # Languages
            pkgs-stable.nodejs_22
            uv
            pkgs-stable.go_1_26
            dotnet-sdk

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

            # Claude Code is intentionally NOT here — installed at container
            # startup via the official installer so it always gets the latest version
            # without requiring an image rebuild
          ];
        };
    in {
      packages.x86_64-linux.default = mkPackage "x86_64-linux";
      packages.aarch64-linux.default = mkPackage "aarch64-linux";
    };
}
