{ config
, lib
, osConfig
, pkgs
, ...
}:
let
  inherit (lib) options types;
  inherit (options) mkEnableOption mkOption;
  inherit (config.lib.nixos) escapeSystemdPath escapeSystemdExecArgs;

  rcloneCfg = config.programs.rclone;
  mountsCfg = config.somasis.mounts;

  rclonePkg = rcloneCfg.package;
  # rclonePkg = rcloneCfg.finalPackage;
  rcloneExe = lib.getExe rclonePkg;

  rcloneConfigValue = v:
    if builtins.isNull v then
      ""
    else if builtins.isList v then
      lib.concatMapStringsSep "," (item: lib.generators.mkValueStringDefault { } item) v
    else
      lib.generators.mkValueStringDefault { } v
  ;

  rcloneFormat = pkgs.formats.ini {
    listToValue = rcloneConfigValue;
    mkKeyValue = lib.generators.mkKeyValueDefault { mkValueString = rcloneConfigValue; } "=";
  };

  rcloneProviders = lib.fromJSON (builtins.readFile (pkgs.runCommandLocal "rclone-providers"
    {
      inherit rcloneExe;
      jqExe = lib.getExe config.programs.jq.package;
    } ''
    $rcloneExe config providers \
        | $jqExe -e '
            map(.Name, (.Prefix // empty), (.Aliases // empty))
                | flatten
                | sort
                | unique
        ' \
        > $out
  ''));

  rcloneProviderExists = wantedProvider:
    lib.lists.any (provider: provider == wantedProvider) rcloneProviders
  ;

  rcloneFlags = attrs: lib.cli.toGNUCommandLine { } attrs;
  rclonefsOptions = list: lib.concatStringsSep " " (map (option: "-o ${option}") list);
in
{
  options = {
    programs.rclone = {
      enable = mkEnableOption "Enable rclone";

      package = mkOption {
        type = types.package;
        default = pkgs.rclone;
        defaultText = options.literalExpression "pkgs.rclone";
        description = "The rclone package to use.";
      };

      # finalPackage = mkOption {
      #   type = types.package;
      #   description = ''
      #     The actual package that will be included in the user environment.
      #   '';

      #   readOnly = true;
      #   defaultText = ''
      #     If programs.rclone.extraOptions is non-empty, programs.rclone.package + extraOptions prepended as flags.
      #     If empty, programs.rclone.package unwrapped.
      #   '';
      # };

      daemon = {
        enable = mkEnableOption "Enable rclone remote control daemon";
        settings = mkOption {
          type = with types; attrsOf;
          default = { };
          description = ''
            Flags to pass to `rclone rcd`.
            See `rclone rcd --help` for details.
          '';
        };
      };

      extraOptions = mkOption {
        type = with types; listOf nonEmptyStr;
        description = ''
          Extra arguments to pass to `rclone` invocations by default.
          See `rclone help flags` for a list of supported global flags, networking-related flags, etc.
        '';
        default = [ ];
        example = [ "--bwlimit" "512K" ];
      };

      remotes = mkOption {
        inherit (rcloneFormat) type;
        description = ''
          Remotes.
          See `rclone help backends` for a list of supported remotes.
        '';

        default = { };
        example = {
          seedbox = {
            type = "sftp";
            host = "ssh.nsa.gov";
            user = "esnowden";

            ask_password = false;
            key_file = "~/.ssh/id_ed25519";
            known_hosts_file = "~/.ssh/known_hosts";
          };
        };
      };
    };

    somasis.mounts = {
      enable = mkEnableOption "Enable rclone mount configuration";

      mounts = mkOption {
        type = types.attrsOf (types.submodule (
          { name, config, ... }: {
            options = {
              remote = mkOption {
                type = types.nonEmptyStr;
                description = "Remote to mount. Remote must exist in `programs.rclone.remotes`.";
                default = null;
                example = "seedbox";
              };

              what = mkOption {
                type = types.str;
                description = "Path on remote to mount";
                default = "";
                example = "/mnt/raid";
              };

              where =
                let remoteSettings = rcloneCfg.remotes."${config.remote}"; in
                mkOption {
                  type = types.nonEmptyStr;
                  description = "Local path to mount remote path";
                  default = "${config.home.homeDirectory}/mnt/${remoteSettings.type}/${name}";
                  defaultText = options.literalExpression "\${config.home.homeDirectory}/mnt/<mount remote type>/<mount name>";
                  example = options.literalExpression "\${config.home.homeDirectory}/mnt/seedbox";
                }
              ;

              options = mkOption {
                type = with types; listOf str;
                description = ''
                  Options for `rclone mount` and the mount services *only*.
                  See `rclone mount --help` for details.
                '';
                default = [ ];
                example = [ "vfs-cache-max-size=1G" ];
              };

              linger = mkOption {
                type = with types; either nonEmptyStr ints.nonnegative;
                description = ''
                  How long the mount should be kept around after its last use.
                  See systemd.automount(7) "TimeoutIdleSec=" for details.
                '';
                default = "5min 20s";
                example = 0;
              };
            };
          }
        ));

        description = "Set of mounts to create";

        default = { };
        example = {
          seedbox = {
            remote = "seedbox";
            what = "/mnt/raid";
            where = options.literalExpression "\${config.home.homeDirectory}/mnt/seedbox";
            options = [ "vfs-cache-max-size=1G" ];
          };
        };
      };
    };
  };

  config = {
    # assertions = [{
    #   assertion =
    #     let
    #       configuredRemotes = builtins.attrNames rcloneCfg.remotes;
    #       configuredMounts = builtins.attrNames mountsCfg.mounts;

    #       invalidMounts =
    #         lib.filter
    #           (remote: lib.lists.any (configuredRemote: configuredRemote == remote) configuredRemotes)
    #           configuredMounts
    #       ;
    #     in
    #     if mountsCfg.enable && mountsCfg.mounts != { } then
    #       invalidMounts == 0
    #     else
    #       true
    #   ;
    #   message = "Each configured mount must match a configured rclone remote";
    # }];

    # programs.rclone.finalPackage =
    #   if rcloneCfg.extraOptions != [ ] then
    #     (pkgs.wrapCommand {
    #       package = rcloneCfg.package;
    #       wrappers = [{
    #         command = "/bin/rclone";
    #         prependFlags = lib.escapeShellArgs rcloneCfg.extraOptions;
    #       }];
    #     })
    #   else
    #     rcloneCfg.package
    # ;

    home =
      lib.mkIf config.programs.rclone.enable {
        packages = [ config.programs.rclone.package ];

        activation.applyRcloneSettings = lib.mkIf (config.programs.rclone.remotes != { }) (
          lib.hm.dag.entryAfter [ "writeBoundary" ]
            (
              let
                getRemovedKeys = pkgs.writeJqScript "get-removed-keys.jq" { null-input = true; raw-output = true; } ''
                  [
                    (
                      input as $configured
                        | input as $actual
                        | $actual
                        | delpaths([(
                          $configured
                            | paths
                            | select(length > 1)
                            | select(.[1] != "token")
                        )])
                        | paths
                        | select(length > 1))
                  ] | map(select(.[1] != "token"))
                ''
                ;

                json2ini = pkgs.writeJqScript "json2ini.jq" { raw-output = true; } ''
                  to_entries
                    | map(
                      "[\(.key)]",
                      (.value | to_entries[] | "\(.key) = \(.value)"),
                      ""
                    )[]
                '';

                # prune-rclone-config = ''
                #   rclone_removed_paths=$(
                #       ${getRemovedKeys} \
                #           <(${rcloneExe} --config ${rcloneFormat.generate "generated-rclone.conf" rcloneCfg.remotes} config dump) \
                #           <(${rcloneExe} --config ${lib.escapeShellArg config.xdg.configHome}/rclone/rclone.conf config dump)
                #   )

                #   ${rcloneExe} config dump \
                #       | ${lib.getExe pkgs.jq} -r --argjson removedPaths "$rclone_removed_paths" 'delpaths($removedPaths)' \
                #       | ${json2ini} \
                #       | ${pkgs.moreutils}/bin/sponge ${lib.escapeShellArg config.xdg.configHome}/rclone/rclone.conf
                # '';

                setCommand = remote: key: value: ''
                  ${lib.toShellVar "rclone_remote" remote}
                  ${lib.toShellVar "rclone_key" key}
                  ${lib.toShellVar "rclone_value" (rcloneConfigValue value)}

                  if ${rcloneExe} listremotes | ${pkgs.gnugrep}/bin/grep -Fq "''${rclone_remote}:"; then
                      run ${rcloneExe} \
                          config update \
                          "$rclone_remote" "$rclone_key=$rclone_value" \
                          --non-interactive --no-obscure \
                          >/dev/null

                      if [ -v DRY_RUN ]; then
                          printf 'would update settings for rclone remote "%s" (%q=%q)\n' \
                              "$rclone_remote" \
                              "$rclone_key" \
                              "$rclone_value"
                      else
                          verboseEcho "updated settings for rclone remote '$rclone_remote' ($rclone_key=$rclone_value)"
                      fi
                  else
                      if [ "$rclone_key" = "type" ]; then
                          run ${rcloneExe} \
                              config create \
                              "$rclone_remote" "$rclone_value" \
                              --non-interactive --no-obscure \
                              >/dev/null
                      else
                          run ${rcloneExe} \
                              config create \
                              "$rclone_remote" "$rclone_key=$rclone_value" \
                              --non-interactive --no-obscure \
                              >/dev/null
                      fi

                      if [ -v DRY_RUN ]; then
                          printf 'would create rclone remote "%s"\n' "$rclone_remote"
                      else
                          printf 'created rclone remote %s, make sure to inspect its configuration before use.\n' "$rclone_remote"
                          printf 'for example, if a token is required for the remote (Google Drive, etc.), run\n'
                          printf '$ rclone config reconnect %q\n' "$rclone_remote:"
                          printf 'and it will walk you through updating the token.\n'
                      fi
                  fi
                '';

                setCommands = lib.mapAttrsToList
                  (remote: remoteSettings:
                    # Ensure `type` is always the first attribute. `rclone config create` needs a type
                    # when creating a remote, and it would complicate activation script logic if we
                    # needed to keep track of the `type` in order to process further remote settings.
                    [ (setCommand remote "type" remoteSettings.type) ]
                    ++ lib.mapAttrsToList
                      (setCommand remote)
                      (builtins.removeAttrs remoteSettings [ "type" ])
                  )
                  config.programs.rclone.remotes;
              in
              # $VERBOSE_ECHO "Pruning rclone configuration of any removed keys"
                # $DRY_RUN_CMD ${prune-rclone-config}
              ''
                verboseEcho "Setting rclone configuration"
                ${lib.concatMapStrings lib.concatStrings setCommands}
              ''
            )
        );
      }
    ;

    systemd.user =
      lib.mkIf (config.somasis.mounts.enable && config.somasis.mounts != { })
        (lib.foldr
          (
            mount:
            units:
            let
              unitPath = escapeSystemdPath mount.where;
              unitDescription = "Mount ${mount.remote}:${mount.what} at ${mount.where}";

              # rclone recommends using
              # > You should not run two copies of rclone using the same VFS cache with
              # > the same or overlapping remotes if using `--vfs-cache-mode > off`.
              # > This can potentially cause data corruption if you do. You can work
              # > around this by giving each rclone its own cache hierarchy with
              # > `--cache-dir`. You don't need to worry about this if the remotes in
              # > use don't overlap.
              # rcloneCache = "${config.xdg.cacheHome}/rclone/
            in
            lib.recursiveUpdate
              units
              {
                services."${unitPath}" = {
                  Unit.Description = unitDescription;
                  Unit.PartOf = [ "rclone.target" ];
                  Unit.Upholds = [ "${unitPath}.mount" ];
                  Install.WantedBy = [ "rclone.target" "${unitPath}.mount" ];

                  Service = {
                    Type = "notify";

                    SyslogIdentifier = "${unitPath}";

                    # <https://rclone.org/commands/rclone_mount/#systemd>
                    # > Note that systemd runs mount units without any environment variables
                    # > including `PATH` or `HOME`. This means that tilde (`~`) expansion will
                    # > not work and you should provide `--config` and `--cache-dir` explicitly
                    # > as absolute paths via rclone arguments.
                    ExecStartPre = [
                      (pkgs.writeShellScript "check-rclone-config" ''
                        ${rcloneExe} \
                            --config ${lib.escapeShellArg config.xdg.configHome}/rclone/rclone.conf \
                            --cache-dir ${lib.escapeShellArg config.xdg.cacheHome}/rclone \
                            config touch
                      '')
                      (pkgs.writeShellScript "mount-rclone-mkdir" ''
                        ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg mount.where}
                      '')
                    ];

                    ExecStart = lib.singleton (pkgs.writeShellScript "mount-rclone" ''
                      exec ${rcloneExe} ${lib.escapeShellArgs (
                        []
                          ++ [ "--config" "${config.xdg.configHome}/rclone/rclone.conf" ]
                          ++ [ "--cache-dir" "${config.xdg.cacheHome}/rclone" ]
                          ++ [ "mount" "${mount.remote}:${mount.what}" mount.where ]
                          ++ lib.optionals (mount.options != [ ]) (
                            [ "-o" ] ++ lib.intersperse "-o" mount.options
                          )
                      )}
                    '');
                  };
                };

                mounts."${unitPath}" = {
                  Unit.Description = unitDescription;
                  Unit.BindsTo = [ "${unitPath}.service" ];
                  Unit.After = [ "${unitPath}.service" ];
                  Install.WantedBy = [ "mounts.target" "rclone.target" ];

                  Mount = {
                    Type = "rclone";
                    What = "${mount.remote}:${mount.what}";
                    Where = mount.where;
                    Options = lib.concatStringsSep "," ([ "rw" "_netdev" "args2env" ]);
                  };
                };

                # BUG These don't properly function right now...
                #     not sure how userspace automounts ever would have worked.
                # automounts."${unitPath}" = {
                #   Unit.Description = unitDescription;
                #   Unit.PartOf = [ "rclone.target" ];
                #   Install.WantedBy = [ "rclone.target" ];

                #   Automount.Where = mount.where;
                #   Automount.TimeoutIdleSec = mount.linger;
                # };
              }
          )
          {
            targets.rclone = {
              Unit.Description = "All rclone mounts";
              Install.WantedBy = [ "default.target" ];
            };
          }
          (lib.mapAttrsToList (n: v: v) config.somasis.mounts.mounts)
        )
    ;
  };
}
