# Migrate Apigee Edge to X

Self service migration from Apigee Edge to Apigee X. 

This is a set of tools, scripts and code to export Apigee Edge data, convert to Apigee X format, and import into Apigee X.

Importing proxies and sharedflows will succeed if they do not use unsupported policies or features in X. The import tool (apigeecli) will show details of what policies and features are not supported.

Importing Developers converts emails to lower case.
Importing API Products and Apps copies the credentials (API key and secret).

Flow: 

1. Export from Edge using apigee-migrate-tool and Edge API (edge-export folder) 
2. Convert Edge data to X format using bash and python (x-import folder)
3. Import to X using apigeecli

# Coverage

- [ ] Org level  
  - [x] Proxies  
  - [x] Sharedflows  
  - [x] KVMs  
    - [x] Encrypted entries only with kvm helper proxy  
  - [x] Developers  
  - [x] API Products  
  - [x] Apps and keys  
  - [ ] Reports  
- [ ] Env level  
  - [x] Target Servers  
     - [ ] Keystores, Truststores  
  - [x] KVMs  
     - [ ] Encrypted entries only with kvm helper proxy  
- [ ] Proxy level  
  - [x] KVMs  
     - [ ] Encrypted entries only with kvm helper proxy

# Background

[Differences between Apigee Edge and Apigee X](https://docs.apigee.com/migration-to-x/compare-apigee-edge-to-apigee-x?hl=en)  
[Apigee Edge to Apigee X migration antipatterns](https://docs.apigee.com/migration-to-x/migration-antipatterns)

# Prerequisites

Export from Edge  
- [apigee-migrate-tool](https://github.com/apigeecs/apigee-migrate-tool)  
  - npm, node, grunt  
- [Edge API](https://apidocs.apigee.com/apis)  
  - [get\_token, acurl](https://docs.apigee.com/api-platform/system-administration/auth-tools) or user credentials without 2 factor authentication  
- Convert to X format  
  - Custom [Python3](https://www.python.org/) scripts  
- Import to X  
  - [apigeecli](https://github.com/apigee/apigeecli)  
  - [Apigee API](https://cloud.google.com/apigee/docs/reference/apis/apigee/rest)  
- Miscellaneous  
  - curl, git, jq

# Setup and Environment Variables

```
##############################################################
# Create a top level working directory to hold the Edge export data, tools and X import data
export EDGE_X_MIGRATION_DIR=$HOME/work/APIGEEX/edge-x-migration
mkdir -p $EDGE_X_MIGRATION_DIR
cd $EDGE_X_MIGRATION_DIR

##############################################################
# Install apigee-migrate-edge-to-x scripts and tools (this repo)
git clone https://github.com/kurtkanaskie/apigee-migrate-edge-to-x-tools.git

# Install Python3
python3 --version
Python 3.11.5

# Install apigee-migrate tool
sudo npm install -g grunt-cli
git clone https://github.com/apigeecs/apigee-migrate-tool.git
cd apigee-migrate-tool
npm install

# Install https://github.com/apigee/apigeecli
curl -L https://raw.githubusercontent.com/apigee/apigeecli/main/downloadLatest.sh | sh -
apigeecli -v
apigeecli version 2.4.2 date: 2024-09-13T12:42:30Z [commit: 494e144]

##############################################################
# Set env variables
export EDGE_X_MIGRATION_DIR=$HOME/work/APIGEEX/edge-x-migration
export EDGE_ORG=amer-demo13
export ENVS="test prod"
export EDGE_EXPORT_DIR=$EDGE_X_MIGRATION_DIR/edge-export
mkdir $EDGE_EXPORT_DIR
export EXPORTED_ORG_DIR=$EDGE_EXPORT_DIR/data-org-${EDGE_ORG}

export X_ORG=apigeex-custom-non-prod
export X_IMPORT_DIR=$EDGE_X_MIGRATION_DIR/x-import
mkdir $X_IMPORT_DIR

export APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR=$EDGE_X_MIGRATION_DIR/apigee-migrate-edge-to-x-tools
export APIGEE_MIGRATE_TOOL_DIR=$EDGE_X_MIGRATION_DIR/apigee-migrate-tool

cd $EDGE_X_MIGRATION_DIR
```

# Export from Edge

Using apigee-migrate-tool and Edge APIs from $APIGEE_MIGRATE_TOOL_DIR

```
cd $APIGEE_MIGRATE_TOOL_DIR

# Create config.js files for each of the environments to be exported
# NOTE: apigee-migrate-tool only supports Basic authorization so you’ll need to have a user without 2-factor authentication

cat config-test.js
module.exports = {
    from: {
        version: '1',
        url: 'https://api.enterprise.apigee.com',
        userid: 'kurt.kanaskie@gmail.com',
        passwd: 'secret',
        org: 'amer-demo13',
        env: 'test'
    },
    to: {
        version: '1',
        url: 'https://api.enterprise.apigee.com',
        userid: 'me@example.com',
        passwd: 'mypassword',
        org: 'my-new-org',
        env: 'my-new-env'
    }
} ;

cat config-prod.js
module.exports = {
    from: {
        version: '1',
        url: 'https://api.enterprise.apigee.com',
        userid: 'kurt.kanaskie@gmail.com',
        passwd: 'secret',
        org: 'amer-demo13',
        env: 'prod'
    },
    to: {
        version: '1',
        url: 'https://api.enterprise.apigee.com',
        userid: 'me@example.com',
        passwd: 'mypassword',
        org: 'my-new-org',
        env: 'my-new-env'
    }
} ;

cp config-test.js config.js

# Org level
grunt exportProxies
grunt exportSharedFlows 
# grunt exportProducts # use output from Edge API instead
# grunt exportApps # use output from Edge API instead
# grunt exportDevs  # use output from Edge API instead
grunt exportReports

grunt exportOrgKVM
# Remove unwanted KVMs
rm data/kvm/org/CustomReportsamer-demo13*
rm data/kvm/org/privacy

# Proxy level
grunt exportProxyKVM


# NOTE: Since apigee-migrate-tool does not create a sub-directory for envs for target servers or flowhooks, do the extract at the org level and for each env level, keeping directories separate

mv data $EDGE_EXPORT_DIR/data-org-${EDGE_ORG}

# Env level
for E in ${ENVS}; do
    cp config-$E.js config.js
    grunt exportEnvKVM
    grunt exportTargetServers
    grunt exportFlowHooks
   
    mv data $EDGE_EXPORT_DIR/data-env-${E}
done

export EDGE_TOKEN=$(get_token)
export EDGE_AUTH="Authorization: Bearer $EDGE_TOKEN"

# Verify credentials
curl -i -H "$EDGE_AUTH" https://api.enterprise.apigee.com/v1/organizations/$EDGE_ORG
# Extract data
curl -H "$EDGE_AUTH" https://api.enterprise.apigee.com/v1/organizations/$EDGE_ORG/apiproducts?expand=true | jq > $EDGE_EXPORT_DIR/apiproducts.json
curl -H "$EDGE_AUTH" https://api.enterprise.apigee.com/v1/organizations/$EDGE_ORG/developers?expand=true | jq > $EDGE_EXPORT_DIR/developers.json
curl -H "$EDGE_AUTH" https://api.enterprise.apigee.com/v1/organizations/$EDGE_ORG/apps?expand=true | jq > $EDGE_EXPORT_DIR/apps.json
```

# Convert from Edge to X apigeecli format
Reformat the output for apigeecli format and move to $X_IMPORT_DIR

```
cd $X_IMPORT_DIR

##############################################################
# Org Level
# Proxies and Shared Flows

mkdir proxies sharedflows
cp $EDGE_EXPORT_DIR/data-org-${EDGE_ORG}/proxies/* proxies
cp $EDGE_EXPORT_DIR/data-org-${EDGE_ORG}/sharedflows/* sharedflows

# API Products, Developers, Apps

python3 ${APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR}/convert-products-edge-x.py $EDGE_EXPORT_DIR/apiproducts.json | jq  > $X_IMPORT_DIR/products.json

python3 ${APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR}/convert-developers-edge-x.py $EDGE_EXPORT_DIR/developers.json | jq  > $X_IMPORT_DIR/developers.json

python3 ${APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR}/convert-apps-edge-x.py $EDGE_EXPORT_DIR/apps.json | jq  > $X_IMPORT_DIR/apps.json

# Org KVMs, Proxy KVMs

$APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR/create-org-kvms.sh
$APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR/create-proxy-kvms.sh

##############################################################
# Env Level

# KVMs
$APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR/create-env-kvms.sh

# Target Servers
$APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR/create-targetservers.sh
```

# Import to X via apigeecli
Use apigeecli to import converted data from $X_IMPORT_DATA

```
cd $X_IMPORT_DIR
export TOKEN=$(gcloud auth print-access-token)

# Enable debug for more details using: APIGEECLI_DEBUG=true apigeecli …

#########################################
# Proxies
apigeecli --token=$TOKEN --org=$ORG apis import --folder=$X_IMPORT_DIR/proxies

#########################################
# Shared Flows
apigeecli --token=$TOKEN --org=$ORG sharedflows import --folder=$X_IMPORT_DIR/sharedflows

#########################################
apigeecli --token=$TOKEN --org=$ORG kvms import --folder=$X_IMPORT_DIR

#########################################
# Target Servers
for E in ${ENVS}; do
    apigeecli --token=$TOKEN --org=$ORG --env=$E targetservers import --file $X_IMPORT_DIR/${E}__targetservers.json
done

#########################################
apigeecli --token=$TOKEN --org=$X_ORG products import --file=$X_IMPORT_DIR/products.json
apigeecli --token=$TOKEN --org=$X_ORG developers import --file=$X_IMPORT_DIR/developers.json
apigeecli --token=$TOKEN --org=$X_ORG apps import --file=$X_IMPORT_DIR/apps.json --dev-file=$X_IMPORT_DIR/developers.json
```

# Notes

As you run the import commands, especially for proxies and shared flows, observe any errors that are output.  
This will let you know what policies and features are not supported (StatisticsCollector policy, NodeJS base proxies, etc.)

# Show what's been imported
```
$APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR/show-target-org.sh
Your active configuration is: [apigeex-custom-non-prod]
apigeex-custom-non-prod
ORG=apigeex-custom-non-prod
OK to proceed (Y/n)? Y

Proceeding...

Apps ================================
oauth-v1-app-test
pingstatus-v1-app-test
pingstatus-oauth-v1-app-test
oauth-v1-app-prod
pingstatus-v1-app-prod
pingstatus-oauth-v1-app-prod
...

Developers ================================
kurtkanaskie@google.com
kurtkanaskie+postpaid@google.com
cicd-developer-prod@google.com
kurtkanaskie+appdev@google.com
kurtkanaskie+prepaid@google.com
cicd-developer-test@google.com
...

APIs ================================
kvm-demo
oauth-v1
oauth-v1-mock
persons-v1
pingstatus-oauth-v1
pingstatus-v1
pingstatus-v1-mock
...

Shared Flows ================================
cors-v1
post-proxy
post-target
pre-proxy
pre-target
proxy-error-handling-v1
set-logging-values-v1
...

ORG KVMS ================================
org-config
ENV KVMS ================================
ENV KVMS: prod ================================
kvm-demo
kvm-parse
oauth-v1
pingstatus-v1
...

ENV KVMS: test ================================
kvm-demo
kvm-parse
oauth-v1
pingstatus-v1
...

PROXY KVMS ================================
PROXY KVMS: helloworld ================================
kvm-config
PROXY KVMS: kvm-demo ================================
kvm-demo
PROXY KVMS: pingstatus-v1 ================================
pingstatus-v1-kvm1
TARGETSERVERS ================================
ENV TARGETSERVERS: prod ================================
oauth-v1
pingstatus-oauth-v1
...
ENV TARGETSERVERS: test ================================
oauth-v1
pingstatus-oauth-v1
...
```

# Clean target org

**WARNING WARNING WARNING:** Use with caution, it deletes what's there, not just what you imported!
```
$APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR/clearn-target-org.sh
Your active configuration is: [apigeex-custom-non-prod]
apigeex-custom-non-prod
ORG=apigeex-custom-non-prod
OK to proceed (Y/n)? Y
...
```

# Issues

### Issue: KVM import does not continue on error.
`apigeecli kvms import` looks for keyvaluemap files in the $X_IMPORT_DIR for org level, env level and proxy level. If the KVM already exists, an error is thrown and apigeecli does not proceed.

### Issue: private KVM entries not exported.
But you can use an Edge API Facade proxy (a.k.a. kvm-helper proxy) to get the values using KVM policy.


# Support
This is not an officially supported Google product.


