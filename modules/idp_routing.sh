#!/bin/bash
# Identiy Provider
# github.com/bhuvangoel04

idp_routing_policy_menu() {
  echo
  echo -e "${C_PURPLE}--- IDP Routing Policy Management ---${C_OFF}"
  echo -e "${C_CYAN}1.${C_OFF} List Direct Associations"
  echo -e "${C_CYAN}2.${C_OFF} Add/Remove Association"
  echo -e "${C_CYAN}3.${C_OFF} List Bound User Groups"
  echo -e "${C_CYAN}4.${C_OFF} List Bound Users"
  echo -e "${C_CYAN}5.${C_OFF} Return to main menu."
  echo -e "${C_PURPLE}=============================================${C_OFF}"
  read -rp "$(echo -e "${C_YELLOW}Choose an option [1-5]: ${C_OFF}")" choice
  
  case $choice in
    1) list_idp_routing_policy_associations ;;
    2) manage_idp_routing_policy_association ;;
    3) list_idp_policy_usergroups ;;
    4) list_idp_policy_users ;;
    5) return ;;
    *) echo "Invalid option" ;;
  esac
}

list_idp_routing_policy_associations() {
  read -p "Enter Routing Policy ID: " policy_id
  read -p "Enter Target Type (user/user_group): " target_type

  curl -s -X GET "$BASE_URL/v2/identity-provider/policies/$policy_id/associations?targets=$target_type" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $API_KEY" | jq
}

manage_idp_routing_policy_association() {
  read -p "Enter Routing Policy ID: " policy_id
  read -p "Enter Object ID to associate/disassociate: " object_id
  read -p "Enter Target Type (user/user_group): " target_type
  read -p "Enter Operation (add/remove): " operation

  curl -s -X POST "$BASE_URL/v2/identity-provider/policies/$policy_id/associations" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $API_KEY" \
    -d "{\"type\":\"$target_type\", \"id\":\"$object_id\", \"op\":\"$operation\"}"

  echo "✅ Association $operation operation sent."
}

list_idp_policy_usergroups() {
  read -p "Enter Routing Policy ID: " policy_id

  curl -s -X GET "$BASE_URL/v2/identity-provider/policies/$policy_id/associations/usergroups" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $API_KEY" | jq
}

list_idp_policy_users() {
  read -p "Enter Routing Policy ID: " policy_id

  curl -s -X GET "$BASE_URL/v2/identity-provider/policies/$policy_id/associations/users" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $API_KEY" | jq
}
