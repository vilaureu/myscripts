{
  description = "Some of my personal scripts that I use quite frequently";

  inputs = {
    noto-color-emoji = {
      url = "https://github.com/googlefonts/noto-emoji/raw/refs/tags/v2.051/fonts/Noto-COLRv1.ttf";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      noto-color-emoji,
      ...
    }:
    let
      name = "myscripts-0.8.0";
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      forAllPkgs = f: forAllSystems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllPkgs (
        pkgs:
        let
          # Create a wrapper script with the right PATH and maybe a shell completion.
          wrap =
            { name, ... }@args:
            (pkgs.writeShellApplication ({ text = ''exec ${./bin/${name}} "$@"''; } // args)).overrideAttrs
              (oldAttrs: {
                nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.installShellFiles ];
                buildCommand = oldAttrs.buildCommand + ''
                  completion=${./completions}/${name}.fish
                  if [[ -e "$completion" ]] then installShellCompletion "$completion"; fi
                '';
              });
          packageFish = (
            name:
            pkgs.stdenv.mkDerivation {
              inherit name;
              src = ./.;
              installPhase = ''
                runHook preInstall
                (
                  target="$out/share/fish/vendor_functions.d"
                  mkdir -p $target
                  cp "$src"/functions/"$name".fish "$target/"
                )
                runHook postInstall
              '';
            }
          );
          fish = nixpkgs.lib.genAttrs [ "cdup" ] packageFish;
          scripts = fish // rec {
            duh = wrap {
              name = "duh";
              runtimeInputs = [
                pkgs.bash
                pkgs.coreutils
              ];
            };
            added-lines =
              let
                python = pkgs.python3.withPackages (ps: [ ps.unidiff ]);
              in
              wrap {
                name = "added-lines";
                runtimeInputs = [ python ];
              };
            silent = wrap {
              name = "silent";
              runtimeInputs = [
                pkgs.bash
                pkgs.util-linux
              ];
            };
            xopen = wrap {
              name = "xopen";
              runtimeInputs = [
                pkgs.bash
                pkgs.xdg-utils
                silent
              ];
            };
            cachedir = wrap {
              name = "cachedir";
              runtimeInputs = [ pkgs.python3 ];
            };
            anontgz = wrap {
              name = "anontgz";
              runtimeInputs = [
                pkgs.bash
                pkgs.gnutar
                pkgs.pigz
              ];
            };
            if-network = wrap {
              name = "if-network";
              runtimeInputs = [
                pkgs.python3
              ];
            };
            if-internet = wrap {
              name = "if-internet";
              runtimeInputs = [
                pkgs.bash
                pkgs.curl
              ];
            };
            develop = wrap {
              name = "develop";
              runtimeInputs = [
                pkgs.bash
              ];
            };
            unicode2tex = wrap {
              name = "unicode2tex";
              runtimeInputs = [
                pkgs.python3
              ];
            };
            j = wrap {
              name = "j";
              runtimeInputs = [
                pkgs.bash
              ];
            };
            ts = wrap {
              name = "ts";
              runtimeInputs = [
                pkgs.bash
              ];
            };
            emoji =
              let
                harfbuzz = pkgs.harfbuzz.override { withRaster = true; };
              in
              wrap {
                name = "emoji";
                runtimeInputs = [
                  pkgs.bash
                  pkgs.fontconfig
                  pkgs.imagemagick
                  harfbuzz.dev
                ];
                runtimeEnv = {
                  EMOJI_FONT_FILE = noto-color-emoji;
                };
              };
          };
          headless = with scripts; [
            duh
            added-lines
            cachedir
            anontgz
            if-network
            if-internet
            develop
            unicode2tex
            j
            ts
            cdup
            emoji
          ];
        in
        with scripts;
        scripts
        // {
          headless = pkgs.buildEnv {
            name = "${name}-headless";
            paths = headless;
          };
          default = pkgs.buildEnv {
            name = name;
            paths = headless ++ [
              xopen
              silent
            ];
          };
        }
      );

      formatter = forAllPkgs (pkgs: pkgs.nixfmt-rfc-style);
    };
}
