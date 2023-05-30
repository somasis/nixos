let
  unboundResolvconf = "/run/unbound-resolvconf.conf";
in
{
  # NOTE: systemd-resolved actually breaks `hostname -f`!
  services.resolved.enable = true;

  # FIXME: Disabled while trying to fix network issues in my bedroom.
  # networking.resolvconf = {
  #   enable = true;
  #   useLocalResolver = true;
  #   # extraOptions = [ "trust-ad" ];
  #   # extraConfig = ''
  #   #   # private_interfaces="*"
  #   #   unbound_conf=${unboundResolvconf}
  #   # '';
  # };
  # networking.wireless.iwd.settings.Network.NameResolvingService = "resolvconf";
  # systemd.tmpfiles.rules = [ "f ${unboundResolvconf} 644 root root" ];
  # services.unbound = {
  #   enable = true;
  #   settings = {
  #     server = {
  #       interface = [ "127.0.0.1" ];
  #       # Allow local network to use DNS; disable DNSSEC for private namespaces
  #       # https://wiki.archlinux.org/title/Unbound#Using_openresolv
  #       domain-insecure = [
  #         "corp"
  #         "home"
  #         "internal"
  #         "intranet"
  #         "lan"
  #         "local"
  #         "private"
  #       ];
  #       # # Protect against DNS rebinding attacks
  #       # private-address = [
  #       #   "10.0.0.0/8"
  #       #   "172.16.0.0/12"
  #       #   "192.168.0.0/16"
  #       #   "169.254.0.0/16"
  #       #   "fd00::/8"
  #       #   "fe80::/10"
  #       # ];
  #       # # Allow replies with private IP address ranges
  #       # private-domain = [
  #       #   "corp"
  #       #   "home"
  #       #   "internal"
  #       #   "intranet"
  #       #   "lan"
  #       #   "local"
  #       #   "private"
  #       # ];
  #       unblock-lan-zones = true;
  #       insecure-lan-zones = true;
  #     };
  #     # forward-zone = [{ name = "."; forward-addr = [ "127.0.0.1@9053" ]; }];
  #     remote-control.control-enable = true;
  #     include = "${unboundResolvconf}";
  #   };
  # };
  # systemd.services.resolvconf.before = [ "unbound.service" ];
  # systemd.services.iwd.after = [ "unbound.service" ];
  # persist.directories = [ "/var/lib/unbound" ];

  # TODO: use DNS over Tor
  #       I can't quite figure out yet why this doesn't work...
  #       the point is that resolv.conf should just use 127.0.0.1,
  #       then unbound forwards all requests to Tor's DNS port on 9053
  #       then Tor gives the answer.
  #
  # services.tor = {
  #   enable = true;
  #   client = {
  #     enable = true;
  #     dns.enable = true;
  #   };
  #   settings.ClientDNSRejectInternalAddresses = true;
  # };
}
