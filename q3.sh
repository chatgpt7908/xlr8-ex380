#!/bin/bash
set -e

echo "=============================================="
echo " EX380 Q3 –  DEPPLOYING OADP"
echo "=============================================="

lab start backup-restore

echo "=============================================="
echo " EX380 Q3 –  DEPLOYMENT DONE"
echo "=============================================="

NS="lynx-web"
APP="lynx-app"
IMAGE="quay.io/ysachin/nginx:latest"
ROUTE_HOST="lynx.apps.ocp4.example.com"

echo "=============================================="
echo " EX380 Q3 –  AUTH APP DEPLOYMENT"
echo "=============================================="

# Namespace
oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${NS}
EOF

# NGINX CONFIG (Bitnami correct)
oc apply -n ${NS} -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: lynx-nginx-config
data:
  lynx.conf: |
    server {
      listen 8080;
      server_name _;

      location / {
        auth_basic "Lynx Secure Application";
        auth_basic_user_file /data/.htpasswd;

        root /opt/bitnami/nginx/html;
        index index.html;
      }
    }
EOF

# HTML CONTENT
oc apply -n ${NS} -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: lynx-html
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head><title>Lynx Application</title></head>
    <body>
      <h1>Lynx Application Restored</h1>
      <p>Protected application – audit access enabled</p>
    </body>
    </html>
EOF

# PVC + Deployment + Service + Route
oc apply -n ${NS} -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: lynx-data
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APP}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${APP}
  template:
    metadata:
      labels:
        app: ${APP}
    spec:
      initContainers:
      - name: init-auth
        image: registry.access.redhat.com/ubi9/httpd-24
        command:
        - /bin/bash
        - -c
        - |
          if [ ! -f /data/.htpasswd ]; then
            echo "Creating htpasswd in PVC"
            htpasswd -bc /data/.htpasswd admin 'Admin1andia!1958'
            chmod 644 /data/.htpasswd
          else
            echo "Auth file exists, skipping"
          fi
        volumeMounts:
        - name: lynx-data
          mountPath: /data

      containers:
      - name: nginx
        image: ${IMAGE}
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: lynx-data
          mountPath: /data
        - name: nginx-config
          mountPath: /opt/bitnami/nginx/conf/server_blocks/lynx.conf
          subPath: lynx.conf
        - name: html
          mountPath: /opt/bitnami/nginx/html/index.html
          subPath: index.html

      volumes:
      - name: lynx-data
        persistentVolumeClaim:
          claimName: lynx-data
      - name: nginx-config
        configMap:
          name: lynx-nginx-config
      - name: html
        configMap:
          name: lynx-html
---
apiVersion: v1
kind: Service
metadata:
  name: lynx-service
spec:
  selector:
    app: ${APP}
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: lynx
spec:
  host: ${ROUTE_HOST}
  to:
    kind: Service
    name: lynx-service
  port:
    targetPort: 8080
  tls:
    termination: edge
EOF

echo "=============================================="
echo " DEPLOYMENT COMPLETE"
echo " URL  : https://${ROUTE_HOST}"
echo " USER : admin"
echo " PASS : Admin1andia!1958"
echo "=============================================="


echo "=============================================="
echo " EX380 Q3 –  CREATING SCHEDULE AND BACKUP"
echo "=============================================="


NS="lynx-web"
SCHEDULE="lynx-web-schedule"
BACKUP="restore-lynx-web"

VELERO="oc -n openshift-adp exec deployment/velero -c velero -- ./velero"

echo "=============================================="
echo " EX380 Q3 – BACKUP, WAIT & ACCIDENTAL DELETE"
echo "=============================================="
$VELERO delete  schedule --all --confirm
$VELERO delete  backup --all --confirm
$VELERO delete  restore --all --confirm


echo "[1/5] Creating scheduled backup"

${VELERO} schedule create ${SCHEDULE} \
  --schedule "0 */6 * * *" \
  --include-namespaces ${NS} \
  --snapshot-volumes=true \
  --ttl 168h

echo "[2/5] Creating backup FROM schedule"
${VELERO} backup create ${BACKUP} \
  --from-schedule ${SCHEDULE}

echo "[3/5] Waiting for backup to COMPLETE..."

while true; do
  STATUS=$(${VELERO} backup get ${BACKUP} -o json 2>/dev/null \
    | grep -o '"phase": "[^"]*"' \
    | awk -F'"' '{print $4}')

  if [[ "${STATUS}" == "Completed" ]]; then
    echo "      Backup ${BACKUP} completed successfully"
    break
  elif [[ "${STATUS}" == "Failed" || "${STATUS}" == "PartiallyFailed" ]]; then
    echo "      Backup failed ❌"
    exit 1
  else
    echo "      Backup status: ${STATUS} (waiting...)"
  fi

  sleep 5
done

echo "[4/5] Simulating ACCIDENTAL deletion of application"
oc delete namespace ${NS}

echo "[5/5] Done"

echo "=============================================="
echo " Application was accidentally deleted"
echo " Backup available : ${BACKUP}"
echo
echo " Next step for user:"
echo " 👉 Restore the application from backup"
echo "=============================================="


