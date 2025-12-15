#!/bin/bash

KUBECONFIG="/home/student/kubeconfig-acme.config"
USER="acme-auditor"
GROUP="acme-corp"

echo "=============================================="
echo " EX380 Q2 – CLIENT CERT PASS/FAIL VALIDATION"
echo "=============================================="
echo

FAIL=0
pass() { echo "[OK] $1"; }
fail() { echo "[FAIL] $1"; FAIL=1; }
step() { echo; echo "▶ $1"; }

# 1. Verify identity
step "Verifying client certificate identity"
oc whoami --kubeconfig $KUBECONFIG &>/dev/null \
  && pass "Client certificate authentication works" \
  || fail "Client certificate authentication FAILED"

# 2. Group exists
step "Checking group existence"
oc get group $GROUP &>/dev/null \
  && pass "Group '$GROUP' exists" \
  || fail "Group '$GROUP' missing"

# 3. User is in group
step "Checking group membership"
oc get group $GROUP -o yaml | grep -q "$USER" \
  && pass "User '$USER' is member of '$GROUP'" \
  || fail "User '$USER' not part of '$GROUP'"

# 4. Can view pods (cluster-wide)
step "Checking READ access to pods (cluster-wide)"
oc auth can-i get pods -A \
  --as $USER --as-group $GROUP | grep -q yes \
  && pass "User can view pods cluster-wide" \
  || fail "User CANNOT view cluster-wide pods"

# 5. Can view users (audit-level visibility)
step "Checking READ access to users"
oc auth can-i get users -A \
  --as $USER --as-group $GROUP | grep -q yes \
  && pass "User can view users (audit access)" \
  || fail "User cannot view users"

# 6. Must NOT create projects
step "Checking project CREATE restriction"
oc auth can-i create project -A \
  --as $USER --as-group $GROUP | grep -q no \
  && pass "User cannot create projects (expected)" \
  || fail "User CAN create projects (NOT allowed)"

# FINAL RESULT
echo
echo "=============================================="
if [ $FAIL -eq 0 ]; then
  echo " 🎉 FINAL RESULT: PASS"
  echo " Q2 – Client Certificate Audit Access COMPLETE"
else
  echo " ❌ FINAL RESULT: FAIL"
  echo " Fix the failed checks above"
fi
echo "=============================================="

