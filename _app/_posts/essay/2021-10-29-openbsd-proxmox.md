---
title: Installing OpenBSD on a Proxmox VM
date: 2021-10-29 08:00:00 -0600
author: joseph
---

I've been playing around with operating systems lately that I wouldn't have before building out my new [infrastructure]({% post_url essay/2021-09-03-infrastructure%}).

Some like Gentoo Linux I've only done for hobbyist reasons. But others like OpenBSD I plan to use for running actual services on both my home network and personal projects.

But I also want to use OpenBSD as my daily driver operating system, and because of the way my `devbox` acts as my personal computer in a lot of ways, I'd like to be able to interact with the VMs as such, including with monitor and keyboard support, rather than through the Proxmox browser UI.

This means I need PCIe passthrough, which means I need UEFI.

However, I've run into a bit of trouble getting UEFI to work with an OpenBSD installation on Proxmox.

## The Problem

OpenBSD comes with several different types of installation media, including `.iso` and `.img`. The `.iso` file doesn't contain any UEFI boot loaders, because you're supposed to use the `.img` file for that purpose.

But every time I used the `.img` file, the Proxmox VM would not boot. I could only boot using the `.iso` file in BIOS.

So, here's my solution, even if it's a little bit goofy.

## Pre-Installation

First, I create a new VM in Proxmox. I make sure to set the CD image as the `.iso` installation file, and select the **Guest OS** as *Other*.

Next, I select the **BIOS** as *SeaBIOS* and the **machine** as *q35*.

My hard disk will be a *SCSI* device with some amount of memory, depending on the workload, though usually 32 GB is enough. Due to my NAS, I have more than enough space to play around with.

I set the **CPU** to *1 core*, though I'll revisit the CPU after I'm done with this setup wizard.

Then, I set the memory to a ballooning device with about 2 to 8 GB of memory, usually dependent on the workload. After setting up the network device to the specific VLAN set aside for services, I confirm the setup and click *Finish*.

Once that's done, I need to log into the shell and edit a file:

```sh
> nano /etc/pve/qemu-server/100.conf
```

Here I'll set the CPU with the following flags:

```
cpu: host,hidden=1,flags=+pcid
```

This will allow me to passthrough my GPU's PCIe lane to the virtual machine.

## Installation

Now I start the virtual machine and go through the OpenBSD installation process.

It's a pretty simple installer, so you don't need to stray very far from the default settings. Here though I make sure to select *GPT* instead of *MBR* when asked:

```sh
Use (W)hole disk MBR, whole disk (G)PT, (O)penBSD area or (E)dit?
```

If we select MBR, then we'll only be able to boot up the virtual machine in BIOS and not UEFI, which means we won't be able to passthrough PCIe, which in turn defeats the whole point of the exercise.

## Post-Installation

After the installation is complete, I halt the virtual machine and change the **BIOS** option to UEFI. Don't forget to add an EFI disk and any PCIe passthrough. I make sure to passthrough the GPU and the USB controller that my USB extender is plugged into.

After that, the virtual machine will boot as normal and use my GPU. Huzzah!

## Conclusion

Like I said, this is a bit kludgy, but if there's a better way, feel free to tell me! I'd be happy to change my current procedure.

All in all, this has been a game changer for me. Being able to boot whatever operating system I want or need has allowed me to learn a lot. Turns out, you learn a lot faster when you have the freedom to break things and spin up fresh new VMs with a click of a button.

One thing I noticed was that GPU passthrough was a little bit weird with my Radeon RX 5500 XT. I have to restart the machine after each VM is stopped  because the GPU doesn't properly reset, even with Nicholas Sherlock's `vendor-reset` [workaround](https://www.nicksherlock.com/2020/11/working-around-the-amd-gpu-reset-bug-on-proxmox/).

However, within the last couple of months, after running `apt dist-upgrade` on the Proxmox server, I've found that I've been able to reboot VMs without needing to reboot the entire machine in between. So I guess that was fixed? I'm not really sure. And I've noticed some weird problems with my USB extender as well.

Still, those problems aren't enough for me to rethink my current setup quite yet. I'm very pleased with how things have turned out.
