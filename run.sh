#!/bin/sh
VELERO="oc -n openshift-adp exec deployment/velero -c velero -- ./velero"

$VELERO delete  schedule --all --confirm
$VELERO delete  backup --all --confirm
$VELERO delete  restore --all --confirm
