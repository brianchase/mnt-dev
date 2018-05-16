#!/bin/bash

# The script mount devices in /mnt:
PNT="mnt"

rmdir-b2 () {
  if [ -d "${B2[i]}" ]; then
    sudo rmdir ${B2[i]}
  fi
}

chk-mount () {
  if [ "$?" -ne "0" ]; then
    echo "Failed to mount ${A1[i]}!"
    rmdir-b2
  fi
}

list-a1 () {
  for i in "${!A1[@]}"; do
    echo -e "\t$((N += 1)). Mount ${A1[$i]} at ${B1[$i]}"
  done
}

list-a2 () {
  for i in "${!A2[@]}"; do
    echo -e "\t$((N += 1)). Unmount ${A2[$i]} at ${B2[$i]}"
  done
}

prune-a1 () {
  TempA="${A1[(($OP - 1))]}"
  TempB="${B1[(($OP - 1))]}"
  unset {A1,B1}
  A1[0]="$TempA"
  B1[0]="$TempB"
}

prune-a2 () {
  TempA="${A2[(($OP - "${#A1[*]}" - 1))]}"
  TempB="${B2[(($OP - "${#A1[*]}" - 1))]}"
  unset {A2,B2}
  A2[0]="$TempA"
  B2[0]="$TempB"
}

mount-a1 () {
  for i in "${!A1[@]}"; do
    unset {MQ,CL}
    echo "Mount ${A1[i]} at ${B1[i]}? [y/n]"
    read MQ
    if [ "$MQ" = "y" ]; then
      if [ ! -d "${B1[i]}" ]; then
        sudo mkdir -p ${B1[i]}
      fi
      CL="$(lsblk -npo FSTYPE ${A1[i]})"
      if [ "$CL" = "crypto_LUKS" ]; then
        if [ -L "/dev/mapper/${A1[$i]:5}" ]; then
          ! echo "Device ${A1[$i]:5} already exists!"
          chk-mount
        else
          sudo cryptsetup open ${A1[i]} ${A1[$i]:5}
          sudo mount /dev/mapper/${A1[$i]:5} ${B1[i]} 2>/dev/null
          chk-mount
        fi
      else
        sudo mount ${A1[i]} ${B1[i]} 2>/dev/null
        chk-mount
      fi
    fi
  done
}

unmount-a2 () {
  for i in "${!A2[@]}"; do
    unset UQ
    echo "Unmount ${A2[i]} at ${B2[i]}? [y/n]"
    read UQ
    if [ "$UQ" = "y" ]; then
      sudo umount ${B2[i]}
      if [ -L "/dev/mapper/${A2[$i]:5}" ]; then
        sudo cryptsetup close ${A2[$i]:5}
      fi
      rmdir-b2
    fi
  done
}

menu () {
  until [[ "$OP" =~ ^[1-9]+$ ]] && [ "$OP" -le "$N" ]; do
    N="0"
    echo -e "Please choose:\n"
    if [ "${#A1[*]}" -ge "1" ]; then
      list-a1
    fi
    if [ "${#A2[*]}" -ge "1" ]; then
      list-a2
    fi
    if [ "${#A1[*]}" -gt "1" ]; then
      echo -e "\t$((N += 1)). Mount all listed devices"
    fi
    if [ "${#A2[*]}" -gt "1" ]; then
      echo -e "\t$((N += 1)). Unmount all listed devices"
    fi
    echo -e "\t$((N += 1)). Exit"
    read OP
    if [ "$OP" = "$N" ]; then
      exit 1
    elif [[ "$OP" =~ ^[1-9]+$ ]] && [ "$OP" -le "${#A1[*]}" ]; then
      prune-a1
      mount-a1
    elif [[ "$OP" =~ ^[1-9]+$ ]] && [ "$OP" -gt "${#A1[*]}" -a "$OP" -le "$((${#A1[*]} + ${#A2[*]}))" ]; then
      prune-a2
      unmount-a2
    elif [[ "$OP" =~ ^[1-9]+$ ]] && [ "${#A1[*]}" -gt "1" -a "$OP" -eq "$((${#A1[*]} + ${#A2[*]} + 1))" ]; then
      mount-a1
    elif [[ "$OP" =~ ^[1-9]+$ ]] && [ "${#A2[*]}" -gt "1" -a "$OP" -lt "$N" ]; then
      unmount-a2
    fi
  done
}

loop-menu () {
  echo -e "\nReturn to menu? [y/n]"
  read LOOP
  if [ "$LOOP" = "y" ]; then
    unset {A1,A2,B1,B2,OP}
    arrays-a
    arrays-b

# Go to chk-menu here, not menu. Why? Because at this point, you might
# have unmounted and removed a device and plugged another in.

    chk-menu
  fi
}

chk-menu () {
  if [ "${#A1[*]}" -eq "1" ] && [ "${#A2[*]}" -eq "0" ]; then
    mount-a1
  elif [ "${#A1[*]}" -eq "0" ] && [ "${#A2[*]}" -eq "1" ]; then
    unmount-a2
  else
    menu
    loop-menu
  fi
}

chk-a1-arg () {
  for i in "${A1[@]}"; do
    if [ "$i" = "$1" ]; then
      unset {A1,B1}
      A1[0]="$1"
      B1[0]="/$PNT/${A1[0]:5}"
      mount-a1
    fi
  done
  if [ "${A1[0]}" != "$1" ]; then
    echo "$1 not found!"
  fi
}

chk-a2-arg () {
  for i in "${A2[@]}"; do
    if [ "$i" = "$1" ]; then
      unset {A2,B2}
      A2[0]="$1"
      B2[0]="$(lsblk -no MOUNTPOINT ${A2[0]} | tail -1)"
      unmount-a2
    fi
  done
  if [ "${A2[0]}" != "$1" ]; then
    echo "$1 not found!"
  fi
}

arrays-a () {
  readarray -t A1 <<< "$(lsblk -po NAME,FSTYPE | grep -vE "^/dev/sd[b-z]\s+$" | grep -oE "/dev/sd[b-z][1-9]|/dev/sd[b-z]")"
  if [ -z "${A1[0]}" ]; then

# If no devices are connected, array "${A1[0]}" is null, though
# "${#A1[*]}" is 1, not 0, as you might expect.

    echo "No connected devices!"
    exit 1
  else
    for i in "${A1[@]}"; do
      if [ "$(lsblk -no MOUNTPOINT $i)" ]; then
        A2+=("$i")
        for j in "${!A1[@]}"; do
          if [ "${A1[$j]}" = "$i" ]; then
            unset A1[$j]
            A1=("${A1[@]}")
          fi
        done
      fi
    done
  fi
}

arrays-b () {
  for i in "${!A1[@]}"; do
    B1+=("/$PNT/${A1[$i]:5}")
  done
  for i in "${!A2[@]}"; do
    B2+=("$(lsblk -no MOUNTPOINT ${A2[$i]} | tail -1)")
  done
}

arrays-a
arrays-b
case $1 in
  mount) chk-a1-arg $2 ;;
  unmount | umount) chk-a2-arg $2 ;;
  *) chk-menu ;;
esac
