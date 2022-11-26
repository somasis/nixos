{ config, ... }: {
  xdg.userDirs.music = "${config.home.homeDirectory}/audio/library";

  _module.args.music = {
    source = "${config.xdg.userDirs.music}/source";
    lossless = "${config.xdg.userDirs.music}/lossless";
    lossy = "${config.xdg.userDirs.music}/lossy";
  };
}
