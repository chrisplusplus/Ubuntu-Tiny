# Ubuntu Tiny 24.04 LTS

Ubuntu Tiny 24.04 is a fast, portable, and power-saving Ubuntu 24.04 LTS edition.

------------------------------------------

### Ubuntu 24.04 LTS Tiny downloads (LANG = en_US | zh_CN)

- **Desktop image**: [x64 (UEFI+MBR)](https://github.com/ghostplant/ubuntu-pe/releases/download/ubuntu-24.04/noble-mate-x86_64-20241225.iso) | [arm64 (UEFI)](https://github.com/ghostplant/ubuntu-pe/releases/download/ubuntu-24.04/noble-mate-aarch64-20241225.iso)
- **Core image**: [x64 (UEFI+MBR)](https://github.com/ghostplant/ubuntu-pe/releases/download/ubuntu-24.04/noble-core-x86_64-20241122.iso)

------------------------------------------

### What's New for Ubuntu Tiny 24.04

* 20241225: Bug Fix - EFI dependency missing using Wiminstall.gptboot for Windows Installation;
* 20241116: Add Ubuntu Tiny 24.04 for Arm64 (support Mac VBox / Android pKVM);
* 20241027: Update virtio_gpu detection for QEMU; Add cmd "mount.ios" for iPhone;
* 20240818: Allow "Boot in normal mode" if booting from Ventoy;
* 20240704: Enable "Alt + PrtScr" for Area Screenshot;
* 20240425: Ubuntu Tiny 24.04 Stable;
* 20240407: Security Packs for Ubuntu 24.04 (beta);
* 20240316: Upgrade to Linux 6.8 + Python 3.12.2;
* 20240224: Second Edition of Ubuntu 24.04 Tiny.

------------------------------------------

### Write Ubuntu Tiny 24.04 ISO to USB

```sh
sudo dd if=./noble-mate-x86_64-xxxxxxxx.iso of=/dev/<usb-dev-file> bs=16K && sync
```

### Ubuntu Tiny 24.04 supported features

1. Support booting USB/CDROM in both MBR and UEFI machines.
2. Support installing Ubuntu image to hard drive: `sudo ubi-lite`.
3. Support installing Windows image to MBR hard drive:

   ```sh
   sudo wiminstall.mbrboot /dev/<os-part-name> <WIM file> <image-id>
   ```

   Method 1 will erase Grub on the hard drive:

   ```sh
   sudo wiminstall.mbrboot /dev/sda1 ./xp-sp3.wim
   sudo wiminstall.mbrboot /dev/sda1 ./windows-7.wim 4
   sudo wiminstall.mbrboot /dev/sda1 ./windows-11.wim 1
   ```

   Method 2 does not erase Grub, but requires manual boot configuration:

   ```sh
   sudo wiminstall /dev/sda1 ./xp-sp3.wim
   sudo update-grub
   ```

   For UEFI installation to a GPT hard drive:

   ```sh
   sudo EFI=/dev/<efi-part-name> wiminstall.gptboot /dev/<os-part-name> <WIM file> <image-id>
   ```

<p align="center">
  <img src="Ubuntu_PE.jpg" data-canonical-src="Ubuntu_PE.jpg" />
</p>

------------------------------------------

### Ubuntu Tiny 24.04 desktop for remote internet

Default VNC password: `123456`. You can update it with `vncpasswd` inside the VNC X session.

```sh
# Build the Ubuntu 24.04 remote desktop image locally
docker build -t ghostplant/flashback:24.04 -f Dockerfile.2404 --network=host .

# Boot service: use a web browser to login at http://localhost:8443/
docker run -it --rm --privileged -p 8443:8443 -v /external:/root ghostplant/flashback:24.04

# Language: set locale to en_US.UTF-8
docker run -it --rm --privileged -e LANG=en_US.UTF-8 -p 8443:8443 -p 5901:5901 -v /external:/root ghostplant/flashback:24.04

# Resolution size: set display resolution to 1366x768
docker run -it --rm --privileged -e GEOMETRY=1366x768 -p 8443:8443 -p 5901:5901 -v /external:/root ghostplant/flashback:24.04

# Initial password: length must be between 6 and 8 characters
docker run -it --rm --privileged -e INIT_PASS=123456 -p 8443:8443 -p 5901:5901 -v /external:/root ghostplant/flashback:24.04
```

Then use Firefox/Chrome to login if you expose port 8443:

```sh
x-www-browser http://localhost:8443/
x-www-browser https://localhost:8443/
```

------------------------------------------

### Remove packages from the historical Ubuntu 24.04 custom APT repo

If an installed Ubuntu Tiny 24.04 system was created from an older ISO that used
the historical Ghostplant custom APT repo, run this cleanup script once after
installation to purge packages that apt still identifies as coming from that repo
and to remove leftover repo source/key files:

```sh
sudo scripts/remove-custom-repo-packages.sh --dry-run
sudo scripts/remove-custom-repo-packages.sh --yes
```

------------------------------------------

## Reporting Issues

You can post issues here for any suggestions to improve Ubuntu Tiny 24.04. To report a new issue, log in with a GitHub account, open a new issue, fill in the report, and submit it.
