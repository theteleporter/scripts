#!/usr/bin/env bash

CPU_LIMIT=30   # percent
WHITELIST="gnome-shell|Xorg|systemd|NetworkManager"

echo "Scanning for power goblins..."

ps -eo pid,comm,%cpu --sort=-%cpu | tail -n +2 | while read pid name cpu
do
  cpu_int=${cpu%.*}

  if [[ $cpu_int -gt $CPU_LIMIT ]]; then
    if [[ ! $name =~ $WHITELIST ]]; then
      echo "Killing $name (PID $pid) using $cpu% CPU"
      kill -15 $pid
    fi
  fi
done
