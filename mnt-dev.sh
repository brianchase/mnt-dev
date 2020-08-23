#!/bin/bash

# From: https://github.com/brianchase/mnt-dev

# The script mount devices in /mnt:
PNT="mnt"

mnt_reset_arr1 () {
# Make the selected device DevArr1[0] and its mount point MntArr1[0].
  DevArr1=("${DevArr1[@]:i:1}")
  MntArr1=("${MntArr1[@]:i:1}")
  mount_dev "$1"
  exit
}

mnt_reset_arr2 () {
# Make the selected device DevArr2[0] and its mount point MntArr2[0].
  DevArr2=("${DevArr2[@]:i:1}")
  MntArr2=("${MntArr2[@]:i:1}")
  umount_dev "$1"
  exit
}

mnt_args () {
  local TempA i
  if mountpoint -q "$1"; then
    for i in "${!MntArr2[@]}"; do
      [ "${MntArr2[i]}" = "${1%/}" ] && mnt_reset_arr2 "$2"
    done
  elif [ -b "$1" ]; then
    for i in "${!DevArr1[@]}"; do
      [ "${DevArr1[i]}" = "$1" ] && mnt_reset_arr1 "$2"
    done
    for i in "${!DevArr2[@]}"; do
      [ "${DevArr2[i]}" = "$1" ] && mnt_reset_arr2 "$2"
    done
    TempA="$(lsblk -no MOUNTPOINT "$1" 2>/dev/null | tail -1)"
    for i in "${!MntArr2[@]}"; do
      [ "${MntArr2[i]}" = "$TempA" ] && mnt_reset_arr2 "$2"
    done
    TempA="$(lsblk -lnpso NAME "$1" | awk 'FNR == 2')"
    for i in "${!DevArr1[@]}"; do
      [ "${DevArr1[i]}" = "$TempA" ] && mnt_reset_arr1 "$2"
    done
  fi
  mnt_error "'$1' is an invalid option!"
}

chk_luks_dev () {
  local FileSys NewDev N=1
  FileSys="$(lsblk -dnpo FSTYPE "${DevArr1[i]}")"
  if [ "$FileSys" = crypto_LUKS ]; then
# If the device is encrypted but unopened, find where to open it.
    NewMap="$(basename "${DevArr1[i]}")"
    while true; do
      if [ -b "/dev/mapper/$NewMap" ]; then
        NewMap="$(basename "${DevArr1[i]}")-$((N += 1))"
      else
        NewDev="/dev/mapper/$NewMap"
        break
      fi
    done
    if ! mnt_sudo cryptsetup open "${DevArr1[i]}" "$NewMap"; then
      mnt_error "Failed to open ${DevArr1[i]}!" noexit
      mnt_sudo rmdir "${MntArr1[i]}"
      return 1
    fi
# Change the value in the array to the path where it was opened.
    DevArr1[$i]="$NewDev"
  fi
}

mount_dev () {
  local MntDev NewMap i
  for i in "${!DevArr1[@]}"; do
    if [ "$1" != now ]; then
      read -r -p "Mount ${DevArr1[i]} on ${MntArr1[i]}? [y/n] " MntDev
    fi
    if [ "$MntDev" = y ] || [ "$1" = now ]; then
      if [ ! -d "${MntArr1[i]}" ]; then
        mnt_sudo mkdir -p "${MntArr1[i]}" || continue
      fi
      chk_luks_dev || continue
      if ! mnt_sudo mount "${DevArr1[i]}" "${MntArr1[i]}"; then
        mnt_error "Failed to mount ${DevArr1[i]}!" noexit
        mnt_sudo rmdir "${MntArr1[i]}"
# Close the device only if chk_luks_dev just opened it.
        [ "$NewMap" ] && mnt_sudo cryptsetup close "$NewMap"
      fi
      unset NewMap
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
# List all unmounted devices for mounting.
    for i in "${!DevArr1[@]}"; do
      printf '\t%s\n' "$((N += 1)). Mount ${DevArr1[i]} on ${MntArr1[i]}"
    done
# List all mounted devices for unmounting.
    for i in "${!DevArr2[@]}"; do
      printf '\t%s\n' "$((N += 1)). Unmount ${DevArr2[i]} on ${MntArr2[i]}"
    done
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
    DevArr1=("${DevArr1[@]:(($Opt - 1)):1}")
    MntArr1=("${MntArr1[@]:(($Opt - 1)):1}")
    mount_dev now
  elif [ "$Opt" -gt "${#DevArr1[*]}" ] && [ "$Opt" -le "$((${#DevArr1[*]} + ${#DevArr2[*]}))" ]; then
# Make the selected device DevArr2[0] and its mount point MntArr2[0].
    DevArr2=("${DevArr2[@]:(($Opt - ${#DevArr1[*]} - 1)):1}")
    MntArr2=("${MntArr2[@]:(($Opt - ${#DevArr1[*]} - 1)):1}")
    umount_dev now
  elif [ "${#DevArr1[*]}" -gt 1 ] && [ "$Opt" -eq "$((${#DevArr1[*]} + ${#DevArr2[*]} + 1))" ]; then
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

dev_arrays () {
  local EmptyDir FileSys N=1 NewDev i
# Make DevArr1 an array of connected devices.
  readarray -t DevArr1 < <(lsblk -dpno NAME,FSTYPE /dev/sd[b-z]* 2>/dev/null | awk '{if ($2) print $1;}')
  if [ "${#DevArr1[*]}" -eq 0 ]; then
    mnt_error "No connected devices!"
  else
    for i in "${!DevArr1[@]}"; do
      FileSys="$(lsblk -dnpo FSTYPE "${DevArr1[i]}")"
      if [ "$FileSys" = crypto_LUKS ]; then
        NewDev="$(lsblk -lp "${DevArr1[i]}" | awk 'FNR == 3 {print $1}')"
        [ "$NewDev" ] && DevArr1[$i]="$NewDev"
      fi
      if [ "$(lsblk -no MOUNTPOINT "${DevArr1[i]}")" ]; then
# Make DevArr2 an array of mounted devices.
        DevArr2+=($(findmnt -no SOURCE "${DevArr1[i]}"))
# Make MntArr2 an array of mount points for devices in DevArr2.
        MntArr2+=($(findmnt -no TARGET "${DevArr1[i]}"))
        unset "DevArr1[$i]"
      fi
    done
    [ "${#DevArr2[*]}" -gt 0 ] && DevArr1=("${DevArr1[@]}")
    for i in "${!DevArr1[@]}"; do
# Make MntArr1 an array of mount points for devices in DevArr1.
      NewPnt="/$PNT/$(basename "${DevArr1[i]}")"
      while true; do
# For a mountpoint or any file but an empty directory, change NewPnt.
        EmptyDir="$(find "$NewPnt" -maxdepth 0 -type d -empty 2>/dev/null)"
        if mountpoint -q "$NewPnt"; then
          NewPnt="/$PNT/$(basename "${DevArr1[i]}")-$((N += 1))"
        elif [ -e "$NewPnt" ] && [ -z "$EmptyDir" ]; then
          NewPnt="/$PNT/$(basename "${DevArr1[i]}")-$((N += 1))"
        else
          MntArr1+=("$NewPnt")
          break
        fi
      done
    done
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
      '') chk_arrays ;;
      mount) [ "${#DevArr1[*]}" -eq 0 ] && \
          mnt_error "All connected devices are mounted!"
        mount_dev "$2" ;;
      umount|unmount) [ "${#DevArr2[*]}" -eq 0 ] && \
          mnt_error "No connected devices are mounted!"
        umount_dev "$2" ;;
      *) mnt_args "$1" "$2"
    esac
  fi
}

mnt_main "$1" "$2"
