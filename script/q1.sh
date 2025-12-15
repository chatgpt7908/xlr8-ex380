#!/bin/bash

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

