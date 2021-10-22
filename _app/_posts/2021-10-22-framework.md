---
title: The New Framework
date: 2021-10-22 08:00:00 -0600
author: joseph
---

I purchased a new [Framework laptop](https://frame.work).

I've actually had my eye on these laptops for more than a few months. Especially coming from a decade of MacBook Pros, I love the idea of a laptop almost as repairable as my own [personal computer]({% post_url essay/2021-09-03-infrastructure %}).

If you know MacBook Pros, they've become almost impossible to repair. Even a simple battery replacement nowadays means I have to go to the Apple Store and ship the machine off for several weeks. Only a decade ago, I could purchase a battery online and replace it myself.

Yet the Framework promised something much more. I could replace the battery, the mainboard, the memory, even the monitor and keyboard. It was a truly repairable laptop.

I decided to take the plunge and preorder one, and it finally came this week.

## Build Quality

Despite being one of the most repairable laptops I've ever owned, I was expecting something quite flimsy. However, it is actually pretty rigid in body, both its keyboard and monitor. And despite being light and thin, it had a good heft and weight to it.

The aluminum chassis felt nice and cool to the touch, though I think the USB expansion cards are a bit hit or miss. The USB-C expansion cards do sit flush against the body of the laptop, but the USB-A expansion cards I do go into the body a bit, leaving behind a noticeable lip that catches on the fingers.

However, other than that, I have very few complaints about the quality of materials.

## Hardware Installation

Installing everything was pretty easy, with one exception.

I put in an extra Samsung 980 PRO 1TB NVMe SSD I had lying around and installed the 64 GB of DDR4 memory. I don't really have any tasks that would require so much RAM, but I suppose I always go for future upgradeability in mind. I don't really want to have to buy new RAM in the future, and it felt like I would rather have it and not need it and such like.

The only thing that was very fiddly to install was the WiFi card. I must have spent ten minutes getting the antennae to catch and then slowly try to insert the card, only to have them slip off anyway. After much frustration, I managed to get it on.

## Disk Setup

I've been playing around with different operating systems on the `devbox` and also on the virtualization machine, including OpenBSD and Gentoo Linux. I've even managed to build a kernel to my exact specifications, which is something of a first for me.

However, I decided to go with OpenBSD for the machine. Additionally, I decided to encrypt my disk with a simple USB keydisk.

Disk setup is actually pretty simple, and I would recommend just following the [OpenBSD FAQ](https://www.openbsd.org/faq/faq14.html). Otherwise, here's what I did.

First I prepared the disk and initialized it:

```sh
cd /dev && sh MAKEDEV sd0
dd if=/dev/urandom of=/dev/sd0c bs=1m
fdisk -iy -g -b 960 sd0
```
The second line writes random data and takes a *long* time, while the third line writes a GPT to the disk.

Then, I created a partition layout:

```sh
# disklabel -E sd0
Label editor (enter '?' for help at any prompt)
sd0> a a
offset: 1024
size: *
FS type: RAID
sd0*> w
sd0> q
No label changes.
```

And I did the same thing with my USB keydisk, though this time writing an MBR to the disk instead of GPT.

```sh
cd /dev && sh MAKEDEV sd2
fdisk -iy sd2
```

If you're wondering, my 1TB SSD is `sd0`, while the OpenBSD installation disk is on a USB that's `sd1`. The keydisk is at `sd2`.

Then I partitioned the keydisk, though I only needed 1 MB:

```sh
# disklabel -E sd2
Label editor (enter '?' for help at any prompt)
sd2> a a
offset: 64
size: 1M
FS type: RAID
sd2*> w
sd2> q
No label changes.
```

Once that was done, I created an encrypted volume:

```sh
bioctl -c C -k sd2a -l sd0a softraid0
sh MAKEDEV sd3
dd if=/dev/zero of=/dev/sd3c bs=1m count=1
```

The last line overwrites the first megabyte of the new pseudo-device `sd3` with zeros.

## Installation

Then, I just went through the installation of OpenBSD, careful to choose `sd3` as my root disk. Honestly, there's no reason to walkthrough it, because it's such an easy installation process.

However, instead of using the [default partition layout](https://man.openbsd.org/disklabel#AUTOMATIC_DISK_ALLOCATION), I changed the swap to 8 GB. I didn't think I needed a 100+ GB of swap, which is what happens in a default installation with a 1 TB disk. Given the size of my RAM, I think I can live with only 8 GB of swap.

Even with the 100+ GB swap, the OpenBSD default partition only utilizes about 50% of the entire disk. I still have like 400+ GB left, which I decided to keep as is.

## Conclusion

And that's my first few days with my new Framework. I don't yet have a graphical user interface, but I'm planning on installing and configuring one next week. Whether I write about any of it remains to be seen.

Other than a few headaches with the WiFi card, the Framework was easy to get up and running. It's quite a nice machine that I expect to be using for many years to come.
