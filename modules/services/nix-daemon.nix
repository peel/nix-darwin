{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.nix-daemon;
in

{
  options = {
    services.nix-daemon.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the nix-daemon service.";
    };

    services.nix-daemon.enableSocketListener = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to make the nix-daemon service socket activated.";
    };

    services.nix-daemon.logFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/var/log/nix-daemon.log";
      description = ''
        The logfile to use for the nix-daemon service. Alternatively
        <command>sudo launchctl debug system/org.nixos.nix-daemon --stderr</command>
        can be used to stream the logs to a shell after restarting the service with
        <command>sudo launchctl kickstart -k system/org.nixos.nix-daemon</command>.
      '';
    };

    services.nix-daemon.tempDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "The TMPDIR to use for nix-daemon.";
    };
  };

  config = mkIf cfg.enable {

    nix.useDaemon = true;

    launchd.daemons.nix-daemon = {
      command = "${config.nix.package}/bin/nix-daemon";
      serviceConfig.ProcessType = "Interactive";
      serviceConfig.LowPriorityIO = config.nix.daemonIONice;
      serviceConfig.Nice = config.nix.daemonNiceLevel;
      serviceConfig.SoftResourceLimits.NumberOfFiles = 4096;
      serviceConfig.StandardErrorPath = cfg.logFile;

      serviceConfig.KeepAlive = mkIf (!cfg.enableSocketListener) true;

      serviceConfig.Sockets = mkIf cfg.enableSocketListener
        { Listeners.SockType = "stream";
          Listeners.SockPathName = "/nix/var/nix/daemon-socket/socket";
        };

      serviceConfig.EnvironmentVariables = mkMerge [
        config.nix.envVars
        { NIX_SSL_CERT_FILE = mkDefault "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          TMPDIR = mkIf (cfg.tempDir != null) cfg.tempDir;
        }
      ];
    };

  };
}
