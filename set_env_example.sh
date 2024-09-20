# Edge variables
export EDGE_X_MIGRATION_DIR=$HOME/work/APIGEEX/edge-x-migration
export EDGE_ORG=your_edge_org_name
export ENVS="env1 env2"

export EDGE_EXPORT_DIR=$EDGE_X_MIGRATION_DIR/edge-export
mkdir $EDGE_EXPORT_DIR
export EXPORTED_ORG_DIR=$EDGE_EXPORT_DIR/data-org-${EDGE_ORG}

# X variables
export X_ORG=your_x_org_name
export X_IMPORT_DIR=$EDGE_X_MIGRATION_DIR/x-import
mkdir $X_IMPORT_DIR

# Other variables
export APIGEE_MIGRATE_EDGE_TO_X_TOOLS_DIR=$EDGE_X_MIGRATION_DIR/apigee-migrate-edge-to-x-tools
export APIGEE_MIGRATE_TOOL_DIR=$EDGE_X_MIGRATION_DIR/apigee-migrate-tool