#!/bin/bash

# Mount point for drives is /mnt/usb:
MAP="usb"
MT1="/mnt/$MAP"

# UUIDs of encrypted drives:
ED[1]="abababab-abab-abab-abab-abababababab"
ED[2]="bcbcbcbc-bcbc-bcbc-bcbc-bcbcbcbcbcbc"
ED[3]="cdcdcdcd-cdcd-cdcd-cdcd-cdcdcdcdcdcd"

umnt-dev () {

# If no device is mounted at $MT1, $MD is empty. If one of my
# encrypted drives is mounted at $MT1, $MD is /dev/mapper/$MAP.
# Otherwise, $MD is a device such as /dev/sdb1.

  MD="$(grep $MT1 /proc/mounts | awk '{print $1}')"
  if [ "$MD" ]; then
    echo "Unmount $MT1? [y/n]"
    read UQ
    if [ "$UQ" = "y" ]; then
      if [ "$MD" = "/dev/mapper/$MAP" ]; then
        sudo umount $MT1
        sudo cryptsetup close $MAP
      elif [ "$MD" != "/dev/sdb1" ]; then
        sudo umount $MT1
      else
        umount $MT1
      fi
    fi
    exit
  fi
}

chk-dev () {
  readarray -t DV <<< "$(lsblk -po NAME,FSTYPE | grep -vE "^/dev/sd[b-z]\s+$" | grep -oE "/dev/sd[b-z][1-9]|/dev/sd[b-z]")"
  if [ -z "${DV[0]}" ]; then
    echo "No connected devices!"
    exit 1
  elif [ "${#DV[*]}" -eq "1" ]; then
    SD="${DV[0]}"
  else
    until [ "$SD" ]; do
      N="0"
      echo -e "Please choose:\n"
      while [ "$N" -lt "${#DV[*]}" ]; do
        echo -e "\t$(expr $N + 1). ${DV[$N]}"
        let "N += 1"
      done
      echo -e "\t$(expr $N + 1). Exit"
      read NB
      if [ "$NB" -eq "$(expr $N + 1)" ]; then
        exit 1
      elif [[ "$NB" =~ ^[0-9]+$ ]] && [ "$NB" -ge 1 -a "$NB" -le "${#DV[*]}" ]; then
        SD="${DV[$(expr $NB - 1)]}"
      else
        echo -e "\nIncorrect value!\n"
      fi
    done
  fi
}

chk-map () {

# Before mounting a drive, close /dev/mapper/$MAP if it's already
# open. This avoids accidents that can happen when $MAP is no longer
# mounted at $MT1 but was never closed.

  if [ -L "/dev/mapper/$MAP" ]; then
    sudo cryptsetup close $MAP
  fi
}

chk-mnt () {
  if [ "$?" -ne "0" ]; then
    echo "Failed to mount device!"
    exit 1
  fi
}

mnt-dev () {
  ID="$(lsblk -o UUID $SD | tail -1)"
  if [ "$ID" ] && [[ "${ED[@]}" =~ "$ID" ]]; then
    echo "Decrypt and mount $SD at $MT1? [y/n]"
    read MQ1
    if [ "$MQ1" = "y" ]; then
      chk-map
      sudo cryptsetup open $SD $MAP
      sudo mount /dev/mapper/$MAP $MT1 2>/dev/null
      chk-mnt
    fi
  elif [ -b "$SD" ]; then
    echo "Mount $SD at $MT1? [y/n]"
    read MQ2
    if [ "$MQ2" = "y" ]; then
      chk-map
      if [ "$SD" = "/dev/sdb1" ]; then
        mount $MT1 2>/dev/null
      else
        sudo mount $SD $MT1 2>/dev/null
      fi
      chk-mnt
    fi
  else
    echo "$SD is not a recognized device!"
    exit 1
  fi
}

umnt-dev
chk-dev
mnt-dev
