#!/bin/bash

# The script mount devices in /mnt:
PNT="mnt"

chk_mount_args () {
  if [ "$1" = all ]; then
    if [ "${#DevArr1[*]}" -eq 0 ]; then
      printf '%s\n' "All connected devices are mounted!" >&2
      exit 1
    else
      mount_dev
    fi
  else
    local i j
    for i in "${DevArr2[@]}"; do
      if [ "$i" = "$1" ]; then
        printf '%s\n' "'$1' is mounted!" >&2
        exit 1
      fi
    done
    for j in "${DevArr1[@]}"; do
      if [ "$j" = "$1" ]; then
        unset DevArr1 MntArr1
        DevArr1[0]="$1"
        MntArr1[0]="/$PNT/${DevArr1[0]:5}"
        mount_dev
        break;
      fi
    done
    if [ "${DevArr1[0]}" != "$1" ]; then
      printf '%s\n' "No '$1' found!" >&2
      exit 1
    fi
  fi
}

chk_umount_args () {
  if [ "$1" = all ]; then
    if [ "${#DevArr2[*]}" -eq 0 ]; then
      printf '%s\n' "No connected devices are mounted!" >&2
      exit 1
    else
      umount_dev
    fi
  else
    local i j
    for i in "${DevArr1[@]}"; do
      if [ "$i" = "$1" ]; then
        printf '%s\n' "'$1' is not mounted!" >&2
        exit 1
      fi
    done
    for j in "${DevArr2[@]}"; do
      if [ "$j" = "$1" ]; then
        unset DevArr2 MntArr2
        DevArr2[0]="$1"
        MntArr2[0]="$(lsblk -no MOUNTPOINT "${DevArr2[0]}" | tail -1)"
        umount_dev
        break;
      fi
    done
    if [ "${DevArr2[0]}" != "$1" ]; then
      printf '%s\n' "No '$1' found!" >&2
      exit 1
    fi
  fi
}

mount_error () {
  printf '%s\n' "$1" >&2
  sudo rmdir "${MntArr1[i]}"
}

mount_dev () {
  local MntDevArr1 FileSys i
  for i in "${!DevArr1[@]}"; do
    if [ "$1" != now ]; then
      read -r -p "Mount ${DevArr1[i]} at ${MntArr1[i]}? [y/n] " MntDevArr1
    fi
    if [ "$MntDevArr1" = y ] || [ "$1" = now ]; then
      if [ ! -d "${MntArr1[i]}" ]; then
        sudo mkdir -p "${MntArr1[i]}"
      fi
      FileSys="$(lsblk -dnpo FSTYPE "${DevArr1[i]}")"
      if [ "$FileSys" = crypto_LUKS ]; then
        if [ -L "/dev/mapper/${DevArr1[i]:5}" ]; then
          mount_error "/dev/mapper/${DevArr1[i]:5} already exists!"
        elif ! sudo cryptsetup open "${DevArr1[i]}" "${DevArr1[i]:5}"; then
          mount_error "Failed to open /dev/mapper/${DevArr1[i]:5}!"
        elif ! sudo mount /dev/mapper/"${DevArr1[i]:5}" "${MntArr1[i]}"; then
          mount_error "Failed to mount ${DevArr1[i]}!"
        fi
      elif ! sudo mount "${DevArr1[i]}" "${MntArr1[i]}"; then
        mount_error "Failed to mount ${DevArr1[i]}!"
      fi
    fi
  done
}

umount_dev () {
  local UmntDevArr2 i
  for i in "${!DevArr2[@]}"; do
    if [ "$1" != now ]; then
      read -r -p "Unmount ${DevArr2[i]} at ${MntArr2[i]}? [y/n] " UmntDevArr2
    fi
    if [ "$UmntDevArr2" = y ] || [ "$1" = now ]; then
      if ! sudo umount "${MntArr2[i]}"; then
        printf '%s\n' "Failed to unmount ${DevArr2[i]}!"
      else
        if [ -L "/dev/mapper/${DevArr2[i]:5}" ]; then
          if ! sudo cryptsetup close "${DevArr2[i]:5}"; then
            printf '%s\n' "Failed to close /dev/mapper/${DevArr2[i]:5}!"
          fi
        fi
        if [ -d "${MntArr2[i]}" ]; then
          sudo rmdir "${MntArr2[i]}"
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
      for i in "${!DevArr1[@]}"; do
        printf '\t%s\n' "$((N += 1)). Mount ${DevArr1[i]} at ${MntArr1[i]}"
      done
    fi
    if [ "${#DevArr2[*]}" -ge 1 ]; then
      for i in "${!DevArr2[@]}"; do
        printf '\t%s\n' "$((N += 1)). Unmount ${DevArr2[i]} at ${MntArr2[i]}"
      done
    fi
    if [ "${#DevArr1[*]}" -gt 1 ]; then
      printf '\t%s\n' "$((N += 1)). Mount all listed devices"
    fi
    if [ "${#DevArr2[*]}" -gt 1 ]; then
      printf '\t%s\n' "$((N += 1)). Unmount all listed devices"
    fi
    printf '\t%s\n' "$((N += 1)). Skip"
    read -r Opt
    case $Opt in
      ''|*[!1-9]*) continue ;;
    esac
    if [ "$Opt" -eq "$N" ]; then
      return 1
    elif [ "$Opt" -gt "$N" ]; then
      continue
    fi
    break
  done
  if [ "$Opt" -le "${#DevArr1[*]}" ]; then
    local TempA="${DevArr1[(($Opt - 1))]}"
    local TempB="${MntArr1[(($Opt - 1))]}"
    unset DevArr1 MntArr1
    DevArr1[0]="$TempA"
    MntArr1[0]="$TempB"
    mount_dev now
  elif [ "$Opt" -gt "${#DevArr1[*]}" ] && [ "$Opt" -le "$((${#DevArr1[*]} + ${#DevArr2[*]}))" ]; then
    local TempA="${DevArr2[(($Opt - "${#DevArr1[*]}" - 1))]}"
    local TempB="${MntArr2[(($Opt - "${#DevArr1[*]}" - 1))]}"
    unset DevArr2 MntArr2
    DevArr2[0]="$TempA"
    MntArr2[0]="$TempB"
    umount_dev now
  elif [ "${#DevArr1[*]}" -gt "1" ] && [ "$Opt" -eq "$((${#DevArr1[*]} + ${#DevArr2[*]} + 1))" ]; then
    mount_dev now
  else
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
    mount_dev
  elif [ "${#DevArr1[*]}" -eq 0 ] && [ "${#DevArr2[*]}" -eq 1 ]; then
    umount_dev
  elif mnt_menu; then
    menu_return
  else
    return 1
  fi
}

dev_arrays () {
  local i j
  readarray -t DevArr1 < <(lsblk -dpno NAME,FSTYPE /dev/sd[b-z]* 2>/dev/null | awk '{if ($2) print $1;}')
  if [ "${#DevArr1[*]}" -eq 0 ]; then
    printf '%s\n' "No connected devices!" >&2
    exit 1
  else
    for i in "${DevArr1[@]}"; do
      if [ "$(lsblk -no MOUNTPOINT "$i")" ]; then
        DevArr2+=("$i")
        for j in "${!DevArr1[@]}"; do
          if [ "${DevArr1[$j]}" = "$i" ]; then
            unset "DevArr1[$j]"
            DevArr1=("${DevArr1[@]}")
          fi
        done
      fi
    done
    for i in "${!DevArr1[@]}"; do
      MntArr1+=("/$PNT/${DevArr1[i]:5}")
    done
    for i in "${!DevArr2[@]}"; do
      MntArr2+=("$(lsblk -no MOUNTPOINT "${DevArr2[i]}" | tail -1)")
    done
  fi
}

mnt_main () {
  local BN1 BN2
  BN1="$(basename "${0#-}")"
  BN2="$(basename "${BASH_SOURCE[0]}")"
  if [ "$BN1" = "$BN2" ]; then
    dev_arrays
    case $1 in
      mount) chk_mount_args "$2" ;;
      unmount|umount) chk_umount_args "$2" ;;
      *) chk_arrays ;;
    esac
  fi
}

mnt_main "$1" "$2"
