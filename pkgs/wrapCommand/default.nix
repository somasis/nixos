{ lib

, package
, name ? package.pname or package.name
, command ? "/bin/${package.meta.mainProgram or package.pname or package.name}"

, commandName ? ""
, inheritCommandName ? false

, workingDirectory ? ""

, setEnvironment ? { }
, setEnvironmentDefault ? { }
, unsetEnvironment ? [ ]
  # , prefixEnvironment ? {}

, prependFlags ? ""
, appendFlags ? ""

, beforeCommand ? [ ]

, makeWrapper
, symlinkJoin
}:

assert (builtins.typeOf name == "string");
assert (builtins.typeOf command == "string");

assert (builtins.typeOf commandName == "string");
assert (builtins.typeOf inheritCommandName == "bool");

assert (builtins.typeOf workingDirectory == "string");

assert (builtins.typeOf setEnvironment == "set");
assert (builtins.typeOf setEnvironmentDefault == "set");
assert (builtins.typeOf unsetEnvironment == "list");

assert (builtins.typeOf prependFlags == "string");
assert (builtins.typeOf appendFlags == "string");

assert (builtins.typeOf beforeCommand == "list");

let
  commandName' = lib.optionalString (commandName != "") ''
    --argv0 ${lib.escapeShellArg commandName}
  '';

  inheritCommandName' = lib.optionalString inheritCommandName "--inherit-argv0";

  workingDirectory' = lib.optionalString (workingDirectory != "") ''
    --chdir ${lib.escapeShellArg workingDirectory}
  '';

  setEnvironment' = lib.optionalString (setEnvironment != { }) (
    lib.concatStringsSep " " (
      lib.mapAttrsToList
        (k: v: "--set ${lib.escapeShellArg k} ${lib.escapeShellArg v}")
        setEnvironment
    )
  );

  setEnvironmentDefault' = lib.optionalString (setEnvironmentDefault != { }) (
    lib.concatStringsSep " " (
      lib.mapAttrsToList
        (k: v: "--set-default ${lib.escapeShellArg k} ${lib.escapeShellArg v}")
        setEnvironmentDefault
    )
  );

  unsetEnvironment' = lib.optionalString (unsetEnvironment != [ ]) (
    lib.concatMapStringsSep " "
      (x: lib.escapeShellArgs [ "--unset" x ])
      unsetEnvironment
  );

  beforeCommand' = lib.optionalString (beforeCommand != [ ]) (
    lib.concatMapStringsSep " "
      (x: lib.escapeShellArgs [ "--run" x ])
      beforeCommand
  );

  prependFlags' = lib.optionalString (prependFlags != "")
    "--add-flags ${lib.escapeShellArg prependFlags}"
  ;

  appendFlags' = lib.optionalString (appendFlags != "")
    "--append-flags ${lib.escapeShellArg appendFlags}"
  ;

  args' = lib.concatStringsSep " " [
    commandName'
    inheritCommandName'

    setEnvironment'
    setEnvironmentDefault'
    unsetEnvironment'

    workingDirectory'

    beforeCommand'

    prependFlags'
    appendFlags'
  ];
in
(symlinkJoin {
  inherit name;

  buildInputs = [ makeWrapper ];

  paths = [ package ];

  postBuild = ''
    wrapProgram $out/${lib.escapeShellArg command} ${args'}
  '';
}) // {
  meta = package.meta // { description = "${package.meta.description} (wrapped)"; };
}
