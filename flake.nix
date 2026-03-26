{
  description = "Development environment with nickel and mask";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        # keep-sorted start
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
        # keep-sorted end
      ];

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        let
          treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

          # Build gaphor as a Python library (nixpkgs only ships it as a Linux GUI app).
          # All C extensions (pycairo, pygobject3) come from nixpkgs — pre-built, correct arch.
          gaphorLib = pkgs.python3.pkgs.buildPythonPackage {
            pname = "gaphor";
            version = "3.2.0";
            pyproject = true;

            src = pkgs.fetchFromGitHub {
              owner = "gaphor";
              repo = "gaphor";
              rev = "3.2.0";
              hash = "sha256-0Z0RFQrN2g0beV2konZBfMroeNtbT+sPRsWlRvQFYBk=";
            };

            build-system = with pkgs.python3.pkgs; [ poetry-core ];

            dependencies = with pkgs.python3.pkgs; [
              babel
              better-exceptions
              defusedxml
              dulwich
              gaphas
              generic
              jedi
              pillow
              pycairo
              pydot
              pygobject3
              tinycss2
            ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin (with pkgs.python3.pkgs; [
              pyobjc-framework-Cocoa
            ]);

            # Relax version pins that are too tight for what nixpkgs provides
            pythonRelaxDeps = [ "dulwich" "pydot" "pygobject" "pyobjc-framework-cocoa" ];

            # No tests or GTK app wrapping — we only need the Python library
            doCheck = false;
          };

          pythonEnv = pkgs.python3.withPackages (_: [ gaphorLib ]);
        in
        {
          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.git
              pkgs.mask
              pythonEnv
              # GObject introspection typelibs (needed for gi.repository at runtime)
              pkgs.gobject-introspection
              pkgs.pango
            ];

            shellHook = ''
              export GI_TYPELIB_PATH="${pkgs.gobject-introspection}/lib/girepository-1.0:${pkgs.pango}/lib/girepository-1.0:''${GI_TYPELIB_PATH:-}"
              echo "🚀 Development environment loaded!"
              echo "Available tools:"
              echo "  - mask: Task runner"
              echo ""
              echo "Run 'mask --help' to see available tasks."
              echo "Run 'nix fmt' to format all files."
            '';
          };

          # for `nix fmt`
          formatter = treefmtEval.config.build.wrapper;

          # for `nix flake check`
          checks = {
            formatting = treefmtEval.config.build.check self;
          };
        };
    };
}
