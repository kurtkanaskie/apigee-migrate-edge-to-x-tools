#! /bin/bash

# Usage: ${APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR}/create-developers.sh

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

ROWS=50
ROWS_PLUS_ONE=$((ROWS + 1 ))
RESULT='/tmp/developers.json'
TMP_RESULT='/tmp/developers_batches.json'
BATCH='/tmp/developers_batch.json'

# Get the first batch of rows
curl -s -H "$EDGE_AUTH" "https://api.enterprise.apigee.com/v1/organizations/$EDGE_ORG/developers?expand=true&rows=$ROWS" | jq -r .developer[:$ROWS] > $RESULT
COUNT=$(jq '. | length' $RESULT)
echo FIRST_COUNT=$COUNT

while [ $COUNT -ne 0 ]
do
    # Get the last email for the startKey
    START_KEY=$(jq -r '.[-1].email' $RESULT)
    echo START_KEY=$START_KEY

    curl -s -H "$EDGE_AUTH" "https://api.enterprise.apigee.com/v1/organizations/$EDGE_ORG/developers?expand=true&rows=$ROWS_PLUS_ONE&startKey=$START_KEY" | jq -r .developer[1:] > $BATCH
    COUNT=$(jq '. | length' $BATCH)
    echo BATCH_COUNT=$COUNT

    # Slurp the batch into the apps
    if [ $COUNT -ne 0 ]; then
        jq -s '. | add' $RESULT $BATCH > $TMP_RESULT
        mv $TMP_RESULT $RESULT
    else
        echo DONE_COUNT=$(jq '. | length' $RESULT)
        # Add outer developer property to array, required for apigeecli import
        jq '{ "developer": . }' $RESULT > $TMP_RESULT
        mv $TMP_RESULT $RESULT
    fi
done

cp $RESULT $EDGE_EXPORT_DIR/developers.json

python3 ${APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR}/convert-developers-edge-x.py $EDGE_EXPORT_DIR/developers.json | jq  > $X_IMPORT_DIR/developers.json

