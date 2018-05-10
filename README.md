# mnt-usb

## ABOUT

This little bash script mounts and unmounts USB drives. It can open
and close encrypted devices with
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/). To use
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/) with encrypted
devices, put their UUIDs in the array starting on line 7, replacing
the dummy values there for illustration:

```
ED[0]="abababab-abab-abab-abab-abababababab"
ED[1]="bcbcbcbc-bcbc-bcbc-bcbc-bcbcbcbcbcbc"
ED[2]="cdcdcdcd-cdcd-cdcd-cdcd-cdcdcdcdcdcd"
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
* [sudo](https://www.sudo.ws/)
* [util-linux](https://github.com/karelzak/util-linux/)

## FEEDBACK

* http://github.com/brianchase/mnt-usb

