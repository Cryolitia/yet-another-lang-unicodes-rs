{
  description = "yet-another-lang-unicodes-rs' Nix flake";
  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    extra-substituters = [ "https://cryolitia.cachix.org" ];
    extra-trusted-public-keys = [
      "cryolitia.cachix.org-1:/RUeJIs3lEUX4X/oOco/eIcysKZEMxZNjqiMgXVItQ8="
    ];
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
    }:
    let
      systems = [
        "x86_64-linux"
        "i686-linux"
        "aarch64-linux"
        "armv6l-linux"
        "armv7l-linux"

        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      devShells = forAllSystems (
        system:
        (
          let
            pkgs = import nixpkgs {
              config = {
                allowUnfree = true;
                cudaSupport = false;
              };
              inherit system;
              overlays = [ (import rust-overlay) ];
            };
            rust = (pkgs.rust-bin.stable.latest.rust.override { extensions = [ "rust-src" ]; });
          in
          {
            default = (
              (pkgs.mkShell.override { stdenv = pkgs.llvmPackages.stdenv; }) {
                buildInputs = (
                  with pkgs;
                  [
                    rust
                    pkg-config
                    opencc
                  ]
                );

                LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
                RUST_SRC_PATH = "${rust}/lib/rustlib/src/rust";
                LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc ];

                shellHook = ''
                  rustc --version
                  cargo --version
                  echo ${rust}

                  exec zsh
                '';
              }
            );
          }
        )
      );
    };
}
