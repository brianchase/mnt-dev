# mnt-dev

## About

This Bash script mounts and unmounts removable devices, such as USB
thumb drives. It opens and closes encrypted devices with
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/).

## How It Works

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
creating the directory in `/mnt` if necessary. Similarly, if a
device's file system is crypto-LUKS, it uses
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
synonymous) require the name of a particular device or `all`. To mount
`/dev/sdb1` in this way:

```
$ mnt-dev.sh mount /dev/sdb1
```

To unmount it, use `unmount` or `umount`:

```
$ mnt-dev.sh unmount /dev/sdb1
```

Using `mount all` tells the script to mount all connected devices that
aren't mounted:

```
$ mnt-dev.sh mount all
```

Using `unmount all` or `umount all` tells the script to unmount all
connected devices that are mounted:

```
$ mnt-dev.sh umount all
```

## Customizing

If you prefer a different mount point, say, `/media`, simply change
the value of `PNT` on line four of the script:

```
PNT="mnt"
```

If your system has more than one internal drive, you may need the
script to look for connected devices starting at `/dev/sdc` or higher.
In that case, find the `readarray` for `DevArr1` in the function
`dev_arrays`:

```
readarray -t DevArr1 < <(lsblk -dpno NAME,FSTYPE /dev/sd[b-z]* 2>/dev/null | awk '{if ($2) print $1;}')

```

Change `/dev/sd[b-z]*` as necessary – for example, to `/dev/sd[c-z]*`
to treat `/dev/sdc` as the first possible connected device.

## Portability

Since the script uses arrays, it's not strictly
[POSIX](https://en.wikipedia.org/wiki/POSIX)-compliant. As a result,
it isn't compatible with
[Dash](http://gondor.apana.org.au/~herbert/dash/) and probably a good
number of other shells.

## License

This project is in the public domain under [The
Unlicense](https://choosealicense.com/licenses/unlicense/).

## Requirements

* [cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/) (for encrypted devices)
* [sudo](https://www.sudo.ws/) (used with mount, umount, cryptsetup, mkdir, rmdir)

