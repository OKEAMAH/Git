# WARNING!
# This file is provided as a courtesy and comes with no guarantees that it will
# continue to work in the future.
let
  pkgs = import ./nix/nixpkgs.nix;

  mkFrameworkFlags = frameworks:
    pkgs.lib.concatStringsSep " " (
      pkgs.lib.concatMap
      (
        framework: [
          "-F${pkgs.darwin.apple_sdk.frameworks.${framework}}/Library/Frameworks"
          "-framework ${framework}"
        ]
      )
      frameworks
    );
in
  pkgs.stdenv.mkDerivation rec {
    name = "tezos";

    NIX_LDFLAGS = pkgs.lib.optional pkgs.stdenv.isDarwin (
      mkFrameworkFlags [
        "CoreFoundation"
        "IOKit"
        "AppKit"
        "Security"
      ]
    );

    NIX_CFLAGS_COMPILE =
      # Silence errors (-Werror) for unsupported flags on MacOS.
      pkgs.lib.optionals
      pkgs.stdenv.isDarwin
      ["-Wno-unused-command-line-argument"];

    hardeningDisable =
      pkgs.lib.optionals
      (pkgs.stdenv.isAarch64 && pkgs.stdenv.isDarwin)
      ["stackprotector"];

    buildInputs = [pkgs.opamPackages.octez-deps pkgs.makeWrapper];

    # Disable OPAM usage in Makefile.
    TEZOS_WITHOUT_OPAM = true;

    # $OPAM_SWITCH_PREFIX is used to link tezos-rust-libs headers during the build phase
    OPAM_SWITCH_PREFIX = "${pkgs.opamPackages.tezos-rust-libs}";

    # $XDG_DATA_DIRS is used to find the ZCash parameters at runtime,
    # which is why is wrap the binaries in the post fixup phase
    XDG_DATA_DIRS = "${pkgs.opamPackages.tezos-sapling-parameters}/share";

    dontConfigure = true;
    dontCheck = true;

    src = pkgs.lib.sources.cleanSourceWith {
      filter = name: type:
        if type == "directory"
        then name != "_build" && name != "target"
        else true;
      src = pkgs.lib.sources.cleanSource ./.;
    };

    buildPhase = ''
      make experimental-release
    '';

    installPhase = ''
      mkdir -p $out/bin
      find . -maxdepth 1 -iname 'octez-*' -type f -executable -exec cp {} $out/bin \;
    '';

    postFixup = ''
      for file in $(find $out/bin -type f); do
        wrapProgram $file --prefix XDG_DATA_DIRS : ${XDG_DATA_DIRS}
      done
    '';
  }
