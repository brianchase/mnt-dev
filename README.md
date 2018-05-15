# mnt-usb

## ABOUT

This little bash script mounts and unmounts devices in `/dev/`, such
as USB drives. It can open and close encrypted devices with
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/).

If the script detects just one connected device, it will check whether
the device is mounted and ask whether to mount or unmount the device
accordingly.

If it detects more than one device, it will list them – up to ten
devices each in `/dev/sdb` through `/dev/sdz` – and ask which ones to
mount or unmount. You can select individual devices or chose to mount
all the ones that aren't mounted or to unmount all the ones that are.
It then gives you the option of returning to the menu, which it
updates to reflect the current status of each device. You can then
make more selections, and so on.

By default, the script mounts all devices in `/mnt` according to its
name in `/dev`. For example, it will mount `/dev/sdb1` in `/mnt/sdb1`,
creating the directory if necessary. Similarly, if it detects that a
device's file system is crypto-LUKS, it will use
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/) to open the
device in `/dev/mapper` under the device's name. For example, it will
open `/dev/sdb1` at `/dev/mapper/sdb1`, then mount it at `/mnt/sdb1`.

After unmounting a device, the script removes the corresponding
directory in `/mnt` and, if the device is encrypted, uses
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/) to close the
corresponding device in `/dev/mapper`.

The script accepts two arguments for mounting or unmounting a specific
device:

```
mnt-usb.sh [mount|unmount|umount] [device]
```

In other words, you could mount `/dev/sdb1` by running the script
normally, without arguments. But if the script would detect more than
one connected device, you could bypass the menu by running:

```
mnt-usb.sh mount /dev/sdb1
```

You could then unmount it by changing `mount` above to `unmount` or
`umount`.

If you prefer to mount devices in a different directory, say,
`/media`, rather than `/mnt`, simply change the value of `PNT` on line
four:

```
PNT="mnt"
```

Please see the script for further comments.

## LICENSE

This project is in the public domain under [The
Unlicense](https://choosealicense.com/licenses/unlicense/).

## REQUIREMENTS

* [cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/) (for encrypted devices)
* [sudo](https://www.sudo.ws/) (used with mount, umount, cryptsetup, mkdir, rmdir)
* [util-linux](https://github.com/karelzak/util-linux/)

## FEEDBACK

* http://github.com/brianchase/mnt-usb

