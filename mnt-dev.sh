#!/bin/bash

# From: https://github.com/brianchase/mnt-dev

# The script mount devices in /mnt:
PNT="mnt"

chk_mount_args () {
  local TempA i
  if [ "$1" = all ]; then
    if [ "${#DevArr1[*]}" -eq 0 ]; then
      mnt_error "All connected devices are mounted!"
    else
      mount_dev "$2"
    fi
  elif [ -b "$1" ]; then
    TempA="$(lsblk -no MOUNTPOINT "$1" 2>/dev/null | tail -1)"
    [ "$TempA" ] && mnt_error "'$1' is mounted on $TempA!"
    for i in "${DevArr1[@]}"; do
      if [ "$i" = "$1" ]; then
# Make the selected device DevArr1[0] and its mount point MntArr1[0].
        unset DevArr1 MntArr1
        DevArr1[0]="$1"
        chk_mount_points
        mount_dev "$2"
        break;
      fi
    done
  else
    mnt_error "'$1' is not a block device!"
  fi
}

chk_umount_args () {
  local TempA i
  if [ "$1" = all ]; then
    if [ "${#DevArr2[*]}" -eq 0 ]; then
      mnt_error "No connected devices are mounted!"
    else
      umount_dev "$2"
    fi
  elif [ -b "$1" ]; then
    TempA="$(lsblk -no MOUNTPOINT "$1" 2>/dev/null | tail -1)"
    [ -z "$TempA" ] && mnt_error "'$1' is not mounted!"
    for i in "${DevArr2[@]}"; do
      if [ "$i" = "$1" ]; then
# Make the selected device DevArr2[0] and its mount point MntArr2[0].
        unset DevArr2 MntArr2
        DevArr2[0]="$1"
        MntArr2[0]="$(lsblk -no MOUNTPOINT "${DevArr2[0]}" | tail -1)"
        umount_dev "$2"
        break;
      fi
    done
  else
    mnt_error "'$1' is not a block device!"
  fi
}

mount_dev () {
  local MntDev FileSys i
  for i in "${!DevArr1[@]}"; do
    if [ "$1" != now ]; then
      read -r -p "Mount ${DevArr1[i]} on ${MntArr1[i]}? [y/n] " MntDev
    fi
    if [ "$MntDev" = y ] || [ "$1" = now ]; then
      if [ ! -d "${MntArr1[i]}" ]; then
        mnt_sudo mkdir -p "${MntArr1[i]}" || continue
      fi
      FileSys="$(lsblk -dnpo FSTYPE "${DevArr1[i]}")"
      if [ "$FileSys" = crypto_LUKS ]; then
        if [ -L "/dev/mapper/${DevArr1[i]:5}" ]; then
          mnt_error "/dev/mapper/${DevArr1[i]:5} already exists!" noexit
          mnt_sudo rmdir "${MntArr1[i]}"
        elif ! mnt_sudo cryptsetup open "${DevArr1[i]}" "${DevArr1[i]:5}"; then
          mnt_error "Failed to open ${DevArr1[i]}!" noexit
          mnt_sudo rmdir "${MntArr1[i]}"
        elif ! mnt_sudo mount /dev/mapper/"${DevArr1[i]:5}" "${MntArr1[i]}"; then
          mnt_error "Failed to mount ${DevArr1[i]}!" noexit
          mnt_sudo rmdir "${MntArr1[i]}"
          mnt_sudo cryptsetup close /dev/mapper/"${DevArr1[i]:5}"
        fi
      elif ! mnt_sudo mount "${DevArr1[i]}" "${MntArr1[i]}"; then
        mnt_error "Failed to mount ${DevArr1[i]}!" noexit
        mnt_sudo rmdir "${MntArr1[i]}"
      fi
    fi
  done
}

mnt_sudo () {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

umount_dev () {
  local UmntDev i
  for i in "${!DevArr2[@]}"; do
    if [ "$1" != now ]; then
      read -r -p "Unmount ${DevArr2[i]} on ${MntArr2[i]}? [y/n] " UmntDev
    fi
    if [ "$UmntDev" = y ] || [ "$1" = now ]; then
      if ! mnt_sudo umount "${MntArr2[i]}"; then
        mnt_error "Failed to unmount ${DevArr2[i]}!" noexit
      else
        mnt_sudo rmdir "${MntArr2[i]}"
        if [ -L "${DevArr2[i]}" ]; then
          mnt_sudo cryptsetup close "${DevArr2[i]}"
        fi
      fi
    fi
  done
}

mnt_menu () {
  while true; do
    local N=0 Opt i
    printf '%s\n\n' "Please choose:"
    if [ "${#DevArr1[*]}" -ge 1 ]; then
# List all unmounted devices for mounting.
      for i in "${!DevArr1[@]}"; do
        printf '\t%s\n' "$((N += 1)). Mount ${DevArr1[i]} on ${MntArr1[i]}"
      done
    fi
    if [ "${#DevArr2[*]}" -ge 1 ]; then
# List all mounted devices for unmounting.
      for i in "${!DevArr2[@]}"; do
        printf '\t%s\n' "$((N += 1)). Unmount ${DevArr2[i]} on ${MntArr2[i]}"
      done
    fi
# If more than one device is unmounted, offer to mount them all.
    [ "${#DevArr1[*]}" -gt 1 ] && printf '\t%s\n' "$((N += 1)). Mount all unmounted devices"
# If more than one device is mounted, offer to unmount them all.
    [ "${#DevArr2[*]}" -gt 1 ] && printf '\t%s\n' "$((N += 1)). Unmount all mounted devices"
    printf '\t%s\n' "$((N += 1)). Skip"
    read -r Opt
    case $Opt in
      ''|*[!1-9]*) continue ;;
      "$N") return 1 ;;
    esac
    [ "$Opt" -gt "$N" ] && continue
    break
  done
  if [ "$Opt" -le "${#DevArr1[*]}" ]; then
# Make the selected device DevArr1[0] and its mount point MntArr1[0].
    local TempA="${DevArr1[(($Opt - 1))]}"
    local TempB="${MntArr1[(($Opt - 1))]}"
    unset DevArr1 MntArr1
    DevArr1[0]="$TempA"
    MntArr1[0]="$TempB"
    mount_dev now
  elif [ "$Opt" -gt "${#DevArr1[*]}" ] && [ "$Opt" -le "$((${#DevArr1[*]} + ${#DevArr2[*]}))" ]; then
# Make the selected device DevArr2[0] and its mount point MntArr2[0].
    local TempA="${DevArr2[(($Opt - "${#DevArr1[*]}" - 1))]}"
    local TempB="${MntArr2[(($Opt - "${#DevArr1[*]}" - 1))]}"
    unset DevArr2 MntArr2
    DevArr2[0]="$TempA"
    MntArr2[0]="$TempB"
    umount_dev now
  elif [ "${#DevArr1[*]}" -gt "1" ] && [ "$Opt" -eq "$((${#DevArr1[*]} + ${#DevArr2[*]} + 1))" ]; then
# Mount all devices in DevArr1 on their mount points in MntArr1.
    mount_dev now
  else
# Unmount all devices in DevArr2 from their mount points in MntArr2.
    umount_dev now
  fi
}

menu_return () {
  local RtoMenu
  read -r -p "Return to menu? [y/n] " RtoMenu
  if [ "$RtoMenu" = y ]; then
    unset DevArr1 DevArr2 MntArr1 MntArr2
    dev_arrays
    chk_arrays
  fi
}

chk_arrays () {
  if [ "${#DevArr1[*]}" -eq 1 ] && [ "${#DevArr2[*]}" -eq 0 ]; then
# If the only connected device is unmounted, offer to mount it.
    mount_dev
  elif [ "${#DevArr1[*]}" -eq 0 ] && [ "${#DevArr2[*]}" -eq 1 ]; then
# If the only connected device is mounted, offer to unmount it.
    umount_dev
  elif mnt_menu; then
    menu_return
  else
    return 1
  fi
}

mnt_error () {
  printf '%s\n' "$1" >&2
  [ "$2" = noexit ] || exit 1
}

chk_mount_points () {
# Ensure that no device in MntArr1 is a mount point.
  local N=1 i
  for i in "${!DevArr1[@]}"; do
    local NewPnt="/$PNT/${DevArr1[i]:5}"
    while true; do
      if mountpoint -q "$NewPnt"; then
        NewPnt="/$PNT/${DevArr1[i]:5}-$((N += 1))"
      else
        MntArr1+=("$NewPnt")
        break
      fi
    done
  done
}

dev_arrays () {
  local i j
# Make DevArr1 an array of connected devices.
  readarray -t DevArr1 < <(lsblk -dpno NAME,FSTYPE /dev/sd[b-z]* 2>/dev/null | awk '{if ($2) print $1;}')
  if [ "${#DevArr1[*]}" -eq 0 ]; then
    mnt_error "No connected devices!"
  else
# Remove mounted devices from DevArr1
    for i in "${DevArr1[@]}"; do
      if [ "$(lsblk -no MOUNTPOINT "$i")" ]; then
        for j in "${!DevArr1[@]}"; do
          if [ "${DevArr1[$j]}" = "$i" ]; then
            unset "DevArr1[$j]"
            DevArr1=("${DevArr1[@]}")
          fi
        done
      fi
    done
# Make MntArr1 an array of mount points for devices in DevArr1.
    chk_mount_points
# Make DevArr2 an array of mounted devices, starting with /dev/sdb and
# giving multiple entries for devices with multiple mount points.
    readarray -t DevArr2 < <(grep -o '^/dev[\/]*[a-z]*/sd[b-z][0-9]*\b' /proc/mounts)
# Make MntArr2 an array of mount points for devices in DevArr2.
    readarray -t MntArr2 < <(grep '^/dev[\/]*[a-z]*/sd[b-z][0-9]*\b' /proc/mounts | awk '{print $2}')
  fi
}

mnt_main () {
# Allow sourcing this script without runnning any other functions.
  local BN1 BN2
  BN1="$(basename "${0#-}")"
  BN2="$(basename "${BASH_SOURCE[0]}")"
  if [ "$BN1" = "$BN2" ]; then
    dev_arrays
    case $1 in
      mount) chk_mount_args "$2" "$3" ;;
      unmount|umount) chk_umount_args "$2" "$3" ;;
      *) chk_arrays ;;
    esac
  fi
}

mnt_main "$1" "$2" "$3"
