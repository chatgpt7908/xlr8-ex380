#!/bin/bash

USER="kristendelgado"
PASS="redhat123"
SECRET="ldap-bind-pass"
CONFIGMAP="ldap-ca-config"
NS="openshift-config"

echo "=============================================="
echo " EX380 Q1 – FINAL LDAP PASS/FAIL VALIDATION"
echo "=============================================="
echo

FAIL=0

step () {
  echo
  echo "▶ $1"
}

pass () {
  echo "[OK] $1"
}

fail () {
  echo "[FAIL] $1"
  FAIL=1
}

# 1. OAuth exists
step "Checking OAuth object"
oc get oauth cluster &>/dev/null \
  && pass "OAuth object exists" \
  || fail "OAuth object missing"

# 2. LDAP IDP configured
step "Checking LDAP identity provider"
oc get oauth cluster -o yaml | grep -q "type: LDAP" \
  && pass "LDAP identity provider configured" \
  || fail "LDAP identity provider NOT found"

# 3. Secret check
step "Checking bind password secret"
oc get secret $SECRET -n $NS &>/dev/null \
  && pass "Secret '$SECRET' exists in $NS" \
  || fail "Secret '$SECRET' missing"

# 4. ConfigMap check
step "Checking CA ConfigMap"
oc get configmap $CONFIGMAP -n $NS &>/dev/null \
  && pass "ConfigMap '$CONFIGMAP' exists in $NS" \
  || fail "ConfigMap '$CONFIGMAP' missing"

# 5. CA mounted in OAuth
step "Checking CA reference in OAuth"
oc get oauth cluster -o yaml | grep -q "$CONFIGMAP" \
  && pass "CA ConfigMap referenced in OAuth" \
  || fail "CA ConfigMap NOT referenced in OAuth"

# 6. Attribute mapping
step "Checking attribute mappings"
oc get oauth cluster -o yaml | grep -q "preferredUsername.*uid" \
  && pass "preferredUsername mapped to uid" \
  || fail "preferredUsername mapping incorrect"

# 7. User exists
step "Checking user creation"
oc get user $USER &>/dev/null \
  && pass "User '$USER' exists" \
  || fail "User '$USER' not created"

# 8. Identity mapped
step "Checking identity mapping"
IDENTITY=$(oc get identity -o jsonpath="{.items[?(@.user.name=='$USER')].metadata.name}")
[ -n "$IDENTITY" ] \
  && pass "Identity mapped ($IDENTITY)" \
  || fail "No identity mapped to user"

# 9. REAL LOGIN TEST
step "Testing real login (oc login)"

API=$(oc whoami --show-server)

oc login "$API" -u "$USER" -p "$PASS" --insecure-skip-tls-verify &>/dev/null

if [ $? -eq 0 ]; then
  pass "LDAP user login successful"
  oc logout &>/dev/null
else
  fail "LDAP user login FAILED"
fi

# FINAL RESULT
echo
echo "=============================================="
if [ $FAIL -eq 0 ]; then
  echo " 🎉 FINAL RESULT: PASS"
  echo " Q1 – LDAP Authentication COMPLETE"
else
  echo " ❌ FINAL RESULT: FAIL"
  echo " Fix the failed checks above"
fi
echo "=============================================="

