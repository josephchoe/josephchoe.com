---
title: WireGuard on OpenBSD
date: 2021-12-03 08:00:00 -0600
author: joseph
---

I'll be traveling a bit next year, and when I do I'll want to have access to my [homelab]({% post_url essay/2021-09-03-infrastructure %}) and all the services therein.

This is where a virtual private network or VPN would certainly come in handy, an encrypted tunnel that would allow me to access my private network from public networks.

So I decided to take a look at [WireGuard](https://wireguard.com), which conveniently for me is available on OpenBSD as [`wg(4)`](https://man.openbsd.org/wg.4).

## Server Configuration

I first provisioned a [new virtual machine]({% post_url essay/2021-10-29-openbsd-proxmox %}) with OpenBSD 7.0 installed.

Then, I enabled IP forwarding:

```sh
$ doas sysctl net.inet.ip.forwarding=1
$ echo 'net.inet.ip.forwarding=1' | doas tee -a /etc/sysctl.conf
```

After that, I downloaded the WireGuard tools:

```sh
$ doas pkg_add wireguard-tools
```

I use these only to extract the public keys from the private keys, but I could probably make do without them. However, I am at times inexplicably, incredibly lazy.

In any case, let's generate the server keys:

```sh
# Generate server private key
$ openssl rand -base64 32 > server_secret.key
# Extract server public key
$ wg pubkey < server_secret.key > server_public.key
```

Next, I need to configure a WireGuard interface by creating a new file called `/etc/hostname.wg0` on the server:

```conf
wgkey $SERVER_PRIVATE_KEY
wgpeer $PEER_PUBLIC_KEY wgaip 10.11.11.10/32
wgport 51820
inet 10.11.11.1/24
up
```
I've decided upon `10.11.11.1` for the server's local IP and `10.11.11.10` for the peer or client's local IP.

I need to update the server's firewall via the `/etc/pf.conf` file:

```conf
set skip on wg0
pass in inet proto udp from any to any port 51820 keep state
pass out on egress inet from wg0:network to any nat-to (egress)
```

These rules allow traffic through the encrypted UDP tunnel over the network interface `vio0`.

Can't forget to run `doas pfctl -f /etc/pf.conf`!

I will need to run `doas sh /etc/netstart wg0` to start the interface. We can see that the interface is running by querying `ifconfig`:

```sh
$ doas ifconfig wg0
wg0: flags=80c3<UP,BROADCAST,RUNNING,NOARP,MULTICAST> mtu 1420
        index 5 priority 0 llprio 3
        wgport 51820
        wgpubkey $SERVER_PUBLIC_KEY
        wgpeer $PEER_PUBLIC_KEY
                tx: 0, rx: 0
                wgaip 10.11.11.10/32
        groups: wg
        inet 10.11.11.1 netmask 0xffffff00 broadcast 10.11.11.255
```

It's also important that I configure the network router to port forward the UDP port `51820` to the virtual machine. However, this is outside the scope of this essay, though it's fairly simple.

We can test this works by using [`nc(1)`](https://man.openbsd.org/nc.1):

```sh
$ nc -uvz $SERVER_PUBLIC_IP 51820
Connection to $SERVER_PUBLIC_IP port 51820 [udp/*] succeeded!
```

Looking good so far!

## MacOS Client Configuration

While I do have a new [Framework laptop]({% post_url 2021-10-22-framework %}), I still use my old MacBook Pro from time to time. I also need to make sure that my wife can connect to the encrypted tunnel, so this section could just as well be titled "Android Client Configuration".

I'll need to download the WireGuard client applicable to whatever platform this is, whether MacOS or Android. Once I've done that, I can generate the client's keys:

```sh
# Generate peer private key
$ openssl rand -base64 32 > peer1_secret.key
# Extract peer public key
$ wg pubkey < peer1_secret.key > peer1_public.key
```

Then, I click `Add Empty Tunnel` and paste the following:

```conf
[Interface]
PrivateKey = $PEER_PRIVATE_KEY
ListenPort = 51820
Address = 10.11.11.10/32

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0
Endpoint = $SERVER_PUBLIC_IP:51820
```

Upon pressing `Activate`, the computer or smartphone begins to route traffic through the encrypted tunnel.

## Framework Laptop Configuration

Ostensibly, my wife and I need to access the WireGuard encrypted tunnel at the same time. Since my Framework laptop is running OpenBSD, the process to configure WireGuard is a bit different.

To start with, I'll need to generate a new set of keys and add an additional peer to the server's `/etc/hostname.wg0` file:

```conf
wgpeer $PEER2_PUBLIC_KEY wgaip 10.11.11.11/32
```

I've selected `10.11.11.11` for the second peer's local IP. Once that file is updated, I can run `doas sh /etc/netstart wg0` once more to catch the new changes on the interface.

In order to route traffic from the WireGuard tunnel to the network device on the Framework laptop, we need to grab the laptop's default gateway:

```sh
$ route show
Routing tables

Internet:
Destination        Gateway            Flags   Refs      Use   Mtu  Prio Iface
default            192.168.0.1        UGS       11       24     -    12 iwx0
...
```

Then, I'll create a new `/etc/hostname.wg0` file on the Framework laptop:

```conf
wgkey $PEER2_PRIVATE_KEY
wgpeer $SERVER_PUBLIC_KEY wgendpoint $SERVER_PUBLIC_IP 51820 wgaip 0.0.0.0/0
wgport 51820
inet 10.11.11.11/24
!route add -priority 2 $SERVER_PUBLIC_IP $LOCAL_GATEWAY
!route add -priority 7 default 10.11.11.1
```

Note the difference between this and the server's `wg0` interface: we've added two routing rules that will route traffic from the local default gateway and through the WireGuard tunnel.

Finally, we can run `doas sh /etc/netstart wg0` to start the new interface. The traffic on the Framework laptop should be immediately routed through the encrypted tunnel. We can tell via the `icmp` protocol and pinging the server's local IP from the laptop:

```sh
$ ping -c 2 10.11.11.1
PING 10.11.11.1 (10.11.11.1): 56 data bytes
64 bytes from 10.11.11.1: icmp_seq=0 ttl=255 time=307.325 ms
64 bytes from 10.11.11.1: icmp_seq=1 ttl=255 time=315.128 ms

--- 10.11.11.1 ping statistics ---
2 packets transmitted, 2 packets received, 0.0% packet loss
round-trip min/avg/max/std-dev = 307.325/311.226/315.128/3.902 ms
```

Yay!

## Conclusion

WireGuard was actually fairly simple to setup. Creating new interfaces, for example, used an easily readable syntax that was easy to wrap my head around.

I'm actually pretty pleased with how this all turned out, and I'm excited by the new things I'm learning with OpenBSD as well.

Having access to my homelab while I'm traveling will be pretty nice, too.
