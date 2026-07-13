{
  description = ''
    A garnix module for projects using rss-bridge.

    [Source](https://github.com/garnix-io/rss-bridge-module).
  '';

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  inputs.garnix-lib.url = "github:joegoldin/garnix-lib";
  inputs.garnix-lib.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      rssBridgeSubmodule.options = {
        path = lib.mkOption {
          type = lib.types.nonEmptyStr;
          description = "Webserver path to host your rss-bridge server on.";
          default = "/";
        };
      };
    in
    {
      garnixModules.default = { pkgs, config, ... }: {
        options = {
          rss-bridge = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule rssBridgeSubmodule);
            description = "An attrset of rss-bridge instances.";
          };
        };

        config = {
          nixosConfigurations.default = builtins.attrValues (builtins.mapAttrs
            (name: projectConfig: {
              services.rss-bridge = {
                enable = true;
                virtualHost = projectConfig.path;
                config = {
                  system.enabled_bridges = [ "*" ];
                  error = {
                    output = "http";
                    report_limit = 5;
                  };
                  FileCache = {
                    enable_purge = true;
                  };
                };
              };
              garnix.server.persistence = {
                enable = true;
                name = "default";
              };
              networking.firewall.allowedTCPPorts = [ 80 ];
            })
            config.rss-bridge);
        };
      };
      checks = import ./tests.nix { inherit self; };
    };
}
