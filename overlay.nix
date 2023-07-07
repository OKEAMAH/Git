final: prev: let
  inherit (prev) callPackage lib stdenv libiconv makeWrapper;
in {
  # fixed point on opam-nix-integration instead of opamPackages since
  # the opam-nix-integration overlay defines ocamlPackages as:
  # final: prev: {
  #   opam-nix-integration = ...;
  #   ocamlPackages = final.opam-nix-integration;
  # }
  opam-nix-integration = let
    tezosOpamRepo = callPackage ./nix/tezos-opam-repo.nix {};
    opamRepo = callPackage ./nix/opam-repo.nix {};
    tezosLibs = callPackage ./nix/libs.nix {};

    pickLatestOverlay = final: prev:
      builtins.mapAttrs
      (pkgName: prevPkg: prevPkg.latest or prevPkg)
      prev;

    increaseJobsForOCamlOverlay = final: prev:
      lib.optionalAttrs (lib.hasAttr "ocaml-base-compiler" prev) {
        ocaml-base-compiler = prev.ocaml-base-compiler.override {
          # Compile faster!
          jobs = "$NIX_BUILD_CORES";
        };
      };

    darwinOverlay = final: prev: {
      hacl-star-raw = prev.hacl-star-raw.overrideAttrs (old: {
        # Uses unsupported command-line flags
        NIX_CFLAGS_COMPILE = ["-Wno-unused-command-line-argument"];
      });

      class_group_vdf = prev.class_group_vdf.overrideAttrs (old: {
        hardeningDisable =
          (old.hardeningDisable or [])
          ++ lib.optionals stdenv.isAarch64 ["stackprotector"];
      });

      # This package makes no sense to build on MacOS. Some OPAM package
      # incorrectly depends on it universally.
      inotify = null;
    };

    fixRustPackagesOverlay = final: prev: {
      conf-rust-2021 = prev.conf-rust.overrideAttrs (old: {
        propagatedNativeBuildInputs =
          (old.propagatedNativeBuildInputs or [])
          ++
          # Upstream conf-rust* packages don't request libiconv
          [libiconv];
      });
    };

    # Tezos sapling
    fixTezosSaplingOverlay = final: prev: {
      tezos-sapling = prev.tezos-sapling.overrideAttrs (old: {
        # OPAM_SWITCH_PREFIX in `dune` file for `lib_sapling` needs to
        # point to nix-store location of tezos-rust-libs
        OPAM_SWITCH_PREFIX = "${prev.tezos-rust-libs}";
      });
    };

    # fix Tezos wasmer
    fixTezosWasmerOverlay = final: prev: {
      tezos-wasmer = prev.tezos-wasmer.overrideAttrs (old: {
        # OPAM_SWITCH_PREFIX in `dune` file for `lib_wasmer` needs to
        # point to nix-store location of tezos-rust-libs
        OPAM_SWITCH_PREFIX = "${prev.tezos-rust-libs}";
      });
    };

    injectZcashInExecutablesOverlay = final: prev:
      builtins.mapAttrs (pkgName: prevPkg:
        if (builtins.elem pkgName tezosLibs.executables)
        then
          prev.${pkgName}.overrideAttrs (old: {
            nativeBuildInputs =
              (old.nativeBuildInputs or [])
              ++ [makeWrapper];
            postFixup = ''
              for file in $(find $out/bin -type f -executable); do
                wrapProgram $file --prefix XDG_DATA_DIRS : ${prev.tezos-sapling-parameters}/share
              done
            '';
          })
        else prevPkg)
      prev;

    opamDir = ./opam;

    mkOpam = name: {
      name = name;
      src = ./.;
      opam = opamDir + "/${name}.opam";
    };

    mkVirtualOpam = name: {
      name = name;
      opam = opamDir + "/virtual/${name}.opam";
    };

    opams = builtins.map mkOpam (tezosLibs.libs ++ tezosLibs.executables);
    virtualOpams = builtins.map mkVirtualOpam tezosLibs.virtualLibs;

    # Using the tezos opam repository, generate a list of package constraints
    packageConstraints = let
      packages =
        (prev.opam-nix-integration.overrideScope'
          (final: prev: {repository = prev.repository.override {src = tezosOpamRepo;};}))
        .repository
        .packages;

      filteredPackages =
        [
          # conflicts with ocaml-options-vanilla
          "ocaml-option-afl"
          "ocaml-option-flambda"
          "ocaml-option-fp"
        ]
        ++
        # Packages not supported on darwin
        (
          if stdenv.isDarwin
          then ["inotify"]
          else []
        );

      filterMapAttrsToList = f: attrs:
        builtins.filter
        (x: !(isNull x))
        (lib.mapAttrsToList f attrs);
    in
      filterMapAttrsToList
      (
        pkgName: pkg:
          if builtins.elem pkgName filteredPackages
          then null
          else "${pkg.latest.pname}=${pkg.latest.version}"
      )
      packages;
  in
    prev.opam-nix-integration.overrideScope' (
      lib.composeManyExtensions [
        # Set the opam-repository which has the package descriptions.
        # The tezos opam repository is merged with the standard opam repository (with
        # the tezos opam repository taking priority over the opam repository)
        (final: prev: {
          repository =
            prev.repository.override {srcs = [tezosOpamRepo opamRepo];};
        })

        (final: prev:
          prev.repository.select {
            # Define 'pinned' opams
            opams = opams ++ virtualOpams;
            # ocamlformat-rpc is missing from the octez-dev-deps package
            # constraint packages according to the tezos opam repository
            packageConstraints = packageConstraints ++ ["ocamlformat-rpc"];
          })

        # Pick latest
        pickLatestOverlay

        # Tweak common packages.
        increaseJobsForOCamlOverlay

        # Overlays for MacOS
        (
          if stdenv.isDarwin
          then darwinOverlay
          else final: prev: {}
        )

        fixRustPackagesOverlay

        fixTezosSaplingOverlay

        fixTezosWasmerOverlay

        injectZcashInExecutablesOverlay
      ]
    );
}
