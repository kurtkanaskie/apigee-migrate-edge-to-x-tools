#! /bin/bash

TBD
echo $EDGE_ORG
echo $ENVS
echo $APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR
echo $EDGE_EXPORT_DIR
echo $X_IMPORT_DIR

# Proxy level
PROXIES=$(ls $EXPORTED_ORG_DIR/kvm/proxy)
for PROXY in $PROXIES
do
    KVMS=$(ls $EXPORTED_ORG_DIR/kvm/proxy/$PROXY)
    for KVM in $KVMS
    do
        echo PROXY KVM: $EXPORTED_ORG_DIR/kvm/proxy/$PROXY/${KVM} TO: ${X_IMPORT_DIR}/proxy__${PROXY}__${KVM}__kvmfile__0.json
        python3 ${APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR}/convert-kvms-edge-x.py $EXPORTED_ORG_DIR/kvm/proxy/$PROXY/${KVM} | jq > ${X_IMPORT_DIR}/proxy__${PROXY}__${KVM}__kvmfile__0.json
    done
done


