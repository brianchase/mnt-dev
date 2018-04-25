# mnt-usb

## ABOUT

This little bash script mounts and unmounts USB drives. It can open
and close encrypted devices with
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/).

The default mount point for all devices is `/mnt/usb`. If you prefer a
different one, simply edit lines 4 and 5 of the script, as necessary:

```
MAP="usb"
MT1="/mnt/$MAP"
```

To use [cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/) with
encrypted devices, edit the array starting on line 8 to include their
UUIDs:

```
ED[1]="abababab-abab-abab-abab-abababababab"
ED[2]="bcbcbcbc-bcbc-bcbc-bcbc-bcbcbcbcbcbc"
ED[3]="cdcdcdcd-cdcd-cdcd-cdcd-cdcdcdcdcdcd"
```

If more than one device is connected to your computer, the script will
list them – up to ten devices each on `/dev/sdb` through `/dev/sdz` –
and ask you which one to mount. For example, if `/dev/sdb` has two
partitions, `/dev/sdb1` and `/dev/sdb2`, it will give you the option
of mounting one or the other. If a device is already mounted at
`/mnt/usb`, the script will offer to unmount it.

Please see the script for further comments.

## LICENSE

This project is in the public domain under [The
Unlicense](https://choosealicense.com/licenses/unlicense/).

## REQUIREMENTS

* [cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/) (for encrypted drives)
* [sudo](https://www.sudo.ws/) (for encrypted drives)
* [util-linux](https://github.com/karelzak/util-linux/)

## FEEDBACK

* http://github.com/brianchase/mnt-usb

