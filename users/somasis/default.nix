{ config
, pkgs
, nixosConfig
, lib
, ...
}:
{
  imports = [
    ./commands
    ./editor
    ./git
    ./modules
    ./shell

    ./less.nix
    ./man.nix
    ./monitor.nix
    ./pass.nix
    ./skim.nix
    ./spell.nix
    ./ssh.nix
    ./syncthing.nix
    ./tmux.nix
    ./xdg.nix
  ];

  nix.settings.extra-experimental-features = [ "flakes" "nix-command" ];

  home.persistence = {
    "/persist${config.home.homeDirectory}" = {
      directories = [
        { method = "symlink"; directory = "bin"; }
        { method = "symlink"; directory = "logs"; }
      ];

      allowOther = true;
    };

    "/cache${config.home.homeDirectory}" = {
      directories = [{ method = "symlink"; directory = "var/cache/nix"; }];

      allowOther = true;
    };
  };

  home.keyboard.options = [ "compose:ralt" ];

  home.packages = [
    pkgs.dateutils
    pkgs.execline
    pkgs.extrace
    pkgs.file
    pkgs.jdupes
    pkgs.lr
    pkgs.ltrace
    pkgs.moreutils
    pkgs.nq
    pkgs.outils
    pkgs.pigz
    pkgs.pv
    pkgs.rlwrap
    pkgs.rsync
    pkgs.s6
    pkgs.s6-dns
    pkgs.s6-linux-init
    pkgs.s6-linux-utils
    pkgs.s6-networking
    pkgs.s6-portable-utils
    pkgs.s6-rc
    pkgs.snooze
    pkgs.strace
    pkgs.teip
    pkgs.uq
    pkgs.xe
    pkgs.xsv
    pkgs.xz
    pkgs.yq
    pkgs.zstd

    # autocurl - curl for use by background/automatically running services
    (
      let
        inherit (nixosConfig.services) tor;

        userAgent = [ "-A" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36" ];
        proxy = lib.optionals (tor.enable && tor.client.enable) (
          let
            proxyProtocol = if tor.client.dns.enable then "socks5h" else "socks5";
            proxyAddress =
              if (builtins.substring 0 1 tor.client.socksListenAddress.addr) == "/" then
                "${tor.client.socksListenAddress.addr}:${toString tor.client.socksListenAddress.port}"
              else
                "localhost/${tor.client.socksListenAddress.addr}";
          in
          [
            "-x"
            "${proxyProtocol}://${proxyAddress}"
          ]
        );
      in
      pkgs.writeShellApplication {
        name = "autocurl";
        # name = "torcurl";
        # "that's a real toe-curler"

        runtimeInputs =
          [ pkgs.curl ]
          ++ lib.optional nixosConfig.networking.networkmanager.enable pkgs.networkmanager
        ;

        text = ''
          ${lib.optionalString nixosConfig.networking.networkmanager.enable "nm-online -t 60 || exit 7"}
          exec curl \
              --disable \
              --silent \
              --show-error \
              --globoff \
              --disallow-username-in-url \
              --connect-timeout 60 \
              --max-time 60 \
              --retry 10 \
              --limit-rate 512K \
              --parallel \
              --parallel-max 4 \
              ${lib.escapeShellArgs [ userAgent proxy ]} "$@"
        '';
      }
    )
  ];

  programs.jq.enable = true;

  # <https://rosettacode.org/wiki/URL_decoding#jq>
  home.file.".jq".text = ''
    def uri_decode:
      # The helper function converts the input string written in the given
      # "base" to an integer
      def to_i(base):
        explode
        | reverse
        | map(if 65 <= . and . <= 90 then . + 32  else . end)   # downcase
        | map(if . > 96  then . - 87 else . - 48 end)  # "a" ~ 97 => 10 ~ 87
        | reduce .[] as $c
            # base: [power, ans]
            ([1,0]; (.[0] * base) as $b | [$b, .[1] + (.[0] * $c)]) | .[1];

      .  as $in
      | length as $length
      | [0, ""]  # i, answer
      | until ( .[0] >= $length;
          .[0] as $i
          |  if $in[$i:$i+1] == "%"
             then [ $i + 3, .[1] + ([$in[$i+1:$i+3] | to_i(16)] | implode) ]
             else [ $i + 1, .[1] + $in[$i:$i+1] ]
             end)
      | .[1];  # answer
  '';

  systemd.user.startServices = true;

  home.sessionPath = [ "$HOME/bin" ];

  home.sessionVariables."SYSTEMD_PAGER" = "cat";

  home.stateVersion = "22.11";
}
