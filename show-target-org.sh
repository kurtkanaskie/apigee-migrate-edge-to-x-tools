#! /bin/bash

gcloud config get project
export ORG=$X_ORG
echo ORG=$ORG

read -p "OK to proceed (Y/n)? " i
if [ "$i" != "Y" ]
then
  echo aborted
  exit 1
fi
echo; echo Proceeding...

export TOKEN=$(gcloud auth print-access-token)

echo; echo Apps ================================
apigeecli -t $TOKEN --org=$ORG apps list --expand | jq -r .app[].name

echo; echo Products ================================
apigeecli -t $TOKEN --org=$ORG products list | jq -r .apiProduct[].name

echo; echo Developers ================================
apigeecli -t $TOKEN --org=$ORG developers list | jq -r .developer[].email

echo; echo APIs ================================
apigeecli -t $TOKEN --org=$ORG apis list | jq -r .proxies[].name

echo; echo Shared Flows ================================
apigeecli -t $TOKEN --org=$ORG sharedflows list | jq -r .sharedFlows[].name

echo; echo ORG KVMS ================================
apigeecli -t $TOKEN --org=$ORG kvms list | jq -r .[]

echo; echo ENV KVMS ================================
for ENV in $(apigeecli -t $TOKEN --org=$ORG environments list | jq -r .[])
do
    echo ENV KVMS: $ENV ================================

    apigeecli -t $TOKEN --org=$ORG --env=$ENV kvms list | jq -r .[]
done

echo; echo PROXY KVMS ================================
PROXIES=$(apigeecli -t $TOKEN --org=$ORG apis list | jq -r .proxies[].name)
for PROXY in $PROXIES
do
    KVMS=$(apigeecli -t $TOKEN --org=$ORG --proxy=$PROXY kvms list | jq -r .[])
    if [ "$KVMS" != "" ]
    then
      echo PROXY KVMS: $PROXY ================================
      echo $KVMS
    fi
done

echo; echo TARGETSERVERS ================================
for ENV in $(apigeecli -t $TOKEN --org=$ORG environments list | jq -r .[])
do
    echo ENV TARGETSERVERS: $ENV ================================

    apigeecli -t $TOKEN --org=$ORG --env=$ENV targetservers list | jq -r .[]
done
