+++
title = "Installing Alpine Linux on a VPS without ISO"
date = 2024-08-02
updated = 2024-08-02
description = "How I installed Alpine on this Server."
authors = ["Behemoth"]
+++

Yesterday I noticed an E-Mail I got from my VPS host, IONOS. The service I've been using so far is getting shut-down by the end of the month.
I tried their replacement service before but since I couldn't load a custom ISO I didn't bother moving to it. However now, with the gun on my chest, I've looked into it again.

After crafting a theory and asking on the #alpine-linux IRC I got a great tip from nero.

This is probably not an install method the alpine-folks endorse.

## Prerequisites
- Any Linux ISO
- VNC or other screen access

## Steps
- boot into any Linux live ISO
	- On the IONOS CloudPanel you can select your server and insert preselected ISOs.
	I've used Debian, but most install ISOs will probably work fine.
	After selecting it, your server will automatically restart.
- connect via VNC
- start the Install procedure
	- You should at least get to a point where you have internet access
- start shell
- download the mini root filesystem for your arch from [the alpine linux](https://alpinelinux.org/downloads/) website
- extract the tar file into any subdirectory
	- e.g. `cd mnt && tar -xvzf alpine-minirootfs-3.20.0-x86_64.tar.gz`
- bind mount proc & sys & dev from the live ISO
	- `mount /proc ./proc`
	- `mount /sys ./sys`
	- `mount /dev ./dev`
- copy the resolve.conf from the live ISO
	- `cp /etc/resolve.conf etc/resolve.conf`
- chroot into this root filesystem
- install alpine-conf with `apk add alpine-conf`
- (on x86_64) modify `/sbin/setup-disk`
	- change `kver=$(uname -r)` to `kver=x86_64`
	- according to the user socksinspace: the distros that have had 64bit x86 since the very early days tend to call it amd64, since amd originally came up with it
	- otherwise this will error out in a late stage of installation because it will search for the apk package "linux-amd64" which doesn't exist
- run `setup-alpine` and go through the install normally
- ...
- profit

After all this, you should be able to boot into alpine after ejecting the ISO.
You might have to run `setup-alpine` again to fix DHCP issues.
