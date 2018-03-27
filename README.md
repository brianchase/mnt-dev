# mnt-usb

## ABOUT

This little bash script mounts and unmounts USB drives. It works with
encrypted drives using
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/), though with
limitations described below.

First, the script sets `/mnt/usb` as its mount point. If you prefer a
different mount point, simply edit lines 4 and 5.

Next, starting on line 8, edit the array to include the UUIDs of
encrypted drives. The script will open and close them with
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/). For this to
work, however, the entire drive must be encrypted. If it has several
partitions, some or all of which are encrypted, don't include its UUID
in the list. In that case, the script should work with the partitions
that aren't encrypted but not the encrypted ones.

If more than one device is connected to your computer, the script will
list them – that is, up to ten devices each on `/dev/sdb` through
`/dev/sdz` – and ask you which one to mount. For example, if a drive
at `/dev/sdb` has two partitions, `/dev/sdb1` and `/dev/sdb2`, the
script will give you the option of mounting one or the other. If a
device is already mounted at `/mnt/usb`, the script will offer to
unmount it.

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

