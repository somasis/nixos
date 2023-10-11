{ lib
, fetchFromGitLab
, buildNpmPackage
, gnused
, electron
, makeWrapper
}:
buildNpmPackage rec {
  pname = "nxapi";
  version = "1.6.1";

  src = fetchFromGitLab {
    domain = "gitlab.fancy.org.uk";
    owner = "samuel";
    repo = "nxapi";
    rev = "v${version}";
    hash = "sha256-qXiem4+lCge+iqy8rNt66/dJkvDNq/BiXm99VK6c8EQ=";
  };

  npmDepsHash = "sha256-dwwweEqQZVWM9uZmcP6fS8Vep/V1nC0PSxBx9t6TH8U=";
  forceGitDeps = true;

  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  postPatch = ''
    sed -i '/"electron"/d' package.json
  '';

  postInstall = ''
    makeWrapper ${electron}/bin/electron $out/bin/nxapi \
      --add-flags $out/lib/node_modules/nxapi/app \
      --set npm_package_version ${version}
  '';

  meta = with lib; {
    description = "Nintendo Switch Online API client";
    homepage = src.meta.homepage;
    changelog = "${src.meta.homepage}/-/releases/v${version}";
    license = licenses.agpl3;
    maintainers = with maintainers; [ somasis ];
  };
}
