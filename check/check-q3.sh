#!/bin/bash

NS="lynx-web"
APP="lynx-app"
ROUTE_HOST="lynx.apps.ocp4.example.com"
USER="admin"
PASS="Admin1andia!1958"

echo "=============================================="
echo " EX380 Q3 – FINAL VALIDATION"
echo "=============================================="

FAIL=0

echo "[1/7] Checking namespace"
oc get ns ${NS} >/dev/null 2>&1 || {
  echo "❌ Namespace ${NS} not found"
  FAIL=1
}
echo "✅ Namespace exists"

echo "[2/7] Checking deployment"
oc get deploy ${APP} -n ${NS} >/dev/null 2>&1 || {
  echo "❌ Deployment ${APP} not found"
  FAIL=1
}
echo "✅ Deployment exists"

echo "[3/7] Checking pod status"
POD=$(oc get pod -n ${NS} -l app=${APP} -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
STATUS=$(oc get pod -n ${NS} ${POD} -o jsonpath='{.status.phase}' 2>/dev/null)

if [[ "${STATUS}" != "Running" ]]; then
  echo "❌ Pod not running (status=${STATUS})"
  FAIL=1
else
  echo "✅ Pod running"
fi

echo "[4/7] Checking PVC"
oc get pvc lynx-data -n ${NS} >/dev/null 2>&1 || {
  echo "❌ PVC lynx-data missing"
  FAIL=1
}
echo "✅ PVC exists"

echo "[5/7] Checking route"
oc get route lynx -n ${NS} >/dev/null 2>&1 || {
  echo "❌ Route lynx missing"
  FAIL=1
}
echo "✅ Route exists"

echo "[6/7] Checking application access (auth + content)"
HTTP_CODE=$(curl -k -s -o /tmp/lynx.out -w "%{http_code}" \
  -u "${USER}:${PASS}" https://${ROUTE_HOST})

if [[ "${HTTP_CODE}" != "200" ]]; then
  echo "❌ Application not accessible (HTTP ${HTTP_CODE})"
  FAIL=1
else
  grep -q "Lynx Application Restored" /tmp/lynx.out && \
    echo "✅ Application content verified" || {
      echo "❌ Unexpected application content"
      FAIL=1
    }
fi

rm -f /tmp/lynx.out

echo "[7/7] Final result"
echo "----------------------------------------------"

if [[ "${FAIL}" -eq 0 ]]; then
  echo "🎉 RESULT: PASS"
  echo "Application successfully restored from backup"
else
  echo "🚨 RESULT: FAIL"
  echo "One or more validation checks failed"
fi

echo "=============================================="

