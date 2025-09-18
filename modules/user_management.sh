#!/bin/bash
#User Management Module
# github.com/bhuvangoel04

# ----------------- 🎨 Colors -----------------
C_OFF='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_PURPLE='\033[0;35m'
C_CYAN='\033[0;36m'


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

