#! /bin/bash

# Add check for variables used
echo $EDGE_ORG
echo $ENVS
echo $APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR
echo $EDGE_EXPORT_DIR
echo $X_IMPORT_DIR

for E in $ENVS
do
    export EXPORTED_DIR=$EDGE_EXPORT_DIR/data-env-${E}/kvm/env/$E
    echo $E
    KVMS=$(ls $EXPORTED_DIR)
    # KVMS="pingstatus-v1 pingstatus-oauth-v1 oauth-v1 oauth-v1-jwt-key"

    for KVM in $KVMS
    do
        # ls -l ${EXPORTED_DIR}/${KVM}
        
        echo Env $E KVM: ${EXPORTED_DIR}/${KVM} TO: ${IMPORT_DIR}/env__${E}__${KVM}__kvmfile__0.json
        python3 ${APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR}/convert-kvms-edge-x.py ${EXPORTED_DIR}/${KVM} | jq > ${X_IMPORT_DIR}/env__${E}__${KVM}__kvmfile__0.json
    done
done


