# this file is a mix of templates below and some little tweaks done by me

# templates used:
# - https://github.com/bobvanderlinden/nixpkgs-ruby/blob/master/template/flake.nix
# - https://github.com/inscapist/ruby-nix/blob/main/examples/simple-app/flake.nix

{
  description = "Development shell for ruby(and rails)";

  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    ruby-versions = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ruby-nix.url = "github:inscapist/ruby-nix";
    bundix = {
      url = "github:inscapist/bundix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ruby-versions, flake-utils, ruby-nix, bundix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ruby = ruby-versions.lib.packageFromRubyVersionFile {
          file = ./.ruby-version;
          inherit system;
        };

        rubyNix = ruby-nix.lib pkgs;
        gemset = if builtins.pathExists ./gemset.nix then import ./gemset.nix else { };
        bundixcli = bundix.packages.${system}.default;
        gemConfig = {};

        bundleLock = pkgs.writeShellScriptBin "bundle-lock" ''
          export BUNDLE_PATH=vendor/bundle
          bundle lock
        '';

        bundleUpdate = pkgs.writeShellScriptBin "bundle-update" ''
          export BUNDLE_PATH=vendor/bundle
          bundle lock --update
        '';

        bundleInstall = pkgs.writeShellScriptBin "bundle-install" ''
          bundix
          echo "-------------------------------------------------------"
          echo "You must reopen dev environment for packages to appear!" | lolcat
          echo "-------------------------------------------------------"
          echo "Exiting..."

          # To automatically reopen dev environment I have set up:
          kill -SIGUSR1 `ps --pid $$ -oppid=`; exit

          # And in .bashrc:
          # trap "kill -SIGUSR2 `ps --pid $$ -oppid=`; exit" SIGUSR1
          # trap "nix develop" SIGUSR2

          # Note: I'm a total amateur in both nix and bash,
          # so if you have a better way.. please tell me!
        '';

      in
      rec {
        inherit (rubyNix {
                  inherit gemset ruby;
                  name = "shell";
                  gemConfig = pkgs.defaultGemConfig // gemConfig;
                }) env;

        devShell = pkgs.mkShell {
          buildInputs =
            [
              env
              bundixcli
              bundleLock
              bundleUpdate
              bundleInstall
            ]
            ++ (with pkgs; [
              yarn
              nodejs
              lolcat
              # more packages here
            ]);

          GREETING = "Welcome to dev environment!";

          shellHook = ''
            export PS1="\[\033[$PROMPT_COLOR\][$(($SHLVL-1)):\w]\\$\[\033[0m\] "
            clear -x
            echo "---------------------------"
            echo $GREETING | lolcat
            echo "---------------------------"
          '';
        };
      }
    );
}
