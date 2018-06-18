# mnt-dev

## ABOUT

This little Bash script mounts and unmounts removable devices, such as
USB thumb drives. It can open and close encrypted devices with
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/).

If the script detects just one connected device, it will check whether
the device is mounted and ask whether to mount or unmount the device
accordingly.

If it detects more than one device, it will list them – up to ten
devices each in `/dev/sdb` through `/dev/sdz` – and ask which ones to
mount or unmount. You can select individual devices or chose to mount
all the ones that aren't mounted or to unmount all the ones that are.
It then gives you the option of returning to the menu, which it
updates to reflect the current status of each device.

By default, the script mounts all devices in `/mnt` according to its
name in `/dev`. For example, it will mount `/dev/sdb1` in `/mnt/sdb1`,
creating the directory if necessary. Similarly, if it detects that a
device's file system is crypto-LUKS, it will use
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/) to open the
device in `/dev/mapper` under the device's name. For example, it will
open `/dev/sdb1` at `/dev/mapper/sdb1`, then mount it at `/mnt/sdb1`.

After unmounting a device, the script will remove the corresponding
directory in `/mnt` and, if the device is encrypted, use
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/) to close the
corresponding device in `/dev/mapper`.

The script accepts two arguments:

```
$ mnt-dev.sh [mount|unmount|umount] [device|all]
```

So, to mount a specific device, such as `/dev/sdb1`, you could run the
script without arguments – and select it from the menu, if the script
detects more than one – or you could run:

```
$ mnt-dev.sh mount /dev/sdb1
```

To unmount it in this way, use `unmount` or `umount` with the device's
name, as in:

```
$ mnt-dev.sh unmount /dev/sdb1
```

The arguments `mount all` tell the script to mount all connected
devices:

```
$ mnt-dev.sh mount all
```

The arguments `unmount all` or `umount all` tell the script to unmount
all connected devices, as in:

```
$ mnt-dev.sh unmount all
```

You can always save keystrokes by running the script without options,
but they come in handy when you want to run it from other scripts.

If you prefer to mount devices in a different directory, say,
`/media`, simply change the value of `PNT` on line four:

```bash
PNT="mnt"
```

## PORTABILITY

Since the script uses arrays – more so than a script probably should –
it's not strictly
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
* [util-linux](https://github.com/karelzak/util-linux/)

## FEEDBACK

* http://github.com/brianchase/mnt-dev

