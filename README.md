# sailfish_ubu_chroot

Bunch of scripts to ease creating chrooted ubuntu in sailfishos

### How to
```
git clone --depth=1 https://github.com/elros34/sailfish_ubu_chroot.git
cd sailfish_ubu_chroot
```

Set path (CHROOT_IMG) in ubu-variables.sh if you want to create image in different place then current directory

```
devel-su
./ubu-create.sh
```
It will create shortcuts needed to enter and leave chroot. Lipstick doesn't handle multi instances of applications so it's good to install [sailfishos-launcher-multi-instances-patch](https://coderus.openrepos.net/pm2/project/sailfishos-launcher-multi-instances-patch)

If you want xfce in landscape mode then install latest [qxcompositor](https://build.merproject.org/package/show/home:elros34:sailfishapps/qxcompositor) and then

```
./ubu-install.sh qxcompositor
./ubu-install.sh xfce4

```
If you have device with hardware keyboard you can install chromium-browser via script. Browser UI scale can be changed via CHROMIUM_SCALE in scripts/dotuburc.

```
./ubu-install.sh chromium-browser
```

### Debugging 

Change TRACE_CMD in ubu-variables.sh to "set -x"

### Contributing
Feel free to improve scripts and this basic "How to" instruction
