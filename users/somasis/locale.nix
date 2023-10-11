{ lib
, config
, pkgs
, ...
}:
let
  fcitxConfig = lib.generators.toINI {
    listsAsDuplicateKeys = false;
    mkKeyValue = k: v:
      if builtins.isList v then
        lib.generators.mkKeyValue { } " = " k
          (
            lib.imap0 (i: item: lib.generators.mkKeyValue { } " = " "${i}" (lib.escape [ ''='' ] item)) v
          )
      else
        lib.generators.mkKeyValueDefault { } " = " k v
    ;
  };
in
{
  home = {
    keyboard.options = [ "compose:ralt" ];
    language = {
      base = "en_US.UTF-8";
      collate = "C";
      # numeric = "C.UTF-8";
      # time = "en_DK.UTF-8/UTF-8";
    };

    # TODO: It would be nice to have ISO dates and such as the default
    #       formats, but people recommend using some European locales
    #       for that, which feels like a poor solution.
    #       There's locale-en_XX, but I'm not sure how to put it into glibcLocales.
    #       <https://xyne.dev/projects/locale-en_xx/>
    # glibcLocales = pkgs.buildPackages.glibcLocales.overrideAttrs (oldAttrs: {
    #   allLocales = lib.any (x: x == "all") config.i18n.supportedLocales;
    #   locales = config.i18n.supportedLocales;
    #   # TODO: I'd really prefer to not patch it like this.
    #   patches = [ ./locale-en_XX.patch ];
    # });
  };

  i18n.inputMethod = {
    enabled = lib.mkIf config.xsession.enable "fcitx5";
    fcitx5.addons = [
      # ja
      # pkgs.fcitx5-mozc
      pkgs.fcitx5-anthy

      # tok
      pkgs.fcitx5-ilo-sitelen

      pkgs.fcitx5-table-extra
      pkgs.fcitx5-table-other

      pkgs.fcitx5-gtk
      pkgs.libsForQt5.fcitx5-qt
    ];
  };

  # xdg.configFile = {
  #   # "fcitx5/config" = fcitxConfig };

  #   "fcitx5/conf/spell" = fcitxConfig {
  #     ProviderOrder = [
  #       "Presage"
  #       "Enchant"
  #       "Custom"
  #     ];
  #   };
  # };

  systemd.user.sessionVariables = {
    GTK_IM_MODULE = lib.mkForce "xim";
    QT_IM_MODULE = lib.mkForce "xim";
    XMODIFIERS = lib.mkForce "@:bim=fcitx";
  };

  persist.directories = [{ method = "symlink"; directory = "etc/fcitx5"; }];
  cache.directories = [
    { method = "symlink"; directory = "etc/fcitx"; }
    { method = "symlink"; directory = ".anthy"; }
  ];

  programs.kakoune.plugins = [ pkgs.kakounePlugins.kakoune-fcitx ];

  home.packages = [
    pkgs.hunspell
    pkgs.hunspellDicts.en-us-large
    pkgs.hunspellDicts.en-gb-ise
    pkgs.hunspellDicts.en-au-large

    pkgs.hunspellDicts.es-any
    pkgs.hunspellDicts.es-es
    pkgs.hunspellDicts.es-mx

    pkgs.hunspellDicts.de-de
    pkgs.hunspellDicts.fr-any

    pkgs.hunspellDicts.tok

    # aspell is still used by kakoune's spell.kak, unfortunately.
    pkgs.aspellDicts.en
    pkgs.aspellDicts.en-computers
    pkgs.aspellDicts.en-science

    pkgs.aspellDicts.es
    pkgs.aspellDicts.de
    pkgs.aspellDicts.fr

    pkgs.aspellDicts.la

    (pkgs.writeShellApplication {
      name = "spell";
      runtimeInputs = [
        pkgs.hunspell
        pkgs.diffutils
      ];

      text = ''
        hunspell() {
            command hunspell ''${d:+-d "$d"} "$@"
        }

        d=
        while getopts :d: arg >/dev/null 2>&1; do
            case "$arg" in
                d) d="$OPTARG"; ;;
                *) usage ;;
            esac
        done
        shift $(( OPTIND - 1 ))

        diff -u "$1" <(hunspell -U "$1")
      '';
    })
  ];
}
