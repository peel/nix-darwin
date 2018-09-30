{ config, pkgs, ... }:

let
  nix = pkgs.runCommand "nix-0.0.0" {} "mkdir -p $out";
in

{
  services.nix-daemon.enable = true;
  services.nix-daemon.enableSocketListener = true;
  nix.package = nix;

  test = ''
    echo checking nix-daemon service in /Library/LaunchDaemons >&2
    grep "<string>org.nixos.nix-daemon</string>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist
    grep "<string>exec ${nix}/bin/nix-daemon</string>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist
    ! grep "<key>KeepAlive</key>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist
    grep "<key>Sockets</key>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist
    grep "/nix/var/nix/daemon-socket/socket" ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist
  '';
}
