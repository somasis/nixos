{ lib, bundlerApp }:
bundlerApp rec {
  pname = "youplot";
  gemdir = ./.;

  exes = [ "youplot" "uplot" ];

  meta = with lib; {
    description = "A command line tool that draws plots on the terminal";
    homepage = "https://github.com/red-data-tools/YouPlot";
    license = licenses.mit;
    maintainers = with maintainers; [ somasis ];
    platforms = platforms.unix;
  };
}
