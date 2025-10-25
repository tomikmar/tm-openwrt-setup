## OpenWrt

Tested on OpenWrt 24.10.



## System / Administration

  * SSH-Keys



## Network

  * Interfaces
    ```bash
    uci show network.lan.ipaddr
    #
    uci set network.lan.ipaddr='192.168.101.1'
    #
    uci commit network
    uci show network.lan.ipaddr
    ```



## System / System

  * Set hostname
    ```bash
    uci get system.@system[0].hostname
    cat /proc/sys/kernel/hostname
    #
    uci set system.@system[0].hostname='<NEW_NAME>'
    #
    uci commit system
    /etc/init.d/system reload
    uci get system.@system[0].hostname
    cat /proc/sys/kernel/hostname
    ```



## System / Administration

  * SSH Access
    ```bash
    uci show dropbear.@dropbear[0].PasswordAuth
    uci show dropbear.@dropbear[0].RootPasswordAuth
    uci show dropbear.@dropbear[0].Interface
    uci show dropbear.@dropbear[0].Port
    #
    uci set dropbear.@dropbear[0].PasswordAuth='off'
    uci set dropbear.@dropbear[0].RootPasswordAuth='off'
    uci set dropbear.@dropbear[0].Interface='lan'
    uci set dropbear.@dropbear[0].Port='<SSH_PORT>'
    #
    uci commit dropbear
    /etc/init.d/dropbear restart
    netstat -antup | grep dropbear
    ```



## Configure uhttpd to listen on LAN port 443 only (No IPv6)

    uci show uhttpd.main.listen_http
    uci show uhttpd.main.listen_https
    #
    uci delete uhttpd.main.listen_http
    uci delete uhttpd.main.listen_https
    # Use only LAN interface instead of 0.0.0.0
    uci add_list uhttpd.main.listen_https='192.168.101.1:443'
    # Disable http -> https redirection
    uci set uhttpd.main.redirect_https='0'
    #
    uci commit uhttpd
    /etc/init.d/uhttpd restart
    uci show uhttpd.main.listen_http
    uci show uhttpd.main.listen_https
    netstat -antup | grep uhttpd



## Limit dnsmask interfaces

    uci show dhcp.@dnsmasq[0].interface
    uci show dhcp.@dnsmasq[0].notinterface
    uci show dhcp.@dnsmasq[0].listen_address
    #
    # Clear previous settings
    uci delete dhcp.@dnsmasq[0].interface
    uci delete dhcp.@dnsmasq[0].notinterface
    uci delete dhcp.@dnsmasq[0].listen_address
    # Configure dnsmasq to listen on specific interfaces and IP
    uci add_list dhcp.@dnsmasq[0].interface='lan'
    uci add_list dhcp.@dnsmasq[0].notinterface='wan'
    uci add_list dhcp.@dnsmasq[0].notinterface='wan6'
    # listen_address is not needed if interfaces inclusions and exclusions are provided
    # uci add_list dhcp.@dnsmasq[0].listen_address='192.168.101.1'
    uci set dhcp.@dnsmasq[0].bind_interfaces='1'
    uci set dhcp.@dnsmasq[0].localservice='1'
    uci set dhcp.@dnsmasq[0].noresolv='0'
    #
    uci commit dhcp
    /etc/init.d/dnsmasq restart
    /etc/init.d/dnsmasq status
    netstat -antup | grep dnsmasq
    ping -c3 dns.quad9.net


#### Remarks regarding additional networks

When resetting `dnsmasq` we should also add interfaces configured later:

    uci add_list dhcp.@dnsmasq[0].interface='guest_net'
    uci add_list dhcp.@dnsmasq[0].interface='iot_net'


#### Remakrs regarding loopback

When `dnsmasq` is configured to not listen on the loopback interface:

    uci add_list dhcp.@dnsmasq[0].notinterface='loopback'

the automatic generation of /etc/resolv.conf should also be disabled:

    uci set dhcp.@dnsmasq[0].noresolv='1'

and `/etc/resolv.conf` must be manually configured to point to the correct IP address
on which `dnsmasq` is listening. Without these changes, the system DNS resolver will
attempt to use the default loopback address (127.0.0.1), which will fail since
`dnsmasq` is no longer listening on that interface.



## Disable services

#### Disable Web Services for Devices (wsdd2)

    /etc/init.d/wsdd2 status
    /etc/init.d/wsdd2 stop
    /etc/init.d/wsdd2 disable
    /etc/init.d/wsdd2 status

Ports used by wsdd2:

  * TCP 5355, 3702
  * UDP 5355, 3702

#### Disable ksmbd

    /etc/init.d/ksmbd status
    /etc/init.d/ksmbd stop
    /etc/init.d/ksmbd disable
    /etc/init.d/ksmbd status

#### Services / Dynamic DNS

  * Disable



## Set custom DNS

#### Set custom DNS servers for DHCP

    uci show dhcp.lan.dhcp_option
    #
    # 6 = DHCP option code for specifying DNS servers
    uci add_list dhcp.lan.dhcp_option="6,1.1.1.2,1.0.0.2"
    #
    uci commit dhcp
    /etc/init.d/dnsmasq restart
    uci show dhcp.lan.dhcp_option

####  Set custom DNS servers for router
    
    cat /etc/resolv.conf
    cat /tmp/resolv.conf.d/resolv.conf.auto
    uci show dhcp.@dnsmasq[0].server
    uci show network.wan.dns
    uci show network.wan.peerdns
    #
    uci set network.wan.dns='1.1.1.3 1.0.0.3'
    uci set network.wan.peerdns='0'
    #
    uci commit network
    /etc/init.d/network restart
    uci show network.wan



## Disable IPv6

    # Disable IPv6 on LAN and WAN
    uci set network.lan.ipv6='0'
    uci set network.wan.ipv6='0'
    # (?)
    uci set network.lan.delegate="0"

    # Disable DHCPv6 and RA on LAN
    uci set dhcp.lan.dhcpv6='disabled'
    uci set dhcp.lan.ra='disabled'
    # Neighbor Discovery Protocol (?)
    uci set dhcp.lan.ndp='disabled'

    # This is also needed (see: ip -6 addr)
    uci delete network.lan.ip6assign

    # Disable IPv6 in kernel
    echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
    sysctl -p 
 
    # Disable odhcpd service
    /etc/init.d/odhcpd status    
    /etc/init.d/odhcpd disable
    /etc/init.d/odhcpd stop

    # Delete wan6 interface
    uci delete network.wan6

    uci commit
    /etc/init.d/network restart

    /etc/init.d/odhcpd status
    ps | grep odhcpd
    ps | grep odhcp6c
    uci show network.wan6



## Services / Wifi Schedule

    uci add wifi_schedule global
    uci set wifi_schedule.@global[0].enabled='1'
    uci set wifi_schedule.@global[0].logging='1'
    uci set wifi_schedule.@global[0].unload_modules='0'  
    uci set wifi_schedule.@global[0].recheck_interval='10'
    uci set wifi_schedule.@global[0].modules_retries='10'

    uci set wifi_schedule.Businesshours=entry
    uci set wifi_schedule.Businesshours.enabled='1'
    uci set wifi_schedule.Businesshours.daysofweek='Monday Tuesday Wednesday Thursday Friday'
    uci set wifi_schedule.Businesshours.starttime='05:00'
    uci set wifi_schedule.Businesshours.stoptime='02:00'
    uci set wifi_schedule.Businesshours.forcewifidown='1'

    uci set wifi_schedule.Weekend=entry
    uci set wifi_schedule.Weekend.enabled='1'
    uci set wifi_schedule.Weekend.daysofweek='Saturday Sunday'
    uci set wifi_schedule.Weekend.starttime='05:00'
    uci set wifi_schedule.Weekend.stoptime='02:00'
    uci set wifi_schedule.Weekend.forcewifidown='1'

    uci commit wifi_schedule
    /etc/init.d/wifi_schedule restart
    wifi_schedule.sh cron



## Network / DHCP and DNS

  * Static leases
    ```bash
    # Static IP for ... device in DHCP
    uci set dhcp.<IOT-NAME>=host
    uci set dhcp.<IOT-NAME>.name='xxxxxxx'
    uci set dhcp.<IOT-NAME>.mac='xx:xx:xx:xx:xx:xx'
    uci set dhcp.<IOT-NAME>.ip='192.168.xxx.xxx'

    uci commit dhcp
    /etc/init.d/dnsmasq restart
    ```



## Network

  * Configure and enable WiFi
    * 'sae-mixed' downgrade is required for my printer
  * Wireless / Edit / Wireless security / Encryption / sae-mixed | sae



## Add separated guest wifi

    # Add interface
    uci delete network.guest_net
    uci set network.guest_net=interface
    uci set network.guest_net.proto='static'
    uci set network.guest_net.ipaddr='192.168.103.1'
    uci set network.guest_net.netmask='255.255.255.0'

    # Configure DHCP
    uci delete dhcp.guest_dhcp
    uci set dhcp.guest_dhcp=dhcp
    uci set dhcp.guest_dhcp.interface='guest_net'
    uci set dhcp.guest_dhcp.start='100'
    uci set dhcp.guest_dhcp.limit='30'
    uci set dhcp.guest_dhcp.leasetime='4h'
    uci add_list dhcp.@dnsmasq[0].interface='guest_net'
    # listen_address is not needed if interfaces inclusions and exclusions are provided
    #uci add_list dhcp.@dnsmasq[0].listen_address='192.168.103.1'

    # Add wifi interface
    uci delete wireless.guest_wifi
    uci set wireless.guest_wifi=wifi-iface
    # ! Verify if radioX is correct for this network
    uci set wireless.guest_wifi.device='radio0'
    uci set wireless.guest_wifi.network='guest_net'
    uci set wireless.guest_wifi.mode='ap'
    # ! UPDATE !
    uci set wireless.guest_wifi.ssid='guest-wifi'
    uci set wireless.guest_wifi.encryption='sae-mixed'
    # ! UPDATE !
    uci set wireless.guest_wifi.key='****************'
    # Block communication between clients on wireless interface level
    uci set wireless.guest_wifi.isolate='1'
    # Disable Wi-Fi Protected Setup (WPS)
    uci set wireless.guest_wifi.wps='0'

    # Set firewall
    uci delete firewall.guest_zone
    uci set firewall.guest_zone='zone'
    uci set firewall.guest_zone.name='guest_zone'
    uci set firewall.guest_zone.network='guest_net'
    uci set firewall.guest_zone.input='REJECT'
    uci set firewall.guest_zone.output='ACCEPT'
    uci set firewall.guest_zone.forward='REJECT'

    uci delete firewall.guest_to_wan
    uci set firewall.guest_to_wan='forwarding'
    uci set firewall.guest_to_wan.src='guest_zone'
    uci set firewall.guest_to_wan.dest='wan'

    # Allow DHCP
    uci delete firewall.guest_dhcp_rule
    uci set firewall.guest_dhcp_rule='rule'
    uci set firewall.guest_dhcp_rule.name='Guest-DHCP'
    uci set firewall.guest_dhcp_rule.src='guest_zone'
    uci set firewall.guest_dhcp_rule.proto='udp'
    uci set firewall.guest_dhcp_rule.dest_port='67-68'
    uci set firewall.guest_dhcp_rule.limit='50/sec'
    uci set firewall.guest_dhcp_rule.limit_burst='100'
    uci set firewall.guest_dhcp_rule.target='ACCEPT'

    # Allow DNS
    uci delete firewall.guest_dns_rule
    uci set firewall.guest_dns_rule='rule'
    uci set firewall.guest_dns_rule.name='Guest-DNS'
    uci set firewall.guest_dns_rule.src='guest_zone'
    uci add_list firewall.guest_dns_rule.proto='udp'
    uci add_list firewall.guest_dns_rule.proto='tcp'
    uci set firewall.guest_dns_rule.dest_port='53'
    uci set firewall.guest_dns_rule.limit='50/sec'
    uci set firewall.guest_dns_rule.target='ACCEPT'

    # Block communication between clients on firewall level
    uci delete firewall.guest_no_interclient
    uci set firewall.guest_no_interclient='rule'
    uci set firewall.guest_no_interclient.name='Guest-No-Interclient'
    uci set firewall.guest_no_interclient.src='guest_zone'
    uci set firewall.guest_no_interclient.dest='guest_zone'
    uci set firewall.guest_no_interclient.target='DROP'

    # Commit changes and restart services
    uci commit
    wifi reload
    /etc/init.d/dnsmasq restart
    /etc/init.d/firewall restart
    /etc/init.d/network restart



## Add separated iot wifi

    # Add interface
    uci delete network.iot_net
    uci set network.iot_net=interface
    uci set network.iot_net.proto='static'
    uci set network.iot_net.ipaddr='192.168.105.1'
    uci set network.iot_net.netmask='255.255.255.0'

    # Configure DHCP
    uci delete dhcp.iot_dhcp
    uci set dhcp.iot_dhcp=dhcp
    uci set dhcp.iot_dhcp.interface='iot_net'
    uci set dhcp.iot_dhcp.start='100'
    uci set dhcp.iot_dhcp.limit='30'
    uci set dhcp.iot_dhcp.leasetime='24h'
    uci add_list dhcp.@dnsmasq[0].interface='iot_net'
    # listen_address is not needed if interfaces inclusions and exclusions are provided
    #uci add_list dhcp.@dnsmasq[0].listen_address='192.168.105.1'

    # Add wifi interface
    uci delete wireless.iot_wifi
    uci set wireless.iot_wifi=wifi-iface
    # ! Verify if radioX is correct for this network
    uci set wireless.iot_wifi.device='radio0'
    uci set wireless.iot_wifi.network='iot_net'
    uci set wireless.iot_wifi.mode='ap'
    # ! UPDATE !
    uci set wireless.iot_wifi.ssid='iot-wifi'
    uci set wireless.iot_wifi.encryption='sae-mixed'
    # ! UPDATE !
    uci set wireless.iot_wifi.key='****************'
    # Disable client isolation on wireless interface
    uci set wireless.iot_wifi.isolate='0'
    # Disable Wi-Fi Protected Setup (WPS)
    uci set wireless.iot_wifi.wps='0'
    # Hide network -> NOT SUPPORTED BY MY DEVICES
    # uci set wireless.iot_wifi.hidden='1'

    # Set firewall
    uci delete firewall.iot_zone
    uci set firewall.iot_zone='zone'
    uci set firewall.iot_zone.name='iot_zone'
    uci set firewall.iot_zone.network='iot_net'
    uci set firewall.iot_zone.input='REJECT'
    uci set firewall.iot_zone.output='ACCEPT'
    uci set firewall.iot_zone.forward='REJECT'

    uci delete firewall.iot_to_wan
    uci set firewall.iot_to_wan='forwarding'
    uci set firewall.iot_to_wan.src='iot_zone'
    uci set firewall.iot_to_wan.dest='wan'

    # Allow DHCP
    uci delete firewall.iot_dhcp_rule
    uci set firewall.iot_dhcp_rule='rule'
    uci set firewall.iot_dhcp_rule.name='Iot-DHCP'
    uci set firewall.iot_dhcp_rule.src='iot_zone'
    uci set firewall.iot_dhcp_rule.proto='udp'
    uci set firewall.iot_dhcp_rule.dest_port='67-68'
    uci set firewall.iot_dhcp_rule.limit='50/sec'
    uci set firewall.iot_dhcp_rule.limit_burst='100'
    uci set firewall.iot_dhcp_rule.target='ACCEPT'

    # Allow DNS
    uci delete firewall.iot_dns_rule
    uci set firewall.iot_dns_rule='rule'
    uci set firewall.iot_dns_rule.name='Iot-DNS'
    uci set firewall.iot_dns_rule.src='iot_zone'
    uci add_list firewall.iot_dns_rule.proto='udp'
    uci add_list firewall.iot_dns_rule.proto='tcp'
    uci set firewall.iot_dns_rule.dest_port='53'
    uci set firewall.iot_dns_rule.limit='50/sec'
    uci set firewall.iot_dns_rule.target='ACCEPT'

    # Commit changes and restart services
    uci commit
    wifi reload
    /etc/init.d/dnsmasq restart
    /etc/init.d/firewall restart
    /etc/init.d/network restart



## Install

    opkg update
    # Network monitoring
    opkg install ifstat iftop nload bmon



## Tests

    nslookup dns.quad9.net
    ping -c3 dns.quad9.net
    netstat -antup



## Recovery

    ip link show
    ip addr add 192.168.100.111/24 dev <INTERFACE>
    ping 192.168.100.1
    # Remove static IP after switching back to a wifi connection
    ip addr del 192.168.100.111/24 dev <INTERFACE>

    ip addr show
    brctl show
    ip route

    iw phy

    iw dev
    iw dev phy1-ap0 station dump
    iw dev wlan0 station del XX:XX:XX:XX:XX:XX

