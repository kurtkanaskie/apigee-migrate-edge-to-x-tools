#! /bin/bash

gcloud config get project
export ORG=$X_ORG
echo ORG=$ORG

echo '*******************************************'
echo; echo WARNING WARNING WARNING
echo '*******************************************'

read -p "OK to proceed (Y/n)? " i
if [ "$i" != "Y" ]
then
  echo aborted
  exit 1
fi
echo Proceeding...

export TOKEN=$(gcloud auth print-access-token)

echo; echo Cleaning Apps
for APP in $(apigeecli -t $TOKEN --org=$ORG apps list | jq -r .app[].appId)
do 
    echo APP: $APP
    apigeecli -t $TOKEN --org=$ORG apps delete --id=$APP
done

echo; echo Cleaning API Products
for PRODUCT in $(apigeecli -t $TOKEN --org=$ORG products list | jq -r .apiProduct[].name)
do 
    echo PRODUCT: $PRODUCT
    apigeecli -t $TOKEN --org=$ORG products delete --name=$PRODUCT
done
echo; echo Cleaning Developers
for DEVELOPER in $(apigeecli -t $TOKEN --org=$ORG developers list | jq -r .developer[].email)
do 
    echo DEVELOPER: $DEVELOPER
    apigeecli -t $TOKEN --org=$ORG developers delete --email=$DEVELOPER
done

echo; echo Cleaning Proxies
for API in $(apigeecli -t $TOKEN --org=$ORG apis list | jq -r .proxies[].name)
do 
    echo API: $API
    apigeecli -t $TOKEN --org=$ORG apis delete --name=$API
done

echo; echo Cleaning SharedFlows
for SF in $(apigeecli -t $TOKEN --org=$ORG sharedflows list | jq -r .sharedFlows[].name)
do 
    echo SF: $SF
    apigeecli -t $TOKEN --org=$ORG sharedflows delete --name=$SF
done

echo; echo Cleaning ORG KVMs
for KVM in $(apigeecli -t $TOKEN --org=$ORG kvms list | jq -r .[])
do 
    echo KVM: $KVM
    apigeecli -t $TOKEN --org=$ORG kvms delete --name=$KVM
done

echo; echo Cleaning ENV KVMs
for ENV in $(apigeecli -t $TOKEN --org=$ORG environments list | jq -r .[])
do
    echo ENV: $ENV

    for KVM in $(apigeecli -t $TOKEN --org=$ORG --env=$ENV kvms list | jq -r .[])
    do 
        echo ENV KVM: $KVM
        apigeecli -t $TOKEN --org=$ORG --env=$ENV kvms delete --name=$KVM
    done
done

PROXIES=$(apigeecli -t $TOKEN --org=$ORG apis list | jq -r .proxies[].name)
for PROXY in $PROXIES
do
    KVMS=$(apigeecli -t $TOKEN --org=$ORG --proxy=$PROXY kvms list | jq -r .[])
    if [ "$KVMS" != "" ]
    then
      echo PROXY KVMS: $PROXY ================================
      for KVM in $KVMS
        do 
            echo PROXY KVMS: $PROXY $KVM ================================
            echo apigeecli --org=$ORG --proxy=$PROXY kvms delete --name=$KVM
            # apigeecli -t $TOKEN --org=$ORG --proxy=$PROXY kvms delete --name=$KVM
        done
    fi
done

echo TARGETSERVERS ================================
for ENV in $(apigeecli -t $TOKEN --org=$ORG environments list | jq -r .[])
do
    echo ENV TARGETSERVERS: $ENV ================================

    for TS in $(apigeecli -t $TOKEN --org=$ORG --env=$ENV targetservers list | jq -r .[])
    do
        echo TS: $TS
        # echo apigeecli --org=$ORG --env=$ENV targetservers delete --name=$TS
        apigeecli -t $TOKEN --org=$ORG --env=$ENV targetservers delete --name=$TS
    done
done
