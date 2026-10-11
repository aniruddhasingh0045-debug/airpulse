#!/usr/bin/env bash
# Fetch air-quality data for Indian cities and save raw JSON files.
set -euo pipefail

OUT_DIR="data/raw"
TS=$(date -u +"%Y%m%dT%H%M%SZ")
BASE_URL="https://air-quality-api.open-meteo.com/v1/air-quality"
PARAMS="current=pm2_5,pm10,us_aqi&hourly=pm2_5,pm10,us_aqi&forecast_days=1&timezone=Asia%2FKolkata"

# format: name:latitude:longitude
CITIES=(
  "indore:22.7196:75.8577"
  "delhi:28.6139:77.2090"
  "mumbai:19.0760:72.8777"
  "kolkata:22.5726:88.3639"
  "chennai:13.0827:80.2707"
  "bengaluru:12.9716:77.5946"
  "hyderabad:17.3850:78.4867"
  "lucknow:26.8467:80.9462"
)

mkdir -p "$OUT_DIR"

for entry in "${CITIES[@]}"; do
  IFS=":" read -r city lat lon <<< "$entry"
  file="${OUT_DIR}/${city}_${TS}.json"

  echo "Fetching ${city}..."
  curl --silent --show-error --fail --retry 3 --retry-delay 2 \
    "${BASE_URL}?latitude=${lat}&longitude=${lon}&${PARAMS}" -o "$file"

  # Quality check: the response must contain a real PM2.5 value
  if ! jq -e '.current.pm2_5 != null' "$file" > /dev/null; then
    echo "ERROR: invalid data for ${city}" >&2
    rm -f "$file"
    exit 1
  fi

  echo "  saved ${file}"
done

echo "Done. ${#CITIES[@]} cities fetched."
