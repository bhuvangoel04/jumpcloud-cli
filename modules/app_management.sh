#!/bin/bash
# App management module
# github.com/bhuvangoel04

# ----------------- 🎨 Colors -----------------
C_OFF='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_PURPLE='\033[0;35m'
C_CYAN='\033[0;36m'

app_management(){
  while true; do
    echo
    echo -e "${C_PURPLE}======= App Management =======${C_OFF}"
    echo -e "${C_CYAN}1.${C_OFF} List all applications"
    echo -e "${C_CYAN}2.${C_OFF} Get application details"
    echo -e "${C_CYAN}3.${C_OFF} Link app to user group"
    echo -e "${C_CYAN}4.${C_OFF} Unlink app from user group"
    echo -e "${C_CYAN}5.${C_OFF} Create Import User Job for Application"
    echo -e "${C_CYAN}6.${C_OFF} Set or Update Application Logo"
    echo -e "${C_CYAN}7.${C_OFF} List all user groups bound to Application"
    echo -e "${C_CYAN}8.${C_OFF} List all users bound to Application"
    echo -e "${C_CYAN}9.${C_OFF} Return to main menu"
    echo -e "${C_PURPLE}==============================${C_OFF}"
    read -rp "$(echo -e "${C_YELLOW}Choose an option [1-9]: ${C_OFF}")" choice
    case "$choice" in
      1) list_apps ;;
      2) get_app_details ;;
      3) link_app_to_group ;;
      4) unlink_app_from_group ;;
      5) create_import_job;;
      6) uploadAppLogo;;
      7) listAppUserGroups;;
      8) listAppUsers;;
      9) return;;
      *) echo -e "${C_RED}⚠️ Invalid option. Try again.${C_OFF}" ;;
    esac
  done
}

# ----------- App Management Functions -------

list_apps() {
  echo -e "${C_BLUE}📦 Fetching list of applications...${C_OFF}"
  curl -s -X GET \
    -H "x-api-key: $JC_API_KEY" \
    https://console.jumpcloud.com/api/v2/applications | jq
}

get_app_details() {
  read -rp "$(echo -e "${C_YELLOW}🆔 Enter Application ID: ${C_OFF}")" app_id
  echo -e "${C_BLUE}🔍 Fetching application details...${C_OFF}"
  curl -s -X GET \
    -H "x-api-key: $JC_API_KEY" \
    https://console.jumpcloud.com/api/v2/applications/$app_id | jq
}

link_app_to_group() {
  read -rp "$(echo -e "${C_YELLOW}🆔 Enter Application ID: ${C_OFF}")" app_id
  
  read -rp "$(echo -e "${C_YELLOW}👥 Enter user group name: ${C_OFF}")" GROUP_NAME

  GROUP_ID=$(get_group_id "$GROUP_NAME")
  if [[ -z "$GROUP_ID" || "$GROUP_ID" == "null" ]]; then
    echo -e "${C_RED}❌ Group not found.${C_OFF}"
    return
  fi
  echo -e "${C_CYAN}🔗 Linking application to group...${C_OFF}"
  curl -s -X POST \
    -H "x-api-key: $JC_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"op": "add", "type": "user_group", "id": "'$GROUP_ID'"}' \
    https://console.jumpcloud.com/api/v2/applications/$app_id/associations | jq
}

unlink_app_from_group() {
  read -rp "$(echo -e "${C_YELLOW}🆔 Enter Application ID: ${C_OFF}")" app_id
  
  read -rp "$(echo -e "${C_YELLOW}👥 Enter user group name: ${C_OFF}")" GROUP_NAME

  GROUP_ID=$(get_group_id "$GROUP_NAME")
  if [[ -z "$GROUP_ID" || "$GROUP_ID" == "null" ]]; then
    echo -e "${C_RED}❌ Group not found.${C_OFF}"
    return
  fi
  echo -e "${C_CYAN}❌ Unlinking application from group...${C_OFF}"
  curl -s -X POST \
    -H "x-api-key: $JC_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"op": "remove", "type": "user_group", "id": "'$GROUP_ID'"}' \
    https://console.jumpcloud.com/api/v2/applications/$app_id/associations | jq
}
create_import_job() {
  echo -e "${C_BLUE}📦 Create Import Job for Application${C_OFF}"

  read -rp "$(echo -e "${C_YELLOW}🔢 Enter Application ID: ${C_OFF}")" application_id
  read -rp "$(echo -e "${C_YELLOW}🎯 Query string (optional): ${C_OFF}")" query_string
  read -rp "$(echo -e "${C_YELLOW}🔁 Allow user reactivation? (Y/n): ${C_OFF}")" reactivation_choice

  # Normalize reactivation input
  allow_reactivation=true
  if [[ "$reactivation_choice" =~ ^[Nn]$ ]]; then
    allow_reactivation=false
  fi

  # Use default operations
  operations='["users.create","users.update"]'

  # Fetch org ID (you can cache this to avoid fetching again)
  echo -e "${C_BLUE}🔍 Fetching organization ID...${C_OFF}"
  org_id=$(curl -s -H "x-api-key: $JC_API_KEY" \
    "$BASE_URL/api/account" | jq -r '.organization')

  if [[ "$org_id" == "null" || -z "$org_id" ]]; then
    echo -e "${C_RED}❌ Failed to fetch organization ID. Check your API key.${C_OFF}"
    return 1
  fi

  echo -e "${C_CYAN}🚀 Sending import job request...${C_OFF}"
  response=$(curl -s -w "\n%{http_code}" -X POST "https://console.jumpcloud.com/api/v2/applications/$application_id/import/jobs" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $JC_API_KEY" \
    -H "x-org-id: $org_id" \
    -d "{
      \"allowUserReactivation\": $allow_reactivation,
      \"operations\": $operations,
      \"queryString\": \"$query_string\"
    }")

  # Split response and HTTP code
  body=$(echo "$response" | head -n -1)
  http_code=$(echo "$response" | tail -n1)

  if [[ "$http_code" == "200" ]]; then
    echo -e "${C_GREEN}✅ Import job created successfully!${C_OFF}"
  else
    echo -e "${C_RED}❌ Failed to create import job. HTTP $http_code${C_OFF}"
    echo "$body" | jq
  fi
}

uploadAppLogo() {
  read -rp "$(echo -e "${C_YELLOW}🆔 Enter Application ID: ${C_OFF}")" app_id
  read -rp "$(echo -e "${C_YELLOW}🖼️ Enter full path to the logo image file: ${C_OFF}")" image_path

  response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://console.jumpcloud.com/api/v2/applications/$app_id/logo" \
      -H "x-api-key: $JC_API_KEY" \
      -F "image=@$image_path")

  if [ "$response" == "204" ]; then
    echo -e "${C_GREEN}✅ Logo uploaded successfully.${C_OFF}"
  else
    echo -e "${C_RED}❌ Failed to upload logo. HTTP Status: $response${C_OFF}"
  fi
}

listAppUserGroups() {
  read -rp "$(echo -e "${C_YELLOW}🆔 Enter Application ID: ${C_OFF}")" app_id

  curl -s -X GET "https://console.jumpcloud.com/api/v2/applications/$app_id/usergroups" \
    -H "accept: application/json" \
    -H "x-api-key: $JC_API_KEY" | jq
}

listAppUsers() {
   read -rp "$(echo -e "${C_YELLOW}🆔 Enter Application ID: ${C_OFF}")" app_id

   curl -s -X GET "https://console.jumpcloud.com/api/v2/applications/$app_id/users" \
     -H "accept: application/json" \
     -H "x-api-key: $JC_API_KEY" | jq
}

