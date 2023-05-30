{ pkgs, config, inputs, ... }: {
  home.packages = [
    (pkgs.mblaze.overrideAttrs (
      let
        year = builtins.substring 0 4 inputs.mblaze.lastModifiedDate;
        month = builtins.substring 4 2 inputs.mblaze.lastModifiedDate;
        day = builtins.substring 6 2 inputs.mblaze.lastModifiedDate;
      in
      oldAttrs:
      {
        version = "unstable-${year}-${month}-${day}";
        src = inputs.mblaze;
      }
    ))

    # (pkgs.writeShellScriptBin "minbox" ''
    #     if [ $# -gt 0 ]; then
    #         set -- ~/mail/"$1"/Inbox
    #     else
    #         set -- ~/mail/*\@*/Inbox
    #     fi

    #     mlist "$@" \
    #         | msort -dUS \
    #         | mseq -S \
    #         | mscan -f ' %n\t%u%r%t%c\t%s\t%f\t%d ' \
    #         | ${pkgs.table}/bin/table -o ' │ ' \
    #             -N ID,~,SUBJECT,SENDER,DATE \
    #             -R ID \
    #             -E SUBJECT \
    #             -W SUBJECT,SENDER
    #   }
    # '')

    pkgs.rdrview
  ];

  home.file.".mblaze/profile".text =
    let
      primary = builtins.toString (builtins.map (x: x.address) (builtins.filter (x: x.primary) (builtins.attrValues config.accounts.email.accounts)));
      alternate = builtins.concatStringsSep "," (builtins.concatLists (builtins.map (x: [ x.address ] ++ x.aliases) (builtins.attrValues config.accounts.email.accounts)));
      replyFrom = builtins.concatStringsSep "," (builtins.map (x: "${x.realName} <${x.address}>") (builtins.attrValues config.accounts.email.accounts));
      mailboxes = builtins.concatStringsSep "," (builtins.map (x: x.maildir.absPath) (builtins.attrValues config.accounts.email.accounts));
    in
    ''
      Local-Mailbox: ${primary}
      Alternative-Mailboxes: ${alternate}
      Reply-From: ${replyFrom}
      Mailboxes: ${mailboxes}

      Sendmail: ${pkgs.msmtp}/bin/sendmail
    '';

  home.file.".mblaze/filter".text =
    let
      html = pkgs.writeShellScript "mblaze-text-html" ''
        ${pkgs.rdrview}/bin/rdrview \
            -T title,byline,body \
            -H /dev/stdin \
            | ${pkgs.html-tidy}/bin/tidy \
                -q \
                -asxml \
                -w 0 2>/dev/null \
            | ${pkgs.w3m-batch}/bin/w3m \
                -dump \
                -T text/html

        exit 62 # mshow(1): The output is printed raw, without escaping.
      '';
    in
    ''
      text/html: ${html}
    '';
}
