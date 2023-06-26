{ lib

, package
, name ? package.pname or package.name

, wrappers

, makeWrapper
, symlinkJoin
}:

assert (lib.isDerivation package || lib.isStorePath package);
assert (lib.isString name);

assert (lib.isList wrappers);
assert (wrappers != [ ]);

(symlinkJoin {
  inherit name;

  buildInputs = [ makeWrapper ];

  paths = [ package ];

  postBuild =
    lib.concatMapStringsSep
      "\n"
      (x:
        let
          command = x.command or "/bin/${package.meta.mainProgram or package.pname or package.name}";

          commandName = x.commandName or "";
          inheritCommandName = x.inheritCommandName or false;

          workingDirectory = x.workingDirectory or "";

          setEnvironment = x.setEnvironment or { };
          setEnvironmentDefault = x.setEnvironmentDefault or { };
          unsetEnvironment = x.unsetEnvironment or [ ];

          # prefixEnvironment = x.prefixEnvironment ? {}

          prependFlags = x.prependFlags or "";
          appendFlags = x.appendFlags or "";

          beforeCommand = x.beforeCommand or [ ];

          extraArgs = x.extraArgs or "";
        in

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

        assert (builtins.typeOf extraArgs == "string");

        let
          args = [ ]
          ++ lib.optionals (commandName != "") [ "--argv0" commandName ]
          ++ lib.optional inheritCommandName "--inherit-argv0"
          ++ lib.optionals (setEnvironment != { }) (lib.flatten (lib.mapAttrsToList (k: v: [ "--set" k v ]) setEnvironment))
          ++ lib.optionals (setEnvironmentDefault != { }) (lib.flatten (lib.mapAttrsToList (k: v: [ "--set-default" k v ]) setEnvironmentDefault))
          ++ lib.optionals (unsetEnvironment != [ ]) (lib.flatten (map (x: [ "--unset" x ]) unsetEnvironment))
          ++ lib.optionals (workingDirectory != "") [ "--chdir" workingDirectory ]
          ++ lib.optionals (beforeCommand != [ ]) (lib.flatten (map (x: [ "--run" x ]) beforeCommand))
          ++ lib.optionals (prependFlags != "") [ "--add-flags" prependFlags ]
          ++ lib.optionals (appendFlags != "") [ "--append-flags" appendFlags ]
          ;
        in
        "wrapProgram $out/${lib.escapeShellArg command} ${lib.escapeShellArgs args} ${extraArgs}"
      )
      wrappers
  ;
}) // {
  meta = package.meta // { description = "${package.meta.description} (wrapped)"; };
}
