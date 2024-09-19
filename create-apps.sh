#! /bin/bash

# Usage: ${APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR}/create-apps.sh

# Add check for variables used
echo $EDGE_ORG
echo $APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR
echo $EDGE_EXPORT_DIR
echo $X_IMPORT_DIR

read -p "OK to proceed (Y/n)? " i
if [ "$i" != "Y" ]
then
  echo aborted
  exit 1
fi
echo; echo Proceeding...

RESULT='/tmp/apps.json'
TMP_RESULT='/tmp/apps_batches.json'
BATCH='/tmp/apps_batch.json'

# Get the first batch
# BUG: apptype doesn't filter results
curl -s -H "$EDGE_AUTH" "https://api.enterprise.apigee.com/v1/organizations/$EDGE_ORG/apps?expand=true&apptype=developer" | jq -r .app > $RESULT
COUNT=$(jq '. | length' $RESULT)
echo FIRST_COUNT=$COUNT

while [ $COUNT -ne 0 ]
do
    # Get the last appId for the startKey
    START_KEY=$(jq -r '.[-1].appId' $RESULT)
    # echo START_KEY=$START_KEY

    # Get all the records after the start key
    curl -s -H "$EDGE_AUTH" "https://api.enterprise.apigee.com/v1/organizations/$EDGE_ORG/apps?expand=true&apptype=developer&startKey=$START_KEY" | jq -r .app[1:] > $BATCH
    COUNT=$(jq '. | length' $BATCH)
    echo BATCH_COUNT=$COUNT

    # Slurp the batch into the apps
    if [ $COUNT -ne 0 ]; then
        jq -s '. | add' $RESULT $BATCH > $TMP_RESULT
        mv $TMP_RESULT $RESULT
    else
        echo DONE_COUNT=$(jq '. | length' $RESULT)
    fi
done

cp $RESULT $EDGE_EXPORT_DIR/apps.json

python3 ${APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR}/convert-apps-edge-x.py $EDGE_EXPORT_DIR/apps.json | jq  > $X_IMPORT_DIR/apps.json

