{
  services.xserver.libinput = {
    enable = true;

    touchpad = {
      naturalScrolling = true;

      # BUG(?): The Framework's touchpad defaults to button presses, according to libinput?
      clickMethod = "clickfinger";
    };
  };
}
