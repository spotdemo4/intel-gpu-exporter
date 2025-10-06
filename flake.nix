{
  description = "go-template";

  nixConfig = {
    extra-substituters = [
      "https://trevnur.cachix.org"
    ];
    extra-trusted-public-keys = [
      "trevnur.cachix.org-1:hBd15IdszwT52aOxdKs5vNTbq36emvEeGqpb25Bkq6o="
    ];
  };

  inputs = {
    systems.url = "systems";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    nur = {
      url = "github:spotdemo4/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    semgrep-rules = {
      url = "github:semgrep/semgrep-rules";
      flake = false;
    };
  };

  outputs = {
    nixpkgs,
    utils,
    nur,
    semgrep-rules,
    ...
  }:
    utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [nur.overlays.default];
      };
    in {
      devShells = {
        default = pkgs.mkShell {
          packages = with pkgs; [
            # python
            python3
            uv

            # deps
            intel-gpu-tools

            # lint
            alejandra
            prettier

            # util
            trev.bumper
          ];
          shellHook = pkgs.trev.shellhook.ref;
        };

        release = pkgs.mkShell {
          packages = with pkgs; [
            skopeo
          ];
        };

        update = pkgs.mkShell {
          packages = with pkgs; [
            trev.renovate
          ];
        };

        vulnerable = pkgs.mkShell {
          packages = with pkgs; [
            flake-checker
          ];
        };
      };

      checks = pkgs.trev.lib.mkChecks {
        python = {
          src = ./.;
          deps = with pkgs; [
            trev.opengrep
          ];
          script = ''
            opengrep scan --quiet --error --config="${semgrep-rules}/python"
          '';
        };

        nix = {
          src = ./.;
          deps = with pkgs; [
            alejandra
          ];
          script = ''
            alejandra -c .
          '';
        };

        actions = {
          src = ./.;
          deps = with pkgs; [
            prettier
            action-validator
            trev.renovate
          ];
          script = ''
            prettier --check .
            action-validator .github/**/*.yaml
            renovate-config-validator .github/renovate.json
          '';
        };
      };

      packages = with pkgs.trev.lib; rec {
        default = with pkgs;
          python3Packages.buildPythonApplication rec {
            pname = "intel-gpu-exporter";
            version = "0.1.0";
            pyproject = true;

            src = ./.;

            build-system = with python3Packages; [
              setuptools
              uv-build
            ];

            dependencies = with python3Packages; [
              prometheus-client
              intel-gpu-tools
            ];

            meta = {
              description = "Get metrics from Intel GPUs";
              mainProgram = "intel-gpu-exporter";
              homepage = "https://github.com/spotdemo4/intel-gpu-exporter";
              changelog = "https://github.com/spotdemo4/intel-gpu-exporter/releases/tag/v${version}";
              license = lib.licenses.mit;
              platforms = lib.platforms.all;
            };
          };

        image = pkgs.dockerTools.streamLayeredImage {
          name = "${default.pname}";
          tag = "${default.version}";
          created = "now";
          contents = with pkgs; [
            default
          ];
          config = {
            Cmd = [
              "${pkgs.lib.meta.getExe default}"
            ];
          };
        };
      };

      formatter = pkgs.alejandra;
    });
}
