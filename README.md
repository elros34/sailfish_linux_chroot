# sailfish_linux_chroot

Bunch of scripts to ease creating chrooted ubuntu/sailfish in sailfishos >= 3.3.0.16

### How to

Clone it to non fat partition. Image (CHROOT_IMG in variables.s) can be set to any path
```
git clone --depth=1 https://github.com/elros34/sailfish_linux_chroot.git
cd sailfish_linux_chroot/"Distro"
devel-su
./create.sh
```
It will create shortcuts needed to enter and leave chroot

## Ubuntu

If you want xfce in landscape mode then make sure you have repository with [qxcompositor](https://build.merproject.org/package/show/home:elros34:sailfishapps/qxcompositor) enabled, then

```
./install.sh qxcompositor
./install.sh xfce4

```
If you have device with hardware keyboard you can install chromium-browser via script. Browser UI scale can be changed via CHROMIUM_SCALE in scripts/dotuburc.

```
./install.sh chromium-browser
```

### Audio (experimental)

Enable it in variables.sh
Sailfish's pulseaudio mutes other audio sources so use pavucontrol (pulse audio volume control) to unmute it in 'playback' tab

### Tips for xfce

 - Increase dpi in 'Settings Manager/Appearance/Fonts/DPI'
 - Select Default-hdpi theme in 'Settings Manager/Window Manager/Style/Theme'
 - Disable compositing in 'Settings Manager/Window Manager Tweaks/Compositor'

### Debugging 

Change TRACE_CMD in variables.sh to "set -x"

### Clean up

 - /usr/local/share/applications/$DISTRO_PREFIX*.desktop and /usr/share/applications/$DISTRO_PREFIX*.desktop
 - icons in /usr/share/icons/hicolor
 - /usr/local/bin/$DISTRO_PREFIXchroot.sh

### Credits

 - [Preflex](https://talk.maemo.org/showthread.php?t=98882) for idea and code inspiration
 - [NotKit](https://github.com/notkit) for help with qxcompositor and libhybris use in kwin/weston
 - [eLtMosen](https://github.com/eLtMosen) for Sailfish OS style icons

### Contributing

Feel free to improve scripts and this basic "How to" instruction

### Donate
[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://paypal.me/sfoselro)
