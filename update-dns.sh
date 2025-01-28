#!/usr/bin/env bash

secrets="${1:-./secrets}"

[ ! -f "${secrets}" ] &&
  echo 'secrets file is missing!' &&
  exit 1

source "${secrets}"

# Exit if the RECORD_IDS array has no elements
[ ${#RECORD_IDS[@]} -eq 0 ] &&
  echo 'RECORD_IDS are missing!' &&
  exit 1

# Check credentials before proceeding
response=$(
  curl \
    --silent \
    --output /dev/null \
    --write-out "%{http_code}" \
    --header "Authorization: Bearer ${ACCESS_TOKEN}" \
    "https://api.digitalocean.com/v2/account"
)
if [ "$response" != "200" ]; then
  echo "Invalid credentials. Please check your ACCESS_TOKEN."
  exit 1
fi

public_ip=$(curl --silent ipinfo.io/ip)

for ID in "${RECORD_IDS[@]}"; do
  local_ip=$(
    curl \
      --fail \
      --silent \
      --request GET \
      --header "Content-Type: application/json" \
      --header "Authorization: Bearer ${ACCESS_TOKEN}" \
      "https://api.digitalocean.com/v2/domains/${DOMAIN}/records/${ID}" |
      grep -Eo '"data":".*?"' |
      grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'
  )

  # if the IPs are the same just exit
  if [ "$local_ip" == "$public_ip" ]; then
    echo "IP has not changed for record ${ID}, skipping."
    continue
  fi

  echo "Updating DNS record ${ID} with new IP address: ${public_ip}"

  # --fail silently on server errors
  curl \
    --fail \
    --silent \
    --output /dev/null \
    --request PUT \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer ${ACCESS_TOKEN}" \
    --data "{\"data\": \"${public_ip}\"}" \
    "https://api.digitalocean.com/v2/domains/${DOMAIN}/records/${ID}"

done
