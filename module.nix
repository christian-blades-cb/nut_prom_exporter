{ self }:
{ pkgs, config, lib, ... }:

with lib;

let
  pkg = self.packages.${pkgs.system}.default;
  cfg = config.services.nut_prom_exporter;
in
{
  options.services.nut_prom_exporter = {
    enable = mkEnableOption "Enables nut_prom_exporter";

    server = mkOption rec {
      type = types.str;
      default = "127.0.0.1";
      example = default;
      description = "NUT host";
    };

    bind = mkOption rec {
      type = types.str;
      default = ":9199";
      example = default;
      description = "Where to listen";
    };

    user = mkOption rec {
      type = types.str;
      default = "monuser";
      example = default;
      description = "NUT username";
    };

    pass = mkOption rec {
      type = types.str;
      default = "secret";
      example = default;
      description = "NUT password";
    };

    extraEnvs = mkOption rec {
      type = types.attrsOf types.str;
      default = { NUT_EXPORTER_METRICS_NAMESPACE = "network_ups"; };
      example = default;
      description = "Extra env vars to configure various options on the exporter";
    };
    
  };

  config = mkIf cfg.enable {
    systemd.services."nut-mastodon-exporter" = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment = { NUT_EXPORTER_PASSWORD=cfg.pass; } // cfg.extraEnvs;

      serviceConfig = {
        ExecStart = ''${pkg}/bin/nut_exporter --nut.server="${cfg.server}" --nut.username "${cfg.user}" --web.listen-address="${cfg.bind}"'';
        Restart = mkDefault "always";
        PrivateTmp = mkDefault true;
        WorkingDirectory = mkDefault /tmp;
        DynamicUser = true;
        # Hardening
        CapabilityBoundingSet = mkDefault [ "" ];
        DeviceAllow = [ "" ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = mkDefault true;
        ProtectClock = mkDefault true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = mkDefault "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
      };
    };
  };
}
