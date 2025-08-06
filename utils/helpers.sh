#!/bin/bash
# Helper functions
# github.com/bhuvangoel04

BASE_URL=https://console.jumpcloud.com/api
CONFIG_FILE="$HOME/.jc-cli"


# ----------------- 🎨 Colors -----------------
C_OFF='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m's
C_PURPLE='\033[0;35m'
C_CYAN='\033[0;36m'

# ----------------- Helper Functions -----------------

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

get_org_id() {
   org_id=$(curl -s -H "x-api-key: $JC_API_KEY" \
    "$BASE_URL/account" | jq -r '.organization')

  if [[ "$org_id" == "null" || -z "$org_id" ]]; then
    echo -e "${C_RED}❌ Failed to fetch organization ID. Check your API key.${C_OFF}"
    return 1
  fi
}
