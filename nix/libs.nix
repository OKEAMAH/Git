{
  runCommand,
  lib,
}: let
  protocolName = "[Pt|Pr][A-Za-z0-9]+|[alpha|demo]";
  protocolNumber = "[0-9]{3}";
  protocolPattern = "([-${protocolNumber}]?-${protocolName})";

  stripProtocol = pkg: let
    matches = builtins.match protocolPattern pkg;
    replaceWithEmpty = from: str:
      builtins.replaceStrings [from] [""] str;
  in
    if matches != null
    then
      # first match should capture the entire protocol
      # (regex only defines 1 group)
      replaceWithEmpty (builtins.head matches) pkg
    else pkg;

  readScriptInputExecutables = file:
    builtins.map stripProtocol
    (lib.splitString "\n" (builtins.readFile ../script-inputs/${file}));

  isExecutable = file: let
    executables = readScriptInputExecutables file;
  in
    pkg: builtins.elem (stripProtocol pkg) executables;

  isDevExecutable = isExecutable "dev-executables";
  isExperimentalExecutable = isExecutable "experimental-executables";
  isReleasedExecutable = isExecutable "released-executables";

  ls = dir: let
    attrSetFilterMap = f: set:
      builtins.filter (x: !(builtins.isNull x)) (lib.attrsets.mapAttrsToList f set);
  in
    attrSetFilterMap
    (name: type:
      if type == "regular"
      then name
      else null)
    (builtins.readDir dir);

  removeOpamSuffix = s: builtins.substring 0 (builtins.stringLength s - 5) s;

  opams = builtins.map removeOpamSuffix (ls ../opam);

  virtualOpams = builtins.map removeOpamSuffix (ls ../opam/virtual);
in rec {
  libs = builtins.filter (pkg: !(builtins.elem pkg executables)) opams;
  virtualLibs = virtualOpams;
  devExecutables = builtins.filter isDevExecutable opams;
  experimentalExecutables = builtins.filter isExperimentalExecutable opams;
  releasedExecutables = builtins.filter isReleasedExecutable opams;
  executables =
    devExecutables
    ++ experimentalExecutables
    ++ releasedExecutables;
  all = opams ++ virtualOpams;
}
