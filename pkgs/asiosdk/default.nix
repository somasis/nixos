{ lib
, stdenv
, fetchzip
,
}:
stdenv.mkDerivation rec {
  pname = "asiosdk";
  version = "2.3.3_2019-06-14";

  # TODO if I ever move this to nixpkgs, change this to use requirefile if I don't want
  # to get someone in trouble, since this is not a legal way to redistribute the SDK.
  src = fetchzip rec {
    url = "https://download.steinberg.net/sdk_downloads/${pname}_${version}.zip";
    sha256 = "sha256-tsrhHmjZEt13Zw8gJQW4nrXhBTpa0PhcIS3vg3icVio=";
  };

  installPhase = "cp -r . $out";

  meta = with lib; {
    description = "Steinberg ASIO audio development library";
    license = licenses.unfree;
    maintainers = with maintainers; [ somasis ];
    platforms = platforms.all;
    homepage = "https://www.steinberg.net/developers/";
  };
}
