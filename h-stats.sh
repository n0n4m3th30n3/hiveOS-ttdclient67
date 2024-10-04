#!/usr/bin/env bash

#######################
# Functions
#######################

get_current_speed() {
  local t_str
  t_str=$(tail -n 100 "$log_name" | grep "Actual speed:" | tail -1)
  if [[ ! -z $t_str ]]; then
    current_speed=$(echo "$t_str" | awk '{print $3}' | sed 's/BK\/s//')  # Valeur
    hs+=("$current_speed")  # Ajouter à l'array hs
    khs=$(echo "$khs + $current_speed" | bc)  # Additionner à total
  else
    current_speed=0
  fi
}

get_accepted_shares() {
  local t_str
  t_str=$(tail -n 100 "$log_name" | grep "Ranges completed this session:" | tail -1)
  if [[ ! -z $t_str ]]; then
    accepted_shares=$(echo "$t_str" | awk '{print $5}')  # Récupérer le nombre de ranges
  else
    accepted_shares=0
  fi
}

get_miner_uptime() {
  local a=0
  let a=$(date +%s) - $(stat --format='%Y' "$1")
  echo $a
}

get_log_time_diff() {
  local a=0
  let a=$(date +%s) - $(stat --format='%Y' "$log_name")
  echo $a
}

#######################
# MAIN script body
#######################

log_name="/var/log/miner/my-miner.log"  # Change this to your actual log file path
ver="67.13"  # Remplacer par votre logique d'obtention de version

# Initialize variables
khs=0
hs=()  # Initialiser comme tableau
accepted_shares=0  # Initialiser à 0

# Calculate log freshness
diffTime=$(get_log_time_diff)
maxDelay=120

# If log is fresh, calculate miner stats
if [ "$diffTime" -lt "$maxDelay" ]; then
  get_current_speed
  get_accepted_shares
  uptime=$(get_miner_uptime "$log_name")  # Uptime du mineur

  # Make JSON
  stats=$(jq -nc \
        --argjson hs "$(echo "${hs[@]}" | jq -cs '.')" \
        --arg hs_units "BK/s" \  # Utiliser BK/s comme unité
        --arg uptime "$uptime" \
        --arg ver "$ver" \
        --argjson ar "[${accepted_shares}]" \  # Ne contient que accepted_shares
        '{hs: $hs, hs_units: $hs_units, uptime: $uptime, ver: $ver, ar: $ar}')

else
  stats=""
  khs=0
fi

# Output the variables
echo "khs: $khs"
echo "$stats"