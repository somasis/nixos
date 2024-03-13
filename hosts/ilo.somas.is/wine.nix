{ pkgs
, lib
, ...
}:
let
  wine = pkgs.wineWow64Packages.stableFull;
in
{
  boot.binfmt.registrations.wine = {
    recognitionType = "magic";
    magicOrExtension = "MZ";
    interpreter = lib.getExe wine;
  };

  environment.systemPackages = [
    pkgs.winetricks
    pkgs.wineasio

    wine
  ];

  boot.kernel.sysctl = {
    # Enable usage of performance data by non-admin programs.
    # I only really enabled this for Wine.
    # <https://wiki.archlinux.org/title/Intel_graphics#Enable_performance_support>
    "dev.i915.perf_stream_paranoid" = 0;
  };
}
