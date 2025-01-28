#!/usr/bin/env bash

secrets="${1:-./secrets}"
source "${secrets}"

response=$(
  curl \
    --silent \
    -X GET \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    "https://api.digitalocean.com/v2/domains/${DOMAIN}/records"
)

echo "${response}"
