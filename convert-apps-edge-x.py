import json
import sys
from datetime import datetime

if len(sys.argv) > 1:
    apps_file = sys.argv[1]
    # print("Converting, " + apps_file)
else:
    print("Please provide filename for apps.json as an argument.")
    exit(1)


# Open the file in read mode
with open(apps_file, 'r') as file:
    # Load JSON data from the file
    json_data = json.load(file)

# Iterate through array of app objects and convert timestamps
for app in json_data:
    # Convert 'createdAt'
    app["createdAt"] = str(app["createdAt"])

    # Convert 'lastModifiedAt'
    app["lastModifiedAt"] = str(app["lastModifiedAt"])

    # Convert credentials expiresAt and issuedAt
    for cred in app["credentials"]:
        cred["expiresAt"] = str(cred["expiresAt"])
        cred["issuedAt"] = str(cred["issuedAt"])

# Print the modified JSON
print(json.dumps(json_data, indent=4))
