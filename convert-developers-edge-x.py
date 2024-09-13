import json
import sys
from datetime import datetime

if len(sys.argv) > 1:
    developers_file = sys.argv[1]
    # print("Converting, " + developers_file)
else:
    print("Please provide filename for developers.json as an argument.")
    exit(1)

# Open the file in read mode
with open(developers_file, 'r') as file:
    # Load JSON data from the file
    json_data = json.load(file)

# Iterate through developers and convert timestamps
for developer in json_data["developer"]:
    # Convert 'createdAt'
    developer["createdAt"] = str(developer["createdAt"])

    # Convert 'lastModifiedAt'
    developer["lastModifiedAt"] = str(developer["lastModifiedAt"])

    # lowercase 'email'
    developer["email"] = developer["email"].lower()

# Print the modified JSON
print(json.dumps(json_data, indent=4))