{
  description = "pdfsizeopt is a program for converting large PDF files to small ones, without decreasing visual quality or removing interactive features (such as hyperlinks).";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-lib.url = "github:NixOS/nixpkgs/nixpkgs-unstable?dir=lib";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs-lib";

    pdfsizeopt_libexec = {
      url = "https://github.com/pts/pdfsizeopt/releases/download/2023-04-18/pdfsizeopt_libexec_linux-v9.tar.gz";
      flake = false;
    };

    pdfsizeopt_single = {
      url = "https://raw.githubusercontent.com/pts/pdfsizeopt/master/pdfsizeopt.single";
      flake = false;
    };
  };

  outputs = inputs @ {
    pdfsizeopt_libexec,
    pdfsizeopt_single,
    nixpkgs,
    flake-parts,
    ...
  }: let
    mk_pdfsizeopt = {
      stdenv,
      bash,
      ...
    }:
      stdenv.mkDerivation {
        name = "pdfsizeopt";

        buildCommand = ''
          mkdir -p $out/lib
          cp -r ${pdfsizeopt_libexec} $out/lib/pdfsizeopt_libexec
          cp ${pdfsizeopt_single} $out/lib/pdfsizeopt.single
          chmod +x $out/lib/pdfsizeopt.single

          mkdir -p $out/bin
          cat > $out/bin/pdfsizeopt << EOF
          #!${bash}/bin/bash
          $out/lib/pdfsizeopt.single "\$@"
          EOF

          chmod +x $out/bin/pdfsizeopt
        '';
      };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      perSystem = {
        pkgs,
        lib,
        system,
        ...
      }: {
        packages = rec {
          default = pdfsizeopt;
          pdfsizeopt = mk_pdfsizeopt pkgs;
        };
      };
    };
}
