#!/bin/bash
# github.com/bhuvangoel04
# MDM Management module

# ----------------- Colors -----------------
C_OFF='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_PURPLE='\033[0;35m'
C_CYAN='\033[0;36m'

mdm_management(){
  while true; do
    echo
    echo -e "${C_PURPLE}============ MDM Management ============${C_OFF}"
    echo -e "${C_CYAN}1.${C_OFF} List ABM Devices"
    echo -e "${C_CYAN}2.${C_OFF} Enable Lost Mode"
    echo -e "${C_CYAN}3.${C_OFF} Disable Lost Mode"
    echo -e "${C_CYAN}4.${C_OFF} Delete Service Discovery URL (ADUE)"
    echo -e "${C_CYAN}5.${C_OFF} Update Service Discovery URL (ADUE)"
    echo -e "${C_CYAN}6.${C_OFF} Validate Service Discovery URL (ADUE)"
    echo -e "${C_CYAN}7.${C_OFF} List Device Background Tasks"
    echo -e "${C_CYAN}8.${C_OFF} Get ADUE Redirect URL"
    echo -e "${C_CYAN}9.${C_OFF} Get ADUE JSON Configuration"
    echo -e "${C_CYAN}10.${C_OFF} Get Google EMM Device Details"
    echo -e "${C_CYAN}11.${C_OFF} Erase Google EMM Android Device"
    echo -e "${C_CYAN}12.${C_OFF} Lock Google EMM Device"    
    echo -e "${C_CYAN}13.${C_OFF} Start Lost Mode (Google EMM)"
    echo -e "${C_CYAN}14.${C_OFF} Stop Lost Mode (Google EMM)"
    echo -e "${C_CYAN}15.${C_OFF} Get the policy JSON of a Google EMM device"
    echo -e "${C_CYAN}16.${C_OFF} Reboot Google EMM device"   
    echo -e "${C_CYAN}16.${C_OFF} Reset password for Google EMM device"
    echo -e "${C_CYAN}17.${C_OFF} Return to main menu"    
    echo -e "${C_PURPLE}========================================${C_OFF}"
    read -rp "$(echo -e "${C_YELLOW}Choose an option [1-15]: ${C_OFF}")" choice
    case "$choice" in
      1) list_abm_devices ;;
      2) enable_lost_mode ;;
      3) disable_lost_mode ;;
      4) delete_service_discovery_url ;;
      5) update_service_discovery_url ;;
      6) validate_service_discovery_url ;;
      7) list_background_tasks ;;
      8) get_adue_redirect_url ;;
      9) get_adue_json_config ;;
      10) get_google_emm_device ;;
      11) erase_google_emm_device ;;
      12) lock_google_emm_device ;;
      13) start_google_emm_lostmode ;;
      14) stop_google_emm_lostmode ;;
      15) get_google_emm_device_policy ;;
      16) reboot_google_emm_device ;;
      17) reset_google_emm_device_password ;;
      18) return ;;
      *) echo -e "${C_RED}Invalid option. Try again.${C_OFF}" ;;
    esac
  done
}

# ----------- MDM Functions -----------

list_abm_devices() {
  echo -e "${C_BLUE}Listing ABM devices...${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Enter Device Manager Object ID: ${C_OFF}")" device_manager_id
  read -rp "$(echo -e "${C_YELLOW}Enter skip (default 0): ${C_OFF}")" skip
  read -rp "$(echo -e "${C_YELLOW}Enter limit (default 100): ${C_OFF}")" limit
  read -rp "$(echo -e "${C_YELLOW}Enter sort (optional): ${C_OFF}")" sort
  read -rp "$(echo -e "${C_YELLOW}Enter filter (optional): ${C_OFF}")" filter

  skip=${skip:-0}
  limit=${limit:-100}

  url="https://console.jumpcloud.com/api/v2/applemdms/${device_manager_id}/abm_devices?skip=$skip&limit=$limit"
  [[ -n "$sort" ]] && url="$url&sort=$sort"
  [[ -n "$filter" ]] && url="$url&filter=$filter"

  curl -s -X GET \
    -H "x-api-key: $JC_API_KEY" \
    -H "Accept: application/json" \
    "$url" | jq
}

enable_lost_mode() {
  echo -e "${C_BLUE}Enabling Lost Mode...${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Enter Device Manager Object ID: ${C_OFF}")" device_manager_id
  read -rp "$(echo -e "${C_YELLOW}Enter Device Object ID: ${C_OFF}")" device_id
  read -rp "$(echo -e "${C_YELLOW}Enter message for lost mode screen: ${C_OFF}")" message
  read -rp "$(echo -e "${C_YELLOW}Enter phone number to display: ${C_OFF}")" phone
  read -rp "$(echo -e "${C_YELLOW}Enter footnote text: ${C_OFF}")" footnote

  body=$(jq -n \
    --arg msg "$message" \
    --arg phone "$phone" \
    --arg footnote "$footnote" \
    '{ enableLostMode: { message: $msg, phoneNumber: $phone, footnote: $footnote } }')

  curl -s -X POST \
    -H "x-api-key: $JC_API_KEY" \
    -H "content-type: application/json" \
    -d "$body" \
    "https://console.jumpcloud.com/api/v2/applemdms/${device_manager_id}/devices/${device_id}/lostmode" | jq
}

disable_lost_mode() {
  echo -e "${C_BLUE}Disabling Lost Mode...${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Enter Device Manager Object ID: ${C_OFF}")" device_manager_id
  read -rp "$(echo -e "${C_YELLOW}Enter Device Object ID: ${C_OFF}")" device_id

  body='{"disableLostMode":{}}'

  curl -s -X POST \
    -H "x-api-key: $JC_API_KEY" \
    -H "content-type: application/json" \
    -d "$body" \
    "https://console.jumpcloud.com/api/v2/applemdms/${device_manager_id}/devices/${device_id}/lostmode" | jq
}
# ----------- ADUE Functions -----------

delete_service_discovery_url() {
  echo -e "${C_BLUE}Deleting Service Discovery URL (ADUE)...${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Enter Device Manager Object ID: ${C_OFF}")" device_manager_id

  curl -s -X DELETE \
    -H "x-api-key: $JC_API_KEY" \
    "https://console.jumpcloud.com/api/v2/applemdms/${device_manager_id}/service-discovery-url" | jq
}

update_service_discovery_url() {
  echo -e "${C_BLUE}Updating Service Discovery URL (ADUE)...${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Enter Device Manager Object ID: ${C_OFF}")" device_manager_id
  read -rp "$(echo -e "${C_YELLOW}Enter new Service Discovery URL: ${C_OFF}")" service_url

  body=$(jq -n --arg url "$service_url" '{ serviceDiscoveryUrl: $url }')

  curl -s -X POST \
    -H "x-api-key: $JC_API_KEY" \
    -H "content-type: application/json" \
    -d "$body" \
    "https://console.jumpcloud.com/api/v2/applemdms/${device_manager_id}/service-discovery-url" | jq
}

validate_service_discovery_url() {
  echo -e "${C_BLUE}Validating Service Discovery URL (ADUE)...${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Enter Device Manager Object ID: ${C_OFF}")" device_manager_id

  curl -s -X GET \
    -H "x-api-key: $JC_API_KEY" \
    "https://console.jumpcloud.com/api/v2/applemdms/${device_manager_id}/validate-service-discovery-url" | jq
}

# ----------- Background Tasks -----------

list_background_tasks() {
  echo -e "${C_BLUE}Listing Background Tasks for Device...${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Enter Device Object ID: ${C_OFF}")" device_id
  read -rp "$(echo -e "${C_YELLOW}Enter skip (default 0): ${C_OFF}")" skip
  read -rp "$(echo -e "${C_YELLOW}Enter limit (default 100): ${C_OFF}")" limit
  read -rp "$(echo -e "${C_YELLOW}Enter fields (comma-separated, optional): ${C_OFF}")" fields

  skip=${skip:-0}
  limit=${limit:-100}

  url="https://console.jumpcloud.com/api/v2/applemdms/${device_id}/background_tasks?skip=$skip&limit=$limit"
  [[ -n "$fields" ]] && url="$url&fields=$fields"

  curl -s -X GET \
    -H "x-api-key: $JC_API_KEY" \
    -H "Accept: application/json" \
    "$url" | jq
}

get_adue_redirect_url() {
  echo -e "${C_BLUE}Fetching ADUE Redirect URL...${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Enter Organization Object ID: ${C_OFF}")" org_id

  curl -s -X GET \
    -H "x-api-key: $JC_API_KEY" \
    "https://console.jumpcloud.com/api/v2/applemdms/${org_id}/account-driven-service-discovery" | jq
}

get_adue_json_config() {
  echo -e "${C_BLUE}Fetching ADUE JSON Configuration...${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Enter Organization Object ID: ${C_OFF}")" org_id

  curl -s -X GET \
    -H "x-api-key: $JC_API_KEY" \
    "https://console.jumpcloud.com/api/v2/applemdms/${org_id}/account-driven-service-discovery/config" | jq
}
# ----------- Google EMM Functions -----------

get_google_emm_device() {
  echo -e "${C_BLUE}Fetching Google EMM device details...${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Enter Device ID: ${C_OFF}")" device_id

  curl -s -X GET \
    -H "x-api-key: $JC_API_KEY" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    "https://console.jumpcloud.com/api/v2/google-emm/devices/${device_id}" | jq
}

erase_google_emm_device() {
  echo -e "${C_BLUE}Erasing Google EMM Android device (work profile & policies will be removed)...${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Enter Device ID: ${C_OFF}")" device_id

  curl -s -X POST \
    -H "x-api-key: $JC_API_KEY" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    "https://console.jumpcloud.com/api/v2/google-emm/devices/${device_id}/erase-device" | jq
}
lock_google_emm_device() {
  echo -e "${C_BLUE}Locking Google EMM device...${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Enter Device ID: ${C_OFF}")" device_id

  curl -s -X POST \
    -H "x-api-key: $JC_API_KEY" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d '{}' \
    "https://console.jumpcloud.com/api/v2/google-emm/devices/${device_id}/lock" | jq
}

start_google_emm_lostmode() {
  echo -e "${C_BLUE}Starting Lost Mode for Google EMM device...${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Enter Device ID: ${C_OFF}")" device_id
  read -rp "$(echo -e "${C_YELLOW}Enter Email Address: ${C_OFF}")" email
  read -rp "$(echo -e "${C_YELLOW}Enter Lost Message: ${C_OFF}")" message
  read -rp "$(echo -e "${C_YELLOW}Enter Organization Name: ${C_OFF}")" org
  read -rp "$(echo -e "${C_YELLOW}Enter Phone Number: ${C_OFF}")" phone
  read -rp "$(echo -e "${C_YELLOW}Enter Street Address: ${C_OFF}")" address

  curl -s -X POST \
    -H "x-api-key: $JC_API_KEY" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{
      \"emailAddress\": \"$email\",
      \"lostMessage\": \"$message\",
      \"organizationName\": \"$org\",
      \"phoneNumber\": \"$phone\",
      \"streetAddress\": \"$address\"
    }" \
    "https://console.jumpcloud.com/api/v2/google-emm/devices/${device_id}/lostmode/start" | jq
}

stop_google_emm_lostmode() {
  echo -e "${C_BLUE}Stopping Lost Mode for Google EMM device...${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Enter Device ID: ${C_OFF}")" device_id

  curl -s -X POST \
    -H "x-api-key: $JC_API_KEY" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d '{}' \
    "https://console.jumpcloud.com/api/v2/google-emm/devices/${device_id}/lostmode/stop" | jq
}

get_google_emm_device_policy() {
  echo -e "${C_BLUE}Fetching Google EMM Device Policy JSON...${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Enter Device ID: ${C_OFF}")" device_id

  curl -s -X GET \
    -H "x-api-key: $JC_API_KEY" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    "https://console.jumpcloud.com/api/v2/google-emm/devices/${device_id}/policy_results" | jq
}

reboot_google_emm_device() {
  echo -e "${C_BLUE}Rebooting Google EMM device...${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Enter Device ID: ${C_OFF}")" device_id

  curl -s -X POST \
    -H "x-api-key: $JC_API_KEY" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d '{}' \
    "https://console.jumpcloud.com/api/v2/google-emm/devices/${device_id}/reboot" | jq
}


reset_google_emm_device_password() {
  echo -e "${C_BLUE}Resetting Google EMM Device Password...${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Enter Device ID: ${C_OFF}")" device_id
  read -srp "$(echo -e "${C_YELLOW}Enter New Password (input hidden): ${C_OFF}")" new_password
  echo

  curl -s -X POST \
    -H "x-api-key: $JC_API_KEY" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{\"newPassword\":\"$new_password\"}" \
    "https://console.jumpcloud.com/api/v2/google-emm/devices/${device_id}/resetpassword"
}
