import json
import sys
from datetime import datetime

if len(sys.argv) > 1:
    products_file = sys.argv[1]
    # print("Converting, " + products_file)
else:
    print("Please provide filename for products.json as an argument.")
    exit(1)

# Open the file in read mode
with open(products_file, 'r') as file:
    # Load JSON data from the file
    json_data = json.load(file)

# Iterate through apiProduct and convert timestamps
for product in json_data:
    # Convert 'createdAt'
    product["createdAt"] = str(product["createdAt"])

    # Convert 'lastModifiedAt'
    product["lastModifiedAt"] = str(product["lastModifiedAt"])

# Print the modified JSON
print(json.dumps(json_data, indent=4))