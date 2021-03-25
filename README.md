# sailfish_linux_chroot [Potentially dangerous]

Bunch of scripts to ease creating chrooted ubuntu/sailfish in sailfishos >= 3.3.0.16.

Tested only with gnu-bash, procps-ng and psmisc-tools instead busybox replacements installed by default on sailfish >= 4.0.1.x

### How to

Clone it to non fat partition. Distro image can be created in any place via CHROOT_SRC in variables.sh
```
git clone --depth=1 https://github.com/elros34/sailfish_linux_chroot.git
cd sailfish_linux_chroot/"Distro"
devel-su
./create.sh
```
It will create shortcuts in sailfish launcher needed to enter, close chroot and helper scripts sfoschroot.sh/ubuchroot.sh in /usr/local/bin/

## Ubuntu distro
Latest working release is 19.04. In later releases: 19.10 - 21.04 weston and qtwayland fail (tested only on one device). Additionally, since 19.10 ubuntu use snap for chromium and other packages but snap fails to work in chroot. The remaining applications started with xwayland might still work. 

If you want xfce in landscape mode then make sure you have installed latest [qxcompositor and qdevel-su](https://build.merproject.org/package/show/home:elros34:sailfishapps/qxcompositor), then

```
./install.sh qxcompositor
./install.sh xfce4

```
If you use some rotation patch different than [sailfishos-default-allowed-orientations-patch](https://coderus.openrepos.net/pm2/project/sailfishos-default-allowed-orientations-patch) then qxcompositor will rotate incorrectly (freely).

For devices with hardware keyboard you can install chromium-browser via script. Browser UI scale can be changed via CHROMIUM_SCALE in scripts/dotuburc. Limited usability for devices without hardware keyboard can be achieved with: QXCOMPOSITOR_PORTRAIT and CHROMIUM_MATCHBOX_KEYBOARD in variables.sh.

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

## Sailfish distro

Useful for building packages on device without breaking base system.

Install 'BuildRequires' dependencies [optional rpm spec]
```
sfoschroot.sh --build-dep [rpm/*.spec]
```

Build rpm package [optional rpm spec]
```
sfoschroot.sh --build [rpm/*.spec]
```

### Debugging 

Change TRACE_CMD in variables.sh to "set -x"

### Clean up

'.copied' file contains all installed files like:
 - /usr/local/share/applications/$DISTRO_PREFIX*.desktop and /usr/share/applications/$DISTRO_PREFIX*.desktop
 - icons in /usr/share/icons/hicolor
 - /usr/local/bin/${DISTRO_PREFIX}chroot.sh

### Credits

 - [Preflex](https://talk.maemo.org/showthread.php?t=98882) for idea and code inspiration
 - [NotKit](https://github.com/notkit) for help with qxcompositor and libhybris use in kwin/weston
 - [eLtMosen](https://github.com/eLtMosen) for Sailfish OS style icons

