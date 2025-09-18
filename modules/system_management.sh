#!/bin/bash
# Systems Managment Module
# github.com/bhuvangoel04

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

