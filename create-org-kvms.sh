#! /bin/bash

# Add check for variables used
echo $EDGE_ORG
echo $APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR
echo $EXPORTED_ORG_DIR
echo $X_IMPORT_DIR

# Org level
KVMS=$(ls $EXPORTED_ORG_DIR/kvm/org)
for KVM in $KVMS
do
    echo KVM: ${EXPORTED_ORG_DIR}/kvm/org/${KVM} TO: ${X_IMPORT_DIR}/org__${KVM}__kvmfile__0.json
    python3 ${APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR}/convert-kvms-edge-x.py ${EXPORTED_ORG_DIR}/kvm/org/${KVM} | jq > ${X_IMPORT_DIR}/org__${KVM}__kvmfile__0.json
done
