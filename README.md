# mnt-usb

## ABOUT

This little bash script mounts and unmounts USB drives. It works with
encrypted drives using
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/), though with
limitations described below.

First, the script sets `/mnt/usb` as the mount point. If you prefer a
different one, simply edit line 4 (`MAP=...`) and line 5 (`MT1=...`).
Keep in mind that the script expects to find all encrypted drives at
`/dev/mapper/$MAP`, so changing line 4 has implications for how it
uses [cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/).

Next, starting on line 8, edit the array to include the UUIDs of
encrypted drives. The script will attempt to open and close them with
[cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/), assuming that
the entire drive is encrypted. If the drive has several partitions,
some or all of which are encrypted, don't include its UUID in the
list. The script should work with the partitions that aren't encrypted
but not the encrypted ones.

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

