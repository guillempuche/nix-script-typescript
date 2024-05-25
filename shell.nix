{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz";
  }) {} }:

let
 nodejs20 = pkgs.stdenv.mkDerivation {
  pname = "nodejs";
  version = "20.12.2";
  src = pkgs.fetchurl {
    url = "https://nodejs.org/dist/v${nodejs20.version}/node-v${nodejs20.version}.tar.gz";  # This line has changed
    sha256 = "sha256-18vMX7+zHpAB8/AVC77aWavl3XE3qqYnOVjNWc41ztc=";
  };
  buildInputs = [ pkgs.python3 pkgs.openssl ];
  configurePhase = ''
    ./configure --prefix=$out
  '';
  buildPhase = "make";
  installPhase = "make install";
  meta = with pkgs.lib; {
    description = "Node.js is a JavaScript runtime built on Chrome's V8 JavaScript engine.";
    homepage = "https://nodejs.org/";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
  };
};

  yarn4 = pkgs.stdenv.mkDerivation rec {
    pname = "yarn-berry";
    version = "4.2.2";

    src = pkgs.fetchFromGitHub {
      owner = "yarnpkg";
      repo = "berry";
      rev = "@yarnpkg/cli/${version}";
      hash = "sha256-dOWcfeWotWgx1ctY/TEuxH1gkgp9Gxou6jaymJMBHLE=";
    };

    buildInputs = [
      pkgs.nodejs
    ];

    nativeBuildInputs = [
      pkgs.yarn
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild
      yarn workspace @yarnpkg/cli build:cli
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm 755 ./packages/yarnpkg-cli/bundles/yarn.js "$out/bin/yarn"
      runHook postInstall
    '';

    meta = with pkgs.lib; {
      homepage = "https://yarnpkg.com/";
      description = "Fast, reliable, and secure dependency management.";
      license = licenses.bsd2;
      maintainers = with maintainers; [ ryota-ka pyrox0 DimitarNestorov ];
      platforms = platforms.unix;
      mainProgram = "yarn";
    };
  };

  typescript = pkgs.buildNpmPackage rec {
    pname = "typescript";
    version = "5.4.5";

    src = pkgs.fetchFromGitHub {
      owner = "microsoft";
      repo = "TypeScript";
      rev = "v${version}";
      hash = "sha256-W2ulYb06K4VSlFTYOmXTBHrjWXnQdDGzkwBxvl+QJWo=";
    };

    patches = [
      ./disable-dprint-dstBundler.patch
    ];

    npmDepsHash = "sha256-T0WfJaSVzwbNbTL1AiuzMUW/3MKMOZo14v4Ut9Iqxas=";

    passthru.tests = {
      version = pkgs.testers.testVersion {
        package = typescript;
      };
    };

    meta = with pkgs.lib; {
      description = "A superset of JavaScript that compiles to clean JavaScript output";
      homepage = "https://www.typescriptlang.org/";
      changelog = "https://github.com/microsoft/TypeScript/releases/tag/v${version}";
      license = licenses.asl20;
      maintainers = [ ];
      mainProgram = "tsc";
    };
  };

in
pkgs.mkShell {
  buildInputs = [
    nodejs20
    yarn4
    typescript
  ];
}
