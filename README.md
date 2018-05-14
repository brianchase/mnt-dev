# mnt-usb

## ABOUT

This little bash script mounts and unmounts USB drives. It can open
and close encrypted devices with
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/).

If the script detects just one connected device, it will check whether
the device is mounted and ask whether to mount or unmount the device
accordingly.

If it detects more than one connected device, it will list them – up
to ten devices each on `/dev/sdb` through `/dev/sdz` – and ask which
ones to mount or unmount. You can select individual devices or chose
to mount all the ones that aren't mounted or to unmount all the ones
that are. It then gives you the option of returning to the menu, which
it updates to reflect the current status of each device. You can then
make more selections, and so on.

By default, the script mounts all devices in `/mnt` according to its
name in `/dev`. For example, it will mount `/dev/sdb1` in `/mnt/sdb1`,
creating the directory if necessary. Similarly, if `lsblk` detects
that a device's file system is crypto-LUKS, the script will use the
name with [cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/) –
for example, by attempting to open `/dev/sdb1` at `/dev/mapper/sdb1`
before mounting it at `/mnt/sdb1`.

After unmounting a device, the script removes the corresponding
directory in `/mnt` and, if the device is encrypted, uses
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/) to close the
corresponding device in `/dev/mapper`.

If you prefer to mount devices in a different directory, say,
`/media`, simply change the value of `PNT` on line four:

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

