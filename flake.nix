{
  description = "Some of my personal scripts that I use quite frequently";

  outputs =
    { self, nixpkgs, ... }:
    let
      name = "myscripts-0.2.0";
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
                buildCommand =
                  oldAttrs.buildCommand
                  + ''
                    completion=${./completions}/${name}.fish
                    if [[ -e "$completion" ]] then installShellCompletion "$completion"; fi
                  '';
              });
          scripts = rec {
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
          };
          headless = with scripts; [
            duh
            added-lines
            cachedir
            anontgz
            if-network
            if-internet
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
