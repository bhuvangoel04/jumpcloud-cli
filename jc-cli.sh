#!/bin/bash

source utils/helpers.sh
source modules/user_management.sh
source modules/app_management.sh
source modules/system_management.sh
source modules/idp_routing.sh
source modules/mdm_management.sh
source modules/monitoring_alerts.sh

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
    echo -e "${C_CYAN}5.${C_OFF} Identity Providers"
    echo -e "${C_CYAN}6.${C_OFF} Monitoring and Alerts"
    echo -e "${C_CYAN}7.${C_OFF} Mobile Device Management"
    echo -e "${C_CYAN}8.${C_OFF} Exit"
    echo -e "${C_BLUE}=============================================${C_OFF}"
    read -rp "$(echo -e "${C_YELLOW}Choose an option [1-8]: ${C_OFF}")" choice

    case "$choice" in
      1) set_api_key;;
      2) user_management;;
      3) systems_management;;
      4) app_management;;
      5) idp_routing_policy_menu;;
      6) monitoring_management;;
      7) mdm_management;;
      8) echo -e "${C_GREEN}👋 Goodbye!${C_OFF}"; exit 0 ;;
      *) echo -e "${C_RED}⚠️ Invalid option. Try again.${C_OFF}" ;;
    esac
  done
}

# ----------------- 🚀 Entry Point -----------------

load_api_key
main_menu
