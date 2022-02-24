---
title: OpenSMTPD on the Local Network
date: 2021-12-24 08:00:00 -0600
author: joseph
---

One of the many great things about OpenBSD is that it comes with OpenSMTPD by default, allowing my servers to communicate with themselves and each other via the SMTP protocol. This is used to send insecurity reports, failed cron jobs, et cetera to various users on the system.

However, I don't want to have to check each machine's mail spool to see if there are any messages I need to act upon. I'd much rather have a central mail server to collect all these messages so that I have a single place to check.

This is easily done as [`smtpd.conf(5)`](https://man.openbsd.org/smtpd.conf) has an easy to understand manual page.

## Mail Server Configuration

First, let's provision a [new virtual machine]({% post_url essay/2021-10-29-openbsd-proxmox %}) with OpenBSD 7.0 installed, [setup NTP]({% post_url essay/2021-11-05-openntpd %}), and so on and so forth.

I'm going to need to generate a self-signed certificate in order to enable TLS, so let's create a private key:

```sh
$ doas openssl genrsa -out /etc/ssl/private/mx0.jfc.dev.key 4096
```

Make sure that the permissions for the key are `600`, otherwise starting `smtpd` will probably fail.

```sh
$ doas chmod 600 /etc/ssl/private/mx0.jfc.dev.key
```

Once I have that, I can generate the certificate. It will take a few variables, which I've exported:

```sh
export OPENSSL_COUNTRY=...
export OPENSSL_STATE=...
export OPENSSL_LOCALITY=...
export OPENSSL_ORGANIZATION=...
export OPENSSL_COMMON_NAME=...

$ doas openssl req -x509 -new -key /etc/ssl/private/mx0.jfc.dev.key \
    -out /etc/ssl/mx0.jfc.dev.crt \
    -days 18250 \
    -subj "/C=$OPENSSL_COUNTRY/ST=$OPENSSL_STATE/L=$OPENSSL_LOCALITY/O=$OPENSSL_ORGANIZATION/OU=/CN=$OPENSSL_COMMON_NAME"
```

I've set it to an absurdly high amount of years, because I don't want to bother with it again.

Once that's done, I can configure the mail server's `/etc/mail/smtpd.conf` file:

```conf
table addresses { $SERVER_IP_1, $SERVER_IP_2, $SERVER_IP_3 }
table domains { devbox-ntp.home.lan, devbox-svc0.home.lan, devbox-wg0.home.lan }

table aliases file:/etc/mail/aliases

pki mx0.jfc.dev cert "/etc/ssl/mx0.jfc.dev.crt"
pki mx0.jfc.dev key "/etc/ssl/private/mx0.jfc.dev.key"

listen on lo0
listen on vio0 tls-require pki mx0.jfc.dev

action local_delivery maildir "/home/%{user.username}/Maildir" alias <aliases>

match from local for local action local_delivery
match from src <addresses> for domain <domains> action local_delivery
```

The first couple of lines sets up the tables I'll need later on in the configuration. I've also let [`smtpd(8)`](https://man.openbsd.org/smtpd.8) know where to find the key and certificate.

The server will listen on both the loopback device and the virtual network device, though it will require TLS. I don't want to set the `verify` option because I don't want to require a valid certificate from a certificate authority or manage my own.

The last few lines deliver all of the incoming mail to each user using the Maildir format. I also use expansion mapping, so mail directed to the `root` user is directed to me, i.e. `joseph`. Check out the `/etc/mail/aliases` file:

```conf
root: joseph
```

And run `doas newaliases`. After that's done, I need to restart `smtpd`:

```sh
$ doas rcctl restart smtpd
```

Next, I need to set up the machine's firewall by editing the `/etc/pf.conf` file:

```conf
if = "vio0"

set skip on lo0
block return

pass in on $if inet proto icmp
pass in on $if inet proto tcp to port {ssh}
pass in on $if inet proto tcp to port {smtp}
pass out on $if
```

The only thing to note here is that I'm passing in the `smtp` port. Restart the firewall:

```sh
$ doas pfctl -f /etc/pf.conf
```

## Other Server Configuration

Next I need to set up each and every other virtual machine I have to send their mail to the mail server.

On each of those servers, I update the `/etc/mail/smtpd.conf` file as follows:

```conf
listen on lo0

action relay_to_mx0 relay host smtp+tls://$MAIL_SERVER_IP tls no-verify

match from local action relay_to_mx0
```

Again I set the `no-verify` option because I don't want to generate a certificate for each server.

Now let's edit the `/etc/pf.conf` file:

```conf
if = "vio0"

set skip on lo
block return

pass in on $if inet proto icmp
pass in on $if inet proto {tcp} to port {ssh}
pass out on $if
```

I think that's fairly straightforward as it's identical to the one on the mail server, except the line for the `smtp` port.

Finally, let's run:

```sh
$ doas rcctl restart smtpd
$ doas pfctl -f /etc/pf.conf
```

## Testing

We need to make sure this setup actually works. We can do that by using [`sendmail(8)`](https://man.openbsd.org/sendmail):

```sh
$ sendmail joseph
Subject: Test Subject

Hello, EHLO!
```

If we check the mail server's Maildir:

```plaintext
Return-Path: <joseph@devbox-ntp.home.lan>
Delivered-To: joseph@devbox-ntp.home.lan
Received: from devbox-ntp.home.lan (devbox-ntp.home.lan [$NTP_SERVER_IP])
        by devbox-mx0.home.lan (OpenSMTPD) with ESMTPS id 64f3eab9 (TLSv1.3:AEAD-AES256-GCM-SHA384:256:NO)
        for <joseph@devbox-ntp.home.lan>;
        Thu, 23 Dec 2021 14:23:47 -0700 (MST)
Received: from localhost (devbox-ntp.home.lan [local])
        by devbox-ntp.home.lan (OpenSMTPD) with ESMTPA id f55200d4
        for <joseph@devbox-ntp.home.lan>;
        Thu, 23 Dec 2021 14:23:46 -0700 (MST)
From:  <joseph@devbox-ntp.home.lan>
Date: Thu, 23 Dec 2021 14:23:32 -0700 (MST)
Subject: Test Subject
Message-ID: <6579236dae00ceb2@devbox-ntp.home.lan>

Hello, EHLO!
```

The mail actually came in!

## Conclusion

Using this setup, I can manage all of my network's communication from the central mail server. I can view insecurity reports and make sure that certain files have correct permissions or if there's been any software installed that I don't know about. I can make sure that the cronjobs are running correctly through any error mails that may come in.

Once the message is on my mail server, I can retrieve it through the IMAP protocol, though setting up an IMAP server will have to wait until a future essay.
