#!/bin/bash

# The script mount devices in /mnt:
PNT="mnt"

chk_a1_arg () {
  if [ "$1" = all ]; then
    if [ "${#A1[*]}" -eq 0 ]; then
      printf '%s\n' "All connected devices are mounted!"
      exit 1
    else
      mount_a1
    fi
  else
    for i in "${A2[@]}"; do
      if [ "$i" = "$1" ]; then
        printf '%s\n' "'$1' is mounted!"
        exit 1
      fi
    done
    for i in "${A1[@]}"; do
      if [ "$i" = "$1" ]; then
        unset A1 B1
        A1[0]="$1"
        B1[0]="/$PNT/${A1[0]:5}"
        mount_a1
        break;
      fi
    done
    if [ "${A1[0]}" != "$1" ]; then
      printf '%s\n' "No '$1' found!"
      exit 1
    fi
  fi
}

chk_a2_arg () {
  if [ "$1" = all ]; then
    if [ "${#A2[*]}" -eq 0 ]; then
      printf '%s\n' "No connected devices are mounted!"
      exit 1
    else
      unmount_a2
    fi
  else
    for i in "${A1[@]}"; do
      if [ "$i" = "$1" ]; then
        printf '%s\n' "'$1' is not mounted!"
        exit 1
      fi
    done
    for i in "${A2[@]}"; do
      if [ "$i" = "$1" ]; then
        unset A2 B2
        A2[0]="$1"
        B2[0]="$(lsblk -no MOUNTPOINT "${A2[0]}" | tail -1)"
        unmount_a2
        break;
      fi
    done
    if [ "${A2[0]}" != "$1" ]; then
      printf '%s\n' "No '$1' found!"
      exit 1
    fi
  fi
}

mount_error () {
  printf '%s\n' "$1"
  sudo rmdir "${B1[i]}"
}

mount_a1 () {
  for i in "${!A1[@]}"; do
    if [ "$1" != now ]; then
      read -r -p "Mount ${A1[i]} at ${B1[i]}? [y/n] " MQ
    fi
    if [ "$MQ" = y ] || [ "$1" = now ]; then
      if [ ! -d "${B1[i]}" ]; then
        sudo mkdir -p "${B1[i]}"
      fi
      FS="$(lsblk -dnpo FSTYPE "${A1[i]}")"
      if [ "$FS" = crypto_LUKS ]; then
        if [ -L "/dev/mapper/${A1[i]:5}" ]; then
          mount_error "/dev/mapper/${A1[i]:5} already exists!"
        elif ! sudo cryptsetup open "${A1[i]}" "${A1[i]:5}"; then
          mount_error "Failed to open /dev/mapper/${A1[i]:5}!"
        elif ! sudo mount /dev/mapper/"${A1[i]:5}" "${B1[i]}"; then
          mount_error "Failed to mount ${A1[i]}!"
        fi
      elif ! sudo mount "${A1[i]}" "${B1[i]}"; then
        mount_error "Failed to mount ${A1[i]}!"
      fi
    fi
  done
}

unmount_a2 () {
  for i in "${!A2[@]}"; do
    if [ "$1" != now ]; then
      read -r -p "Unmount ${A2[i]} at ${B2[i]}? [y/n] " UQ
    fi
    if [ "$UQ" = y ] || [ "$1" = now ]; then
      if ! sudo umount "${B2[i]}"; then
        printf '%s\n' "Failed to unmount ${A2[i]}!"
      else
        if [ -L "/dev/mapper/${A2[i]:5}" ]; then
          if ! sudo cryptsetup close "${A2[i]:5}"; then
            printf '%s\n' "Failed to close /dev/mapper/${A2[i]:5}!"
          fi
        fi
        if [ -d "${B2[i]}" ]; then
          sudo rmdir "${B2[i]}"
        fi
      fi
    fi
  done
}

mnt_menu () {
  while true; do
    local N=0
    printf '%s\n\n' "Please choose:"
    if [ "${#A1[*]}" -ge 1 ]; then
      for i in "${!A1[@]}"; do
        printf '\t%s\n' "$((N += 1)). Mount ${A1[i]} at ${B1[i]}"
      done
    fi
    if [ "${#A2[*]}" -ge 1 ]; then
      for i in "${!A2[@]}"; do
        printf '\t%s\n' "$((N += 1)). Unmount ${A2[i]} at ${B2[i]}"
      done
    fi
    if [ "${#A1[*]}" -gt 1 ]; then
      printf '\t%s\n' "$((N += 1)). Mount all listed devices"
    fi
    if [ "${#A2[*]}" -gt 1 ]; then
      printf '\t%s\n' "$((N += 1)). Unmount all listed devices"
    fi
    printf '\t%s\n' "$((N += 1)). Skip"
    local OP
    read -r OP
    case $OP in
      ''|*[!1-9]*) continue ;;
    esac
    if [ "$OP" -eq "$N" ]; then
      return 1
    elif [ "$OP" -gt "$N" ]; then
      continue
    fi
    break
  done
  if [ "$OP" -le "${#A1[*]}" ]; then
    local TempA="${A1[(($OP - 1))]}"
    local TempB="${B1[(($OP - 1))]}"
    unset A1 B1
    A1[0]="$TempA"
    B1[0]="$TempB"
    mount_a1 now
  elif [ "$OP" -gt "${#A1[*]}" ] && [ "$OP" -le "$((${#A1[*]} + ${#A2[*]}))" ]; then
    local TempA="${A2[(($OP - "${#A1[*]}" - 1))]}"
    local TempB="${B2[(($OP - "${#A1[*]}" - 1))]}"
    unset A2 B2
    A2[0]="$TempA"
    B2[0]="$TempB"
    unmount_a2 now
  elif [ "${#A1[*]}" -gt "1" ] && [ "$OP" -eq "$((${#A1[*]} + ${#A2[*]} + 1))" ]; then
    mount_a1 now
  else
    unmount_a2 now
  fi
}

menu_return () {
  read -r -p "Return to menu? [y/n] " RT
  if [ "$RT" = y ]; then
    unset A1 A2 B1 B2
    dev_arrays
    chk_arrays
  fi
}

chk_arrays () {
  if [ "${#A1[*]}" -eq 1 ] && [ "${#A2[*]}" -eq 0 ]; then
    mount_a1
  elif [ "${#A1[*]}" -eq 0 ] && [ "${#A2[*]}" -eq 1 ]; then
    unmount_a2
  elif mnt_menu; then
    menu_return
  fi
}

dev_arrays () {
  readarray -t A1 < <(lsblk -dpno NAME,FSTYPE /dev/sd[b-z]* 2>/dev/null | awk '{if ($2) print $1;}')
  if [ "${#A1[*]}" -eq 0 ]; then
    printf '%s\n' "No connected devices!"
    exit 1
  else
    for i in "${A1[@]}"; do
      if [ "$(lsblk -no MOUNTPOINT "$i")" ]; then
        A2+=("$i")
        for j in "${!A1[@]}"; do
          if [ "${A1[$j]}" = "$i" ]; then
            unset "A1[$j]"
            A1=("${A1[@]}")
          fi
        done
      fi
    done
    for i in "${!A1[@]}"; do
      B1+=("/$PNT/${A1[i]:5}")
    done
    for i in "${!A2[@]}"; do
      B2+=("$(lsblk -no MOUNTPOINT "${A2[i]}" | tail -1)")
    done
  fi
}

mnt_main () {
  BN1="$(basename "${0#-}")"
  BN2="$(basename "${BASH_SOURCE[0]}")"
  if [ "$BN1" = "$BN2" ]; then
    dev_arrays
    case $1 in
      mount) chk_a1_arg "$2" ;;
      unmount|umount) chk_a2_arg "$2" ;;
      *) chk_arrays ;;
    esac
  fi
}

mnt_main "$1" "$2"
