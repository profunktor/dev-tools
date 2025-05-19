{
  description = "ProfunKtor - Scala development tools";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-jekyll.url = github:NixOS/nixpkgs?rev=9a9dae8f6319600fa9aebde37f340975cab4b8c0;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { nixpkgs, nixpkgs-jekyll, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        scalaOverlay = self: super: {
          # jekyll v4.3.1 is needed for sbt-microsite
          inherit (nixpkgs-jekyll.legacyPackages.${system}) jekyll;
          jre = super.jdk21_headless;
          sbt = super.sbt.overrideAttrs (
            old: {
              nativeBuildInputs = old.nativeBuildInputs or [ ] ++ [ super.makeWrapper ];
              # Setting SBT_OPTS because of this bug: https://github.com/sbt/sbt-site/issues/169
              postInstall = ''
                wrapProgram $out/bin/sbt \
                  --suffix SBT_OPTS : '--add-opens java.base/java.lang=ALL-UNNAMED' \
                  --prefix PATH : ${super.lib.makeBinPath [ self.jekyll ]}
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
        devShells.default = pkgs.mkShell {
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
