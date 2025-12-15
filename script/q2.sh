#!/bin/bash

clear
echo "=============================================="
echo " EX380 MOCK EXAM – QUESTION 2"
echo " CLIENT CERTIFICATE (AUDIT ACCESS)"
echo "=============================================="
echo

echo "[*] Lab environment ready (no pre-lab command required)"
echo

cat <<'EOF'
EX380 – Question 2: Create and Use a Client Certificate

The ACME Security company has been hired to audit your OpenShift cluster.
You need to create a client certificate that allows the auditor to examine
everything in the cluster but does not allow the auditor to make any changes.

Requirements:
-------------
- A client certificate exists with the username: acme-auditor
- A group exists with the name: acme-corp
- Members of this group have access to the cluster role: cluster-reader
- The client certificate exists at: /home/student/kubeconfig-acme.config
- The client certificate must not be able to create or delete projects
- The client certificate must be able to view all pods in the cluster

EOF

echo
echo "----------------------------------------------"
echo " Start working on Question 2"
echo "----------------------------------------------"

