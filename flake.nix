{
  description = "ProfunKtor - Scala development tools";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        scalaOverlay = self: super: {
          jre = super.jdk21_headless;
          sbt = super.sbt.overrideAttrs (
            old: {
              nativeBuildInputs = old.nativeBuildInputs or [ ] ++ [ super.makeWrapper ];
              # Setting SBT_OPTS because of this bug: https://github.com/sbt/sbt-site/issues/169
              postInstall = ''
                wrapProgram $out/bin/sbt --suffix SBT_OPTS : '--add-opens java.base/java.lang=ALL-UNNAMED'
              '';
            }
          );
        };

        pkgs = import nixpkgs {
          inherit system;
          overlays = [ scalaOverlay ];
        };
      in
      {
        devShell = pkgs.mkShell {
          name = "profunktor-scala-dev-shell";

          buildInputs = with pkgs; [
            coursier
            gnupg
            jekyll
            jre
            sbt
            scala-cli
          ];

          shellHook = ''
            JAVA_HOME="${pkgs.jre}"
          '';
        };

        packages = {
          inherit (pkgs) sbt;
        };
      });
}
