# WARNING!
# This file is provided as a courtesy and comes with no guarantees that it will
# continue to work in the future.
let
  tezos = (import ./default.nix).overrideAttrs (old: {
    # This makes the shell load faster.
    # Usually Nix will try to load the package's source, which in this case
    # is the entire repository. Given the repository is fairly large, and we
    # don't actually need the source to build the development dependencies,
    # we just remove the dependency on the source entirely.
    src = null;
  });

  pkgs = import ./nix/nixpkgs.nix;

  kernelPackageSet = [
    # Packages required to build & develop kernels
    (pkgs.rust-bin.stable."1.66.0".default.override {
      targets = ["wasm32-unknown-unknown"];
    })
    pkgs.rust-analyzer
    pkgs.wabt

    # Bring Clang into scope in case the stdenv doesn't come with it already.
    pkgs.clang

    # This brings in things like llvm-ar which are needed for Rust WebAssembly
    # compilation on Mac.
    # It isn't used by default. Configure the AR environment variable to
    # make rustc use it.
    pkgs.llvmPackages.bintools
  ];
in
  pkgs.mkShell {
    name = "tezos-shell";

    hardeningDisable =
      pkgs.lib.optionals
      (pkgs.stdenv.isAarch64 && pkgs.stdenv.isDarwin)
      ["stackprotector"];

    inherit (tezos) NIX_LDFLAGS NIX_CFLAGS_COMPILE TEZOS_WITHOUT_OPAM OPAM_SWITCH_PREFIX;

    shellHook = ''
      XDG_DATA_DIRS="${tezos.XDG_DATA_DIRS}:$XDG_DATA_DIRS"
      export XDG_DATA_DIRS
    '';

    buildInputs = with pkgs;
      kernelPackageSet
      ++ [
        nodejs
        cacert
        curl
        shellcheck
        poetry
        opamPackages.octez-deps
        opamPackages.octez-dev-deps
        alejandra
      ]
      ++ (
        if pkgs.stdenv.isDarwin
        then [
          fswatch
        ]
        else [
          inotify-tools
        ]
      );
  }
