#!/bin/bash
# Reach out to https://github.com/bhuvangoel04 for any suggestions, issues or if you need support.
# Enhanced by Google's Gemini

CONFIG_FILE="$HOME/.jc-cli"

# ----------------- 🎨 Colors -----------------
C_OFF='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_PURPLE='\033[0;35m'
C_CYAN='\033[0;36m'

# ----------------- 🔐 Load / Save API Key -----------------

load_api_key() {
  if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
  fi

  if [[ -z "$JC_API_KEY" ]]; then
    echo -en "${C_YELLOW}🔑 Enter your JumpCloud API key: ${C_OFF}"
    read -rs JC_API_KEY
    echo
    echo "JC_API_KEY=$JC_API_KEY" > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    echo -e "${C_GREEN}✅ API key saved to $CONFIG_FILE${C_OFF}"
  fi
}

set_api_key() {
  echo -en "${C_YELLOW}🔑 Enter new JumpCloud API key: ${C_OFF}"
  read -rs JC_API_KEY
  echo
  echo "JC_API_KEY=$JC_API_KEY" > "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"
  echo -e "${C_GREEN}✅ New API key saved.${C_OFF}"
}

# ----------------- 🔧 Helper Functions -----------------

get_user_id() {
  local email="$1"
  curl -s -X GET "https://console.jumpcloud.com/api/systemusers?filter=email:\$eq:$email" \
    -H "x-api-key: $JC_API_KEY" | jq -r '.results[] | .id'
}

get_group_id() {
  local group_name="$1"
  curl -s -X GET "https://console.jumpcloud.com/api/v2/usergroups?limit=100" \
    -H "x-api-key: $JC_API_KEY" | jq -r --arg name "$group_name" '.[] | select(.name | ascii_downcase == ($name | ascii_downcase)) | .id'
}

# ----------------- 🚀 Operations -----------------

add_user_to_group() {
  read -rp "$(echo -e "${C_YELLOW}📧 Enter user email: ${C_OFF}")" USER_EMAIL
  USER_ID=$(get_user_id "$USER_EMAIL")

  if [[ -z "$USER_ID" || "$USER_ID" == "null" ]]; then
    echo -e "${C_RED}❌ User not found.${C_OFF}"
    return
  fi

  read -rp "$(echo -e "${C_YELLOW}👥 Enter group name: ${C_OFF}")" GROUP_NAME
  GROUP_ID=$(get_group_id "$GROUP_NAME")

  if [[ -z "$GROUP_ID" || "$GROUP_ID" == "null" ]]; then
    echo -e "${C_RED}❌ Group not found.${C_OFF}"
    return
  fi
  MEMBERS=$(curl -s -X GET "https://console.jumpcloud.com/api/v2/usergroups/$GROUP_ID/members" \
    -H "x-api-key: $JC_API_KEY")

  if echo "$MEMBERS" | jq -e --arg uid "$USER_ID" '.[] | select(.to.id == $uid)' > /dev/null; then
    echo -e "${C_BLUE}ℹ️ User is already a member of the group.${C_OFF}"
    return
  fi
  echo -e "${C_CYAN}🚀 Adding user to group...${C_OFF}"
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://console.jumpcloud.com/api/v2/usergroups/$GROUP_ID/members" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $JC_API_KEY" \
    -d "{\"op\": \"add\", \"type\": \"user\", \"id\": \"$USER_ID\"}")

  if [[ "$RESPONSE" == "204" ]]; then
    echo -e "${C_GREEN}✅ User added successfully.${C_OFF}"
  else
    echo -e "${C_RED}❌ Failed. HTTP code: $RESPONSE${C_OFF}"
  fi
}

remove_user_from_group() {
  read -rp "$(echo -e "${C_YELLOW}📧 Enter user email: ${C_OFF}")" USER_EMAIL
  USER_ID=$(get_user_id "$USER_EMAIL")

  if [[ -z "$USER_ID" || "$USER_ID" == "null" ]]; then
    echo -e "${C_RED}❌ User not found.${C_OFF}"
    return
  fi

  read -rp "$(echo -e "${C_YELLOW}👥 Enter group name: ${C_OFF}")" GROUP_NAME
  GROUP_ID=$(get_group_id "$GROUP_NAME")

  if [[ -z "$GROUP_ID" || "$GROUP_ID" == "null" ]]; then
    echo -e "${C_RED}❌ Group not found.${C_OFF}"
    return
  fi

  echo -e "${C_CYAN}🧹 Removing user from group...${C_OFF}"
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://console.jumpcloud.com/api/v2/usergroups/$GROUP_ID/members" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $JC_API_KEY" \
    -d "{\"op\": \"remove\", \"type\": \"user\", \"id\": \"$USER_ID\"}")

  if [[ "$RESPONSE" == "204" ]]; then
    echo -e "${C_GREEN}✅ User removed successfully.${C_OFF}"
  else
    echo -e "${C_RED}❌ Failed. HTTP code: $RESPONSE${C_OFF}"
  fi
}

list_all_users() {
  echo -e "${C_BLUE}📋 Listing all users:${C_OFF}"
  curl -s -X GET "https://console.jumpcloud.com/api/systemusers?limit=100" \
    -H "x-api-key: $JC_API_KEY" | jq -r '.results[] | "\(.email) (\(.username))"'
}

list_all_groups() {
  echo -e "${C_BLUE}📋 Listing all user groups:${C_OFF}"
  curl -s -X GET "https://console.jumpcloud.com/api/v2/usergroups" \
    -H "x-api-key: $JC_API_KEY" | jq -r '.[] | "\(.name) [\(.id)]"'
}

# ===================== SYSTEM FUNCTIONS ======================

get_system_id_by_hostname() {
  local hostname="$1"
  curl -s -X GET "https://console.jumpcloud.com/api/systems?filter=hostname:\$eq:$hostname" \
    -H "x-api-key: $JC_API_KEY" | jq -r '.results[0].id'
}

view_system_info() {
  read -rp "$(echo -e "${C_YELLOW}💻 Enter system hostname: ${C_OFF}")" HOSTNAME
  SYSTEM_ID=$(get_system_id_by_hostname "$HOSTNAME")

  if [[ -z "$SYSTEM_ID" || "$SYSTEM_ID" == "null" ]]; then
    echo -e "${C_RED}❌ System not found.${C_OFF}"
    return
  fi

  echo -e "${C_BLUE}🔍 System Info for '$HOSTNAME':${C_OFF}"
  curl -s -X GET "https://console.jumpcloud.com/api/systems/$SYSTEM_ID" \
    -H "x-api-key: $JC_API_KEY" | jq
}

list_all_systems() {
  echo -e "${C_BLUE}🖥️ Listing all systems:${C_OFF}"
  curl -s -X GET "https://console.jumpcloud.com/api/systems?limit=100" \
    -H "x-api-key: $JC_API_KEY" | jq -r '.results[] | "\(.hostname)\t|\t\(.os)\t|\t\(.id)\t|\tActive: \(.allowPublicKeyAuthentication)"' | column -t -s $'\t'
}

view_users_on_system() {
  read -rp "$(echo -e "${C_YELLOW}💻 Enter system hostname: ${C_OFF}")" HOSTNAME
  SYSTEM_ID=$(get_system_id_by_hostname "$HOSTNAME")

  if [[ -z "$SYSTEM_ID" || "$SYSTEM_ID" == "null" ]]; then
    echo -e "${C_RED}❌ System not found.${C_OFF}"
    return
  fi

  echo -e "${C_BLUE}👤 Users bound to system '$HOSTNAME':${C_OFF}"
  curl -s -X GET "https://console.jumpcloud.com/api/v2/systems/$SYSTEM_ID/users" \
    -H "x-api-key: $JC_API_KEY" | jq -r '.[] | "\(.attributes.email) (\(.id))"'
}

view_system_groups() {
  read -rp "$(echo -e "${C_YELLOW}💻 Enter system hostname: ${C_OFF}")" HOSTNAME
  SYSTEM_ID=$(get_system_id_by_hostname "$HOSTNAME")

  if [[ -z "$SYSTEM_ID" || "$SYSTEM_ID" == "null" ]]; then
    echo -e "${C_RED}❌ System not found.${C_OFF}"
    return
  fi

  echo -e "${C_BLUE}🧠 Groups for system '$HOSTNAME':${C_OFF}"
  curl -s -X GET "https://console.jumpcloud.com/api/v2/systems/$SYSTEM_ID/memberof" \
    -H "x-api-key: $JC_API_KEY" | jq -r '.[] | select(.type=="system_group") | .name'
}

add_system_to_group() {
  read -rp "$(echo -e "${C_YELLOW}💻 Enter system hostname: ${C_OFF}")" HOSTNAME
  SYSTEM_ID=$(get_system_id_by_hostname "$HOSTNAME")

  if [[ -z "$SYSTEM_ID" || "$SYSTEM_ID" == "null" ]]; then
    echo -e "${C_RED}❌ System not found.${C_OFF}"
    return
  fi

  read -rp "$(echo -e "${C_YELLOW}👥 Enter system group name: ${C_OFF}")" GROUP_NAME
  GROUP_ID=$(get_group_id "$GROUP_NAME")
  if [[ -z "$GROUP_ID" || "$GROUP_ID" == "null" ]]; then
    echo -e "${C_RED}❌ Group not found.${C_OFF}"
    return
  fi

  # Check membership before adding
  CURRENT_MEMBERS=$(curl -s -X GET "https://console.jumpcloud.com/api/v2/systemgroups/$GROUP_ID/members" \
    -H "x-api-key: $JC_API_KEY")

  if echo "$CURRENT_MEMBERS" | jq -e --arg sid "$SYSTEM_ID" '.[] | select(.to.id == $sid)' > /dev/null; then
    echo -e "${C_BLUE}ℹ️ System already in group.${C_OFF}"
    return
  fi

  echo -e "${C_CYAN}🚀 Adding system to group...${C_OFF}"
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://console.jumpcloud.com/api/v2/systemgroups/$GROUP_ID/members" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $JC_API_KEY" \
    -d "{\"op\": \"add\", \"type\": \"system\", \"id\": \"$SYSTEM_ID\"}")

  if [[ "$RESPONSE" == "204" ]]; then
    echo -e "${C_GREEN}✅ System added to group.${C_OFF}"
  else
    echo -e "${C_RED}❌ Failed. HTTP code: $RESPONSE${C_OFF}"
  fi
}

delete_system() {
  read -rp "$(echo -e "${C_YELLOW}💻 Enter system hostname: ${C_OFF}")" HOSTNAME
  SYSTEM_ID=$(get_system_id_by_hostname "$HOSTNAME")

  if [[ -z "$SYSTEM_ID" || "$SYSTEM_ID" == "null" ]]; then
    echo -e "${C_RED}❌ System not found.${C_OFF}"
    return
  fi

  read -rp "$(echo -e "${C_RED}⚠️ Are you sure you want to DELETE this system? Type 'yes' to confirm: ${C_OFF}")" CONFIRM
  if [[ "$CONFIRM" != "yes" ]]; then
    echo -e "${C_YELLOW}❌ Cancelled.${C_OFF}"
    return
  fi

  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "https://console.jumpcloud.com/api/systems/$SYSTEM_ID" \
    -H "x-api-key: $JC_API_KEY")

  if [[ "$RESPONSE" == "204" ]]; then
    echo -e "${C_GREEN}🗑️ System deleted successfully.${C_OFF}"
  else
    echo -e "${C_RED}❌ Deletion failed. HTTP code: $RESPONSE${C_OFF}"
  fi
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
    https://console.jumpcloud.com/api/account | jq -r '.organization')

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

# ----------------- Menus --------------------

user_management(){
  while true; do
    echo
    echo -e "${C_PURPLE}====== User Management ======${C_OFF}"
    echo -e "${C_CYAN}1.${C_OFF} Add user to group"
    echo -e "${C_CYAN}2.${C_OFF} Remove user from group"
    echo -e "${C_CYAN}3.${C_OFF} List all users"
    echo -e "${C_CYAN}4.${C_OFF} List all groups"
    echo -e "${C_CYAN}5.${C_OFF} Return to main menu"
    echo -e "${C_PURPLE}=============================${C_OFF}"
    read -rp "$(echo -e "${C_YELLOW}Choose an option [1-5]: ${C_OFF}")" choice
    case "$choice" in
      1) add_user_to_group ;;
      2) remove_user_from_group ;;
      3) list_all_users ;;
      4) list_all_groups ;;
      5) return;;
      *) echo -e "${C_RED}⚠️ Invalid option. Try again.${C_OFF}" ;;
    esac
  done
}


systems_management(){
  while true; do
    echo
    echo -e "${C_PURPLE}====== System Management ======${C_OFF}"
    echo -e "${C_CYAN}1.${C_OFF} View system info"
    echo -e "${C_CYAN}2.${C_OFF} List all systems"
    echo -e "${C_CYAN}3.${C_OFF} View users on system"
    echo -e "${C_CYAN}4.${C_OFF} View system’s group memberships"
    echo -e "${C_CYAN}5.${C_OFF} Add system to system group"
    echo -e "${C_CYAN}6.${C_OFF} ${C_RED}Delete a system${C_OFF}"
    echo -e "${C_CYAN}7.${C_OFF} Return to main menu"
    echo -e "${C_PURPLE}===============================${C_OFF}"
    read -rp "$(echo -e "${C_YELLOW}Choose an option [1-7]: ${C_OFF}")" choice
    case "$choice" in
      1) view_system_info;;
      2) list_all_systems;;
      3) view_users_on_system;;
      4) view_system_groups;;
      5) add_system_to_group;;
      6) delete_system;;
      7) return;;
      *) echo -e "${C_RED}⚠️ Invalid option. Try again.${C_OFF}" ;;
    esac
  done
}

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

# ----------------- 📋 Main Menu -----------------
main_menu() {
  while true; do
    clear
    echo -e "${C_CYAN}"
    cat << "EOF"
     _                       _____ _                 _    _____ _     _____ 
    | |_   _ _ __ ___  _ __ / ____| | ___  _   _  __| |  / ____| |   |_   _|
 _  | | | | | '_ \` _ \| '_ \ |    | |/ _ \| | | |/ _\` | | |    | |     | |  
| |_| | |_| | | | | | | |_) | |____| | (_) | |_| | (_| | | |____| |___ _| |_ 
 \___/ \__,_|_| |_| |_| .__/ \_____|_|\___/ \__,_|\__,_|  \_____|_____|_____|
                      |_|                          CLI by Bhuvangoel04      
EOF
    echo -e "${C_OFF}"
    echo -e "${C_BLUE}========== JumpCloud CLI Main Menu ==========${C_OFF}"
    echo -e "${C_CYAN}1.${C_OFF} Set/Update API key"
    echo -e "${C_CYAN}2.${C_OFF} User Management"
    echo -e "${C_CYAN}3.${C_OFF} Systems Management"
    echo -e "${C_CYAN}4.${C_OFF} App Management"
    echo -e "${C_CYAN}5.${C_OFF} Exit"
    echo -e "${C_BLUE}=============================================${C_OFF}"
    read -rp "$(echo -e "${C_YELLOW}Choose an option [1-5]: ${C_OFF}")" choice

    case "$choice" in
      1) set_api_key;;
      2) user_management;;
      3) systems_management;;
      4) app_management;;
      5) echo -e "${C_GREEN}👋 Goodbye!${C_OFF}"; exit 0 ;;
      *) echo -e "${C_RED}⚠️ Invalid option. Try again.${C_OFF}" ;;
    esac
  done
}

# ----------------- 🚀 Entry Point -----------------

load_api_key
main_menu