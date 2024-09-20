# Migrate Apigee Edge to X

Self service migration from Apigee Edge to Apigee X. 

This is a set of tools, scripts and code to export Apigee Edge data, convert to Apigee X format, and import into Apigee X.

Importing proxies and sharedflows will succeed if they do not use unsupported policies or features in X. The import tool (apigeecli) will show details of what policies and features are not supported.

Importing Developers requires emails to lower case. This may be an issue as Apigee Edge emails are case sensitive, meaning that "CaseSensitive@any.com" and "casesensitive@any.com" are different developers in Edge but they will be the same in X.

Importing Developers and Apps copies the credentials (API key and secret).

Flow: 

1. Export from Edge using apigee-migrate-tool and Edge API (writes to $EDGE_EXPORT_DIR)
2. Convert Edge data to X format using bash and python (writes to $X_IMPORT_DIR)
3. Import to X using apigeecli (reads from $X_IMPORT_DIR)

# Coverage

- [ ] Org level  
  - [x] Proxies  
  - [x] Sharedflows  
  - [x] KVMs  
    - [x] Encrypted entries only with kvm helper proxy  
  - [x] Developers  
  - [x] API Products  
  - [x] Apps and keys  
  - [ ] Companies, Company Developers and Company Apps - need to convert to AppGroups 
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

Convert to X format
  - Custom [Python3](https://www.python.org/) scripts  

Import to X
  - [apigeecli](https://github.com/apigee/apigeecli)  
  - [Apigee API](https://cloud.google.com/apigee/docs/reference/apis/apigee/rest)
    - [gcloud](https://cloud.google.com/sdk/gcloud)

Miscellaneous
  - curl, git, jq, tree

# Set up and Environment Variables
Consider using [glcoud config](https://cloud.google.com/sdk/gcloud/reference/config) to create a configurations for your Apigee X orgs to easily switch between them.

## Set up
Clone and install [apigee-migrate-tool](https://github.com/apigeecs/apigee-migrate-tool).\
Install [python3](https://www.python.org/downloads/), apigeecli and any other required tools.\
Clone [apigee-migrate-edge-to-x-tools](https://github.com/kurtkanaskie/apigee-migrate-edge-to-x-tools) (this repository).
```
# Create a top level working directory to hold the Edge export data, tools and X import data
export EDGE_X_MIGRATION_DIR=$HOME/work/APIGEEX/edge-x-migration
mkdir -p $EDGE_X_MIGRATION_DIR
cd $EDGE_X_MIGRATION_DIR

# Install apigee-migrate-edge-to-x-tools scripts and tools (this repo)
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
```
## Set Environment Variables
Specify your top level working directory: EDGE_X_MIGRATION_DIR\
Specify your values for Apigee Edge: EDGE_ORG and ENVS\
Specify your values for Apigee X: X_ORG\
The rest can be left as they are.

**TIP:** copy the `set_env_example.sh` file to `set_env.sh` and edit to use your values, then use `source set_env.sh` to set the environment variables.

```
export EDGE_X_MIGRATION_DIR=$HOME/work/APIGEEX/edge-x-migration
export EDGE_ORG=your_edge_org_name
export ENVS="env1 env2"

export EDGE_EXPORT_DIR=$EDGE_X_MIGRATION_DIR/edge-export
mkdir $EDGE_EXPORT_DIR
export EXPORTED_ORG_DIR=$EDGE_EXPORT_DIR/data-org-${EDGE_ORG}

export X_ORG=your_x_org_name
export X_IMPORT_DIR=$EDGE_X_MIGRATION_DIR/x-import
mkdir $X_IMPORT_DIR

export APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR=$EDGE_X_MIGRATION_DIR/apigee-migrate-edge-to-x-tools
export APIGEE_MIGRATE_TOOL_DIR=$EDGE_X_MIGRATION_DIR/apigee-migrate-tool
```

## Set Edge Authorization
Specify your username and password for your machine user or use the [get_token](https://docs.apigee.com/api-platform/system-administration/using-gettoken) tool.
```
# Using a machine user credentials with base64:
B64UNPW=$(echo -n 'username:password' | base64)
export EDGE_AUTH="Authorization: Basic $B64UNPW"

# Using get_token:
export EDGE_TOKEN=$(get_token)
export EDGE_AUTH="Authorization: Bearer $EDGE_TOKEN"

# Verify credentials by getting the response from you Edge org
curl -i -H "$EDGE_AUTH" https://api.enterprise.apigee.com/v1/organizations/$EDGE_ORG
```

# Export from Edge

Uses apigee-migrate-tool and Edge APIs in scripts.

## Set up config.js files
Create `config-$ENV.js` files for each environment and be sure to copy the lowest level env to `config.js` as apigee-migrate-tool only uses that file. Don't worry about the `to:` configuration, that is not being used.

**NOTE:** apigee-migrate-tool only supports Basic authorization so you’ll need to have a machine user without 2-factor authentication.
```
cd $APIGEE_MIGRATE_TOOL_DIR

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
```
## Export Resources from Edge
The apigee-migrate-tool outputs data to the `data`.

**NOTE:** Since apigee-migrate-tool does not create a sub-directory for envs for target servers or flowhooks, do the extract at the org level and then for each environment separate directories.
```
cp config-test.js config.js

# Org level
grunt exportProxies
grunt exportSharedFlows 
grunt exportReports

grunt exportOrgKVM
# Remove any unwanted KVMs, for example:
rm data/kvm/org/CustomReports${EDGE_ORG}*
rm data/kvm/org/privacy

# Proxy level
grunt exportProxyKVM

mv data $EDGE_EXPORT_DIR/data-org-${EDGE_ORG}

# Env level
for ENV in ${ENVS}; do
    echo ===========================
    echo ENV=$ENV
    cp config-$ENV.js config.js
    grunt exportEnvKVM
    grunt exportTargetServers
    grunt exportFlowHooks
   
    mv data $EDGE_EXPORT_DIR/data-env-${ENV}
done
```
View the results of the export, for example:
```
ls -l $EDGE_EXPORT_DIR
-rw-r--r--  1 user  primarygroup  175249 Sep 20 10:43 apps.json
drwxr-xr-x  5 user  primarygroup     160 Sep 20 10:27 data-env-prod
drwxr-xr-x  5 user  primarygroup     160 Sep 20 10:27 data-env-test
drwxr-xr-x  6 user  primarygroup     192 Sep 20 10:13 data-org-amer-demo13
-rw-r--r--  1 user  primarygroup   56075 Sep 20 10:43 developers.json
-rw-r--r--  1 user  primarygroup   64793 Sep 20 10:43 products.json
```
```
tree $EDGE_EXPORT_DIR
├── apps.json
├── data-env-prod
│   ├── flowhooks
│   │   └── flow_hook_config
│   ├── kvm
│   │   └── env
│   │       └── prod
│   │           ├── GeoIPFilter
│   │           └── GetLogValues
│   └── targetservers
│       ├── oauth-v1
│       └── pingstatus-v1-sharedflows
├── data-env-test
│   ├── flowhooks
│   │   └── flow_hook_config
│   ├── kvm
│   │   └── env
│   │       └── test
│   │           ├── AccessControl
│   │           └── GetLogValues
│   └── targetservers
│       ├── oauth-v1
│       └── pingstatus-v1
├── data-org-amer-demo13
│   ├── kvm
│   │   ├── org
│   │   │   ├── org-config
│   │   │   └── org-config-private
│   │   └── proxy
│   │       ├── kvm-demo
│   │       │   └── kvm-demo
│   │       └── pingstatus-v1
│   │           └── pingstatus-v1-kvm1
│   ├── proxies
│   │   ├── oauth-v1
│   │   └── pingstatus-v1
│   ├── reports
│   │   ├── 0a5ee23f-1947-4188-8bf5-7beb4007f3fe
│   │   └── fe17c0e3-0769-4072-9566-f1b557a4aab5
│   └── sharedflows
│       ├── AccessControl.zip
│       └── GetLogValues.zip
├── developers.json
└── products.json
```

# Convert from Edge to X apigeecli format
Reformat the output for apigeecli format and move to $X_IMPORT_DIR.

The scripts create-products.sh, create-developers.sh and create-apps.sh use Edge APIs with pagination to extract the entities and convert to apigeecli format.

```
cd $X_IMPORT_DIR

##############################################################
# Org Level
# Proxies and Shared Flows

cp -pr $EDGE_EXPORT_DIR/data-org-${EDGE_ORG}/proxies .
cp -pr $EDGE_EXPORT_DIR/data-org-${EDGE_ORG}/sharedflows .

# API Products, Developers, Apps

$APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR/create-products.sh
$APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR/create-developers.sh
$APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR/create-apps.sh

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

View the results of the conversion, for example:
```
ls -l $X_IMPORT_DIR
-rw-r--r--    1 user  primarygroup  176681 Sep 20 10:43 apps.json
-rw-r--r--    1 user  primarygroup   56375 Sep 20 10:43 developers.json
-rw-r--r--    1 user  primarygroup     260 Sep 20 10:44 env__prod__GeoIPFilter__kvmfile__0.json
-rw-r--r--    1 user  primarygroup     711 Sep 20 10:44 env__prod__GetLogValues__kvmfile__0.json
-rw-r--r--    1 user  primarygroup     199 Sep 20 10:43 org__org-config-private__kvmfile__0.json
-rw-r--r--    1 user  primarygroup     194 Sep 20 10:43 org__org-config__kvmfile__0.json
-rw-r--r--    1 user  primarygroup    2472 Sep 20 10:44 prod__targetservers.json
-rw-r--r--    1 user  primarygroup   65125 Sep 20 10:43 products.json
drwxr-xr-x  260 user  primarygroup    8320 Sep 20 10:07 proxies
-rw-r--r--    1 user  primarygroup     127 Sep 20 10:43 proxy__kvm-demo__kvm-demo__kvmfile__0.json
-rw-r--r--    1 user  primarygroup     208 Sep 20 10:43 proxy__pingstatus-v1__pingstatus-v1-kvm1__kvmfile__0.json
drwxr-xr-x   57 user  primarygroup    1824 Sep 20 10:10 sharedflows
-rw-r--r--    1 user  primarygroup    6878 Sep 20 10:44 test__targetservers.json
```

# Import to X via apigeecli
Use apigeecli to import converted data from $X_IMPORT_DATA

**USAGE TIPS:**
- If Data Residency has been used for your organziation, use the `--region=$REGION` option to set the prefix for the Apigee API. See [Available Apigee API control plane hosting jurisdictions](https://cloud.google.com/apigee/docs/locations#available-apigee-api-control-plane-hosting-jurisdictions) for more details.
- Enable debug for more details using: APIGEECLI_DEBUG=true apigeecli …
```
cd $X_IMPORT_DIR
export TOKEN=$(gcloud auth print-access-token)

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
# Products, Developers, Apps
apigeecli --token=$TOKEN --org=$X_ORG products import --file=$X_IMPORT_DIR/products.json
apigeecli --token=$TOKEN --org=$X_ORG developers import --file=$X_IMPORT_DIR/developers.json
apigeecli --token=$TOKEN --org=$X_ORG apps import --file=$X_IMPORT_DIR/apps.json --dev-file=$X_IMPORT_DIR/developers.json
```

**NOTES:**

- As you run the import commands, especially for proxies and shared flows, observe any errors that are output.
This will let you know what policies and features are not supported (StatisticsCollector policy, NodeJS base proxies, etc.)
- Many 404 errors will be shown when importing KVMs, this is due to how apigeecli works.


For example:
```
bundle wsdl-pass-through-calc not imported: (HTTP 400) {
  "error": {
    "code": 400,
    "message": "bundle contains errors",
    "status": "INVALID_ARGUMENT",
    "details": [
      {
        "@type": "type.googleapis.com/edge.configstore.bundle.BadBundle",
        "violations": [
          {
            "filename": "apiproxy/policies/Extract-Operation-Name.xml",
            "description": "The XMLPayload Variable type attribute \"String\" must be one of \"boolean\", \"double\", \"float\", \"integer\", \"long\", \"nodeset\", or \"string\"."
          }
        ]
      },
      {
        "@type": "type.googleapis.com/google.rpc.RequestInfo",
        "requestId": "16309497941049400312"
      }
    ]
  }
}
```

# Show what's been imported
## Use show-target-org.sh
See the complete target organization artifacts.

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
oauth-v1-app-prod
pingstatus-v1-app-prod

Developers ================================
cicd-developer-prod@google.com
cicd-developer-test@google.com

APIs ================================
oauth-v1
pingstatus-oauth-v1
pingstatus-v1
pingstatus-v1-mock

Shared Flows ================================
cors-v1
post-proxy
post-target
pre-proxy
pre-target
proxy-error-handling-v1
set-logging-values-v1

ORG KVMS ================================
org-config
org-config-private
ENV KVMS ================================
ENV KVMS: prod ================================
oauth-v1
pingstatus-v1

ENV KVMS: test ================================
oauth-v1
pingstatus-v1

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
ENV TARGETSERVERS: test ================================
oauth-v1
pingstatus-oauth-v1
```
## Compare Individual Counts
### Developers
Remove `wc -l` to compare sorted emails, discrepancy could be due to case sensitive emails not being supported.
```
curl -s -H "$EDGE_AUTH" https://api.enterprise.apigee.com/v1/organizations/$EDGE_ORG/developers | jq -r .[] | sort | wc -l
    77
apigeecli --token=$TOKEN --org=$X_ORG developers list | jq -r .developer[].email | sort | wc -l
    74
```

### Apps
Returns appIds, discrepancy could be due to Company Apps not being supported.
```
curl -s -H "$EDGE_AUTH" https://api.enterprise.apigee.com/v1/organizations/$EDGE_ORG/apps | jq -r .[] | wc -l
    107
apigeecli --token=$TOKEN --org=$X_ORG apps list | jq .app[].appId | wc -l
    106
```

### API Products
Remove `wc -l` to compare names
```
curl -s -H "$EDGE_AUTH" https://api.enterprise.apigee.com/v1/organizations/$EDGE_ORG/apiproducts | jq .[] | sort | wc -l
    83
apigeecli --token=$TOKEN --org=$X_ORG products list | jq .apiProduct[].name | sort | wc -l
    83
```

# Clean target org

**WARNING WARNING WARNING:** 

Use with caution, it deletes what's there, not just what you imported!\
It will not delete any deployed proxies or remove target servers that are in use by a deployed proxy.
```
$APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR/clean-target-org.sh
Your active configuration is: [apigeex-custom-non-prod]
apigeex-custom-non-prod
ORG=apigeex-custom-non-prod
OK to proceed (Y/n)? Y
...
```

# Support
This is not an officially supported Google product.


