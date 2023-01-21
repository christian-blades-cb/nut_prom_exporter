{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nut-src = {
      url = "github:DRuggeri/nut_exporter/?ref=v2.5.2";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, nut-src, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
        {
          packages.default = pkgs.buildGoModule {
            pname = "nut_exporter";
            version = "2.5.2";

            src = nut-src;

            vendorHash = "sha256-ji8JlEYChPBakt5y6+zcm1l04VzZ0/fjfGFJ9p+1KHE=";
          };
        }
    ) // {
      nixosModule = import ./module.nix { inherit self; };
      nixosConfigurations.container = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModule
          {
            boot.isContainer = true;
            networking.firewall.allowedTCPPorts = [ 9199 ];

            services.nut_prom_exporter = {
              enable = true;
              server = "localhost";
            };

            users.users.admin = {
              isNormalUser = true;
              initialPassword = "admin";
              extraGroups = [ "wheel" ];
            };

            services.openssh.passwordAuthentication = true;
            services.openssh.enable = true;
          }
        ];
      };
    };
}
