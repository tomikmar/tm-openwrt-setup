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

