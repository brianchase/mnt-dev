#!/bin/bash

# The script mount devices in /mnt:
PNT="mnt"

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
      CL="$(lsblk -npo FSTYPE "${A1[i]}")"
      if [ "$CL" = crypto_LUKS ]; then
        if [ -L "/dev/mapper/${A1[i]:5}" ]; then
          mount_error "${A1[i]:5} already exists!"
        else
          if ! sudo cryptsetup open "${A1[i]}" "${A1[i]:5}"; then
            mount_error "Failed to open /dev/mapper/${A1[i]:5}!"
          fi
          if ! sudo mount /dev/mapper/"${A1[i]:5}" "${B1[i]}"; then
            mount_error "Failed to mount ${A1[i]}!"
          fi
        fi
      else
        if ! sudo mount "${A1[i]}" "${B1[i]}"; then
          mount_error "Failed to mount ${A1[i]}!"
        fi
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

list_a1 () {
  for i in "${!A1[@]}"; do
    printf '\t%s\n' "$((N += 1)). Mount ${A1[i]} at ${B1[i]}"
  done
}

list_a2 () {
  for i in "${!A2[@]}"; do
    printf '\t%s\n' "$((N += 1)). Unmount ${A2[i]} at ${B2[i]}"
  done
}

prune_a1 () {
  local TempA="${A1[(($OP - 1))]}"
  local TempB="${B1[(($OP - 1))]}"
  unset A1 B1
  A1[0]="$TempA"
  B1[0]="$TempB"
}

prune_a2 () {
  local TempA="${A2[(($OP - "${#A1[*]}" - 1))]}"
  local TempB="${B2[(($OP - "${#A1[*]}" - 1))]}"
  unset A2 B2
  A2[0]="$TempA"
  B2[0]="$TempB"
}

menu_loop () {
  while true; do
    N=0
    printf '%s\n\n' "Please choose:"
    if [ "${#A1[*]}" -ge 1 ]; then
      list_a1
    fi
    if [ "${#A2[*]}" -ge 1 ]; then
      list_a2
    fi
    if [ "${#A1[*]}" -gt 1 ]; then
      printf '\t%s\n' "$((N += 1)). Mount all listed devices"
    fi
    if [ "${#A2[*]}" -gt 1 ]; then
      printf '\t%s\n' "$((N += 1)). Unmount all listed devices"
    fi
    printf '\t%s\n' "$((N += 1)). Skip"
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
}

menu_choice () {
  if [ "$OP" -le "${#A1[*]}" ]; then
    prune_a1
    mount_a1 now
  elif [ "$OP" -gt "${#A1[*]}" ] && [ "$OP" -le "$((${#A1[*]} + ${#A2[*]}))" ]; then
    prune_a2
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
    arrays_a
    arrays_b
    chk_arrays
  fi
}

chk_arrays () {
  if [ "${#A1[*]}" -eq 1 ] && [ "${#A2[*]}" -eq 0 ]; then
    mount_a1
  elif [ "${#A1[*]}" -eq 0 ] && [ "${#A2[*]}" -eq 1 ]; then
    unmount_a2
  elif menu_loop; then
    menu_choice
    menu_return
  fi
}

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

arrays_a () {
  readarray -t A1 < <(lsblk -po NAME,FSTYPE | grep -vE '^/dev/sd[b-z]\s+$' | grep -oE '/dev/sd[b-z][1-9]|/dev/sd[b-z]')
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
  fi
}

arrays_b () {
  for i in "${!A1[@]}"; do
    B1+=("/$PNT/${A1[i]:5}")
  done
  for i in "${!A2[@]}"; do
    B2+=("$(lsblk -no MOUNTPOINT "${A2[i]}" | tail -1)")
  done
}

arrays_a
arrays_b
case $1 in
  mount) chk_a1_arg "$2" ;;
  unmount|umount) chk_a2_arg "$2" ;;
  *) chk_arrays ;;
esac
