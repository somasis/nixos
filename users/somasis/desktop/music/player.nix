{ config
, lib
, pkgs
, ...
}:
let
  inherit (config.lib.somasis)
    formatColor
    removeComments
    ;

  colorAccent = lib.pipe config.xresources.properties."*colorAccent" [
    (formatColor "rgb")
    (replaceStrings [ "rgb" ", " ] [ "Rgb" "," ])
  ];
in
{
  # <https://github.com/figsoda/mmtc/blob/main/Configuration.md#Condition>
  xdg.configFile = {
    "mmtc/mmtc.ron".source = removeComments ''
      Config(
        jump_lines: 10,

        layout:
          Rows([
            Fixed(1,
              Columns([
                Ratio(2,
                  TextboxL(
                    Parts([
                      If(Searching,
                        Parts([
                          Styled([Bold, Fg(LightRed)], Text("/ ")),
                          Styled([Fg(Reset)], Query)
                        ])
                      ),

                      Parts([
                        If(Repeat, Styled([Fg(White)], Text("↻ ")), Styled([Dim], Text("↻ "))),
                        If(Single, Styled([Fg(White)], Text("❶ ")), Styled([Dim], Text("❶ "))),
                        If(Random, Styled([Fg(White)], Text("⁑ ")), Styled([Dim], Text("⁑ "))),
                        If(Consume, Styled([Fg(White)], Text("␡ ")), Styled([Dim], Text("␡ ")))
                      ])
                    ])
                  )
                ),

                Ratio(4,
                  TextboxR(
                    Styled([],
                      If(Not(Stopped),
                        Parts([
                          Styled(
                            [Fg(Green)],
                            Parts([
                              If(Playing, Text("▶️ "), Text("⏸️ ")),
                              CurrentElapsed,
                              Text("/"),
                              CurrentDuration,
                              Text(" "),
                            ])
                          ),

                          If(TitleExist,
                            Styled(
                              [Italic],
                              Parts([
                                Styled([Italic, Bold], CurrentTitle),
                                If(ArtistExist, Parts([
                                  Text(" — "),
                                  Styled([Italic, Fg(LightMagenta)], CurrentArtist)
                                ])),
                                If(AlbumExist, Parts([
                                  Text(" — "),
                                  Styled([Italic, Fg(LightMagenta)], CurrentAlbum)
                                ]))
                              ])
                            ),

                            Styled([Fg(Reset)], CurrentFile)
                          ),
                        ])
                      ),
                    )
                  )
                ),
              ])
            ),

            Min(0,
              Queue([
                Column(
                  item:
                    Ratio(10,
                      If(QueueCurrent,
                        Styled([Italic, Bold],
                          If(QueueTitleExist, QueueTitle, QueueFile)
                        ),
                        If(QueueTitleExist, QueueTitle, QueueFile)
                      )
                    ),
                  style: [Fg(Reset)],
                  selected_style: [Fg(Reset), Bg(${colorAccent})]
                ),
                Column(
                  item:
                    Ratio(8,
                      If(QueueCurrent,
                        Styled([Italic, Bold], QueueArtist),
                        QueueArtist,
                      )
                    ),
                  style: [Fg(Magenta)],
                  selected_style: [Fg(Reset), Bg(${colorAccent})]
                ),
                Column(
                  item:
                    Ratio(8,
                      If(QueueCurrent,
                        Styled([Italic, Bold], QueueAlbum),
                        QueueAlbum,
                      )
                    ),
                  style: [Fg(Magenta)],
                  selected_style: [Fg(Reset), Bg(${colorAccent})]
                ),
                Column(
                  item:
                    Ratio(2,
                      If(QueueCurrent,
                        Styled([Italic, Bold], QueueDuration),
                        QueueDuration,
                      )
                    ),
                  style: [Fg(Magenta)],
                  selected_style: [Fg(Reset), Bg(${colorAccent})]
                )
              ])
            )
          ])
      )
    '';

    "tmux/mmtc.conf".text = ''
      # tmux -L mmtc -f ~/etc/tmux/mmtc.conf attach-session
      new-session -t mmtc

      source "$XDG_CONFIG_HOME/tmux/unobtrusive.conf"

      # Disable scrollback, no need for it
      set-option -g history-limit     0

      set-option -g status           off
      set-option -g status-left      ""
      set-option -g status-right     ""

      # Ignore bells, only check for activity.
      set-option -g monitor-activity  on
      set-option -g monitor-bell      on
      set-option -g visual-activity   off
      set-option -g visual-bell       off

      set-option -g set-titles        on
      set-option -g set-titles-string "mmtc#{?,: #T,}"

      # Set window title rules.
      set-option -g automatic-rename  off
      set-option -g allow-rename      off
      set-option -g renumber-windows  on

      # Respawn mmtc if it exits.
      set-option -g remain-on-exit    on
      set-hook -g   pane-died         kill-server

      # Keybinds.

      ## Disable menus.
      unbind-key -T root MouseDown3Pane
      unbind-key -T root M-MouseDown3Pane

      unbind-key -T root F1

      new-window -n mmtc -- mmtc

      # Delete the default shell window that is spawned by tmux.
      kill-window -t 0
      select-window -t 0
    '';
  };

  home.packages = [ pkgs.mmtc ];

  services.sxhkd.keybindings =
    let
      mpc-toggle = pkgs.writeShellScript "mpc-toggle" ''
        c=$(${pkgs.mpc-cli}/bin/mpc playlist | wc -l)
        [ "$c" -gt 0 ] || ${pkgs.mpc-cli}/bin/mpc add /
        ${pkgs.mpc-cli}/bin/mpc "$@" toggle
      '';
    in
    {
      "XF86AudioPlay" = "${mpc-toggle} -q";
      "shift + XF86AudioPlay" = "${pkgs.mpc-cli}/bin/mpc -q stop";

      "XF86AudioPrev" = "${pkgs.mpc-cli}/bin/mpc -q cdprev";
      "XF86AudioNext" = "${pkgs.mpc-cli}/bin/mpc -q next";

      "shift + XF86AudioPrev" = "${pkgs.mpc-cli}/bin/mpc -q consume";
      "shift + XF86AudioNext" = "${pkgs.mpc-cli}/bin/mpc -q random";
    }
  ;
}
