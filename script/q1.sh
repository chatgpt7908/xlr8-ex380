#!/bin/bash


clear
echo "=============================================="
echo " EX380 Q1 – SIMPLE COMPONENT CLEANUP"
echo " (NO OAUTH / NO LDAP TOUCH)"
echo "=============================================="
echo

# -------- VARIABLES --------
NS="openshift-config"
SECRET="ldap-bind-pass"
CONFIGMAP="ldap-ca-config"
USER="kristendelgado"

info () { echo "▶ $1"; }
ok ()   { echo "  [OK] $1"; }
skip () { echo "  [SKIP] $1"; }

# -------- SECRET --------
info "Checking Secret '${SECRET}'"
if oc get secret "${SECRET}" -n "${NS}" &>/dev/null; then
  oc delete secret "${SECRET}" -n "${NS}"
  ok "Secret deleted"
else
  skip "Secret not found"
fi

echo

# -------- CONFIGMAP --------
info "Checking ConfigMap '${CONFIGMAP}'"
if oc get configmap "${CONFIGMAP}" -n "${NS}" &>/dev/null; then
  oc delete configmap "${CONFIGMAP}" -n "${NS}"
  ok "ConfigMap deleted"
else
  skip "ConfigMap not found"
fi

echo

# -------- USER --------
info "Checking User '${USER}'"
if oc get user "${USER}" &>/dev/null; then
  oc delete user "${USER}"
  ok "User deleted"
else
  skip "User not found"
fi

echo

# -------- IDENTITY --------
info "Checking Identity mapping for '${USER}'"
IDENTITY=$(oc get identity -o jsonpath="{.items[?(@.user.name=='${USER}')].metadata.name}")

if [ -n "$IDENTITY" ]; then
  oc delete identity "$IDENTITY"
  ok "Identity deleted (${IDENTITY})"
else
  skip "No identity mapping found"
fi

echo
echo "=============================================="
echo " COMPONENT CLEANUP COMPLETE"
echo "=============================================="
echo



clear
echo "=============================================="
echo " EX380 MOCK EXAM – QUESTION 1"
echo " LDAP AUTHENTICATION (LAB MODE)"
echo "=============================================="
echo

echo "[*] Starting lab environment..."
lab start auth-ldap

echo
echo "----------------------------------------------"
echo " QUESTION:"
echo "----------------------------------------------"
cat <<'EOF'

EX380 – Question 1: Configure LDAP Authentication

LDAP Connection Details:
------------------------
Name                : ex380-oauth-lab
Bind DN             : cn=Directory Manager
Base DN             : dc=example,dc=com
Server Hostname     : rhds.ocp4.example.com
Bind Password       : redhatocp
Connection Protocol : ldaps
Insecure            : false
Query Method        : uid
Mapping Method      : claim

Attributes:
-----------
Preferred Username : uid
Email              : mail
ID                 : dn
Name               : cn

Certificate:
------------
#######You can download the LDAP CA certificate from: ######
https://raw.githubusercontent.com/chatgpt7908/xlr8-ex380/refs/heads/main/ca.crt

LDAP URL Format Reference:
--------------------------
(Connection Protocol)://(Server name):(port)/(Base DN)?(Query filter)

Example:
ldap://ldap.example.com:389/dc=example,dc=com?givenName,sn,cn?(uid=payden.tomcheck)

Requirements:
-------------
- Configure LDAP authentication in OpenShift
- Use a Secret named 'ldap-bind-pass' in the 'openshift-config' namespace
  to store the bind password
- Use a ConfigMap named 'ldap-ca-config' in the 'openshift-config' namespace
  to store the LDAP CA certificate
- User 'kristendelgado' must be able to log in using password 'redhat123'

EOF

echo
echo "----------------------------------------------"
echo " Lab is ready. Start working."
echo "----------------------------------------------"

