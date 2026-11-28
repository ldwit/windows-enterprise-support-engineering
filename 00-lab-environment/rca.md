# Root cause analysis: VirtualBox can't start VMs on an Ubuntu host

This write-up covers the main incident hit while building this lab: VirtualBox was installed, but its kernel driver wouldn't load, so no VM could start. It's written the way you'd explain it to a customer.

## Summary

On an Ubuntu 24.04 host running Linux kernel 7.0, VirtualBox reported that its kernel module (`vboxdrv`) wasn't loaded, and no virtual machine could start. The host already had VirtualBox **7.0.26** installed. That version's kernel module build failed on kernel 7.0 every time the system booted. Replacing it with VirtualBox **7.2.22** from Oracle's repository and rebuilding the module fixed the problem in about two minutes, with no loss of existing VMs.

## Impact

- **Who:** anyone on this host trying to start a VirtualBox VM.
- **What:** VirtualBox Manager opened, but every VM failed to start. Three existing VMs (two RHEL VMs plus the new Windows 11 lab) were unusable until the fix.
- **Data loss:** none. VM disks and settings in `~/VirtualBox VMs` and `~/.config/VirtualBox` were untouched.

## Timeline (US Central, Nov 27, 2026)

| Time | Event |
|---|---|
| 07:51 | Host boots. `vboxdrv.service` tries to build the VirtualBox kernel modules and fails. Nobody notices, because no VM is started. |
| 12:24 | During lab setup, `VBoxManage --version` prints **"WARNING: The vboxdrv kernel module is not loaded"** and reports version `7.0.26r168464`. `systemctl status vboxdrv` shows **failed (exit-code)** since 07:51. |
| 12:25 | `dpkg -l` shows only `virtualbox-7.0` installed. `/var/log/vbox-setup.log` shows the module build failing with missing VirtualBox headers. Oracle's repository offers `virtualbox-7.2` 7.2.22. |
| 12:26 | `virtualbox-7.0` removed, `virtualbox-7.2` installed, `vboxconfig` rebuilds the module. `vboxdrv.service` is **active**. |
| 12:27 | Verified: version `7.2.22r175245`, and `vboxdrv`, `vboxnetflt`, and `vboxnetadp` are loaded. |

## Root cause

VirtualBox runs VMs through its own Linux kernel driver, `vboxdrv`. Because it's an out-of-tree module, it's compiled on the host against the running kernel each time the kernel changes (and at boot if it's missing).

The installed VirtualBox 7.0.26 predates kernel 7.0. Its module build system expects an older kernel build layout, so when it compiled against kernel 7.0 the compiler couldn't find VirtualBox's own bundled headers:

```text
SUPDrvInternal.h:47:10: fatal error: VBox/cdefs.h: No such file or directory
common/string/strformatrt.c:42:10: fatal error: iprt/string.h: No such file or directory
make: *** [/tmp/vbox.0/Makefile-footer.gmk:133: vboxdrv] Error 2
```

**Evidence that rules out other causes:**

- `linux-headers-7.0.0-44-generic` was installed, and the build ran inside `/usr/src/linux-headers-7.0.0-44-generic`. The *kernel* headers weren't missing; VirtualBox's own headers weren't found.
- Host Secure Boot was **disabled** (`mokutil --sb-state`), so this wasn't an unsigned-module rejection.
- The failure happened at boot, before KVM or any VM was involved, so it wasn't a VT-x conflict.

The likely trigger was a kernel upgrade (Ubuntu's hardware enablement stack moves 24.04 to newer kernels) on a machine where an older VirtualBox was already installed. Nothing fails visibly until someone tries to start a VM.

## Resolution

```bash
sudo apt remove --purge -y virtualbox-7.0
sudo apt autoremove -y
sudo apt install -y virtualbox-7.2
sudo /sbin/vboxconfig
```

Verified with:

```bash
VBoxManage --version            # 7.2.22r175245
systemctl status vboxdrv        # active (exited)
lsmod | grep vbox               # vboxdrv, vboxnetflt, vboxnetadp
```

## Prevention

- **Install VirtualBox from Oracle's apt repository**, not Ubuntu's `virtualbox` package, so `apt upgrade` brings in VirtualBox releases that support new kernels.
- **Check VirtualBox after every kernel upgrade.** After rebooting into a new kernel, run `systemctl status vboxdrv`. If it failed, update VirtualBox and run `sudo /sbin/vboxconfig`.
- **Check the release's supported kernels before a major kernel jump.** VirtualBox's changelog lists newly supported kernel versions.
- **Keep the previous kernel in GRUB** (Ubuntu does this by default), so you can boot it under **Advanced options for Ubuntu** if VirtualBox hasn't caught up with a brand-new kernel yet.
