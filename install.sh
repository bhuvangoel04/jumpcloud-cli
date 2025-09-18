#!/bin/bash
set -e

SCRIPT_NAME="jc-cli"
INSTALL_PATH="/usr/local/bin/$SCRIPT_NAME"

echo "🔧 Installing $SCRIPT_NAME to $INSTALL_PATH..."

# Move the script to /usr/local/bin
sudo cp "./jc-cli.sh" "$INSTALL_PATH"
sudo chmod +x "$INSTALL_PATH"

echo "✅ Installed! You can now use the CLI by running: $SCRIPT_NAME"

