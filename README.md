# mnt-dev

## ABOUT

This Bash script mounts and unmounts removable devices, such as USB
thumb drives. It opens and closes encrypted devices with
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/).

## HOW IT WORKS

If the script detects just one connected device (it looks at
`/dev/sdb` through `/dev/sdz`), it checks whether the device is
mounted. If it's mounted, the script asks to unmount it. If it's not
mounted, the script asks to mount it.

If the script detects more than one device, it lists them and ask
which ones to mount or unmount. You can select individual devices or
chose to mount all the ones that aren't mounted or to unmount all the
ones that are. It then gives you the option of returning to the menu,
which it updates to reflect the current status of each device.

By default, the script mounts all devices in `/mnt` according to its
name in `/dev`. For example, it mounts `/dev/sdb1` in `/mnt/sdb1`,
creating the directory if necessary. Similarly, if a device's file
system is crypto-LUKS, it uses
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/) to open the
device in `/dev/mapper` under the device's name. For example, it opens
`/dev/sdb1` at `/dev/mapper/sdb1`, then mounts it at `/mnt/sdb1`.

After unmounting a device, the script removes the corresponding
directory in `/mnt` and, if the device is encrypted, uses
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/) to close the
corresponding device in `/dev/mapper`.

You may run the script without options and follow the prompts or
run it with these options:

```
$ mnt-dev.sh [mount|unmount|umount] [device|all]
```

The options `mount`, `unmount`, and `umount` (the latter two are
synonymous) require the name of a device, such as `/dev/sdb1`, or
`all`. For example, to mount `/dev/sdb1`:

```
$ mnt-dev.sh mount /dev/sdb1
```

To unmount it in this way, use `unmount` or `umount`:

```
$ mnt-dev.sh unmount /dev/sdb1
```

The options `mount all` tell the script to mount all connected
devices:

```
$ mnt-dev.sh mount all
```

The options `unmount all` and `umount all` tell the script to unmount
all connected devices:

```
$ mnt-dev.sh umount all
```

If you prefer to mount devices in a different directory, say,
`/media`, simply change the value of `PNT` on line four of the script:

```
PNT="mnt"
```

## PORTABILITY

Since the script uses arrays, it's not strictly
[POSIX](https://en.wikipedia.org/wiki/POSIX)-compliant. As a result,
it isn't compatible with
[Dash](http://gondor.apana.org.au/~herbert/dash/) and probably a good
number of other shells.

## LICENSE

This project is in the public domain under [The
Unlicense](https://choosealicense.com/licenses/unlicense/).

## REQUIREMENTS

* [cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/) (for encrypted devices)
* [sudo](https://www.sudo.ws/) (used with mount, umount, cryptsetup, mkdir, rmdir)

