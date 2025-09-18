#!/bin/bash
# Monitoring & Alerts module
# github.com/bhuvangoel04

# ----------------- Colors -----------------
C_OFF='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_PURPLE='\033[0;35m'
C_CYAN='\033[0;36m'

monitoring_management(){
  while true; do
    echo
    echo -e "${C_PURPLE}======= Monitoring & Alerts =======${C_OFF}"
    echo -e "${C_CYAN}1.${C_OFF} List all alerts"
    echo -e "${C_CYAN}2.${C_OFF} Get alert statistics"
    echo -e "${C_CYAN}3.${C_OFF} Bulk delete alerts"
    echo -e "${C_CYAN}4.${C_OFF} Bulk update alerts"
    echo -e "${C_CYAN}5.${C_OFF} Return to main menu"
    echo -e "${C_PURPLE}===================================${C_OFF}"
    read -rp "$(echo -e "${C_YELLOW}Choose an option [1-5]: ${C_OFF}")" choice
    case "$choice" in
      1) list_alerts ;;
      2) alert_statistics ;;
      3) bulk_delete_alerts ;;
      4) bulk_update_alerts ;;
      5) return ;;
      *) echo -e "${C_RED}Invalid option. Try again.${C_OFF}" ;;
    esac
  done
}

# ----------- Monitoring & Alerts Functions -------

list_alerts() {
  echo -e "${C_BLUE}Fetching alerts...${C_OFF}"

  read -rp "$(echo -e "${C_YELLOW}Enter filter (optional): ${C_OFF}")" filter
  read -rp "$(echo -e "${C_YELLOW}Enter fields (comma separated, optional): ${C_OFF}")" fields
  read -rp "$(echo -e "${C_YELLOW}Enter sort field (optional): ${C_OFF}")" sort
  read -rp "$(echo -e "${C_YELLOW}Enter skip (default 0): ${C_OFF}")" skip
  read -rp "$(echo -e "${C_YELLOW}Enter limit (default 100): ${C_OFF}")" limit

  skip=${skip:-0}
  limit=${limit:-100}

  url="https://console.jumpcloud.com/api/v2/alerts?skip=$skip&limit=$limit"

  [[ -n "$filter" ]] && url="$url&filter=$filter"
  [[ -n "$fields" ]] && url="$url&fields=$fields"
  [[ -n "$sort" ]] && url="$url&sort=$sort"

  curl -s -X GET \
    -H "x-api-key: $JC_API_KEY" \
    "$url" | jq
}

alert_statistics() {
  echo -e "${C_BLUE}Fetching alert statistics...${C_OFF}"
  echo -e "${C_YELLOW}Available groupBy options:${C_OFF}"
  echo "  - GROUP_BY_STATUS"
  echo "  - GROUP_BY_SEVERITY"
  echo "  - GROUP_BY_STATUS:GROUP_BY_SEVERITY"

  read -rp "$(echo -e "${C_YELLOW}Enter groupBy value(s) (comma separated): ${C_OFF}")" groupBy

  url="https://console.jumpcloud.com/api/v2/alerts-stats"
  [[ -n "$groupBy" ]] && url="$url?groupBy=$groupBy"

  curl -s -X GET \
    -H "x-api-key: $JC_API_KEY" \
    "$url" | jq
}

bulk_delete_alerts() {
  echo -e "${C_RED}WARNING: This will permanently delete alerts matching criteria.${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Do you really want to continue? (y/n): ${C_OFF}")" confirm
  [[ "$confirm" != "y" ]] && echo -e "${C_GREEN}Operation cancelled.${C_OFF}" && return

  read -rp "$(echo -e "${C_YELLOW}Enter alert IDs to exclude (comma separated, optional): ${C_OFF}")" excludeIds
  read -rp "$(echo -e "${C_YELLOW}Enter category filter (optional): ${C_OFF}")" category
  read -rp "$(echo -e "${C_YELLOW}Enter severity filter (optional): ${C_OFF}")" severity
  read -rp "$(echo -e "${C_YELLOW}Enter status filter (optional): ${C_OFF}")" status
  read -rp "$(echo -e "${C_YELLOW}Enter title filter (optional): ${C_OFF}")" title

  excludeJson=""
  if [[ -n "$excludeIds" ]]; then
    IFS=',' read -ra arr <<< "$excludeIds"
    excludeJson="\"excludeIds\": [$(printf '"%s",' "${arr[@]}" | sed 's/,$//')]"
  fi

  filterJson="\"filter\": {"
  [[ -n "$category" ]] && filterJson="$filterJson \"category\": [\"$category\"],"
  [[ -n "$severity" ]] && filterJson="$filterJson \"severity\": [\"$severity\"],"
  [[ -n "$status" ]] && filterJson="$filterJson \"status\": [\"$status\"],"
  [[ -n "$title" ]] && filterJson="$filterJson \"title\": \"$title\","
  filterJson=$(echo "$filterJson" | sed 's/,$//') # remove trailing comma
  filterJson="$filterJson }"

  body="{ $excludeJson, $filterJson }"
  body=$(echo "$body" | sed 's/^, //; s/, ,/,/') # cleanup

  echo -e "${C_BLUE}Sending bulk delete request...${C_OFF}"
  curl -s -X POST \
    -H "x-api-key: $JC_API_KEY" \
    -H "content-type: application/json" \
    -d "$body" \
    "https://console.jumpcloud.com/api/v2/alerts/bulk-delete" | jq
}

bulk_update_alerts() {
  echo -e "${C_BLUE}Bulk update alerts operation.${C_OFF}"

  read -rp "$(echo -e "${C_YELLOW}Enter alert IDs to exclude (comma separated, optional): ${C_OFF}")" excludeIds
  read -rp "$(echo -e "${C_YELLOW}Enter category filter (optional): ${C_OFF}")" category
  read -rp "$(echo -e "${C_YELLOW}Enter severity filter (optional): ${C_OFF}")" severity
  read -rp "$(echo -e "${C_YELLOW}Enter status filter (optional): ${C_OFF}")" status
  read -rp "$(echo -e "${C_YELLOW}Enter title filter (optional): ${C_OFF}")" title
  read -rp "$(echo -e "${C_YELLOW}Enter remark for this update (optional): ${C_OFF}")" remark
  read -rp "$(echo -e "${C_YELLOW}Enter new status for alerts (e.g., ALERT_STATUS_UNSPECIFIED, ALERT_STATUS_OPEN, ALERT_STATUS_CLOSED): ${C_OFF}")" new_status

  excludeJson=""
  if [[ -n "$excludeIds" ]]; then
    IFS=',' read -ra arr <<< "$excludeIds"
    excludeJson="\"excludeIds\": [$(printf '"%s",' "${arr[@]}" | sed 's/,$//')]"
  fi

  filterJson="\"filter\": {"
  [[ -n "$category" ]] && filterJson="$filterJson \"category\": [\"$category\"],"
  [[ -n "$severity" ]] && filterJson="$filterJson \"severity\": [\"$severity\"],"
  [[ -n "$status" ]] && filterJson="$filterJson \"status\": [\"$status\"],"
  [[ -n "$title" ]] && filterJson="$filterJson \"title\": \"$title\","
  filterJson=$(echo "$filterJson" | sed 's/,$//') # remove trailing comma
  filterJson="$filterJson }"

  updateFieldJson="\"updateField\": { \"status\": \"$new_status\" }"
  [[ -n "$remark" ]] && remarkJson="\"remark\": \"$remark\""

  body="{ $excludeJson, $filterJson, $remarkJson, $updateFieldJson }"
  body=$(echo "$body" | sed 's/^, //; s/, ,/,/') # cleanup

  echo -e "${C_BLUE}Sending bulk update request...${C_OFF}"
  curl -s -X POST \
    -H "x-api-key: $JC_API_KEY" \
    -H "content-type: application/json" \
    -d "$body" \
    "https://console.jumpcloud.com/api/v2/alerts/bulk-update" | jq
}
