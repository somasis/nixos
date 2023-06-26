{ config
, lib
, pkgs
, ...
}:
let
  directory = "share/sonapona";

  click-config-file = with pkgs.python3Packages;
    buildPythonPackage rec {
      pname = "click-config-file";
      version = "0.6.0";

      src = fetchPypi {
        pname = "click_config_file";
        version = "0.6.0";
        hash = "sha256-3tbsGnPEEoByfsnAYDHpKc3YpZRr8PmcDD2zpxeT1RU=";
      };

      propagatedBuildInputs = [
        click
        configobj
      ];

      checkInputs = [
        pytestCheckHook
        pytest-runner
        twine
      ];

      postPatch = ''
        substituteInPlace setup.py \
          --replace "'pytest-runner'" ""
      '';

      doCheck = false;
      pythonImportsCheck = [ "click_config_file" ];

      meta = with lib; {
        description = "Add support for configuration files to Click applications";
        homepage = "https://github.com/phha/click_config_file";
        license = licenses.mit;
      };
    }
  ;

  twarc = with pkgs.python3Packages;
    buildPythonApplication rec {
      pname = "twarc";
      version = "2.14.0";

      src = fetchPypi {
        inherit pname version;
        hash = "sha256-+o7jBS2LlngjG+qV0b3Lq7OWjTXFao0fztyJgujGamY=";
      };

      propagatedBuildInputs = [
        click
        click-config-file
        click-plugins
        humanize
        python-dateutil
        requests-oauthlib
        tqdm

        setuptools # needs pkg_resources
      ];

      checkInputs = [
        pytestCheckHook
        pytest-runner

        black
        pytest-black
        pytest-dotenv

        pytz
        tomli
      ];

      postPatch = ''
        substituteInPlace setup.py \
          --replace '"pytest-runner"' ""
      '';

      preBuild = "export HOME=$(mktemp -d)";

      doCheck = false;
      pythonImportsCheck = [ "twarc" ];

      meta = with lib; {
        description = "Archive tweets from the command line";
        homepage = "https://github.com/docnow/twarc";
        license = licenses.mit;
      };
    }
  ;
in
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "sonapona";

      runtimeInputs = [
        pkgs.bfs
        pkgs.coreutils
        pkgs.xe
        pkgs.gnused
      ];

      text = ''
        bfs -H "$HOME/"${lib.escapeShellArg directory} \
            -mindepth 2 \
            -type f \
            ! -executable \
            -print0 \
            | shuf -z -n 1 \
            | xe fold -w 80 -s \
            | sed 's/ *$//'
      '';
    })

    twarc
  ];

  persist.directories = [{
    method = "symlink";
    inherit directory;
  }];

  somasis.chrome.stw.widgets.sonapona = {
    text = {
      font = "monospace:style=heavy:size=10";
      color = config.xresources.properties."*darkForeground";
    };

    window = {
      color = config.xresources.properties."*color4";
      opacity = 0.15;
      position = {
        x = -24;
        y = -24;
      };

      padding = 12;
    };

    update = 60;

    command = "sonapona ! -name '*.long'";
  };
}
