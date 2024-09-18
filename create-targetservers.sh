#! /bin/bash

# Add check for variables used
echo $EDGE_ORG
echo $APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR
echo $EDGE_EXPORT_DIR
echo $ENVS
echo $X_IMPORT_DIR


for E in $ENVS
do
    export EXPORTED_DIR=$EDGE_EXPORT_DIR/data-env-${E}

    TS=$(ls $EXPORTED_DIR/targetservers)
    # TS="pingstatus-v1 pingstatus-oauth-v1 oauth-v1"

    echo TS $TS TS: ${EXPORTED_DIR}/${TS} TO: ${IMPORT_DIR}/{E}__targetservers.json

    OUTPUT="["
    for T in $TS
    do
        TMP=$(cat $EXPORTED_DIR/targetservers/$T)
        OUTPUT="${OUTPUT}${TMP},"
    done
    OUTPUT="${OUTPUT%?}"
    OUTPUT="${OUTPUT}]"
    echo $OUTPUT | jq > /tmp/${E}__targetservers.json

    python3 $APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR/convert-targetservers-edge-x.py /tmp/${E}__targetservers.json | jq > ${X_IMPORT_DIR}/${E}__targetservers.json
done


