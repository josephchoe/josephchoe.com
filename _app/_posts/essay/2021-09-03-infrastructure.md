---
title: Personal Infrastructure
date: 2021-09-03 08:00:00 -0600
author: joseph
image_url: /assets/posts/essay/2021-09-03-infrastructure/share.png
---

Homelabs are one of those things that quickly spiral out of control.

For the longest time, my "homelab" has been my laptop, a MacBook Pro that I might update every three cycles or so. I did everything on this computer, including watching movies, browsing the Internet, and of course software development.

Prior to that, about a decade ago, I used to build all of my computers. However, the constant need for maintenance and upgrade quickly diminished my tolerance for the finicky nature of building computers.

Still, it quickly became clear over the last couple of years that my current laptop was on its last legs. Couple that with the knowledge that machines from most major vendors constantly monitors your telemetry, and I needed to look for a better way.

I started thinking about building computers again, not just for myself but also for my wife.

Now, almost a year later, things have certainly expanded.

{% include image.html src="assets/posts/essay/2021-09-03-infrastructure/rack.png" description="Personal homelab, circa September 2021. <br>Pay no attention to the cable management." %}

## The Rack

When I set about this project of building out my homelab in December 2020, I decided I would build out a server rack for all of my family's computing needs.

Why exactly?

Part of my decision making was that I didn't want to clutter our desks with bulky workstations. Personal computer cases take up way too much space for my liking, and I didn't want to put these huge heavy computer cases on our rather flimsy desks. Nor did I want to put them on the floor where they could overheat from the carpet.

I also didn't want the noise pollution of several different fans going off at once in our home office. I could mitigate that somewhat by using better CPU and exhaust fans, but the GPU or chipset fans were mostly out of my control. I also didn't want to look into AIO coolers or custom water loops, because at the end of the day, fans are still being used in the radiator, so it's still just as noisy.

But, if I could keep the rack out of the way and move a couple of cables to our office, I could have absolute silent computing!

Plus, I thought it would be an educational experience to build out a server rack. You suddenly learn a lot about a lot of different things!

## Networking

Building out my homelab has inevitably led me to learn more and more about networking. Before this project, I had no idea about VLANs or subnets or whatever. About the most I did on a firewall was to forward a port or two.

Prior to this project, I had already used a couple of Raspberry Pi's to serve as a DNS-based sinkhole for ads, as well as a controller for the network. When I did that, I had purchased a small 8-port switch and an access point from UniFi. The access point served our laptops just fine, while the Raspberry Pi's used ethernet via the switch.

That worked well, but for this project, I would need a lot more ports, so I had to purchase an even larger switch. I purchased a 24 port switch, which was more than what I actually needed, but I suppose it's better to have it and not need it, than to need it and not have it.

One of my future goals is to build my own router, but I didn't want to take several weeks to do that, so I reused our old UniFi router. However, I really had to dig in and understand how to set up different private subnets, VLANs, and so forth. It took a while for me to wrap my head around it, and I did after a particularly frustrating weekend, but for a while there I was tearing my hair out.

## My Wife's Personal Computer

This was the first of many computers I built this year.

Though it's funny how it's customary to say I "built" this computer, when really I purchased components from an online vendor and assembled those components together. It's something more akin to Legos in that respect.

My wife's requirements were that it be able to play games, so her computer is actually a bit better than mine in terms of hardware. However, due to the parts shortages of 2020 and 2021, I had to make do with the last generation of CPU and GPU.

Due to personal reasons, I'm a big supporter of AMD, and I try to avoid using Nvidia's products whenever I can. So her machine has a Ryzen CPU and a Radeon GPU.

Because this PC lives on a rack that's a fair distance from our desk, we had to look for solutions that allowed us to feed our I/O through one or two cables. At first, we tried a single Thunderbolt cable, but Thunderbolt on most AMD motherboards seems to be lacking much support. It was finicky and unstable, no matter what we did. So I settled on a USB extender paired with a very long DisplayPort cable.

Honestly, this was the most difficult to build, because my computer-building skills had atrophied from almost a decade of purchasing MacBook Pros. I learned many valuable lessons in this first iteration that were very helpful as the year rolled onwards.

## Network Attached Storage

Next, I decided to tackle building a network attached storage server, or NAS.

I'm a big fan of the chassis made by Supermicro, and I found one on Ebay with the right form factor I was looking for. It didn't come with any motherboard or anything like that though, so I had to look for those myself. I went with a server-grade CPU and motherboard, as well as ECC RAM. I suppose I was pretty paranoid about losing data.

I run Unraid on this machine, mostly because I didn't want to buy 24 hard drives and learn to set up ZFS. My budget limited me to two 12 TB hard drives, one which I use as a parity drive, while giving myself the option in the future to buy more drives and expand the machine's capacity.

I must say, it's been pretty nice to have so much storage available. I managed to free up a *lot* of space on my laptop.

## KVM

At around this time, I bought a KVM switch and hooked up an extra keyboard and mouse along with a tiny monitor. This allowed me to directly control each machine and switch between them pretty easily.

## Virtualization Server

Next I decided to build a virtualization server. Parts shortages were still affecting my ability to purchase consumer-grade hardware, but server-grade hardware was actually pretty easy to find at reasonable prices. A Supermicro chassis makes another appearance here, this time in 1U form factor.

I use this for many different odd workloads, including video encoding and even private game servers for my wife. Sometimes I'll use it to spin up a test virtual machine so I can play around with a new operating system. It's especially useful for work, as I can spin up new VMs to build and test server configurations.

## My Personal Computer

Finally, I could build my personal computer, which I've come to call `devbox`. It was supposed to replace my laptop, but it's grown to be much more. Building the other computers allowed me to make more informed decisions, and I decided to *also* use the same virtualization engine on the `devbox` in order to virtualize whatever operating system I needed.

So I've got a virtual machine for personal software development, one for work, another to edit videos in Windows 8, and yet another to play video games, though this one doesn't get used very much, alas. These VMs passthrough the relevant USB and PCIe, also using a USB extender and DisplayPort cable, to the monitor and keyboard at my desk.

Doing things this way also allows me to try out operating systems like Fedora or OpenBSD, breaking things without worrying about doing things the "right" way. Coupled with the NAS and the virtualization server, I have a lot of computing power available to use at my fingertips.

## Conclusion

I'm not sure what's next. I think my homelab is pretty much complete, though I suppose there's the router build I've put on hold.

My main takeaway is that while companies like Apple spend a great deal of resources to make things "just work", if you take the time and effort to learn **how and why things work**, you gain much more in the long term. I've used the knowledge and skills I've attained in this personal project in many other projects besides, both personal and work-related.

I don't know if I could ever go back.
