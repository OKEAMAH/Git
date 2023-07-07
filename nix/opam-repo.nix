{runCommand}: let
  revision = builtins.readFile (
    runCommand
    "opam-repo-rev"
    {
      src = ../scripts/version.sh;
    }
    ''
      . $src
      echo -n $full_opam_repository_tag > $out
    ''
  );
in
  fetchTarball "https://github.com/ocaml/opam-repository/archive/${revision}.tar.gz"
